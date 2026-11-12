import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../core/storage/local_data_exception.dart';

class LocalDatabase {
  LocalDatabase({DatabaseFactory? factory, String? databasePath})
    : _factory = factory ?? databaseFactory,
      _databasePath = databasePath;

  /// New namespace; never inspect, overwrite or delete legacy pilogy.db files.
  static const filename = 'pilogy_v1_local.db';
  static const schemaVersion = 1;
  final DatabaseFactory _factory;
  final String? _databasePath;
  Future<Database>? _opening;
  bool _closed = false;

  Future<Database> get database {
    if (_closed) throw const LocalDataException(LocalDataFailure.closed);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final location =
          _databasePath ??
          path.join(await _factory.getDatabasesPath(), filename);
      return await _factory.openDatabase(
        location,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            for (final statement in schema) {
              await db.execute(statement);
            }
          },
          onUpgrade: migrate,
          // Unknown future schema versions fail closed; never downgrade/delete.
          onDowngrade: (db, oldVersion, newVersion) async {
            throw const LocalDataException(LocalDataFailure.unsupportedSchema);
          },
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Register explicit, tested incremental steps before increasing schemaVersion.
    throw const LocalDataException(LocalDataFailure.unsupportedSchema);
  }

  Future<void> close() async {
    _closed = true;
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  static const schema = [
    '''CREATE TABLE user_profiles (
      id TEXT PRIMARY KEY NOT NULL,
      full_name TEXT NOT NULL,
      birth_date TEXT NOT NULL CHECK (
        birth_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
      ),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE app_state (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      selected_profile_id TEXT REFERENCES user_profiles(id) ON DELETE SET NULL
    )''',
    'INSERT INTO app_state (id) VALUES (1)',
    '''CREATE TABLE profile_cache_revisions (
      profile_id TEXT PRIMARY KEY NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
      revision_token TEXT NOT NULL
    )''',
    '''CREATE TABLE calculation_contexts (
      profile_id TEXT PRIMARY KEY NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
      context_id TEXT NOT NULL,
      input_fingerprint TEXT NOT NULL,
      calculation_version TEXT NOT NULL,
      reference_date TEXT NOT NULL,
      locale TEXT NOT NULL
    )''',
    '''CREATE TABLE calculation_cache (
      id TEXT PRIMARY KEY NOT NULL,
      profile_id TEXT NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
      calculation_version TEXT NOT NULL,
      content_version TEXT,
      reference_date TEXT NOT NULL,
      locale TEXT NOT NULL,
      input_fingerprint TEXT NOT NULL,
      response_json TEXT NOT NULL,
      cached_at TEXT NOT NULL,
      UNIQUE (profile_id, calculation_version, reference_date, locale, input_fingerprint)
    )''',
    '''CREATE TABLE interpretation_cache (
      id TEXT PRIMARY KEY NOT NULL,
      index_type TEXT NOT NULL,
      number_value INTEGER NOT NULL,
      locale TEXT NOT NULL,
      content_version TEXT NOT NULL,
      response_json TEXT NOT NULL,
      cached_at TEXT NOT NULL,
      UNIQUE (index_type, number_value, locale, content_version)
    )''',
  ];
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final database = LocalDatabase();
  ref.onDispose(() {
    unawaited(database.close().catchError((Object _) {}));
  });
  return database;
});
