import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/cache_store.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../data/local_data_actions.dart';

class PrivacyState {
  const PrivacyState(
    this.statistics, {
    this.busy = false,
    this.message,
    this.failed = false,
  });
  final CacheStatistics statistics;
  final bool busy, failed;
  final String? message;
}

class PrivacyViewModel extends AutoDisposeAsyncNotifier<PrivacyState> {
  @override
  Future<PrivacyState> build() async =>
      PrivacyState(await ref.watch(cacheStoreProvider).statistics());
  Future<void> _run(Future<String> Function() action) async {
    final current = state.valueOrNull;
    if (current == null || current.busy) return;
    final link = ref.keepAlive();
    state = AsyncData(PrivacyState(current.statistics, busy: true));
    try {
      final message = await action();
      state = AsyncData(
        PrivacyState(
          await ref.read(cacheStoreProvider).statistics(),
          message: message,
        ),
      );
    } catch (_) {
      state = AsyncData(
        PrivacyState(
          current.statistics,
          message:
              'Không thể hoàn tất thao tác trên thiết bị. Vui lòng thử lại.',
          failed: true,
        ),
      );
    } finally {
      link.close();
    }
  }

  Future<void> exportProfiles() => _run(
    () async =>
        await ref.read(localDataActionsProvider).exportProfiles()
            ? 'Đã xuất hồ sơ.'
            : 'Đã hủy xuất hồ sơ.',
  );
  Future<void> clearCache() => _run(() async {
    final profile = ref.read(selectedProfileProvider).valueOrNull;
    await ref.read(cacheStoreProvider).clearCache();
    ref.read(calculationSuspensionProvider.notifier).state =
        profile == null ? null : calculationIdentity(profile);
    invalidateCalculations(ref);
    ref.invalidate(fullInterpretationProvider);
    return 'Đã xóa bộ nhớ đệm. Hồ sơ vẫn được giữ lại.';
  });
  Future<void> deleteAllProfiles() => _run(() async {
    await ref.read(profilesViewModelProvider.notifier).deleteAllProfiles();
    invalidateCalculations(ref);
    return 'Đã xóa toàn bộ hồ sơ trên thiết bị.';
  });
}

final privacyViewModelProvider =
    AsyncNotifierProvider.autoDispose<PrivacyViewModel, PrivacyState>(
      PrivacyViewModel.new,
    );
