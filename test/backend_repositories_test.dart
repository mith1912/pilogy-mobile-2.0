import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/core/config/app_environment.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/data/backend_repositories.dart';
import 'package:pilogy_app/services/network/api_client.dart';
import 'package:pilogy_app/services/network/dio_provider.dart';
import 'package:pilogy_app/services/storage/cache_store.dart';
import 'package:pilogy_app/services/storage/local_database.dart';
import 'backend_test_support.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late LocalDatabase database;
  late LocalProfileRepository profiles;
  late CacheStore cache;
  late Dio dio;
  late TestAdapter adapter;
  late NumerologyRepository repository;
  late InterpretationRepository articles;
  bool offline = false;
  String version = 'v1', content = 'v1.0.0-draft';
  Completer<void>? pending;
  setUp(() async {
    offline = false;
    version = 'v1';
    content = 'v1.0.0-draft';
    pending = null;
    directory = await Directory.systemTemp.createTemp('pilogy-m03-');
    database = LocalDatabase(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}/test.db',
    );
    profiles = LocalProfileRepository(database);
    cache = CacheStore(database);
    dio = createDio(AppEnvironment());
    adapter = TestAdapter((o) async {
      if (offline)
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      if (o.path == 'config') {
        final body = fixture('config');
        object(body['data'])['calculationVersion'] = version;
        return jsonBody(body);
      }
      if (o.path == 'numerology/definitions') {
        final body = fixture('definitions');
        object(body['data'])['contentVersion'] = content;
        return jsonBody(body);
      }
      if (o.path == 'numerology/calculate') {
        final gate = pending;
        if (gate != null) await gate.future;
        final body = fixture('calculation');
        final data = object(body['data']);
        data['calculationVersion'] = version;
        data['contentVersion'] = content;
        final request = object(o.data);
        data['referenceDate'] = request['referenceDate'];
        for (final value in object(data['indices']).values) {
          final index = object(value);
          if (index.containsKey('referenceDate'))
            index['referenceDate'] = request['referenceDate'];
        }
        return jsonBody(body);
      }
      final body = fixture('article');
      object(body['data'])['contentVersion'] = content;
      return jsonBody(body);
    });
    dio.httpClientAdapter = adapter;
    final api = ApiClient(dio);
    repository = NumerologyRepository(api, cache, ConfigRepository(api));
    articles = InterpretationRepository(api, cache);
  });
  tearDown(() async {
    dio.close(force: true);
    await database.close();
    await directory.delete(recursive: true);
  });
  Future<String> profile([String name = 'Nguyễn Văn An']) async =>
      (await profiles.createProfile(
        fullName: name,
        birthDate: '1990-05-20',
      )).id;
  Future<List<DataSnapshot<CalculationResult>>> load(
    String id, [
    String date = '2026-11-08',
  ]) => repository.watch(profileId: id, referenceDate: date).toList();

  test(
    'successful compact request writes and reads private SQLite cache',
    () async {
      final id = await profile();
      final states = await load(id);
      expect(states.first.refreshing, true);
      expect(states.last.freshness, DataFreshness.fresh);
      expect(states.last.data!.indices[IndexType.personality]!.value, 11);
      final request = adapter.requests.singleWhere(
        (r) => r.path == 'numerology/calculate',
      );
      expect(object(request.data).keys.toSet(), {
        'fullName',
        'birthDate',
        'referenceDate',
        'locale',
      });
      expect(
        await cache.findCalculation(profileId: id, referenceDate: '2026-11-08'),
        isNotNull,
      );
      final again = await load(id);
      expect(again.first.data, isNotNull);
      expect(again.first.freshness, DataFreshness.stale);
      expect(again.last.freshness, DataFreshness.fresh);
    },
  );
  test(
    'offline fallback is stale and no-cache is missing with safe error',
    () async {
      final id = await profile();
      await load(id);
      offline = true;
      final cached = (await load(id)).last;
      expect(cached.data, isNotNull);
      expect(cached.offline, true);
      expect(cached.freshness, DataFreshness.stale);
      final missing = (await load(await profile('Lê An'))).last;
      expect(missing.data, isNull);
      expect(missing.offline, true);
      expect(missing.freshness, DataFreshness.missing);
    },
  );
  test('profile edit invalidates private data and isolates profiles', () async {
    final first = await profile();
    final second = await profile('Lê An');
    await load(first);
    offline = true;
    expect((await load(second)).last.data, isNull);
    await profiles.updateProfile(
      id: first,
      fullName: 'Trần An',
      birthDate: '1990-05-20',
    );
    expect((await load(first)).last.data, isNull);
  });
  for (final date in ['2026-12-01', '2027-01-01']) {
    test('period boundary $date does not reuse older date', () async {
      final id = await profile();
      await load(id);
      offline = true;
      expect((await load(id, date)).last.data, isNull);
      offline = false;
      expect((await load(id, date)).last.data!.referenceDate, date);
    });
  }
  test(
    'calculation version changes replace old identity; unknown versions are stale',
    () async {
      final id = await profile();
      await load(id);
      version = 'v2';
      final next = await load(id);
      expect(next.first.freshness, DataFreshness.stale);
      expect(next.last.data!.calculationVersion, 'v2');
      final rows = await (await database.database).query('calculation_cache');
      expect(rows, hasLength(1));
      expect(rows.single['calculation_version'], 'v2');
    },
  );
  test(
    'known incompatible calculation version is removed even if definitions fails',
    () async {
      final id = await profile();
      await load(id);
      dio.httpClientAdapter = TestAdapter((o) async {
        if (o.path == 'config') {
          final body = fixture('config');
          object(body['data'])['calculationVersion'] = 'v2';
          return jsonBody(body);
        }
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      });
      final states = await load(id);
      expect(states.last.data, isNull);
      expect(states.last.freshness, DataFreshness.missing);
      expect(
        await cache.findCalculation(profileId: id, referenceDate: '2026-11-08'),
        isNull,
      );
    },
  );
  test(
    'content-only update retains numeric fallback while refreshing',
    () async {
      final id = await profile();
      await load(id);
      content = 'v-next';
      final next = await load(id);
      expect(next.first.data!.indices[IndexType.lifePath]!.value, 8);
      expect(next.last.data!.contentVersion, 'v-next');
    },
  );
  test('late calculation after edit is rejected by SQLite context', () async {
    final id = await profile();
    pending = Completer<void>();
    final future = load(id);
    await Future<void>(() async {
      while (!adapter.requests.any((r) => r.path == 'numerology/calculate')) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }).timeout(const Duration(seconds: 5));
    await profiles.updateProfile(
      id: id,
      fullName: 'Trần An',
      birthDate: '1990-05-20',
    );
    pending!.complete();
    final states = await future;
    expect(states.where((s) => s.freshness == DataFreshness.fresh), isEmpty);
    expect(
      await cache.findCalculation(profileId: id, referenceDate: '2026-11-08'),
      isNull,
    );
  });
  test(
    'new article content version keeps old article as stale offline fallback',
    () async {
      await articles.watch(type: IndexType.personality, value: 11).toList();
      offline = true;
      final states =
          await articles
              .watch(
                type: IndexType.personality,
                value: 11,
                contentVersion: 'next',
              )
              .toList();
      expect(states.first.data, isNotNull);
      expect(states.first.freshness, DataFreshness.stale);
      expect(states.last.contentStale, true);
      expect(states.last.data!.contentVersion, 'v1.0.0-draft');
    },
  );
  test('Master article key uses 11; shared cache falls back offline', () async {
    final states =
        await articles.watch(type: IndexType.personality, value: 11).toList();
    expect(states.last.freshness, DataFreshness.fresh);
    expect(adapter.requests.last.path, endsWith('/personality/11'));
    expect(
      await cache.readInterpretation(
        indexType: 'personality',
        numberValue: 11,
        locale: 'vi',
        contentVersion: content,
      ),
      isNotNull,
    );
    offline = true;
    final cached =
        await articles
            .watch(
              type: IndexType.personality,
              value: 11,
              contentVersion: content,
            )
            .toList();
    expect(cached.first.freshness, DataFreshness.cached);
    expect(cached.last.freshness, DataFreshness.stale);
    expect(cached.last.offline, true);
  });
}
