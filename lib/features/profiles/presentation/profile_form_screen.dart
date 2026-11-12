import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../data/local_profile_repository.dart';
import '../domain/user_profile.dart';
import 'profiles_view_model.dart';
import 'widgets/profile_input_form.dart';
import 'widgets/profile_list.dart';

final editingProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>(
      (ref, id) => ref.watch(profileRepositoryProvider).getProfileById(id),
    );

class ProfileFormScreen extends ConsumerWidget {
  const ProfileFormScreen({super.key, this.profileId});
  final String? profileId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = profileId;
    Widget form(UserProfile? profile) => ProfileInputForm(
      key: ValueKey('form-${profile?.id ?? 'new'}'),
      profile: profile,
      selectOnSave: true,
      onSaved: (_) {
        context.go('/discover');
      },
    );
    return PilogyScaffold(
      screenId: 'V02',
      title: id == null ? 'Tạo Hồ Sơ Mới' : 'Chỉnh Sửa Hồ Sơ',
      back: true,
      backFallback: id == null ? '/welcome' : '/profiles',
      children: [
        if (id == null)
          form(null)
        else
          ref
              .watch(editingProfileProvider(id))
              .when(
                loading: () => const AppLoadingState(),
                error:
                    (e, s) => AppErrorState(
                      message: localDataErrorMessage(e),
                      onRetry: () => ref.invalidate(editingProfileProvider(id)),
                    ),
                data:
                    (profile) =>
                        profile == null
                            ? const AppEmptyState(
                              message: 'Hồ sơ không còn trên thiết bị.',
                            )
                            : form(profile),
              ),
        AppButton(
          label: 'Hủy Bỏ',
          secondary: true,
          onPressed:
              () => contextualBack(
                context,
                fallback: id == null ? '/welcome' : '/profiles',
              ),
        ),
        if (id != null) _DeleteProfileAction(profileId: id),
      ],
    );
  }
}

class _DeleteProfileAction extends ConsumerStatefulWidget {
  const _DeleteProfileAction({required this.profileId});
  final String profileId;
  @override
  ConsumerState<_DeleteProfileAction> createState() =>
      _DeleteProfileActionState();
}

class _DeleteProfileActionState extends ConsumerState<_DeleteProfileAction> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (error != null) AppErrorState(message: error!),
      TextButton.icon(
        icon: const Icon(Icons.delete_outline),
        label: const Text('Xóa Hồ Sơ Này'),
        onPressed:
            busy
                ? null
                : () async {
                  if (!await confirmProfileDeletion(context) || !mounted)
                    return;
                  setState(() => busy = true);
                  try {
                    await ref
                        .read(profilesViewModelProvider.notifier)
                        .deleteProfile(widget.profileId);
                    if (mounted) context.go('/profiles');
                  } catch (e) {
                    if (mounted)
                      setState(() => error = localDataErrorMessage(e));
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
      ),
    ],
  );
}
