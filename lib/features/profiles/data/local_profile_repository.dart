import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';

import '../../../core/storage/local_data_exception.dart';
import '../../../services/storage/local_database.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_validation.dart';
import '../domain/user_profile.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this.database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final LocalDatabase database;
  final DateTime Function() _now;
  static final _uuid = Uuid(goptions: GlobalOptions(CryptoRNG()));

  @override
  Future<UserProfile> createProfile({
    required String fullName,
    required String birthDate,
  }) => protectLocalData(() async {
    ProfileValidation.validate(fullName, birthDate);
    final timestamp = _now().toUtc();
    final profile = UserProfile(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      birthDate: birthDate,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.insert('user_profiles', profile.toMap());
      await txn.insert('profile_cache_revisions', {
        'profile_id': profile.id,
        'revision_token': _uuid.v4(),
      });
      // Auto-select only when creating the first local profile.
      await txn.rawUpdate(
        'UPDATE app_state SET selected_profile_id = ? '
        'WHERE id = 1 AND selected_profile_id IS NULL '
        'AND (SELECT COUNT(*) FROM user_profiles) = 1',
        [profile.id],
      );
    });
    return profile;
  });

  @override
  Future<UserProfile?> getProfileById(String id) => protectLocalData(() async {
    final db = await database.database;
    final rows = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : UserProfile.fromMap(rows.single);
  });

  @override
  Future<List<UserProfile>> getAllProfiles() => protectLocalData(() async {
    final db = await database.database;
    final rows = await db.query(
      'user_profiles',
      orderBy: 'created_at ASC, id ASC',
    );
    return List.unmodifiable(rows.map(UserProfile.fromMap));
  });

  @override
  Future<UserProfile> updateProfile({
    required String id,
    required String fullName,
    required String birthDate,
  }) => protectLocalData(() async {
    ProfileValidation.validate(fullName, birthDate);
    final db = await database.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'user_profiles',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty)
        throw const LocalDataException(LocalDataFailure.notFound);
      final old = UserProfile.fromMap(rows.single);
      final name = fullName.trim();
      if (old.fullName == name && old.birthDate == birthDate) return old;
      final now = _now().toUtc();
      // Strictly increase updated_at even if the device clock moved backwards.
      final updatedAt =
          now.isAfter(old.updatedAt)
              ? now
              : old.updatedAt.add(const Duration(microseconds: 1));
      final updated = UserProfile(
        id: id,
        fullName: name,
        birthDate: birthDate,
        createdAt: old.createdAt,
        updatedAt: updatedAt,
      );
      await txn.update(
        'user_profiles',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'profile_cache_revisions',
        {'revision_token': _uuid.v4()},
        where: 'profile_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'calculation_cache',
        where: 'profile_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'calculation_contexts',
        where: 'profile_id = ?',
        whereArgs: [id],
      );
      return updated;
    });
  });

  @override
  Future<void> deleteProfile(String id) => protectLocalData(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.delete('user_profiles', where: 'id = ?', whereArgs: [id]);
      // Foreign keys clear selected ID and cascade private caches atomically.
    });
  });

  @override
  Future<void> deleteAllProfiles() => protectLocalData(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.delete('user_profiles');
    });
  });

  @override
  Future<void> selectProfile(String? id) => protectLocalData(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      if (id != null) {
        final rows = await txn.query(
          'user_profiles',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isEmpty)
          throw const LocalDataException(LocalDataFailure.notFound);
      }
      await txn.update('app_state', {
        'selected_profile_id': id,
      }, where: 'id = 1');
    });
  });

  @override
  Future<ProfileSnapshot> getSnapshot() => protectLocalData(() async {
    final db = await database.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'user_profiles',
        orderBy: 'created_at ASC, id ASC',
      );
      final profiles = List<UserProfile>.unmodifiable(
        rows.map(UserProfile.fromMap),
      );
      final selection = await txn.query('app_state', where: 'id = 1');
      final selectedId = selection.single['selected_profile_id'];
      UserProfile? selected;
      for (final profile in profiles) {
        if (profile.id == selectedId) selected = profile;
      }
      // Repair any stale reference left by externally modified database files.
      if (selected == null && selectedId != null) {
        await txn.update('app_state', {
          'selected_profile_id': null,
        }, where: 'id = 1');
      }
      return ProfileSnapshot(profiles, selected);
    });
  });
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => LocalProfileRepository(ref.watch(localDatabaseProvider)),
);
