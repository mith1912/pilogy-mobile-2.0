import 'package:flutter/foundation.dart';
import '../../../services/ads/ad_inspector.dart';
import '../../../services/ads/ad_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/widgets/app_components.dart';
import '../../../core/presentation/pilogy_scaffold.dart';
import '../../profiles/presentation/profiles_view_model.dart';
import '../../numerology/presentation/calculation_widgets.dart';
import '../domain/settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(selectedProfileProvider).valueOrNull;
    final consent = ref.watch(adConsentProvider);
    final reminder = ref.watch(settingsViewModelProvider);
    return PilogyScaffold(
      screenId: 'V09',
      title: 'Cài Đặt',
      tab: 2,
      back: true,
      children: [
        const InfoPanel(
          icon: Icons.tune,
          title: 'Cài Đặt',
          message: 'Tùy chỉnh trải nghiệm và quyền riêng tư thiết bị.',
        ),
        const AppSectionHeader(title: 'Hồ Sơ & Dữ Liệu'),
        if (profile != null)
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(profile.fullName),
              subtitle: Text(displayDate(profile.birthDate)),
              onTap: () => context.go('/profiles'),
            ),
          ),
        ActionRow(
          title: 'Quản Lý Hồ Sơ Đã Lưu',
          icon: Icons.group_outlined,
          onTap: () => context.go('/profiles'),
        ),
        ActionRow(
          title: 'Quyền Riêng Tư & Dữ Liệu',
          icon: Icons.shield_outlined,
          onTap: () => context.push('/privacy-data'),
        ),
        const AppSectionHeader(title: 'Tùy Chọn Trải Nghiệm'),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Thông Báo Chiêm Nghiệm'),
                subtitle: const Text(
                  'Lưu tùy chọn trên máy. Chưa có thông báo được lên lịch.',
                ),
                value: reminder.valueOrNull ?? false,
                onChanged:
                    reminder.isLoading
                        ? null
                        : (value) async {
                          try {
                            await ref
                                .read(settingsViewModelProvider.notifier)
                                .setReminder(value);
                          } catch (_) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không thể lưu tùy chọn.'),
                                ),
                              );
                          }
                        },
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language),
                title: Text('Ngôn Ngữ Hiển Thị'),
                subtitle: Text('Tiếng Việt'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.light_mode_outlined),
                title: Text('Chế Độ Hiển Thị'),
                subtitle: Text('Sáng · Chưa Có Giao Diện Tối'),
              ),
              if (reminder.hasError)
                AppErrorState(
                  message: 'Không thể tải tùy chọn.',
                  onRetry: () => ref.invalidate(settingsViewModelProvider),
                ),
            ],
          ),
        ),
        const AppSectionHeader(title: 'Hỗ Trợ & Kiến Thức'),
        const Card(
          child: ExpansionTile(
            leading: Icon(Icons.calculate_outlined),
            title: Text('Phương Pháp Pythagoras'),
            childrenPadding: EdgeInsets.all(16),
            children: [
              Text(
                'PILOGY nhận kết quả và các bước tính từ máy chủ. Các giá trị 11, 22, 33 được giữ nguyên cùng giá trị cơ sở. Xem từng bước trong màn hình chi tiết chỉ số.',
              ),
            ],
          ),
        ),
        const ActionRow(
          title: 'Trung Tâm Trợ Giúp (FAQ)',
          icon: Icons.help_outline,
          subtitle: 'Chưa có nội dung trợ giúp được cung cấp.',
        ),
        if (kDebugMode)
          ActionRow(
            title: 'Ad Inspector (Debug)',
            icon: Icons.bug_report_outlined,
            onTap: () => openDebugAdInspector(ref.read(adMobServiceProvider)),
          ),
        const AppSectionHeader(title: 'Pháp Lý & Minh Bạch'),
        if (consent.privacyRequired)
          ActionRow(
            title: 'Lựa Chọn Quyền Riêng Tư Quảng Cáo',
            icon: Icons.privacy_tip_outlined,
            onTap:
                consent.busy
                    ? null
                    : () async {
                      await consent.privacyOptions();
                      if (context.mounted && consent.unavailable)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chưa thể mở lựa chọn quyền riêng tư. Vui lòng thử lại.',
                            ),
                          ),
                        );
                    },
          ),
        const InfoPanel(
          icon: Icons.info_outline,
          title: 'Tuyên Bố Miễn Trừ Trách Nhiệm',
          message:
              'Thần số học là công cụ chiêm nghiệm, không dự đoán tương lai tuyệt đối và không thay thế tư vấn tâm lý chuyên nghiệp.',
        ),
        const ActionRow(
          title: 'Chính Sách Riêng Tư & Điều Khoản',
          icon: Icons.policy_outlined,
          subtitle: 'Chưa có đường dẫn văn bản chính thức được cung cấp.',
        ),
        const Center(
          child: Text(
            'PILOGY Numerology · 1.0.0\nHồ sơ được lưu cục bộ',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
