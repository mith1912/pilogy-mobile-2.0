import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/core/storage/local_data_exception.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'package:pilogy_app/services/storage/local_database.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late LocalDatabase database;
  late LocalProfileRepository repository;
  late ProviderContainer container;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pilogy-view-model-');
    database = LocalDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, LocalDatabase.filename),
    );
    repository = LocalProfileRepository(database);
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
  });
  tearDown(() async {
    container.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('loads empty state without fabricated profiles', () async {
    final subscription = container.listen(
      profilesViewModelProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final state = await container.read(profilesViewModelProvider.future);
    expect(state.profiles, isEmpty);
    expect(state.selectedProfile, isNull);
  });

  test(
    'writes refresh list and derived selection; failed writes retain state',
    () async {
      final subscription = container.listen(
        selectedProfileProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      await container.read(profilesViewModelProvider.future);
      final model = container.read(profilesViewModelProvider.notifier);
      final first = await model.createProfile(
        fullName: 'Nguyễn An',
        birthDate: '2000-02-29',
      );
      final second = await model.createProfile(
        fullName: 'Lê Minh',
        birthDate: '1995-08-18',
      );
      await model.selectProfile(second.id);
      expect(
        container.read(selectedProfileProvider).valueOrNull?.id,
        second.id,
      );
      await expectLater(
        model.updateProfile(
          id: second.id,
          fullName: '',
          birthDate: '1995-08-18',
        ),
        throwsA(isA<LocalDataException>()),
      );
      expect(
        container.read(profilesViewModelProvider).valueOrNull?.profiles,
        hasLength(2),
      );
      await model.deleteProfile(second.id);
      expect(container.read(selectedProfileProvider).valueOrNull, isNull);
      expect(
        container
            .read(profilesViewModelProvider)
            .valueOrNull
            ?.profiles
            .single
            .id,
        first.id,
      );
    },
  );

  test(
    'serialized concurrent creates keep the complete refreshed list',
    () async {
      final subscription = container.listen(
        profilesViewModelProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      final model = container.read(profilesViewModelProvider.notifier);
      await Future.wait([
        model.createProfile(fullName: 'Nguyễn An', birthDate: '2000-01-01'),
        model.createProfile(fullName: 'Trần Nam', birthDate: '1999-01-01'),
      ]);
      expect(
        container.read(profilesViewModelProvider).valueOrNull?.profiles,
        hasLength(2),
      );
    },
  );
}
