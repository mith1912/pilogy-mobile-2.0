import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../profiles/domain/user_profile.dart';
import '../data/backend_repositories.dart';
import '../domain/api_models.dart';

final backendConfigProvider = FutureProvider.autoDispose<BackendConfig>((ref) {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref.watch(configRepositoryProvider).config(cancelToken: token);
});
final definitionsProvider = FutureProvider.autoDispose<DefinitionsResult>((
  ref,
) {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref.watch(configRepositoryProvider).definitions(cancelToken: token);
});

/// Override for deterministic clocks. Local wall-calendar fields, never UTC conversion.
final calendarClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class _CalendarObserver extends WidgetsBindingObserver {
  _CalendarObserver(this.check);
  final VoidCallback check;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }
}

final currentReferenceDateProvider = StreamProvider.autoDispose<String>((ref) {
  final now = ref.watch(calendarClockProvider);
  final controller = StreamController<String>();
  String? previous;
  void check() {
    final date = localCalendarDate(now());
    if (previous != date) {
      previous = date;
      controller.add(date);
    }
  }

  final observer = _CalendarObserver(check);
  WidgetsBinding.instance.addObserver(observer);
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  check();
  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(observer);
    controller.close();
  });
  return controller.stream;
});
String calculationIdentity(UserProfile profile) =>
    '${profile.id}:${profile.updatedAt.toIso8601String()}';
final calculationSuspensionProvider = StateProvider<String?>((ref) => null);

final selectedReferenceDateProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final _selectedProfileCalculationStreamProvider = StreamProvider.autoDispose<
  DataSnapshot<CalculationResult>
>((ref) {
  ref.keepAlive();
  final selected = ref.watch(selectedProfileProvider);
  // Never reuse the previous profile while a new snapshot is loading.
  if (selected.isLoading) return const Stream.empty();
  if (selected.hasError)
    return Stream.error(selected.error!, selected.stackTrace);
  final profile = selected.valueOrNull;
  if (profile == null)
    return Stream.value(const DataSnapshot(freshness: DataFreshness.missing));
  if (ref.watch(calculationSuspensionProvider) ==
      calculationIdentity(profile)) {
    return Stream.value(const DataSnapshot(freshness: DataFreshness.missing));
  }
  final explicit = ref.watch(selectedReferenceDateProvider);
  final date = explicit ?? ref.watch(currentReferenceDateProvider).valueOrNull;
  if (date == null) return const Stream.empty();
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref
      .watch(numerologyRepositoryProvider)
      .watch(profileId: profile.id, referenceDate: date, cancelToken: token);
});

/// Value semantics ensure identical detail requests share state.
class ArticleRequest {
  const ArticleRequest(
    this.type,
    this.value, {
    this.locale = 'vi',
    this.contentVersion,
  });
  final IndexType type;
  final int value;
  final String locale;
  final String? contentVersion;
  @override
  bool operator ==(Object other) =>
      other is ArticleRequest &&
      other.type == type &&
      other.value == value &&
      other.locale == locale &&
      other.contentVersion == contentVersion;
  @override
  int get hashCode => Object.hash(type, value, locale, contentVersion);
}

final fullInterpretationProvider = StreamProvider.autoDispose
    .family<DataSnapshot<ArticleResult>, ArticleRequest>((ref, request) async* {
      final token = CancelToken();
      ref.onDispose(token.cancel);
      Timer? retention;
      ref.onDispose(() => retention?.cancel());
      await for (final snapshot in ref
          .watch(interpretationRepositoryProvider)
          .watch(
            type: request.type,
            value: request.value,
            locale: request.locale,
            contentVersion: request.contentVersion,
            cancelToken: token,
          )) {
        if (snapshot.freshness == DataFreshness.fresh &&
            snapshot.error == null) {
          final link = ref.keepAlive();
          retention?.cancel();
          retention = Timer(const Duration(minutes: 5), link.close);
        }
        yield snapshot;
      }
    });

/// Strip Riverpod's retained previous value during identity changes.
final selectedProfileCalculationProvider =
    Provider.autoDispose<AsyncValue<DataSnapshot<CalculationResult>>>((ref) {
      final state = ref.watch(_selectedProfileCalculationStreamProvider);
      return state.isLoading ? const AsyncLoading() : state;
    });

void refreshSelectedCalculation(WidgetRef ref) {
  final current = ref.read(selectedProfileCalculationProvider);
  if (current.isLoading || current.valueOrNull?.refreshing == true) return;
  ref.read(calculationSuspensionProvider.notifier).state = null;
  ref.invalidate(_selectedProfileCalculationStreamProvider);
}

/// Invalidate presentation state; privacy callers suspend the current revision first.
void invalidateCalculations(Ref ref) =>
    ref.invalidate(_selectedProfileCalculationStreamProvider);
