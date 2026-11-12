import '../../../services/ads/ad_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../../numerology/presentation/profile_header.dart';
import '../../numerology/presentation/refresh_status.dart';
import 'interpretation_article.dart';

class NumberDetailScreen extends ConsumerStatefulWidget {
  const NumberDetailScreen({super.key, this.type});
  final IndexType? type;
  @override
  ConsumerState<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends ConsumerState<NumberDetailScreen>
    with CalculationRefresh<NumberDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedProfileProvider);
    final profile =
        selected.isLoading || selected.hasError ? null : selected.valueOrNull;
    final text = Theme.of(context).textTheme;
    final type = widget.type;
    return PilogyScaffold(
      screenId: 'V05',
      title: 'Chi Tiết Chỉ Số Thần Số Học',
      back: true,
      backFallback: '/analysis',
      flatHeader: true,
      showDefaultProfileAction: false,
      sectionSpacing: 8,
      actions: [
        IconButton(
          tooltip: 'Tùy Chọn Hồ Sơ',
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.resolveWith(
              (states) =>
                  states.contains(MaterialState.pressed) ||
                          states.contains(MaterialState.hovered)
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
            ),
            overlayColor: MaterialStateProperty.all(
              AppColors.primary.withOpacity(.06),
            ),
          ),
          onPressed: () => showLocalProfileSwitcher(context),
          icon: const Icon(Icons.more_vert, size: 20),
        ),
        const ProfileAvatarButton(),
      ],
      onRefresh: () async {
        final before =
            ref.read(selectedProfileCalculationProvider).valueOrNull?.data;
        await refreshCalculation();
        if (!mounted || type == null) return;
        final after =
            ref.read(selectedProfileCalculationProvider).valueOrNull?.data;
        if (after == null ||
            before == null ||
            before.contentVersion != after.contentVersion ||
            before.indices[type]?.value != after.indices[type]?.value)
          return;
        final provider = fullInterpretationProvider(
          ArticleRequest(
            type,
            after.indices[type]!.value,
            locale: after.locale,
            contentVersion: after.contentVersion,
          ),
        );
        final article = ref.read(provider);
        if (!article.isLoading && article.valueOrNull?.refreshing != true)
          ref.invalidate(provider);
      },
      children: [
        if (profile != null)
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ Sơ Chiêm Nghiệm',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      '${profile.fullName} · ${displayDate(profile.birthDate)}',
                      key: const ValueKey('detail-profile-context'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ProfileSelectorButton(
                controlKey: ValueKey('detail-profile-switcher'),
              ),
            ],
          ),
        if (type == null)
          const AppEmptyState(
            message: 'Chọn một chỉ số trong bản phân tích để xem chi tiết.',
          )
        else
          CalculationContent(
            showProfileIdentity: false,
            statusBuilder:
                (context, ref, snapshot) => CompactDataState(
                  snapshot: snapshot,
                  onRefresh: () => refreshSelectedCalculation(ref),
                ),
            builder:
                (context, ref, profile, result) => _ArticleContent(
                  key: ValueKey(
                    '${calculationIdentity(profile)}:${result.referenceDate}:${type.name}',
                  ),
                  identity: calculationIdentity(profile),
                  index: result.indices[type]!,
                  request: ArticleRequest(
                    type,
                    result.indices[type]!.value,
                    locale: result.locale,
                    contentVersion: result.contentVersion,
                  ),
                ),
          ),
      ],
    );
  }
}

class _ArticleContent extends ConsumerWidget {
  const _ArticleContent({
    super.key,
    required this.request,
    required this.index,
    required this.identity,
  });
  final ArticleRequest request;
  final IndexResult index;
  final String identity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = fullInterpretationProvider(request);
    final state = ref.watch(provider);
    final snapshot =
        state.isLoading || state.hasError ? null : state.valueOrNull;
    final article = snapshot?.data?.interpretation;
    if (article != null && snapshot?.error == null) {
      final ads = ref.read(adMobServiceProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ads.interpretationReady();
      });
    }
    void retry() => ref.invalidate(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransientUpdateNotice<ArticleResult>(
          source: provider,
          identity: identity,
          noticeKey: const ValueKey('detail-updated-notice'),
        ),
        if (state.isLoading)
          const AppLoadingState(label: 'Đang tải luận giải…')
        else if (state.hasError)
          AppErrorState(message: safeDataMessage(state.error!), onRetry: retry)
        else if (snapshot != null) ...[
          CompactDataState(snapshot: snapshot, onRefresh: retry),
          if (article == null)
            const AppEmptyState(message: 'Nội dung luận giải chưa có sẵn.')
          else
            InterpretationArticle(
              article: article,
              index: index,
              onRefresh: retry,
            ),
        ],
      ],
    );
  }
}
