import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../application/auth_session.dart';
import '../widgets/auth_form_layout.dart';

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
  final _password = TextEditingController();
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
    final controller = ref.read(authSessionProvider.notifier);
    if (widget.mode == AuthPageMode.login) {
      final signedIn = await controller.login(
        username: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted || !signedIn) {
        return;
      }
      context.go(_postLoginRoute(context));
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
        final verified = await controller.verifyEmail(
          email: _email.text.trim(),
          otp: _otp.text.trim(),
        );
        if (verified && mounted) context.go(AppRoutes.account);
      }
      return;
    }
    if (!_otpStep) {
      final sent = await controller.requestPasswordReset(_email.text.trim());
      if (sent && mounted) setState(() => _otpStep = true);
    } else {
      final reset = await controller.resetPassword(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
        password: _password.text,
      );
      if (reset && mounted) context.go(AppRoutes.login);
    }
  }

  String _postLoginRoute(BuildContext context) {
    final route = GoRouterState.of(context).uri.queryParameters['continue'];
    if (route != null && route.startsWith('/') && !route.startsWith('//')) {
      return route;
    }
    return AppRoutes.home;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (widget.mode == AuthPageMode.login && session.isAuthenticated) {
      final route = _postLoginRoute(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(route);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final title = switch (widget.mode) {
      AuthPageMode.login => 'Đăng nhập',
      AuthPageMode.register => _otpStep ? 'Xác thực OTP' : 'Tạo tài khoản',
      AuthPageMode.forgotPassword =>
        _otpStep ? 'Đặt mật khẩu mới' : 'Khôi phục mật khẩu',
    };
    final description = switch (widget.mode) {
      AuthPageMode.login =>
        'Đăng nhập để quản lý vé, đơn bắp nước và tài khoản CinePremier.',
      AuthPageMode.register =>
        _otpStep ? 'Nhập mã đã được gửi đến email để xác thực tài khoản.' : 'Nhập thông tin tài khoản. Bước tiếp theo là xác thực email bằng OTP.',
      AuthPageMode.forgotPassword =>
        _otpStep
            ? 'Nhập mã OTP từ email và mật khẩu mới cho tài khoản.'
            : 'Nhập email tài khoản để yêu cầu mã khôi phục mật khẩu.',
    };
    final actionLabel = widget.mode == AuthPageMode.forgotPassword
        ? (_otpStep ? 'Đổi mật khẩu' : 'Gửi mã OTP')
        : title;
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: AuthFormLayout(
        title: title,
        description: description,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.account),
        form: _buildForm(),
        message: session.message,
        submitButton: AppButton(
          key: const ValueKey('auth-submit'),
          label: session.isSubmitting ? 'Đang xử lý…' : actionLabel,
          loading: session.isSubmitting,
          fullWidth: true,
          onPressed: session.isSubmitting ? null : _submit,
        ),
        secondaryActions: [
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
    );
  }

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      children: [
        if (widget.mode == AuthPageMode.register && !_otpStep) ...[
          TextFormField(
            key: const ValueKey('auth-name'),
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Họ và tên',
              errorMaxLines: 3,
            ),
            validator: (value) =>
                (value?.trim().length ?? 0) < 2 ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!_otpStep)
          TextFormField(
            key: const ValueKey('auth-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              errorMaxLines: 3,
            ),
            validator: (value) =>
                !(value ?? '').contains('@') ? 'Email không hợp lệ' : null,
          ),
        if (_otpStep)
          TextFormField(
            key: const ValueKey('auth-otp'),
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'OTP',
              helperText: 'Nhập mã OTP đã được gửi đến email',
              helperMaxLines: 3,
              errorMaxLines: 3,
            ),
            validator: (value) =>
                value?.length != 6 ? 'OTP gồm 6 chữ số' : null,
          ),
        if (widget.mode == AuthPageMode.login ||
            widget.mode == AuthPageMode.register ||
            _otpStep) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('auth-password'),
            controller: _password,
            obscureText: _hidePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: widget.mode == AuthPageMode.forgotPassword
                  ? 'Mật khẩu mới'
                  : 'Mật khẩu',
              errorMaxLines: 3,
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value?.length ?? 0) < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
          ),
        ],
      ],
    ),
  );
}
