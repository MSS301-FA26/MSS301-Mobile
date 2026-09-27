import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../application/mock_auth_session.dart';

enum AuthPageMode { login, register, forgotPassword }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.mode});

  final AuthPageMode mode;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'demo@cinepremier.vn');
  final _password = TextEditingController(text: '12345678');
  final _otp = TextEditingController();
  var _otpStep = false;
  var _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(mockAuthSessionProvider.notifier);
    if (widget.mode == AuthPageMode.login) {
      final pending = await controller.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted || !ref.read(mockAuthSessionProvider).isAuthenticated) {
        return;
      }
      context.go(
        pending == null
            ? AppRoutes.account
            : AppRoutes.seatSelection(pending.showtimeId),
      );
      return;
    }
    if (widget.mode == AuthPageMode.register) {
      if (!_otpStep) {
        final sent = await controller.register(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        if (sent && mounted) setState(() => _otpStep = true);
      } else {
        final verified = await controller.verifyOtp(_otp.text.trim());
        if (verified && mounted) context.go(AppRoutes.account);
      }
      return;
    }
    if (!_otpStep) {
      final sent = await controller.requestPasswordReset(_email.text.trim());
      if (sent && mounted) setState(() => _otpStep = true);
    } else {
      final reset = await controller.resetPassword(
        otp: _otp.text.trim(),
        password: _password.text,
      );
      if (reset && mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mockAuthSessionProvider);
    final title = switch (widget.mode) {
      AuthPageMode.login => 'Đăng nhập',
      AuthPageMode.register => _otpStep ? 'Xác thực OTP' : 'Tạo tài khoản',
      AuthPageMode.forgotPassword =>
        _otpStep ? 'Đặt mật khẩu mới' : 'Khôi phục mật khẩu',
    };
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.heroTitle),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Phiên xác thực mock • Không gửi dữ liệu ra ngoài thiết bị',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.mode == AuthPageMode.register && !_otpStep)
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                  if (!_otpStep) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => !(value ?? '').contains('@')
                          ? 'Email không hợp lệ'
                          : null,
                    ),
                  ],
                  if (_otpStep) ...[
                    TextFormField(
                      key: const ValueKey('auth-otp'),
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        helperText: 'Mã demo: 123456',
                      ),
                      validator: (value) =>
                          value?.length != 6 ? 'OTP gồm 6 chữ số' : null,
                    ),
                  ],
                  if (widget.mode == AuthPageMode.login ||
                      widget.mode == AuthPageMode.register ||
                      _otpStep) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: widget.mode == AuthPageMode.forgotPassword
                            ? 'Mật khẩu mới'
                            : 'Mật khẩu',
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6
                          ? 'Mật khẩu tối thiểu 6 ký tự'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            if (session.message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                session.message!,
                key: const ValueKey('auth-message'),
                style: const TextStyle(color: AppColors.gold),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('auth-submit'),
              label: session.isSubmitting ? 'Đang xử lý…' : title,
              onPressed: session.isSubmitting ? null : _submit,
            ),
            if (widget.mode == AuthPageMode.login) ...[
              TextButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: const Text('Quên mật khẩu?'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Tiếp tục với tư cách khách'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
