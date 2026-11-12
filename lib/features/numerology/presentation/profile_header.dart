import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../profiles/presentation/widgets/profile_list.dart';

void showLocalProfileSwitcher(BuildContext context) {
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
                    'Chọn Hồ Sơ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ProfileList(
                    onSelected: (_) {
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

class PilogyBrandTitle extends StatelessWidget {
  const PilogyBrandTitle({super.key});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PILOGY',
            style: text.headlineSmall?.copyWith(color: AppColors.primary),
          ),
          Container(
            height: 16,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.outlineVariant.withOpacity(.4),
          ),
          Text(
            'V1',
            style: text.labelSmall?.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class ProfileSelectorButton extends ConsumerWidget {
  const ProfileSelectorButton({super.key, this.controlKey});
  final Key? controlKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesViewModelProvider);
    if ((profiles.valueOrNull?.profiles.length ?? 0) <= 1)
      return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return TextButton(
      key: controlKey,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(AppColors.surfaceContainer),
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
        shape: MaterialStateProperty.all(const StadiumBorder()),
        minimumSize: MaterialStateProperty.all(const Size(0, 36)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      onPressed: () => showLocalProfileSwitcher(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 84),
            child: Text(
              'Hồ Sơ Chính',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: text.labelSmall?.fontFamily,
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .66,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, size: 14),
        ],
      ),
    );
  }
}

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key, this.controlKey});
  final Key? controlKey;
  @override
  Widget build(BuildContext context) => IconButton(
    key: controlKey,
    tooltip: 'Hồ Sơ Đã Lưu',
    style: ButtonStyle(
      overlayColor: MaterialStateProperty.all(
        AppColors.primary.withOpacity(.06),
      ),
    ),
    onPressed: () => context.go('/profiles'),
    icon: Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(Icons.person, size: 18, color: AppColors.onPrimary),
    ),
  );
}

class ProfileHeaderActions extends StatelessWidget {
  const ProfileHeaderActions({super.key, this.selectorKey, this.avatarKey});
  final Key? selectorKey, avatarKey;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ProfileSelectorButton(controlKey: selectorKey),
      const SizedBox(width: 8),
      ProfileAvatarButton(controlKey: avatarKey),
    ],
  );
}
