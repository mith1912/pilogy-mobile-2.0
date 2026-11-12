import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import 'privacy_view_model.dart';

Future<bool> confirmLocalAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (dialog) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Hủy Bỏ'),
              ),
              TextButton(
                key: const ValueKey('confirm-local-action'),
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(action),
              ),
            ],
          ),
    ) ??
    false;

class PrivacyDataScreen extends ConsumerWidget {
  const PrivacyDataScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyViewModelProvider);
    final count =
        ref.watch(profilesViewModelProvider).valueOrNull?.profiles.length ?? 0;
    return PilogyScaffold(
      screenId: 'V10',
      title: 'Quyền Riêng Tư & Dữ Liệu',
      back: true,
      children: [
        const AppSectionHeader(
          title: 'Quyền Riêng Tư & Dữ Liệu',
          eyebrow: 'Bảo Mật & Minh Bạch',
        ),
        const InfoPanel(
          icon: Icons.swap_horiz,
          title: 'Cơ Chế Lưu Trữ Và Tính Toán',
          message:
              'Hồ sơ được lưu trên thiết bị. Khi phân tích, họ tên và ngày sinh được gửi qua kết nối HTTPS tới API để tính toán. Kết quả và luận giải được lưu vào bộ nhớ đệm cục bộ.',
        ),
        privacy.when(
          loading: () => const AppLoadingState(),
          error:
              (e, s) => AppErrorState(
                message: 'Không thể đọc bộ nhớ trên thiết bị.',
                onRetry: () => ref.invalidate(privacyViewModelProvider),
              ),
          data:
              (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(title: 'Lưu Trữ Cục Bộ'),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      children: [
                        Text(
                          '${(state.statistics.allocatedBytes / 1024).toStringAsFixed(0)} KB\nCơ sở dữ liệu',
                        ),
                        Text('$count\nHồ sơ đã lưu'),
                        Text(
                          '${state.statistics.calculations}\nBộ chỉ số cache',
                        ),
                        Text(
                          '${state.statistics.articles}\nBài luận giải cache',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    key: const ValueKey('export-profiles'),
                    label: 'Xuất Dữ Liệu Hồ Sơ (JSON)',
                    secondary: true,
                    icon: Icons.download_outlined,
                    loading: state.busy,
                    onPressed:
                        count == 0
                            ? null
                            : () async {
                              final confirmed = await confirmLocalAction(
                                context,
                                title: 'Xuất Hồ Sơ Trên Thiết Bị',
                                message:
                                    'Tệp JSON chứa họ tên và ngày sinh. Bạn chọn nơi lưu hoặc chia sẻ tệp bằng công cụ của thiết bị.',
                                action: 'Chọn nơi lưu',
                              );
                              if (confirmed && context.mounted)
                                await ref
                                    .read(privacyViewModelProvider.notifier)
                                    .exportProfiles();
                            },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    key: const ValueKey('clear-cache'),
                    label: 'Xóa Dữ Liệu Bộ Nhớ Đệm',
                    secondary: true,
                    icon: Icons.cleaning_services_outlined,
                    loading: state.busy,
                    onPressed: () async {
                      if (await confirmLocalAction(
                            context,
                            title: 'Xóa bộ nhớ đệm?',
                            message:
                                'Xóa kết quả và luận giải đã lưu. Hồ sơ và lựa chọn được giữ lại.',
                            action: 'Xóa cache',
                          ) &&
                          context.mounted) {
                        await ref
                            .read(privacyViewModelProvider.notifier)
                            .clearCache();
                      }
                    },
                  ),
                  if (state.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          state.message!,
                          style: TextStyle(
                            color:
                                state.failed
                                    ? AppColors.error
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  EditorialPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Vùng Nguy Hiểm',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Xóa vĩnh viễn tất cả hồ sơ. Không có bản sao từ xa để khôi phục.',
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          key: const ValueKey('delete-all-profiles'),
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Xóa Toàn Bộ Hồ Sơ Đã Lưu'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          onPressed:
                              state.busy || count == 0
                                  ? null
                                  : () async {
                                    if (await confirmLocalAction(
                                          context,
                                          title: 'Bạn có chắc chắn muốn xóa?',
                                          message:
                                              'Toàn bộ hồ sơ và kết quả riêng của từng hồ sơ sẽ bị xóa. Thao tác này không thể hoàn tác.',
                                          action: 'Xóa vĩnh viễn',
                                        ) &&
                                        context.mounted) {
                                      await ref
                                          .read(
                                            privacyViewModelProvider.notifier,
                                          )
                                          .deleteAllProfiles();
                                    }
                                  },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }
}
