import '../../../core/text/display_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../data/backend_repositories.dart';
import '../domain/api_models.dart';
import 'backend_providers.dart';
import 'calculation_widgets.dart';

/// Event-driven notice, shared by calculation and full-article consumers.
class TransientUpdateNotice<T> extends ConsumerStatefulWidget {
  const TransientUpdateNotice({
    super.key,
    required this.source,
    required this.identity,
    this.noticeKey,
  });
  final ProviderListenable<AsyncValue<DataSnapshot<T>>> source;
  final Object? identity;
  final Key? noticeKey;
  @override
  ConsumerState<TransientUpdateNotice<T>> createState() =>
      _TransientUpdateNoticeState<T>();
}

class _TransientUpdateNoticeState<T>
    extends ConsumerState<TransientUpdateNotice<T>> {
  Timer? _timer;
  bool _visible = false;
  int _generation = 0;
  DataSnapshot<T>? _lastSuccess;

  void _clear() {
    final generation = ++_generation;
    _timer?.cancel();
    if (_visible)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _generation)
          setState(() => _visible = false);
      });
  }

  void _observe(
    AsyncValue<DataSnapshot<T>>? previous,
    AsyncValue<DataSnapshot<T>> next,
  ) {
    final snapshot = next.valueOrNull;
    if (next.isLoading ||
        next.hasError ||
        snapshot?.refreshing == true ||
        snapshot?.error != null) {
      _clear();
      return;
    }
    if (snapshot == null ||
        snapshot.data == null ||
        snapshot.freshness != DataFreshness.fresh ||
        previous?.valueOrNull?.refreshing != true ||
        identical(snapshot, _lastSuccess))
      return;
    _lastSuccess = snapshot;
    final generation = ++_generation;
    _timer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      setState(() => _visible = true);
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted && generation == _generation)
          setState(() => _visible = false);
      });
    });
  }

  @override
  void didUpdateWidget(covariant TransientUpdateNotice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity ||
        oldWidget.source != widget.source) {
      _generation++;
      _timer?.cancel();
      _visible = false;
      _lastSuccess = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(widget.source, _observe);
    ref.listen(selectedProfileProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull || next.isLoading) _clear();
    });
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration:
          MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 200),
      child:
          !_visible
              ? const SizedBox.shrink()
              : Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    key: widget.noticeKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đã Cập Nhật',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}

class CompactDataState<T> extends StatelessWidget {
  const CompactDataState({
    super.key,
    required this.snapshot,
    required this.onRefresh,
    this.messageKey,
  });
  final DataSnapshot<T> snapshot;
  final VoidCallback onRefresh;
  final Key? messageKey;
  @override
  Widget build(BuildContext context) {
    if (!snapshot.refreshing &&
        snapshot.freshness == DataFreshness.fresh &&
        snapshot.error == null &&
        !snapshot.contentStale)
      return const SizedBox.shrink();
    final label =
        snapshot.refreshing
            ? 'Đang cập nhật…'
            : snapshot.offline && snapshot.data != null
            ? 'Không có kết nối · Dữ liệu đã lưu'
            : snapshot.error != null
            ? safeDataMessage(snapshot.error!)
            : snapshot.contentStale
            ? 'Nội dung luận giải có thể đã thay đổi.'
            : snapshot.data == null
            ? 'Chưa có dữ liệu đã lưu.'
            : 'Dữ liệu đã lưu · Chưa xác minh phiên bản';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            snapshot.offline ? Icons.cloud_off_outlined : Icons.info_outline,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              snapshot.refreshing
                  ? formatUiLabel(label)
                  : formatSentence(label),
              key: messageKey,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!snapshot.refreshing)
            IconButton(
              tooltip: 'Làm Mới Dữ Liệu',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
            ),
        ],
      ),
    );
  }
}

/// Presentation refresh orchestration only; repository/cache identity stays unchanged.
mixin CalculationRefresh<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Completer<void>? _refreshDone;
  Future<void> refreshCalculation() async {
    final pending = _refreshDone;
    if (pending != null) return pending.future;
    final done = Completer<void>();
    _refreshDone = done;
    final subscription = ref.listenManual(selectedProfileCalculationProvider, (
      previous,
      next,
    ) {
      final snapshot = next.valueOrNull;
      if (!next.isLoading &&
          (next.hasError || (snapshot != null && !snapshot.refreshing))) {
        if (!done.isCompleted) done.complete();
      }
    });
    try {
      refreshSelectedCalculation(ref);
      await done.future;
    } finally {
      subscription.close();
      if (identical(_refreshDone, done)) _refreshDone = null;
    }
  }

  @override
  void dispose() {
    final refresh = _refreshDone;
    if (refresh != null && !refresh.isCompleted) refresh.complete();
    super.dispose();
  }
}
