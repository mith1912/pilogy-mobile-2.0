import 'package:flutter/material.dart';

import '../design_system/app_spacing.dart';
import '../design_system/widgets/app_components.dart';

/// M01 shell only. No demo profiles or fabricated backend interpretation.
class RoutePlaceholder extends StatelessWidget {
  const RoutePlaceholder({
    super.key,
    required this.screenId,
    required this.title,
    required this.purpose,
    this.action,
  });

  final String screenId;
  final String title;
  final String purpose;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PILOGY')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          AppSectionHeader(title: title, eyebrow: screenId),
          const SizedBox(height: AppSpacing.lg),
          AppCard(child: Text(purpose)),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}
