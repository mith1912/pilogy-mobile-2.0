import '../../../services/ads/native_content_ad.dart';
import '../../../core/text/display_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../../numerology/presentation/refresh_status.dart';

const _core = [
  IndexType.lifePath,
  IndexType.soulUrge,
  IndexType.personality,
  IndexType.expression,
];
const _supporting = [
  IndexType.birthday,
  IndexType.attitude,
  IndexType.maturity,
];
const _labels = <IndexType, String>{
  IndexType.lifePath: 'Con số Đường đời',
  IndexType.soulUrge: 'Con số Linh hồn',
  IndexType.personality: 'Con số Nhân cách',
  IndexType.expression: 'Con số Sứ mệnh',
  IndexType.birthday: 'Con số Ngày sinh',
  IndexType.attitude: 'Con số Thái độ',
  IndexType.maturity: 'Con số Trưởng thành',
};
BoxDecoration _card() => BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(.05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ],
);

class AnalysisCards extends StatelessWidget {
  const AnalysisCards({super.key, required this.result});
  final CalculationResult result;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: _QuickCard(
                  title: 'Biểu Đồ Ngày Sinh',
                  subtitle: 'Chưa có dữ liệu.',
                  icon: Icons.grid_4x4,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickCard(
                  key: const ValueKey('analysis-cycles'),
                  title: 'Chu Kỳ Cá Nhân',
                  subtitle:
                      'Năm số ${result.indices[IndexType.personalYear]!.value} · ${result.interpretations[IndexType.personalYear]!.keywords.isEmpty ? result.interpretations[IndexType.personalYear]!.subtitle : result.interpretations[IndexType.personalYear]!.keywords.first}',
                  icon: Icons.timelapse,
                  gold: true,
                  onTap: () => _showCycles(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          key: const ValueKey('analysis-editorial-highlight'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 18,
                    color: AppColors.secondaryFixed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tổng Luận Năng Lượng Chính',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Nội dung tổng luận chưa có sẵn.',
                style: text.titleLarge?.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _GroupHeading(
          title: 'Nhóm Chỉ Số Cốt Lõi',
          eyebrow: 'Trọng Tâm Bản Mệnh',
          count: '4 Chỉ Số',
        ),
        const SizedBox(height: 16),
        for (final type in _core)
          _IndexRow(result: result, type: type, core: true),
        const NativeContentAd(),
        const SizedBox(height: 16),
        const _GroupHeading(
          title: 'Nhóm Chỉ Số Bổ Trợ',
          eyebrow: 'Tương Tác Môi Trường & Giai Đoạn',
          count: '3 Chỉ Số',
        ),
        const SizedBox(height: 16),
        for (final type in _supporting) _IndexRow(result: result, type: type),
        const SizedBox(height: 16),
        const _GroupHeading(
          title: 'Chỉ Số Tiềm Thức & Tâm Linh',
          eyebrow: 'Tầng Sâu Nội Tâm & Nghiệp Nợ',
        ),
        const SizedBox(height: 16),
        for (final label in const [
          'Chỉ số Cân bằng',
          'Chỉ số Nợ nghiệp',
          'Chỉ số Thiếu (Karmic Lesson)',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: _card(),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '—',
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Chưa có dữ liệu.',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 24,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lời Nhắc Nhở Pythagoras',
                      style: text.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Các con số không định đoạt số phận cố định, mà phản ánh dòng chảy rung động tự nhiên. Khi hiểu rõ bản đồ này, bạn là người làm chủ tay lái trên hành trình tiến hóa của tâm thức.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCycles(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: FractionallySizedBox(
              heightFactor: .75,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Chu Kỳ Cá Nhân',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    CalculationContent(
                      showProfileIdentity: false,
                      statusBuilder:
                          (context, ref, snapshot) => CompactDataState(
                            snapshot: snapshot,
                            onRefresh: () => refreshSelectedCalculation(ref),
                          ),
                      builder:
                          (context, ref, profile, current) => Column(
                            children: [
                              for (final type in const [
                                IndexType.personalYear,
                                IndexType.personalMonth,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AppCard(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${indexTitles[type]} ${formatIndexValue(current.indices[type]!.value, current.indices[type]!.baseValue)}',
                                      ),
                                      subtitle: Text(
                                        current.interpretations[type]!.summary,
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        context.push(
                                          '/number-detail?type=${type.name}',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.title, required this.eyebrow, this.count});
  final String title, eyebrow;
  final String? count;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatUiTitle(eyebrow),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 4),
            Text(
              formatUiTitle(title),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
      if (count != null) ...[
        const SizedBox(width: 8),
        Text(
          count!,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    ],
  );
}

class _IndexRow extends StatelessWidget {
  const _IndexRow({
    required this.result,
    required this.type,
    this.core = false,
  });
  final CalculationResult result;
  final IndexType type;
  final bool core;
  @override
  Widget build(BuildContext context) {
    final index = result.indices[type]!;
    final summary = result.interpretations[type]!;
    final text = Theme.of(context).textTheme;
    final gold = type == IndexType.soulUrge || type == IndexType.attitude;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: _card(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('detail-${type.name}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/number-detail?type=${type.name}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: core ? 56 : 48,
                    height: core ? 56 : 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          core
                              ? AppColors.surfaceContainerHigh
                              : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(core ? 12 : 8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatIndexValue(index.value, index.baseValue),
                        key: ValueKey('number-${type.name}'),
                        style: (core ? text.displayMedium : text.headlineMedium)
                            ?.copyWith(
                              color:
                                  gold
                                      ? AppColors.secondary
                                      : AppColors.primary,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _labels[type]!,
                              style: text.titleLarge?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            if (type == IndexType.lifePath)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'Cốt Tủy',
                                  style: text.labelSmall?.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          core
                              ? formatUiTitle(summary.title)
                              : formatSentence(summary.tagline),
                          maxLines: core ? 1 : null,
                          overflow: core ? TextOverflow.ellipsis : null,
                          style: core ? text.bodyMedium : text.bodySmall,
                        ),
                        if (core) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Năng lượng: ${summary.keywords.join(', ')}',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (core)
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.secondary,
                    )
                  else
                    Text(
                      'Chi Tiết →',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gold = false,
    this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final bool gold;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: _card(),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          gold
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color:
                          gold
                              ? AppColors.onSecondaryContainer
                              : AppColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.north_east,
                    size: 18,
                    color:
                        onTap == null
                            ? AppColors.outlineVariant
                            : AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                formatUiTitle(title),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                formatSentence(subtitle),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      gold ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
