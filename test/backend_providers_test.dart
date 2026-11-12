import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/features/numerology/data/backend_repositories.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'backend_test_support.dart';

final selection = StateProvider<UserProfile?>((ref) => null);

class FakeNumerology extends Fake implements NumerologyRepository {
  final streams = <String, StreamController<DataSnapshot<CalculationResult>>>{};
  final tokens = <String, CancelToken?>{};
  @override
  Stream<DataSnapshot<CalculationResult>> watch({
    required String profileId,
    required String referenceDate,
    String locale = 'vi',
    CancelToken? cancelToken,
  }) {
    tokens[profileId] = cancelToken;
    return (streams[profileId] ??= StreamController.broadcast()).stream;
  }
}

UserProfile profile(String id) => UserProfile(
  id: id,
  fullName: 'Synthetic',
  birthDate: '1990-05-20',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
void main() {
  late ProviderContainer container;
  late FakeNumerology repository;
  setUp(() {
    repository = FakeNumerology();
    container = ProviderContainer(
      overrides: [
        selectedProfileProvider.overrideWith(
          (ref) => AsyncData(ref.watch(selection)),
        ),
        numerologyRepositoryProvider.overrideWithValue(repository),
        selectedReferenceDateProvider.overrideWith((ref) => '2026-11-08'),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    for (final stream in repository.streams.values) {
      await stream.close();
    }
  });
  test('loading, success, cached refresh and missing error states', () async {
    container.read(selection.notifier).state = profile('a');
    final sub = container.listen(
      selectedProfileCalculationProvider,
      (_, __) {},
    );
    addTearDown(sub.close);
    expect(container.read(selectedProfileCalculationProvider).isLoading, true);
    await Future<void>.delayed(Duration.zero);
    final result = CalculationResult.fromJson(
      object(fixture('calculation')['data']),
    );
    repository.streams['a']!.add(
      DataSnapshot(
        data: result,
        freshness: DataFreshness.cached,
        refreshing: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(selectedProfileCalculationProvider).value!.refreshing,
      true,
    );
    repository.streams['a']!.add(
      DataSnapshot(data: result, freshness: DataFreshness.fresh),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(selectedProfileCalculationProvider).value!.freshness,
      DataFreshness.fresh,
    );
    repository.streams['a']!.add(
      const DataSnapshot(
        freshness: DataFreshness.missing,
        error: ApiFailure(ApiFailureKind.connection),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(selectedProfileCalculationProvider).value!.offline,
      true,
    );
  });
  test(
    'stream failure becomes provider error without a previous result',
    () async {
      container.read(selection.notifier).state = profile('a');
      final sub = container.listen(
        selectedProfileCalculationProvider,
        (_, __) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      repository.streams['a']!.addError(
        const ApiFailure(ApiFailureKind.connection),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(selectedProfileCalculationProvider).hasError, true);
      expect(
        container.read(selectedProfileCalculationProvider).valueOrNull,
        isNull,
      );
    },
  );
  test(
    'profile switch clears previous data and cancels stale in-flight request',
    () async {
      container.read(selection.notifier).state = profile('a');
      final sub = container.listen(
        selectedProfileCalculationProvider,
        (_, __) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      final result = CalculationResult.fromJson(
        object(fixture('calculation')['data']),
      );
      repository.streams['a']!.add(
        DataSnapshot(data: result, freshness: DataFreshness.fresh),
      );
      await Future<void>.delayed(Duration.zero);
      container.read(selection.notifier).state = profile('b');
      expect(
        container.read(selectedProfileCalculationProvider).valueOrNull,
        isNull,
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.tokens['a']!.isCancelled, true);
      repository.streams['a']!.add(
        DataSnapshot(data: result, freshness: DataFreshness.fresh),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(selectedProfileCalculationProvider).valueOrNull,
        isNull,
      );
      repository.streams['b']!.add(
        const DataSnapshot(freshness: DataFreshness.missing),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(selectedProfileCalculationProvider).value!.data,
        isNull,
      );
    },
  );
}
