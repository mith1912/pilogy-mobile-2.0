import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../../core/text/display_text.dart';
import '../../numerology/data/backend_repositories.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/backend_providers.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../domain/user_profile.dart';
import 'profiles_view_model.dart';
import 'widgets/profile_management_cards.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});
  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = localDataErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(UserProfile profile) => context.push('/profile-form?edit=${Uri.encodeQueryComponent(profile.id)}');

  Future<void> _delete(UserProfile profile) async {
    if (_busy) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 20),
              const CircleAvatar(radius: 24, backgroundColor: AppColors.errorContainer, child: Icon(Icons.delete_forever_outlined, color: AppColors.error, size: 28)),
              const SizedBox(height: 16),
              Text('Xác Nhận Xóa Hồ Sơ', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Bạn có chắc chắn muốn xóa hồ sơ của ${profile.fullName} khỏi thiết bị? Thao tác này không thể hoàn tác.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(0, 48)),
                onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Xóa Vĩnh Viễn'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ProfileAction(label: 'Hủy bỏ', icon: Icons.close, height: 48, onPressed: () => Navigator.pop(sheetContext, false))),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutate(() => ref.read(profilesViewModelProvider.notifier).deleteProfile(profile.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilesViewModelProvider);
    final snapshot = state.isLoading ? null : state.valueOrNull;
    final selected = snapshot?.selectedProfile;
    final others = snapshot?.profiles.where((profile) => profile.id != selected?.id).toList() ?? <UserProfile>[];
    final calculation = selected == null ? null : ref.watch(selectedProfileCalculationProvider);
    final result = calculation?.valueOrNull;
    final theme = Theme.of(context).textTheme;
    return PilogyScaffold(
      screenId: 'V08',
      title: 'Hồ Sơ',
      tab: 2,
      titleSpacing: 20,
      flatHeader: true,
      showDefaultProfileAction: false,
      sectionSpacing: 24,
      actions: const [Padding(padding: EdgeInsets.only(right: 12), child: CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: AppColors.onPrimary, size: 18)))],
      bottomActions: const _ProfileNavigation(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, runSpacing: 4, children: [
              Text('Hồ Sơ Đã Lưu', style: theme.headlineSmall?.copyWith(color: AppColors.primary)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(100)),
                child: Text('${snapshot?.profiles.length ?? 0} Hồ Sơ', style: theme.labelSmall?.copyWith(color: AppColors.onSecondaryContainer))),
            ]),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.verified_user_outlined, size: 16, color: AppColors.secondary)),
              const SizedBox(width: 6),
              Expanded(child: Text('Lưu trữ cục bộ an toàn trên thiết bị của bạn', style: theme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant))),
            ]),
          ]),
        ),
        if (state.isLoading) const AppLoadingState(),
        if (state.hasError) AppErrorState(message: localDataErrorMessage(state.error!), onRetry: () => _mutate(() => ref.read(profilesViewModelProvider.notifier).refresh())),
        if (selected != null)
          SelectedProfileCard(
            profile: selected,
            calculation: result?.data,
            onEdit: _busy ? null : () => _edit(selected),
            onAnalysis: _busy ? null : () => context.go('/analysis'),
            onDelete: _busy ? null : () => _delete(selected),
            status: calculation?.isLoading == true
                ? const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator())
                : calculation?.hasError == true
                    ? AppErrorState(message: safeDataMessage(calculation!.error!), onRetry: () => refreshSelectedCalculation(ref))
                    : result != null && (result.freshness != DataFreshness.fresh || result.refreshing || result.offline || result.contentStale || result.error != null)
                        ? DataStatus<CalculationResult>(snapshot: result, onRefresh: () => refreshSelectedCalculation(ref))
                        : null,
          ),
        if (snapshot != null && snapshot.profiles.isEmpty)
          const AppEmptyState(message: 'Chưa có hồ sơ nào trên thiết bị.', icon: Icons.person_add_outlined),
        if (others.isNotEmpty)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(alignment: WrapAlignment.spaceBetween, spacing: 8, runSpacing: 4, children: [
              Text('DANH SÁCH HỒ SƠ KHÁC (${others.length})', style: theme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
              Text('Chạm để đổi', style: theme.labelSmall?.copyWith(color: AppColors.outline)),
            ]),
            for (final profile in others) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OtherProfileCard(
                key: ValueKey('other-profile-${profile.id}'),
                profile: profile,
                onSelect: _busy ? null : () => _mutate(() => ref.read(profilesViewModelProvider.notifier).selectProfile(profile.id)),
                onEdit: _busy ? null : () => _edit(profile),
                onDelete: _busy ? null : () => _delete(profile),
              ),
            ),
          ]),
        if (_error != null) AppErrorState(message: _error!),
        ProfileAction(label: '+ Thêm hồ sơ mới', icon: Icons.person_add_outlined, height: 52, color: AppColors.surfaceContainerHighest,
          onPressed: _busy || snapshot == null ? null : () => context.push('/profile-form')),
        ProfileSurface(
          color: AppColors.surfaceContainerLow,
          shadow: false,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceContainer, child: Icon(Icons.storage_outlined, size: 18, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BẢO MẬT THIẾT BỊ', style: theme.labelSmall?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('Tất cả hồ sơ được lưu an toàn trong bộ nhớ máy. Không cần đăng ký tài khoản hay mật khẩu.', style: theme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ])),
          ]),
        ),
        ProfileSurface(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            _SettingsLink(title: 'Cài đặt ứng dụng', subtitle: 'Giao diện, thông báo & ngày tháng', icon: Icons.settings_outlined, onTap: () => context.push('/settings')),
            const SizedBox(height: 4),
            _SettingsLink(title: 'Quyền riêng tư & Quản lý dữ liệu', subtitle: 'Xuất hồ sơ, bộ nhớ đệm hoặc xóa dữ liệu', icon: Icons.shield_outlined, onTap: () => context.push('/privacy-data')),
          ]),
        ),
      ],
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Icon(icon, size: 22, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(formatUiLabel(title), style: Theme.of(context).textTheme.labelMedium),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.outline)),
      ])),
      const SizedBox(width: 8),
      const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
    ])),
  );
}

class _ProfileNavigation extends StatelessWidget {
  const _ProfileNavigation();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Color(0x0A51415F), blurRadius: 20, offset: Offset(0, -4))]),
    child: SafeArea(top: false, child: Row(children: [
      for (final item in const [
        (route: '/discover', key: 'tab-discover', title: 'Khám Phá', icon: Icons.explore_outlined),
        (route: '/analysis', key: 'tab-analysis', title: 'Phân Tích', icon: Icons.grid_view_outlined),
        (route: '/profiles', key: 'tab-profiles', title: 'Hồ Sơ', icon: Icons.account_circle),
      ]) Expanded(child: Semantics(selected: item.route == '/profiles', child: InkWell(
        key: ValueKey(item.key),
        onTap: item.route == '/profiles' ? null : () => context.go(item.route),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 64), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, size: 24, color: item.route == '/profiles' ? AppColors.primary : AppColors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(item.title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: item.route == '/profiles' ? AppColors.primary : AppColors.onSurfaceVariant)),
        ]))),
      ))),
    ])),
  );
}
