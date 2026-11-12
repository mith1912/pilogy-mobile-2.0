import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/app_components.dart';
import '../../domain/profile_validation.dart';
import '../../domain/user_profile.dart';
import '../profiles_view_model.dart';

/// Reusable create/edit component. Parent screens own navigation (M04).
class ProfileInputForm extends ConsumerStatefulWidget {
  const ProfileInputForm({
    super.key,
    this.profile,
    this.onSaved,
    this.selectOnSave = false,
  });
  final UserProfile? profile;
  final bool selectOnSave;
  final ValueChanged<UserProfile>? onSaved;

  @override
  ConsumerState<ProfileInputForm> createState() => _ProfileInputFormState();
}

class _ProfileInputFormState extends ConsumerState<ProfileInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileInputForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile?.id != widget.profile?.id ||
        oldWidget.profile?.updatedAt != widget.profile?.updatedAt) {
      _setProfile();
      _formKey.currentState?.reset();
    }
  }

  void _setProfile() {
    _name.text = widget.profile?.fullName ?? '';
    final date = widget.profile?.birthDate.split('-');
    _year.text = date?[0] ?? '';
    _month.text = date?[1] ?? '';
    _day.text = date?[2] ?? '';
    _error = null;
  }

  String get _date {
    if (_day.text.isEmpty || _month.text.isEmpty || _year.text.length != 4)
      return '';
    return '${_year.text}-${_month.text.padLeft(2, '0')}-${_day.text.padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final model = ref.read(profilesViewModelProvider.notifier);
      final profile = widget.profile;
      final saved =
          widget.selectOnSave
              ? await model.saveAndSelect(
                id: profile?.id,
                fullName: _name.text,
                birthDate: _date,
              )
              : profile == null
              ? await model.createProfile(
                fullName: _name.text,
                birthDate: _date,
              )
              : await model.updateProfile(
                id: profile.id,
                fullName: _name.text,
                birthDate: _date,
              );
      if (mounted) widget.onSaved?.call(saved);
    } catch (error) {
      if (mounted) setState(() => _error = localDataErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _datePart(
    TextEditingController controller,
    String label,
    int digits,
    FormFieldState<String> field,
  ) => Expanded(
    child: TextField(
      key: ValueKey('profile-date-$label'),
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(digits),
      ],
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => field.didChange(_date),
    ),
  );

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nguyên Tắc Chuẩn Xác',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Nhập họ tên khai sinh và ngày sinh dương lịch của bạn.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AbsorbPointer(
          absorbing: _saving,
          child: AppInputField(
            key: const ValueKey('profile-full-name'),
            label: 'Họ Và Tên Khai Sinh',
            controller: _name,
            validator: ProfileValidation.fullNameError,
            trailingIcon: Icons.badge_outlined,
            helperText:
                'Dùng đầy đủ chữ có dấu tiếng Việt, không dùng biệt danh.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ngày Sinh Dương Lịch',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        FormField<String>(
          key: ValueKey('profile-birth-date-${widget.profile?.id ?? 'new'}'),
          initialValue: widget.profile?.birthDate,
          validator: ProfileValidation.birthDateError,
          builder:
              (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _datePart(_day, 'Ngày', 2, field),
                      const SizedBox(width: AppSpacing.sm),
                      _datePart(_month, 'Tháng', 2, field),
                      const SizedBox(width: AppSpacing.sm),
                      _datePart(_year, 'Năm', 4, field),
                    ],
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.secondary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Hồ sơ được lưu cục bộ trên thiết bị. Không cần tài khoản.',
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppErrorState(message: _error!),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: const ValueKey('save-profile'),
          label:
              widget.selectOnSave
                  ? 'Khám phá bản thân'
                  : widget.profile == null
                  ? 'Lưu hồ sơ'
                  : 'Cập nhật hồ sơ',
          icon: Icons.save_outlined,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    ),
  );

  @override
  void dispose() {
    for (final controller in [_name, _day, _month, _year]) {
      controller.dispose();
    }
    super.dispose();
  }
}
