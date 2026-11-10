import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import 'registration_consent.dart';
import 'registration_validation.dart';

/// Transient registration inputs only; never stored as session or profile data.
class RegistrationFormData {
  final phone = TextEditingController();
  final username = TextEditingController();
  final identity = TextEditingController();
  final confirmation = TextEditingController();
  final birthDateText = TextEditingController();
  DateTime? birthDate;

  void dispose() {
    phone.dispose();
    username.dispose();
    identity.dispose();
    confirmation.dispose();
    birthDateText.dispose();
  }
}

class RegisterFormFields extends ConsumerStatefulWidget {
  const RegisterFormFields({
    super.key,
    required this.data,
    required this.name,
    required this.email,
    required this.password,
  });

  final RegistrationFormData data;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;

  @override
  ConsumerState<RegisterFormFields> createState() => _RegisterFormFieldsState();
}

class _RegisterFormFieldsState extends ConsumerState<RegisterFormFields> {
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  Future<void> _pickBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = ref.read(appClockProvider).now().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate:
          widget.data.birthDate ??
          (today.isBefore(DateTime(2000)) ? today : DateTime(2000)),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'CHỌN NGÀY SINH',
      cancelText: 'Hủy',
      confirmText: 'OK',
    );
    if (chosen == null || !mounted) return;
    setState(() {
      widget.data.birthDate = chosen;
      widget.data.birthDateText.text =
          '${chosen.day.toString().padLeft(2, '0')}/'
          '${chosen.month.toString().padLeft(2, '0')}/${chosen.year}';
    });
  }

  Widget _field(String label, Widget input) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        label: '$label, bắt buộc',
        excludeSemantics: true,
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Text('*', style: TextStyle(color: AppColors.gold)),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      input,
    ],
  );

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.emphasis.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        fillColor: AppColors.surface,
        prefixIcon: Icon(icon, size: AppSizes.iconMedium),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        suffixIcon: suffix,
        constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
        errorMaxLines: 5,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderStrong),
          borderRadius: BorderRadius.zero,
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderStrong),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
      );

  Widget _textInput({
    required String key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    List<String>? autofillHints,
    bool obscure = false,
    Widget? suffix,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    style: AppTextStyles.emphasis.copyWith(fontWeight: FontWeight.w400),
    textInputAction: TextInputAction.next,
    keyboardType: keyboard,
    inputFormatters: formatters,
    autofillHints: autofillHints,
    obscureText: obscure,
    autocorrect: !obscure && key != 'auth-identity-number',
    enableSuggestions: !obscure && key != 'auth-identity-number',
    decoration: _decoration(hint, icon, suffix: suffix),
    validator: validator,
  );

  Widget _visibility(
    bool hidden,
    VoidCallback onPressed, {
    bool confirm = false,
  }) => IconButton(
    tooltip: confirm
        ? (hidden ? 'Hiện xác thực mật khẩu' : 'Ẩn xác thực mật khẩu')
        : (hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu'),
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: onPressed,
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: AppSizes.iconMedium,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final fields = [
      _field(
        'HỌ VÀ TÊN',
        _textInput(
          key: 'auth-name',
          controller: widget.name,
          hint: 'Họ và tên',
          icon: Icons.person_outline_rounded,
          validator: RegistrationValidation.name,
          autofillHints: const [AutofillHints.name],
        ),
      ),
      _field(
        'NGÀY SINH',
        TextFormField(
          key: const ValueKey('auth-birth-date'),
          controller: data.birthDateText,
          readOnly: true,
          onTap: _pickBirthDate,
          style: AppTextStyles.emphasis.copyWith(fontWeight: FontWeight.w400),
          decoration:
              _decoration(
                'ngày/tháng/năm',
                Icons.calendar_today_outlined,
              ).copyWith(
                helperText: 'Chỉ năm sinh được lưu trong tài khoản.',
                helperMaxLines: 3,
              ),
          validator: (_) =>
              data.birthDate == null ? 'Vui lòng chọn ngày sinh' : null,
        ),
      ),
      _field(
        'SỐ ĐIỆN THOẠI',
        _textInput(
          key: 'auth-phone',
          controller: data.phone,
          hint: 'Số điện thoại',
          icon: Icons.phone_outlined,
          validator: RegistrationValidation.phone,
          keyboard: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ),
      _field(
        'TÊN ĐĂNG NHẬP',
        _textInput(
          key: 'auth-username',
          controller: data.username,
          hint: 'Tên đăng nhập',
          icon: Icons.person_outline_rounded,
          validator: RegistrationValidation.username,
          autofillHints: const [AutofillHints.newUsername],
        ),
      ),
      _field(
        'CCCD/CMND',
        _textInput(
          key: 'auth-identity-number',
          controller: data.identity,
          hint: 'Số CCCD/CMND',
          icon: Icons.shield_outlined,
          validator: RegistrationValidation.identity,
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),
      ),
      _field(
        'EMAIL',
        _textInput(
          key: 'auth-email',
          controller: widget.email,
          hint: 'Điền email',
          icon: Icons.mail_outline_rounded,
          validator: RegistrationValidation.email,
          keyboard: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
      ),
      _field(
        'MẬT KHẨU',
        _textInput(
          key: 'auth-password',
          controller: widget.password,
          hint: 'Mật khẩu',
          icon: Icons.lock_outline_rounded,
          validator: RegistrationValidation.password,
          autofillHints: const [AutofillHints.newPassword],
          obscure: _hidePassword,
          suffix: _visibility(
            _hidePassword,
            () => setState(() => _hidePassword = !_hidePassword),
          ),
        ),
      ),
      _field(
        'XÁC THỰC MẬT KHẨU',
        _textInput(
          key: 'auth-confirm-password',
          controller: data.confirmation,
          hint: 'Xác thực mật khẩu',
          icon: Icons.lock_outline_rounded,
          validator: (value) =>
              RegistrationValidation.confirm(value, widget.password.text),
          obscure: _hideConfirmation,
          suffix: _visibility(
            _hideConfirmation,
            () => setState(() => _hideConfirmation = !_hideConfirmation),
            confirm: true,
          ),
        ),
      ),
      const RegistrationConsent(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          fields[i],
        ],
      ],
    );
  }
}
