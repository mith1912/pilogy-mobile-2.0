import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_failure.dart';
import '../../../services/network/api_client.dart';
import '../../../services/storage/cache_store.dart';
import '../domain/api_models.dart';

enum DataFreshness { fresh, cached, stale, missing }

/// A refresh failure retains usable data, with the error visible independently.
class DataSnapshot<T> {
  const DataSnapshot({
    this.data,
    required this.freshness,
    this.refreshing = false,
    this.error,
    this.cachedAt,
    this.contentStale = false,
  });
  final T? data;
  final DataFreshness freshness;
  final bool refreshing, contentStale;
  final Object? error;
  final DateTime? cachedAt;
  bool get offline => error is ApiFailure && (error! as ApiFailure).isOffline;
}

class ConfigRepository {
  ConfigRepository(this.api);
  final ApiClient api;
  Future<HealthResult> health({CancelToken? cancelToken}) async =>
      HealthResult.fromJson(
        await api.request('health', cancelToken: cancelToken),
      );
  Future<BackendConfig> config({CancelToken? cancelToken}) async =>
      BackendConfig.fromJson(
        await api.request('config', cancelToken: cancelToken),
      );
  Future<DefinitionsResult> definitions({
    String locale = 'vi',
    CancelToken? cancelToken,
  }) async => DefinitionsResult.fromJson(
    await api.request(
      'numerology/definitions',
      query: {'locale': locale},
      cancelToken: cancelToken,
    ),
  );
}

class NumerologyRepository {
  NumerologyRepository(this.api, this.cache, this.config);
  final ApiClient api;
  final CacheStore cache;
  final ConfigRepository config;

  Stream<DataSnapshot<CalculationResult>> watch({
    required String profileId,
    required String referenceDate,
    String locale = 'vi',
    CancelToken? cancelToken,
  }) async* {
    CalculationResult? previous;
    DateTime? cachedAt;
    bool contentStale = true;
    try {
      calendarDate(referenceDate);
      final cached = await cache.findCalculation(
        profileId: profileId,
        referenceDate: referenceDate,
        locale: locale,
      );
      if (cached != null) {
        try {
          previous = CalculationResult.fromJson(
            object(jsonDecode(cached.responseJson)),
          );
          if (previous.referenceDate != referenceDate ||
              previous.locale != locale)
            previous = null;
          if (previous != null) cachedAt = cached.cachedAt;
        } on ApiFailure {
          previous = null;
        } on FormatException {
          previous = null;
        }
      }
      // Unknown deployed versions must never be labelled fresh.
      yield DataSnapshot(
        data: previous,
        freshness:
            previous == null ? DataFreshness.missing : DataFreshness.stale,
        cachedAt: cachedAt,
        refreshing: true,
        contentStale: previous != null,
      );
      final settings = await config.config(cancelToken: cancelToken);
      if (previous != null) {
        if (previous.calculationVersion != settings.calculationVersion) {
          previous = null;
          yield const DataSnapshot(
            freshness: DataFreshness.missing,
            refreshing: true,
          );
        }
      }
      final context = await cache.prepareCalculation(
        profileId: profileId,
        calculationVersion: settings.calculationVersion,
        referenceDate: referenceDate,
        locale: locale,
      );
      final definitions = await config.definitions(
        locale: locale,
        cancelToken: cancelToken,
      );
      if (previous != null)
        contentStale = previous.contentVersion != definitions.contentVersion;
      final data = await api.request(
        'numerology/calculate',
        body:
            CalculateRequest(
              fullName: context.profile.fullName,
              birthDate: context.profile.birthDate,
              referenceDate: context.referenceDate,
              locale: context.locale,
            ).toJson(),
        cancelToken: cancelToken,
      );
      final result = CalculationResult.fromJson(data);
      if (result.referenceDate != referenceDate ||
          result.locale != locale ||
          result.calculationVersion != context.calculationVersion)
        schemaError();
      if (cancelToken?.isCancelled ?? false) return;
      final saved = await cache.saveCalculation(
        context,
        responseJson: jsonEncode(data),
        contentVersion: result.contentVersion,
      );
      // Profile edit/delete, period switch or clear invalidated this response.
      if (!saved) return;
      yield DataSnapshot(
        data: result,
        freshness: DataFreshness.fresh,
        contentStale: result.contentVersion != definitions.contentVersion,
      );
    } catch (error) {
      if (cancelToken?.isCancelled ?? false) return;
      yield DataSnapshot(
        data: previous,
        freshness:
            previous == null ? DataFreshness.missing : DataFreshness.stale,
        error: error,
        cachedAt: cachedAt,
        contentStale: contentStale,
      );
    }
  }
}

class InterpretationRepository {
  InterpretationRepository(this.api, this.cache);
  final ApiClient api;
  final CacheStore cache;

  Stream<DataSnapshot<ArticleResult>> watch({
    required IndexType type,
    required int value,
    String locale = 'vi',
    String? contentVersion,
    CancelToken? cancelToken,
  }) async* {
    ArticleResult? previous;
    DateTime? cachedAt;
    try {
      var cached =
          contentVersion == null
              ? await cache.findInterpretation(
                indexType: type.name,
                numberValue: value,
                locale: locale,
              )
              : await cache.readInterpretation(
                indexType: type.name,
                numberValue: value,
                locale: locale,
                contentVersion: contentVersion,
              );
      cached ??= await cache.findInterpretation(
        indexType: type.name,
        numberValue: value,
        locale: locale,
      );
      if (cached != null) {
        try {
          previous = ArticleResult.fromJson(
            object(jsonDecode(cached.responseJson)),
          );
          if (previous.interpretation.index != type ||
              previous.interpretation.value != value ||
              previous.locale != locale ||
              previous.contentVersion != cached.contentVersion)
            previous = null;
          if (previous != null) cachedAt = cached.cachedAt;
        } on ApiFailure {
          previous = null;
        } on FormatException {
          previous = null;
        }
      }
      yield DataSnapshot(
        data: previous,
        cachedAt: cachedAt,
        refreshing: true,
        contentStale:
            contentVersion == null ||
            previous?.contentVersion != contentVersion,
        freshness:
            previous == null
                ? DataFreshness.missing
                : contentVersion == null ||
                    previous.contentVersion != contentVersion
                ? DataFreshness.stale
                : DataFreshness.cached,
      );
      // Unconditional revalidation: schema v1 has no persistent ETag mapping.
      final data = await api.request(
        'numerology/interpretations/${type.name}/$value',
        query: {'locale': locale},
        cancelToken: cancelToken,
      );
      final result = ArticleResult.fromJson(data);
      if (result.interpretation.index != type ||
          result.interpretation.value != value ||
          result.locale != locale)
        schemaError();
      if (cancelToken?.isCancelled ?? false) return;
      await cache.saveInterpretation(
        indexType: type.name,
        numberValue: value,
        locale: locale,
        contentVersion: result.contentVersion,
        responseJson: jsonEncode(data),
      );
      yield DataSnapshot(data: result, freshness: DataFreshness.fresh);
    } catch (error) {
      if (cancelToken?.isCancelled ?? false) return;
      yield DataSnapshot(
        data: previous,
        cachedAt: cachedAt,
        error: error,
        freshness:
            previous == null ? DataFreshness.missing : DataFreshness.stale,
        contentStale:
            contentVersion == null ||
            previous?.contentVersion != contentVersion,
      );
    }
  }
}

final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => ConfigRepository(ref.watch(apiClientProvider)),
);
final numerologyRepositoryProvider = Provider<NumerologyRepository>(
  (ref) => NumerologyRepository(
    ref.watch(apiClientProvider),
    ref.watch(cacheStoreProvider),
    ref.watch(configRepositoryProvider),
  ),
);
final interpretationRepositoryProvider = Provider<InterpretationRepository>(
  (ref) => InterpretationRepository(
    ref.watch(apiClientProvider),
    ref.watch(cacheStoreProvider),
  ),
);
