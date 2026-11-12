import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/presentation/widgets/profile_list.dart';
import '../../../core/design_system/widgets/app_components.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PilogyScaffold(
    screenId: 'V01',
    title: 'PILOGY',
    showHeader: false,
    bottomActions: const _WelcomeActions(),
    children: [
      Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: PilogyEmblem()),
          const Chip(label: Text('PILOGY Numerology')),
          const SizedBox(height: 16),
          Text(
            'Thấu Hiểu Bản Thân Qua Thần Số Học Pythagoras',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Khám phá bản đồ số học và chu kỳ cá nhân. Hồ sơ được lưu trên thiết bị của bạn.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      const EditorialPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.architecture_outlined,
              size: 36,
              color: AppColors.secondary,
            ),
            SizedBox(height: 12),
            Text('Hệ Thức Pythagoras'),
            SizedBox(height: 8),
            Text('Một không gian dành cho sự tĩnh tại và thấu hiểu bản thân.'),
          ],
        ),
      ),
      const InfoPanel(
        icon: Icons.auto_stories_outlined,
        title: 'Luận Giải Chuyên Sâu',
        message:
            'Các chỉ số và nội dung tiếng Việt được cung cấp bởi hệ thống PILOGY.',
      ),
      const InfoPanel(
        title: 'Bảo Mật Dữ Liệu Cá Nhân Cục Bộ',
        message:
            'Hồ sơ lưu trên máy. Họ tên và ngày sinh được gửi tới API khi yêu cầu tính toán.',
      ),
      const InfoPanel(
        icon: Icons.no_accounts_outlined,
        title: 'Không Cần Tài Khoản Hay Mật Khẩu',
        message: 'Tạo hồ sơ và bắt đầu khám phá.',
      ),
    ],
  );
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions();

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration:
        MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              key: const ValueKey('welcome-actions'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const ValueKey('welcome-start'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push('/profile-form'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Bắt Đầu Khám Phá',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('welcome-restore'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      backgroundColor: AppColors.surfaceContainer,
                      foregroundColor: AppColors.primary,
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _openSavedProfiles(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Tôi Đã Có Hồ Sơ Đã Lưu',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _openSavedProfiles(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (sheetContext) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: .8,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hồ Sơ Trên Thiết Bị',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const ProfileList(),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Mở Hồ Sơ Đã Lưu',
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/profiles');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
