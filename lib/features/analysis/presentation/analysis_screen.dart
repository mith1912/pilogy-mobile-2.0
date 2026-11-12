import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../../numerology/presentation/profile_header.dart';
import '../../numerology/presentation/refresh_status.dart';
import 'analysis_cards.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with CalculationRefresh<AnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedProfileProvider);
    final profile =
        selected.isLoading || selected.hasError ? null : selected.valueOrNull;
    final text = Theme.of(context).textTheme;
    return PilogyScaffold(
      screenId: 'V04',
      title: 'PILOGY',
      tab: 1,
      flatHeader: true,
      titleSpacing: 20,
      showDefaultProfileAction: false,
      headerTitle: const PilogyBrandTitle(),
      actions: const [
        ProfileHeaderActions(
          selectorKey: ValueKey('analysis-profile-switcher'),
        ),
      ],
      onRefresh: refreshCalculation,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransientUpdateNotice<CalculationResult>(
              source: selectedProfileCalculationProvider,
              identity: profile == null ? null : calculationIdentity(profile),
              noticeKey: const ValueKey('analysis-updated-notice'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pythagoras V1',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bản Đồ Thần Số Học',
              style: text.headlineMedium?.copyWith(color: AppColors.primary),
            ),
            if (profile != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person_pin_outlined,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          profile.fullName,
                          key: const ValueKey('analysis-profile-name'),
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '•',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.outlineVariant,
                          ),
                        ),
                        Text(
                          displayDate(profile.birthDate),
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        CalculationContent(
          showProfileIdentity: false,
          statusBuilder:
              (context, ref, snapshot) => CompactDataState(
                snapshot: snapshot,
                onRefresh: () => refreshSelectedCalculation(ref),
              ),
          builder:
              (context, ref, profile, result) => AnalysisCards(result: result),
        ),
      ],
    );
  }
}
