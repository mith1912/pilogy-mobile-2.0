import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/core/storage/local_data_exception.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/services/storage/cache_store.dart';
import 'package:pilogy_app/services/storage/local_database.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late LocalDatabase store;
  late LocalProfileRepository profiles;
  late CacheStore cache;
  late DateTime clock;

  void connect() {
    store = LocalDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, LocalDatabase.filename),
    );
    profiles = LocalProfileRepository(store, now: () => clock);
    cache = CacheStore(store, now: () => clock);
  }

  Future<UserProfile> create([
    String name = 'Nguyễn Thị Minh An',
    String birth = '2000-02-29',
  ]) => profiles.createProfile(fullName: name, birthDate: birth);

  Future<CalculationCacheContext> context(
    UserProfile profile, {
    String version = 'v1',
    String date = '2026-11-09',
  }) => cache.prepareCalculation(
    profileId: profile.id,
    calculationVersion: version,
    referenceDate: date,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pilogy-m02-');
    clock = DateTime.utc(2026, 11, 9);
    connect();
  });
  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test('initializes versioned schema with enforced foreign keys', () async {
    final db = await store.database;
    expect(await db.getVersion(), LocalDatabase.schemaVersion);
    expect(LocalDatabase.schemaVersion, 1);
    expect((await db.rawQuery('PRAGMA foreign_keys')).single.values.single, 1);
    final tables =
        (await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        )).map((row) => row['name']).toSet();
    expect(
      tables,
      containsAll([
        'user_profiles',
        'calculation_cache',
        'interpretation_cache',
        'app_state',
        'profile_cache_revisions',
        'calculation_contexts',
      ]),
    );
    final fields =
        (await db.rawQuery(
          'PRAGMA table_info(user_profiles)',
        )).map((row) => row['name']).toSet();
    expect(fields, {
      'id',
      'full_name',
      'birth_date',
      'created_at',
      'updated_at',
    });
  });

  test(
    'create and read profile uses UUID and preserves Vietnamese Unicode',
    () async {
      final profile = await create('  Đặng Thị Mỹ Duyên  ');
      expect(
        profile.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(profile.fullName, 'Đặng Thị Mỹ Duyên');
      expect(profile.birthDate, '2000-02-29');
      expect(profile.createdAt, clock);
      expect(profile.updatedAt, clock);
      expect(
        (await profiles.getProfileById(profile.id))?.fullName,
        profile.fullName,
      );
      expect(await profiles.getProfileById('absent'), isNull);
    },
  );

  test('multiple independent profiles survive a database restart', () async {
    final first = await create();
    clock = clock.add(const Duration(seconds: 1));
    final second = await create('Trần Hoàng Nam', '1994-03-24');
    await profiles.selectProfile(second.id);
    await store.close();
    connect();
    expect((await profiles.getAllProfiles()).map((p) => p.id), [
      first.id,
      second.id,
    ]);
    expect((await profiles.getSnapshot()).selectedProfile?.id, second.id);
  });

  test(
    'update preserves creation timestamp and advances updated timestamp',
    () async {
      final profile = await create();
      clock = clock.add(const Duration(days: 1));
      final updated = await profiles.updateProfile(
        id: profile.id,
        fullName: 'Lê Hoàng Minh',
        birthDate: '1995-08-18',
      );
      expect(updated.createdAt, profile.createdAt);
      expect(updated.updatedAt, clock);
      expect(
        (await profiles.getProfileById(profile.id))?.birthDate,
        '1995-08-18',
      );
      final noChange = await profiles.updateProfile(
        id: profile.id,
        fullName: updated.fullName,
        birthDate: updated.birthDate,
      );
      expect(noChange.updatedAt, updated.updatedAt);
      clock = DateTime.utc(2020);
      final later = await profiles.updateProfile(
        id: profile.id,
        fullName: 'Lê Minh',
        birthDate: updated.birthDate,
      );
      expect(later.updatedAt.isAfter(updated.updatedAt), isTrue);
    },
  );

  test(
    'selected deletion clears selection without selecting a different profile',
    () async {
      expect((await profiles.getSnapshot()).selectedProfile, isNull);
      final first = await create();
      final second = await create('Trần Nam');
      expect((await profiles.getSnapshot()).selectedProfile?.id, first.id);
      await profiles.deleteProfile(first.id);
      expect((await profiles.getSnapshot()).selectedProfile, isNull);
      expect(await profiles.getProfileById(first.id), isNull);
      await profiles.selectProfile(second.id);
      await profiles.deleteProfile(second.id);
      expect((await profiles.getSnapshot()).profiles, isEmpty);
      expect((await profiles.getSnapshot()).selectedProfile, isNull);
    },
  );

  test(
    'delete all profiles cascades private cache and keeps public articles',
    () async {
      final first = await create();
      await create('Trần An');
      final key = await context(first);
      await cache.saveCalculation(key, responseJson: '{}');
      await cache.saveInterpretation(
        indexType: 'personality',
        numberValue: 11,
        locale: 'vi',
        contentVersion: 'draft',
        responseJson: '{}',
      );
      await profiles.deleteAllProfiles();
      expect((await profiles.getSnapshot()).profiles, isEmpty);
      expect((await profiles.getSnapshot()).selectedProfile, isNull);
      final statistics = await cache.statistics();
      expect(statistics.calculations, 0);
      expect(statistics.articles, 1);
      expect(await cache.saveCalculation(key, responseJson: '{}'), isFalse);
    },
  );

  test(
    'invalid selection is rejected and existing selection is retained',
    () async {
      final first = await create();
      await expectLater(
        profiles.selectProfile('missing'),
        throwsA(isA<LocalDataException>()),
      );
      expect((await profiles.getSnapshot()).selectedProfile?.id, first.id);
      await profiles.selectProfile(null);
      expect((await profiles.getSnapshot()).selectedProfile, isNull);
    },
  );

  for (final name in ['', '   ', '12345', '★', List.filled(201, 'a').join()]) {
    test(
      'rejects invalid name without writing a profile (${name.length} chars)',
      () async {
        await expectLater(create(name), throwsA(isA<LocalDataException>()));
        expect(await profiles.getAllProfiles(), isEmpty);
      },
    );
  }
  for (final date in [
    '2023-02-29',
    '1900-02-29',
    '0000-01-01',
    '2000-13-01',
    '2000-04-31',
    '2000-00-01',
    '2000-01-00',
    '2000-2-03',
    '2000-01-01T00:00:00Z',
    '2000-01-01\n',
    'invalid',
  ]) {
    test('rejects invalid Gregorian birth date $date', () async {
      await expectLater(
        create('Nguyễn An', date),
        throwsA(isA<LocalDataException>()),
      );
      expect(await profiles.getAllProfiles(), isEmpty);
    });
  }
  for (final date in [
    '0001-01-01',
    '2000-02-29',
    '2024-02-29',
    '2400-02-29',
    '9999-12-31',
  ]) {
    test(
      'accepts real date $date including leap years and future dates',
      () async {
        expect((await create('Nguyễn An', date)).birthDate, date);
      },
    );
  }

  test('bound parameters preserve punctuation without executing SQL', () async {
    final profile = await create("O'Connor; DROP TABLE user_profiles; --");
    expect(
      (await profiles.getProfileById(profile.id))?.fullName,
      profile.fullName,
    );
    expect(await profiles.getAllProfiles(), hasLength(1));
  });

  test(
    'invalid update is atomic and retains existing profile and result',
    () async {
      final profile = await create();
      final key = await context(profile);
      await cache.saveCalculation(key, responseJson: '{"test":true}');
      await expectLater(
        profiles.updateProfile(
          id: profile.id,
          fullName: '',
          birthDate: profile.birthDate,
        ),
        throwsA(isA<LocalDataException>()),
      );
      expect(
        (await profiles.getProfileById(profile.id))?.fullName,
        profile.fullName,
      );
      expect(await cache.readCalculation(key), isNotNull);
    },
  );

  test(
    'changed name and birth date invalidate cache and rotate opaque revisions',
    () async {
      var profile = await create();
      var key = await context(profile);
      await cache.saveCalculation(
        key,
        responseJson: '{"test":true}',
        contentVersion: 'draft',
      );
      profile = await profiles.updateProfile(
        id: profile.id,
        fullName: 'Lê An',
        birthDate: profile.birthDate,
      );
      expect(await cache.readCalculation(key), isNull);
      expect(await cache.saveCalculation(key, responseJson: '{}'), isFalse);
      final next = await context(profile);
      expect(next.inputFingerprint, isNot(key.inputFingerprint));
      await cache.saveCalculation(next, responseJson: '{}');
      key = next;
      await profiles.updateProfile(
        id: profile.id,
        fullName: profile.fullName,
        birthDate: '2001-03-01',
      );
      expect(await cache.readCalculation(key), isNull);
      final latest = await context(profile);
      expect(latest.profile.birthDate, '2001-03-01');
    },
  );

  test('no-op update and identical context retain cached results', () async {
    final profile = await create();
    final key = await context(profile);
    await cache.saveCalculation(key, responseJson: '{}');
    await profiles.updateProfile(
      id: profile.id,
      fullName: profile.fullName,
      birthDate: profile.birthDate,
    );
    final same = await context(profile);
    expect(same.contextId, key.contextId);
    expect(await cache.readCalculation(same), isNotNull);
  });

  test(
    'calculation version and reference period changes reject late responses',
    () async {
      final profile = await create();
      final first = await context(profile);
      await cache.saveCalculation(first, responseJson: '{}');
      final newVersion = await context(profile, version: 'v2');
      expect(await cache.readCalculation(first), isNull);
      expect(await cache.saveCalculation(first, responseJson: '{}'), isFalse);
      await cache.saveCalculation(newVersion, responseJson: '{}');
      final newDate = await context(profile, version: 'v2', date: '2026-12-01');
      expect(await cache.readCalculation(newVersion), isNull);
      expect(
        await cache.saveCalculation(newVersion, responseJson: '{}'),
        isFalse,
      );
      expect(await cache.saveCalculation(newDate, responseJson: '{}'), isTrue);
    },
  );

  test(
    'deletion cascades private cache and leaves shared interpretations',
    () async {
      final profile = await create();
      final key = await context(profile);
      await cache.saveCalculation(key, responseJson: '{}');
      await cache.saveInterpretation(
        indexType: 'lifePath',
        numberValue: 7,
        locale: 'vi',
        contentVersion: 'draft',
        responseJson: '{"article":"shared"}',
      );
      await profiles.deleteProfile(profile.id);
      final db = await store.database;
      expect(await db.query('calculation_cache'), isEmpty);
      expect(await db.query('calculation_contexts'), isEmpty);
      expect(await db.query('profile_cache_revisions'), isEmpty);
      expect(await cache.saveCalculation(key, responseJson: '{}'), isFalse);
      expect(
        await cache.readInterpretation(
          indexType: 'lifePath',
          numberValue: 7,
          locale: 'vi',
          contentVersion: 'draft',
        ),
        isNotNull,
      );
    },
  );

  test('shared article uniqueness and independent content versions', () async {
    for (final body in ['{"revision":1}', '{"revision":2}']) {
      await cache.saveInterpretation(
        indexType: 'personality',
        numberValue: 11,
        locale: 'vi',
        contentVersion: 'draft',
        responseJson: body,
      );
    }
    await cache.saveInterpretation(
      indexType: 'personality',
      numberValue: 11,
      locale: 'vi',
      contentVersion: 'next',
      responseJson: '{}',
    );
    final db = await store.database;
    expect(await db.query('interpretation_cache'), hasLength(2));
    expect(
      (await cache.readInterpretation(
        indexType: 'personality',
        numberValue: 11,
        locale: 'vi',
        contentVersion: 'draft',
      ))?.responseJson,
      '{"revision":2}',
    );
  });

  test(
    'foreign key rejects orphan calculations and stale selected IDs',
    () async {
      final db = await store.database;
      await expectLater(
        db.insert('calculation_cache', {
          'id': 'orphan',
          'profile_id': 'absent',
          'calculation_version': 'v1',
          'reference_date': '2026-11-09',
          'locale': 'vi',
          'input_fingerprint': 'opaque',
          'response_json': '{}',
          'cached_at': clock.toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.update('app_state', {
          'selected_profile_id': 'absent',
        }, where: 'id=1'),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'cache clear retains profiles and selection and blocks in-flight saves',
    () async {
      final profile = await create();
      final key = await context(profile);
      await cache.saveCalculation(key, responseJson: '{}');
      await cache.clearCache();
      expect(await profiles.getAllProfiles(), hasLength(1));
      expect((await profiles.getSnapshot()).selectedProfile?.id, profile.id);
      expect(await cache.saveCalculation(key, responseJson: '{}'), isFalse);
    },
  );

  test(
    'closed database errors are safe and contain no SQL or profile values',
    () async {
      await store.close();
      await expectLater(
        create('Sensitive Name'),
        throwsA(
          isA<LocalDataException>().having(
            (e) => e.failure,
            'failure',
            LocalDataFailure.closed,
          ),
        ),
      );
    },
  );

  test(
    'private and shared cached responses survive reopening the file',
    () async {
      final profile = await create();
      final key = await context(profile);
      await cache.saveCalculation(
        key,
        responseJson: '{"fixture":true}',
        contentVersion: 'draft',
      );
      await cache.saveInterpretation(
        indexType: 'lifePath',
        numberValue: 7,
        locale: 'vi',
        contentVersion: 'draft',
        responseJson: '{"fixture":"article"}',
      );
      await store.close();
      connect();
      expect((await cache.readCalculation(key))?.contentVersion, 'draft');
      expect(
        (await cache.readInterpretation(
          indexType: 'lifePath',
          numberValue: 7,
          locale: 'vi',
          contentVersion: 'draft',
        ))?.responseJson,
        '{"fixture":"article"}',
      );
    },
  );

  test(
    'malformed cache objects and unsupported article keys are rejected',
    () async {
      final profile = await create();
      final key = await context(profile);
      for (final body in ['not json', 'null', '[]']) {
        await expectLater(
          cache.saveCalculation(key, responseJson: body),
          throwsA(isA<LocalDataException>()),
        );
      }
      await expectLater(
        cache.saveInterpretation(
          indexType: 'inventedIndex',
          numberValue: 7,
          locale: 'vi',
          contentVersion: 'draft',
          responseJson: '{}',
        ),
        throwsA(isA<LocalDataException>()),
      );
      expect(await (await store.database).query('calculation_cache'), isEmpty);
    },
  );

  test('legacy database filename remains untouched', () async {
    final legacyPath = path.join(directory.path, 'pilogy.db');
    final legacy = await databaseFactoryFfi.openDatabase(legacyPath);
    await legacy.execute('CREATE TABLE untouched (marker TEXT)');
    await legacy.insert('untouched', {'marker': 'legacy'});
    await legacy.close();
    await create();
    final reopened = await databaseFactoryFfi.openDatabase(legacyPath);
    expect((await reopened.query('untouched')).single['marker'], 'legacy');
    await reopened.close();
  });

  test('unknown schema downgrade fails without deleting data', () async {
    final profile = await create();
    final db = await store.database;
    await db.setVersion(2);
    await store.close();
    connect();
    await expectLater(store.database, throwsA(anything));
    // Reopen without a target version to inspect the untouched future database.
    final future = await databaseFactoryFfi.openDatabase(
      path.join(directory.path, LocalDatabase.filename),
    );
    expect(await future.getVersion(), 2);
    expect((await future.query('user_profiles')).single['id'], profile.id);
    await future.close();
  });
}
