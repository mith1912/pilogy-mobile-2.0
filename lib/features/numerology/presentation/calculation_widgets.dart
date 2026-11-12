import 'calculation_explanation.dart';
import '../../../core/text/display_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/domain/user_profile.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../data/backend_repositories.dart';
import '../domain/api_models.dart';
import 'backend_providers.dart';

const indexTitles = <IndexType, String>{
  IndexType.lifePath: 'Đường Đời',
  IndexType.expression: 'Sứ Mệnh',
  IndexType.soulUrge: 'Linh Hồn',
  IndexType.personality: 'Nhân Cách',
  IndexType.birthday: 'Ngày Sinh',
  IndexType.attitude: 'Thái Độ',
  IndexType.maturity: 'Trưởng Thành',
  IndexType.personalYear: 'Năm Cá Nhân',
  IndexType.personalMonth: 'Tháng Cá Nhân',
};
String displayDate(String value) => value.split('-').reversed.join('/');
String safeDataMessage(Object error) =>
    error is ApiFailure ? apiErrorMessage(error) : localDataErrorMessage(error);

class DataStatus<T> extends StatelessWidget {
  const DataStatus({
    super.key,
    required this.snapshot,
    required this.onRefresh,
  });
  final DataSnapshot<T> snapshot;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final label =
        snapshot.refreshing
            ? 'Đang cập nhật…'
            : snapshot.offline
            ? 'Không có kết nối · Dữ liệu đã lưu'
            : switch (snapshot.freshness) {
              DataFreshness.fresh => 'Đã cập nhật',
              DataFreshness.cached => 'Dữ liệu đã lưu',
              DataFreshness.stale => 'Dữ liệu đã lưu · Chưa xác minh phiên bản',
              DataFreshness.missing => 'Chưa có dữ liệu',
            };
    return EditorialPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                snapshot.offline ? Icons.cloud_off_outlined : Icons.sync,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, key: const ValueKey('data-freshness')),
              ),
              IconButton(
                tooltip: 'Làm Mới Dữ Liệu',
                onPressed: snapshot.refreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (snapshot.refreshing) const LinearProgressIndicator(),
          if (snapshot.contentStale && snapshot.data != null)
            const Text('Nội dung luận giải có thể đã thay đổi.'),
          if (snapshot.error != null)
            Text(
              safeDataMessage(snapshot.error!),
              style: const TextStyle(color: AppColors.error),
            ),
          if (snapshot.cachedAt != null)
            Text(
              'Đã lưu: ${displayDate(localCalendarDate(snapshot.cachedAt!.toLocal()))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// Shared gate prevents stale profile results reaching any of the three result views.
class CalculationContent extends ConsumerWidget {
  const CalculationContent({
    super.key,
    required this.builder,
    this.showProfileIdentity = true,
    this.statusBuilder,
  });
  final Widget Function(BuildContext, WidgetRef, UserProfile, CalculationResult)
  builder;
  final bool showProfileIdentity;
  final Widget Function(
    BuildContext,
    WidgetRef,
    DataSnapshot<CalculationResult>,
  )?
  statusBuilder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProfileProvider);
    if (selected.isLoading) return const AppLoadingState();
    if (selected.hasError)
      return AppErrorState(
        message: localDataErrorMessage(selected.error!),
        onRetry: () => ref.read(profilesViewModelProvider.notifier).refresh(),
      );
    final profile = selected.valueOrNull;
    if (profile == null)
      return Column(
        children: [
          const AppEmptyState(
            message: 'Chọn hoặc tạo hồ sơ để xem phân tích.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Hồ Sơ Đã Lưu',
            onPressed: () => context.go('/profiles'),
          ),
        ],
      );
    final async = ref.watch(selectedProfileCalculationProvider);
    if (async.isLoading)
      return const AppLoadingState(label: 'Đang tải bản đồ của bạn…');
    if (async.hasError)
      return AppErrorState(
        message: safeDataMessage(async.error!),
        onRetry: () => refreshSelectedCalculation(ref),
      );
    final snapshot = async.valueOrNull;
    if (snapshot == null) return const AppLoadingState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showProfileIdentity) ...[
          Text(
            '${profile.fullName} · ${displayDate(profile.birthDate)}',
            key: const ValueKey('result-profile'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (statusBuilder != null)
          statusBuilder!(context, ref, snapshot)
        else ...[
          DataStatus(
            snapshot: snapshot,
            onRefresh: () => refreshSelectedCalculation(ref),
          ),
          const SizedBox(height: 24),
        ],
        if (snapshot.data != null)
          builder(context, ref, profile, snapshot.data!)
        else if (snapshot.refreshing)
          const AppLoadingState(label: 'Đang tính toán từ máy chủ…')
        else
          const AppEmptyState(
            message:
                'Cần kết nối mạng cho lần tính đầu tiên của hồ sơ và ngày đã chọn. Hãy kết nối rồi thử lại.',
          ),
      ],
    );
  }
}

class NumberCard extends StatelessWidget {
  const NumberCard({
    super.key,
    required this.result,
    required this.type,
    this.hero = false,
  });
  final CalculationResult result;
  final IndexType type;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final index = result.indices[type]!;
    final summary = result.interpretations[type]!;
    if (!hero)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: InkWell(
            key: ValueKey('detail-${type.name}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/number-detail?type=${type.name}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 56),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatIndexValue(index.value, index.baseValue),
                          key: ValueKey('number-${type.name}'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          indexTitles[type]!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(formatUiTitle(summary.title)),
                        const SizedBox(height: 4),
                        Text(
                          formatSentence(summary.tagline),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.secondary),
                ],
              ),
            ),
          ),
        ),
      );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          indexTitles[type]!,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: hero ? AppColors.secondaryFixed : AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatIndexValue(index.value, index.baseValue),
              key: ValueKey('number-${type.name}'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: hero ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatUiTitle(summary.title),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: hero ? AppColors.onPrimary : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(formatSentence(summary.tagline)),
        if (hero) ...[
          const SizedBox(height: 16),
          Text(formatSentence(summary.summary)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final word in summary.keywords)
              Chip(
                label: Text(formatUiLabel(word)),
                backgroundColor:
                    hero
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainer,
                labelStyle: TextStyle(
                  color: hero ? AppColors.onPrimary : AppColors.primary,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: ValueKey('detail-${type.name}'),
            style: TextButton.styleFrom(
              foregroundColor:
                  hero ? AppColors.secondaryFixed : AppColors.secondary,
            ),
            onPressed: () => context.push('/number-detail?type=${type.name}'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Xem Chi Tiết'),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child:
          hero
              ? EditorialPanel(dark: true, child: content)
              : AppCard(child: content),
    );
  }
}

class CalculationSteps extends StatelessWidget {
  const CalculationSteps({super.key, required this.index});
  final IndexResult index;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: ValueKey('steps-${index.type.name}'),
      leading: const Icon(Icons.calculate_outlined),
      title: const Text('Phương Thức Quy Nạp Pythagoras'),
      subtitle: const Text('Các Bước Do Máy Chủ Cung Cấp'),
      childrenPadding: const EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [CalculationExplanation(index: index)],
    ),
  );
}
