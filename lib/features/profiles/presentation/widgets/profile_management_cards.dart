import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/text/display_text.dart';
import '../../../numerology/domain/api_models.dart';
import '../../../numerology/presentation/calculation_widgets.dart';
import '../../domain/user_profile.dart';

/// V1-08 surfaces use the reference's 16px corners and soft editorial shadow.
class ProfileSurface extends StatelessWidget {
  const ProfileSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surfaceContainerLowest,
    this.shadow = true,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: shadow
          ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))]
          : null,
    ),
    child: child,
  );
}

class ProfileAction extends StatelessWidget {
  const ProfileAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.color = AppColors.surfaceContainerHigh,
    this.height = 44,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: primary ? AppColors.primary : color,
      foregroundColor: primary ? AppColors.onPrimary : AppColors.primary,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: Theme.of(context).textTheme.labelMedium,
    ),
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(formatUiLabel(label), textAlign: TextAlign.center)),
      ],
    ),
  );
}

class SelectedProfileCard extends StatelessWidget {
  const SelectedProfileCard({
    super.key,
    required this.profile,
    required this.calculation,
    required this.onEdit,
    required this.onAnalysis,
    required this.onDelete,
    this.status,
  });
  final UserProfile profile;
  final CalculationResult? calculation;
  final VoidCallback? onEdit, onAnalysis, onDelete;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final lifePath = calculation?.indices[IndexType.lifePath];
    final subtitle = calculation?.interpretations[IndexType.lifePath]?.subtitle;
    return ProfileSurface(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x4DFFDEA5), Color(0x00FFDEA5)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const DecoratedBox(
                                decoration: BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                                child: SizedBox(width: 8, height: 8),
                              ),
                              const SizedBox(width: 6),
                              Flexible(child: Text('HỒ SƠ CHÍNH ĐANG CHỌN', style: theme.labelSmall?.copyWith(color: AppColors.primary))),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Tùy Chọn Hồ Sơ',
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        enabled: onEdit != null,
                        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceVariant),
                        onSelected: (value) => value == 'edit' ? onEdit?.call() : onDelete?.call(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Chỉnh Sửa')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa Hồ Sơ')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Text('ĐƯỜNG ĐỜI', style: theme.labelSmall?.copyWith(fontSize: 9, color: AppColors.onPrimaryContainer)),
                                const SizedBox(height: 4),
                                Text(lifePath == null ? '—' : formatIndexValue(lifePath.value, lifePath.baseValue),
                                  style: theme.headlineSmall?.copyWith(color: AppColors.secondaryFixed), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                              child: const Icon(Icons.star, size: 12, color: AppColors.onSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.fullName, style: theme.titleLarge),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.cake_outlined, size: 15, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(child: Text(displayDate(profile.birthDate), style: theme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant))),
                            ]),
                            if (subtitle != null && subtitle.isNotEmpty)
                              Text(formatUiTitle(subtitle), style: theme.labelSmall?.copyWith(color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final type in [IndexType.lifePath, IndexType.soulUrge, IndexType.expression])
                          Expanded(child: _Metric(type: type, index: calculation?.indices[type])),
                      ],
                    ),
                  ),
                  if (status != null) ...[const SizedBox(height: 12), status!],
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ProfileAction(label: 'Chỉnh sửa', icon: Icons.edit_outlined, onPressed: onEdit)),
                      const SizedBox(width: 8),
                      Expanded(child: ProfileAction(label: 'Xem phân tích', icon: Icons.auto_stories_outlined, primary: true, onPressed: onAnalysis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.type, required this.index});
  final IndexType type;
  final IndexResult? index;

  @override
  Widget build(BuildContext context) {
    final soul = type == IndexType.soulUrge;
    final theme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: soul ? AppColors.surfaceContainerLowest : null, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(indexTitles[type]!.toUpperCase(), textAlign: TextAlign.center,
          style: theme.labelSmall?.copyWith(color: soul ? AppColors.secondary : AppColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(index == null ? '—' : formatIndexValue(index!.value, index!.baseValue),
          style: theme.titleLarge?.copyWith(color: soul ? AppColors.secondary : AppColors.primary), textAlign: TextAlign.center),
      ]),
    );
  }
}

class OtherProfileCard extends StatelessWidget {
  const OtherProfileCard({super.key, required this.profile, required this.onSelect, required this.onEdit, required this.onDelete});
  final UserProfile profile;
  final VoidCallback? onSelect, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ProfileSurface(
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              // No local calculation or sample number for an unselected profile.
              child: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(profile.fullName, style: theme.titleLarge)),
                IconButton(tooltip: 'Xóa Hồ Sơ', constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: const EdgeInsets.all(4), onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.outline)),
              ]),
              Text(displayDate(profile.birthDate), style: theme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ])),
          ],
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: ProfileAction(key: ValueKey('select-profile-${profile.id}'), label: 'Chọn hồ sơ này', icon: Icons.radio_button_unchecked, height: 40, onPressed: onSelect)),
          const SizedBox(width: 8),
          ProfileAction(label: 'Sửa', icon: Icons.edit_outlined, height: 40, color: AppColors.surfaceContainerLow, onPressed: onEdit),
        ]),
      ]),
    );
  }
}
