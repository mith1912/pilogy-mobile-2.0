import '../../text/display_text.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.secondary = false,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  secondary
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(formatUiLabel(label), textAlign: TextAlign.center),
        ),
      ],
    );
    final action = loading ? null : onPressed;
    return Semantics(
      liveRegion: loading,
      child:
          secondary
              ? OutlinedButton(onPressed: action, child: child)
              : FilledButton(onPressed: action, child: child),
    );
  }
}

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.label,
    this.controller,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.trailingIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: formatUiLabel(label),
      helperText: helperText == null ? null : formatSentence(helperText!),
      helperMaxLines: 3,
      errorMaxLines: 3,
      suffixIcon: trailingIcon == null ? null : Icon(trailingIcon),
      constraints: const BoxConstraints(minHeight: 54),
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.eyebrow});
  final String title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(
          formatUiTitle(eyebrow!),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
      Text(formatUiTitle(title), style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.label = 'Đang tải…'});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.md),
        Text(formatUiLabel(label)),
      ],
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = 'Không thể tải dữ liệu. Vui lòng thử lại.',
    this.onRetry,
  });
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(height: AppSpacing.sm),
        Text(formatSentence(message), textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Thử Lại', onPressed: onRetry),
        ],
      ],
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 32, color: AppColors.secondary),
      const SizedBox(height: AppSpacing.sm),
      Text(formatSentence(message), textAlign: TextAlign.center),
    ],
  );
}
