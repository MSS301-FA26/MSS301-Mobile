import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RegistrationConsent extends StatefulWidget {
  const RegistrationConsent({super.key});

  @override
  State<RegistrationConsent> createState() => _RegistrationConsentState();
}

class _RegistrationConsentState extends State<RegistrationConsent> {
  bool _showPolicy = false;

  @override
  Widget build(BuildContext context) => FormField<bool>(
    key: const ValueKey('auth-consent'),
    initialValue: false,
    validator: (value) => value == true
        ? null
        : 'Vui lòng đồng ý với Chính sách bảo mật để tiếp tục.',
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Đồng ý với Chính sách bảo mật',
              child: Checkbox(
                value: field.value ?? false,
                onChanged: field.didChange,
                activeColor: AppColors.gold,
                checkColor: AppColors.background,
                shape: const RoundedRectangleBorder(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tôi đã đọc và đồng ý với',
                    style: AppTextStyles.body,
                  ),
                  TextButton(
                    key: const ValueKey('auth-privacy-policy'),
                    onPressed: () => setState(() => _showPolicy = !_showPolicy),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      _showPolicy
                          ? 'Ẩn Chính sách bảo mật'
                          : 'Chính sách bảo mật',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (field.errorText != null)
          Semantics(
            liveRegion: true,
            child: Text(
              field.errorText!,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
        if (_showPolicy)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Text(
              // Same disclosure as current Web Register, not a new policy.
              'CinePremier thu thập thông tin đăng ký cần thiết để tạo tài khoản, '
              'xác minh email, đặt vé và hỗ trợ khách hàng.\n\n'
              'Thông tin cá nhân được bảo vệ trong hệ thống; chúng tôi không chia sẻ '
              'cho bên thứ ba, trừ trường hợp cần thiết để cung cấp dịch vụ hoặc '
              'theo yêu cầu pháp luật.\n\n'
              'Bạn có trách nhiệm cung cấp thông tin chính xác, bảo vệ mật khẩu '
              'và mã OTP của mình. Người dùng dưới 16 tuổi cần có sự đồng ý của '
              'cha mẹ hoặc người giám hộ hợp pháp.\n\n'
              'CinePremier có thể cập nhật chính sách theo thời gian; phiên bản '
              'mới sẽ được công bố trên hệ thống.',
              style: AppTextStyles.body,
            ),
          ),
      ],
    ),
  );
}
