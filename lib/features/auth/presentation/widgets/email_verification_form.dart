import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Registration verification only; password reset retains its separate form.
class EmailVerificationForm extends StatelessWidget {
  const EmailVerificationForm({
    super.key,
    required this.email,
    required this.secondsLeft,
    required this.otp,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String email;
  final int secondsLeft;
  final TextEditingController otp;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        key: const ValueKey('auth-verification-panel'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.gold,
                  size: AppSizes.iconMedium,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'XÁC THỰC EMAIL',
                      style: AppTextStyles.emphasis.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Hệ thống đã gửi OTP đến', style: AppTextStyles.body),
            Text(
              email,
              key: const ValueKey('auth-verification-email'),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              secondsLeft > 0
                  ? 'OTP hết hạn sau ${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}'
                  : 'OTP đã hết hạn. Hãy gửi lại mã mới.',
              key: const ValueKey('auth-verification-countdown'),
              style: AppTextStyles.caption.copyWith(color: AppColors.gold),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'MÃ OTP EMAIL',
        style: AppTextStyles.label.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      TextFormField(
        key: const ValueKey('auth-otp'),
        controller: otp,
        enabled: !isSubmitting,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 6,
        style: AppTextStyles.emphasis.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 4,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập mã OTP',
          hintStyle: AppTextStyles.emphasis.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
            letterSpacing: 4,
          ),
          prefixIcon: const Icon(
            Icons.mail_outline_rounded,
            size: AppSizes.iconMedium,
          ),
          prefixIconColor: AppColors.textMuted,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 56,
          ),
          fillColor: AppColors.surface,
          constraints: const BoxConstraints(minHeight: 56),
          counterText: '',
          errorMaxLines: 3,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
          disabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.gold, width: 1.5),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        validator: (value) => value?.length != 6 ? 'OTP gồm 6 chữ số' : null,
        onFieldSubmitted: (_) => onSubmit(),
      ),
    ],
  );
}

class EmailVerificationActions extends StatelessWidget {
  const EmailVerificationActions({
    super.key,
    required this.onBack,
    required this.onResend,
  });

  final VoidCallback? onBack;
  final VoidCallback? onResend;

  Widget _button({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    bool resend = false,
  }) => OutlinedButton(
    key: key,
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      shape: const RoundedRectangleBorder(),
      backgroundColor: resend && onPressed != null
          ? AppColors.gold.withValues(alpha: 0.10)
          : AppColors.surface,
      foregroundColor: resend ? AppColors.gold : AppColors.textMuted,
      disabledForegroundColor: AppColors.textDisabled,
      side: BorderSide(
        color: resend && onPressed != null
            ? AppColors.goldBorder
            : AppColors.borderStrong,
      ),
      textStyle: AppTextStyles.label.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final back = _button(
        key: const ValueKey('auth-otp-back'),
        label: 'QUAY LẠI',
        onPressed: onBack,
      );
      final resend = _button(
        key: const ValueKey('auth-otp-resend'),
        label: 'GỬI LẠI MÃ OTP',
        onPressed: onResend,
        resend: true,
      );
      if (MediaQuery.textScalerOf(context).scale(12) > 18 &&
          constraints.maxWidth < 400) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            back,
            const SizedBox(height: AppSpacing.sm),
            resend,
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: constraints.maxWidth < 300 ? 3 : 1, child: back),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: constraints.maxWidth < 300 ? 5 : 2, child: resend),
          ],
        ),
      );
    },
  );
}
