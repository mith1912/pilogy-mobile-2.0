import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';

import '../../core/storage/local_data_exception.dart';
import '../../features/profiles/domain/profile_validation.dart';
import '../../features/profiles/domain/user_profile.dart';
import 'local_database.dart';

/// Capture before a future M03 request, then supply unchanged when saving it.
class CalculationCacheContext {
  const CalculationCacheContext({
    required this.profileId,
    required this.contextId,
    required this.inputFingerprint,
    required this.calculationVersion,
    required this.profile,
    required this.referenceDate,
    required this.locale,
  });
  final String profileId;
  final UserProfile profile;
  final String contextId;
  final String inputFingerprint;
  final String calculationVersion;
  final String referenceDate;
  final String locale;
}

class CachedResponse {
  const CachedResponse({
    required this.responseJson,
    required this.cachedAt,
    this.contentVersion,
  });
  final String responseJson;
  final DateTime cachedAt;
  final String? contentVersion;
}

class CacheStatistics {
  const CacheStatistics(this.calculations, this.articles, this.allocatedBytes);
  final int calculations, articles, allocatedBytes;
}

/// Local persistence only: no HTTP, number formulas, or fabricated API data.
class CacheStore {
  CacheStore(this.database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final LocalDatabase database;
  final DateTime Function() _now;
  static final _uuid = Uuid(goptions: GlobalOptions(CryptoRNG()));
  static const indexTypes = {
    'lifePath',
    'soulUrge',
    'personality',
    'expression',
    'birthday',
    'attitude',
    'maturity',
    'personalYear',
    'personalMonth',
  };

  /// Changes of calculation version/date/locale expire the profile's old result.
  /// Fingerprints are random local revision UUIDs, never hashes of personal data.
  Future<CalculationCacheContext> prepareCalculation({
    required String profileId,
    required String calculationVersion,
    required String referenceDate,
    String locale = 'vi',
  }) => protectLocalData(() async {
    if (calculationVersion.trim().isEmpty ||
        locale != 'vi' ||
        !ProfileValidation.isCalendarDate(referenceDate)) {
      throw const LocalDataException(LocalDataFailure.invalidInput);
    }
    final db = await database.database;
    return db.transaction((txn) async {
      final revisions = await txn.query(
        'profile_cache_revisions',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      if (revisions.isEmpty)
        throw const LocalDataException(LocalDataFailure.notFound);
      final inputRows = await txn.query(
        'user_profiles',
        where: 'id = ?',
        whereArgs: [profileId],
      );
      final profile = UserProfile.fromMap(inputRows.single);
      final fingerprint = revisions.single['revision_token']! as String;
      final current = await txn.query(
        'calculation_contexts',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      final unchanged =
          current.isNotEmpty &&
          current.single['input_fingerprint'] == fingerprint &&
          current.single['calculation_version'] == calculationVersion &&
          current.single['reference_date'] == referenceDate &&
          current.single['locale'] == locale;
      final contextId =
          unchanged ? current.single['context_id']! as String : _uuid.v4();
      if (!unchanged) {
        await txn.delete(
          'calculation_cache',
          where: 'profile_id = ?',
          whereArgs: [profileId],
        );
        await txn.insert('calculation_contexts', {
          'profile_id': profileId,
          'context_id': contextId,
          'input_fingerprint': fingerprint,
          'calculation_version': calculationVersion,
          'reference_date': referenceDate,
          'locale': locale,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return CalculationCacheContext(
        profileId: profileId,
        profile: profile,
        contextId: contextId,
        inputFingerprint: fingerprint,
        calculationVersion: calculationVersion,
        referenceDate: referenceDate,
        locale: locale,
      );
    });
  });

  /// Read without assuming the currently deployed calculation version.
  Future<CachedResponse?> findCalculation({
    required String profileId,
    required String referenceDate,
    String locale = 'vi',
  }) => protectLocalData(() async {
    final db = await database.database;
    final rows = await db.rawQuery(
      'SELECT c.* FROM calculation_cache c JOIN profile_cache_revisions r '
      'ON c.profile_id = r.profile_id AND c.input_fingerprint = r.revision_token '
      'WHERE c.profile_id = ? AND c.reference_date = ? AND c.locale = ? '
      'ORDER BY c.cached_at DESC LIMIT 1',
      [profileId, referenceDate, locale],
    );
    return rows.isEmpty ? null : _decode(rows.single);
  });

  Future<CachedResponse?> findInterpretation({
    required String indexType,
    required int numberValue,
    String locale = 'vi',
  }) => protectLocalData(() async {
    final db = await database.database;
    final rows = await db.query(
      'interpretation_cache',
      where: 'index_type = ? AND number_value = ? AND locale = ?',
      whereArgs: [indexType, numberValue, locale],
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _decode(rows.single);
  });

  Future<bool> _isCurrent(
    DatabaseExecutor db,
    CalculationCacheContext context,
  ) async {
    final rows = await db.rawQuery(
      'SELECT c.context_id FROM calculation_contexts c '
      'JOIN profile_cache_revisions r ON c.profile_id = r.profile_id '
      'WHERE c.profile_id = ? AND c.context_id = ? '
      'AND c.input_fingerprint = ? AND r.revision_token = ? '
      'AND c.calculation_version = ? AND c.reference_date = ? AND c.locale = ?',
      [
        context.profileId,
        context.contextId,
        context.inputFingerprint,
        context.inputFingerprint,
        context.calculationVersion,
        context.referenceDate,
        context.locale,
      ],
    );
    return rows.isNotEmpty;
  }

  Future<bool> saveCalculation(
    CalculationCacheContext context, {
    required String responseJson,
    String? contentVersion,
  }) => protectLocalData(() async {
    _validateJson(responseJson);
    final db = await database.database;
    return db.transaction((txn) async {
      if (!await _isCurrent(txn, context)) return false;
      await txn.insert('calculation_cache', {
        'id': _uuid.v4(),
        'profile_id': context.profileId,
        'calculation_version': context.calculationVersion,
        'content_version': contentVersion,
        'reference_date': context.referenceDate,
        'locale': context.locale,
        'input_fingerprint': context.inputFingerprint,
        'response_json': responseJson,
        'cached_at': _now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    });
  });

  Future<CachedResponse?> readCalculation(
    CalculationCacheContext context,
  ) => protectLocalData(() async {
    final db = await database.database;
    return db.transaction((txn) async {
      if (!await _isCurrent(txn, context)) return null;
      final rows = await txn.query(
        'calculation_cache',
        where:
            'profile_id = ? AND calculation_version = ? AND reference_date = ? '
            'AND locale = ? AND input_fingerprint = ?',
        whereArgs: [
          context.profileId,
          context.calculationVersion,
          context.referenceDate,
          context.locale,
          context.inputFingerprint,
        ],
      );
      return rows.isEmpty ? null : _decode(rows.single);
    });
  });

  Future<void> saveInterpretation({
    required String indexType,
    required int numberValue,
    required String locale,
    required String contentVersion,
    required String responseJson,
  }) => protectLocalData(() async {
    _validateArticleKey(indexType, numberValue, locale, contentVersion);
    _validateJson(responseJson);
    final db = await database.database;
    // Update the same versioned article without changing its existing UUID.
    await db.transaction((txn) async {
      final rows = await txn.query(
        'interpretation_cache',
        columns: ['id'],
        where: _articleWhere,
        whereArgs: [indexType, numberValue, locale, contentVersion],
      );
      await txn.insert('interpretation_cache', {
        'id': rows.isEmpty ? _uuid.v4() : rows.single['id'],
        'index_type': indexType,
        'number_value': numberValue,
        'locale': locale,
        'content_version': contentVersion,
        'response_json': responseJson,
        'cached_at': _now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  });

  static const _articleWhere =
      'index_type = ? AND number_value = ? AND locale = ? AND content_version = ?';

  Future<CachedResponse?> readInterpretation({
    required String indexType,
    required int numberValue,
    required String locale,
    required String contentVersion,
  }) => protectLocalData(() async {
    _validateArticleKey(indexType, numberValue, locale, contentVersion);
    final db = await database.database;
    final rows = await db.query(
      'interpretation_cache',
      where: _articleWhere,
      whereArgs: [indexType, numberValue, locale, contentVersion],
    );
    return rows.isEmpty ? null : _decode(rows.single);
  });

  Future<CacheStatistics> statistics() => protectLocalData(() async {
    final db = await database.database;
    return db.transaction((txn) async {
      final calculations =
          (await txn.rawQuery(
                'SELECT COUNT(*) AS n FROM calculation_cache',
              )).single['n']!
              as int;
      final articles =
          (await txn.rawQuery(
                'SELECT COUNT(*) AS n FROM interpretation_cache',
              )).single['n']!
              as int;
      final pages =
          (await txn.rawQuery('PRAGMA page_count')).single.values.single!
              as int;
      final size =
          (await txn.rawQuery('PRAGMA page_size')).single.values.single! as int;
      return CacheStatistics(calculations, articles, pages * size);
    });
  });

  /// Preserve profiles and selected profile. In-flight saves are invalidated too.
  Future<void> clearCache() => protectLocalData(() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.delete('calculation_cache');
      await txn.delete('calculation_contexts');
      await txn.delete('interpretation_cache');
    });
  });

  static CachedResponse _decode(Map<String, Object?> row) => CachedResponse(
    responseJson: row['response_json']! as String,
    cachedAt: DateTime.parse(row['cached_at']! as String),
    contentVersion: row['content_version'] as String?,
  );

  static void _validateJson(String json) {
    try {
      if (jsonDecode(json) is! Map<String, dynamic>)
        throw const FormatException();
    } on FormatException {
      throw const LocalDataException(
        LocalDataFailure.invalidInput,
        field: 'responseJson',
      );
    }
  }

  static void _validateArticleKey(
    String type,
    int value,
    String locale,
    String version,
  ) {
    if (!indexTypes.contains(type) ||
        !((value >= 1 && value <= 9) || const {11, 22, 33}.contains(value)) ||
        locale != 'vi' ||
        version.trim().isEmpty) {
      throw const LocalDataException(LocalDataFailure.invalidInput);
    }
  }
}

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(ref.watch(localDatabaseProvider)),
);
