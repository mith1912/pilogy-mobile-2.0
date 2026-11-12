import '../../../core/text/display_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../numerology/domain/api_models.dart';

const discoverCoreTypes = [
  IndexType.soulUrge,
  IndexType.personality,
  IndexType.expression,
];
const _coreLabels = ['Linh Hồn', 'Nhân Cách', 'Sứ Mệnh'];

BoxDecoration _whiteCard(double radius) => BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(.05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ],
);
void _detail(BuildContext context, IndexType type) =>
    context.push('/number-detail?type=${type.name}');

class DiscoverLifePathCard extends StatelessWidget {
  const DiscoverLifePathCard({super.key, required this.result});
  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final index = result.indices[IndexType.lifePath]!;
    final summary = result.interpretations[IndexType.lifePath]!;
    return Container(
      key: const ValueKey('discover-life-path-card'),
      decoration: _whiteCard(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: ExcludeSemantics(
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerLow.withOpacity(.6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Con Số Đường Đời',
                        style: theme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Năng Lượng Cốt Lõi',
                          style: theme.labelSmall?.copyWith(
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 112),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatIndexValue(index.value, index.baseValue),
                          key: const ValueKey('number-lifePath'),
                          style: theme.displayMedium?.copyWith(
                            color: AppColors.secondary,
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
                            formatUiTitle(summary.title),
                            style: theme.titleLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatSentence(summary.subtitle),
                            style: theme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  formatSentence(summary.summary),
                  key: const ValueKey('life-path-description'),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('detail-lifePath'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                    onPressed: () => _detail(context, IndexType.lifePath),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Xem Chi Tiết'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverCoreNumbers extends StatelessWidget {
  const DiscoverCoreNumbers({super.key, required this.result});
  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scale = MediaQuery.textScaleFactorOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Bộ Ba Chỉ Số Cốt Lõi',
          trailing: Text(
            'Tổng Hòa Danh Xưng',
            textAlign: TextAlign.right,
            style: theme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            key: const ValueKey('discover-core-row'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < discoverCoreTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: _whiteCard(12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('detail-${discoverCoreTypes[i].name}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _detail(context, discoverCoreTypes[i]),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 14 * scale,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _coreLabels[i],
                                    style: theme.labelSmall?.copyWith(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 34 * scale,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatIndexValue(
                                      result
                                          .indices[discoverCoreTypes[i]]!
                                          .value,
                                      result
                                          .indices[discoverCoreTypes[i]]!
                                          .baseValue,
                                    ),
                                    key: ValueKey(
                                      'number-${discoverCoreTypes[i].name}',
                                    ),
                                    style: theme.headlineMedium?.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                result
                                        .interpretations[discoverCoreTypes[i]]!
                                        .keywords
                                        .isEmpty
                                    ? formatSentence(
                                      result
                                          .interpretations[discoverCoreTypes[i]]!
                                          .subtitle,
                                    )
                                    : formatUiTitle(
                                      result
                                          .interpretations[discoverCoreTypes[i]]!
                                          .keywords
                                          .first,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatSentence(
                                  result
                                      .interpretations[discoverCoreTypes[i]]!
                                      .tagline,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: .11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DiscoverCycles extends StatelessWidget {
  const DiscoverCycles({super.key, required this.result});
  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final date = result.referenceDate.split('-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Chu Kỳ Rung Động Hiện Tại',
          trailing: Text(
            'Năm ${date[0]}',
            key: const ValueKey('discover-cycle-year'),
            textAlign: TextAlign.right,
            style: theme.labelSmall?.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: 8),
        for (final type in const [
          IndexType.personalYear,
          IndexType.personalMonth,
        ])
          Padding(
            padding: EdgeInsets.only(
              bottom: type == IndexType.personalYear ? 10 : 0,
            ),
            child: Container(
              decoration: _whiteCard(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('detail-${type.name}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _detail(context, type),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatIndexValue(
                                result.indices[type]!.value,
                                result.indices[type]!.baseValue,
                              ),
                              key: ValueKey('number-${type.name}'),
                              style: theme.headlineSmall?.copyWith(
                                color:
                                    type == IndexType.personalYear
                                        ? AppColors.secondary
                                        : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${type == IndexType.personalYear ? 'Năm Cá Nhân' : 'Tháng Cá Nhân'} ${result.indices[type]!.value}',
                                    style: theme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    type == IndexType.personalYear
                                        ? date[0]
                                        : 'Tháng ${int.parse(date[1])}',
                                    style: theme.labelSmall?.copyWith(
                                      color:
                                          type == IndexType.personalYear
                                              ? AppColors.secondary
                                              : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatSentence(
                                  result.interpretations[type]!.tagline,
                                ),
                                style: theme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          type == IndexType.personalYear
                              ? Icons.sync
                              : Icons.spa_outlined,
                          size: 20,
                          color: AppColors.outlineVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          formatUiTitle(title),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
      ),
      const SizedBox(width: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: trailing,
      ),
    ],
  );
}
