import '../../../services/ads/native_content_ad.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../../profiles/domain/user_profile.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../numerology/presentation/profile_header.dart';
import '../../numerology/presentation/refresh_status.dart';
import 'discover_cards.dart';
import 'discover_quotes.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with CalculationRefresh<DiscoverScreen> {
  late final String _quote;
  @override
  void initState() {
    super.initState();
    _quote = discoverQuotes[Random().nextInt(discoverQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesViewModelProvider);
    final selected = ref.watch(selectedProfileProvider);
    final profile =
        selected.isLoading || selected.hasError ? null : selected.valueOrNull;
    final calculation = ref.watch(selectedProfileCalculationProvider);
    final referenceDate =
        calculation.valueOrNull?.data?.referenceDate ??
        ref.watch(selectedReferenceDateProvider) ??
        ref.watch(currentReferenceDateProvider).valueOrNull ??
        localCalendarDate(DateTime.now());
    return PilogyScaffold(
      screenId: 'V03',
      title: 'PILOGY',
      tab: 0,
      titleSpacing: 20,
      showDefaultProfileAction: false,
      flatHeader: true,
      onRefresh: refreshCalculation,
      headerTitle: const PilogyBrandTitle(),
      actions: const [
        ProfileHeaderActions(
          selectorKey: ValueKey('discover-profile-switcher'),
          avatarKey: ValueKey('discover-profile-icon'),
        ),
      ],
      children: [
        if (profile != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransientUpdateNotice<CalculationResult>(
                source: selectedProfileCalculationProvider,
                identity: calculationIdentity(profile),
                noticeKey: const ValueKey('discover-updated-notice'),
              ),
              _greeting(
                context,
                profile,
                referenceDate,
                (profiles.valueOrNull?.profiles.indexWhere(
                          (item) => item.id == profile.id,
                        ) ??
                        -1) +
                    1,
              ),
            ],
          ),
        CalculationContent(
          showProfileIdentity: false,
          statusBuilder:
              (context, ref, snapshot) => CompactDataState(
                snapshot: snapshot,
                messageKey: const ValueKey('discover-data-state'),
                onRefresh: () => refreshSelectedCalculation(ref),
              ),
          builder:
              (context, ref, profile, result) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DiscoverLifePathCard(result: result),
                  const SizedBox(height: 24),
                  DiscoverCoreNumbers(result: result),
                  const NativeContentAd(),
                  const SizedBox(height: 24),
                  DiscoverCycles(result: result),
                  const SizedBox(height: 24),
                  AppButton(
                    key: const ValueKey('discover-analysis'),
                    label: 'Xem Bản Phân Tích Chi Tiết Của Tôi',
                    icon: Icons.arrow_forward,
                    onPressed: () => context.go('/analysis'),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  Widget _greeting(
    BuildContext context,
    UserProfile profile,
    String referenceDate,
    int profileNumber,
  ) {
    final text = Theme.of(context).textTheme;
    final date = referenceDate.split('-');
    final today = localCalendarDate(DateTime.now()) == referenceDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${today ? 'Hôm Nay' : 'Ngày Tham Chiếu'}, ${int.parse(date[2])} Tháng ${int.parse(date[1])}, ${date[0]}',
                style: text.labelSmall?.copyWith(color: AppColors.secondary),
              ),
            ),
            if (profileNumber > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Hồ sơ #$profileNumber',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Xin Chào, ${discoverGreetingName(profile.fullName)}',
          key: const ValueKey('discover-greeting'),
          style: text.headlineMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          '“$_quote”',
          key: const ValueKey('discover-quote'),
          style: text.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
