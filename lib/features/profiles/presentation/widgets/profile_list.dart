import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/app_components.dart';
import '../../domain/user_profile.dart';
import '../profiles_view_model.dart';

Future<bool> confirmProfileDeletion(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: AppColors.error,
            ),
            title: const Text('Xác Nhận Xóa Hồ Sơ'),
            content: const Text(
              'Hồ sơ và kết quả đã lưu của hồ sơ này sẽ bị xóa khỏi thiết bị. '
              'Thao tác này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy Bỏ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa Vĩnh Viễn'),
              ),
            ],
          ),
    ) ??
    false;

/// Presentation-only tile, reusable in a list or a profile-selection sheet.
class ProfileSelectionTile extends StatelessWidget {
  const ProfileSelectionTile({
    super.key,
    required this.profile,
    required this.selected,
    this.onSelect,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });
  final UserProfile profile;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.cake_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(profile.birthDate),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton.icon(
                key: ValueKey('select-profile-${profile.id}'),
                onPressed: busy || selected ? null : onSelect,
                icon: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                label: Text(selected ? 'Hồ sơ đang chọn' : 'Chọn hồ sơ này'),
              ),
              IconButton(
                tooltip: 'Chỉnh Sửa Hồ Sơ',
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Xóa Hồ Sơ',
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Component only; M04 decides which screen/sheet hosts it and the edit flow.
class ProfileList extends ConsumerStatefulWidget {
  const ProfileList({super.key, this.onEdit, this.onAdd, this.onSelected});
  final ValueChanged<UserProfile>? onEdit;
  final VoidCallback? onAdd;
  final ValueChanged<UserProfile>? onSelected;

  @override
  ConsumerState<ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends ConsumerState<ProfileList> {
  bool _busy = false;
  String? _error;

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = localDataErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(UserProfile profile) async {
    if (_busy || !await confirmProfileDeletion(context) || !mounted) return;
    await _mutate(
      () => ref
          .read(profilesViewModelProvider.notifier)
          .deleteProfile(profile.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesViewModelProvider);
    return profiles.when(
      loading: () => const AppLoadingState(),
      error:
          (error, stack) => AppErrorState(
            message: localDataErrorMessage(error),
            onRetry:
                () => _mutate(
                  () => ref.read(profilesViewModelProvider.notifier).refresh(),
                ),
          ),
      data:
          (snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.profiles.isEmpty)
                const AppEmptyState(
                  message: 'Chưa có hồ sơ nào trên thiết bị.',
                  icon: Icons.person_add_outlined,
                ),
              for (final profile in snapshot.profiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProfileSelectionTile(
                    profile: profile,
                    selected: snapshot.selectedProfile?.id == profile.id,
                    busy: _busy,
                    onSelect:
                        () => _mutate(() async {
                          await ref
                              .read(profilesViewModelProvider.notifier)
                              .selectProfile(profile.id);
                          if (mounted) widget.onSelected?.call(profile);
                        }),
                    onEdit:
                        widget.onEdit == null
                            ? null
                            : () => widget.onEdit!(profile),
                    onDelete: () => _delete(profile),
                  ),
                ),
              if (_error != null) AppErrorState(message: _error!),
              if (widget.onAdd != null)
                AppButton(
                  label: '+ Thêm Hồ Sơ Mới',
                  icon: Icons.person_add_outlined,
                  onPressed: _busy ? null : widget.onAdd,
                  secondary: true,
                ),
            ],
          ),
    );
  }
}
