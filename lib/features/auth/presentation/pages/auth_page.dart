import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/auth_session.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/email_verification_form.dart';
import '../widgets/register_form_fields.dart';

enum AuthPageMode { login, register, forgotPassword }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.mode});

  final AuthPageMode mode;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _registrationFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  final _registration = RegistrationFormData();
  var _otpStep = false;
  var _hidePassword = true;
  var _isSubmitting = false;
  Timer? _verificationTimer;
  DateTime? _verificationExpiresAt;
  int _verificationTtlSeconds = 0;
  String _verificationEmail = '';

  bool get _isRegisterEntry =>
      widget.mode == AuthPageMode.register && !_otpStep;

  bool get _isEmailVerification =>
      widget.mode == AuthPageMode.register && _otpStep;

  int get _verificationSecondsLeft {
    final deadline = _verificationExpiresAt;
    if (deadline == null) return 0;
    final milliseconds = deadline
        .difference(ref.read(appClockProvider).now())
        .inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isEmailVerification) {
      setState(() {});
    }
  }

  void _startVerificationCountdown(DateTime requestedAt) {
    _verificationTimer?.cancel();
    // Duration comes from register. Backend issues OTP before sending email;
    // request start is a conservative estimate, not an authoritative expiry.
    _verificationExpiresAt = requestedAt.add(
      Duration(
        seconds: _verificationTtlSeconds > 0 ? _verificationTtlSeconds : 0,
      ),
    );
    // Timer delivery can drift: derive remaining time from the injected clock.
    // https://api.dart.dev/dart-async/Timer/Timer.periodic.html
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isEmailVerification) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (_verificationSecondsLeft == 0) timer.cancel();
    });
  }

  void _returnToRegistration() {
    if (_isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _verificationTimer?.cancel();
    _otp.clear();
    ref.read(authSessionProvider.notifier).clearVerificationMessage();
    setState(() {
      _otpStep = false;
      _verificationExpiresAt = null;
    });
  }

  Future<void> _resendVerification() async {
    if (_isSubmitting ||
        !_isEmailVerification ||
        _verificationSecondsLeft > 0) {
      return;
    }
    setState(() => _isSubmitting = true);
    final requestedAt = ref.read(appClockProvider).now();
    try {
      final sent = await ref
          .read(authSessionProvider.notifier)
          .resendVerification(_verificationEmail);
      if (!mounted || !sent) return;
      _otp.clear();
      setState(() => _startVerificationCountdown(requestedAt));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    // https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html
    WidgetsBinding.instance.removeObserver(this);
    _verificationTimer?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    _registration.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitTap() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _submit();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    final form = _isRegisterEntry ? _registrationFormKey : _formKey;
    if (!form.currentState!.validate()) return;
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
        final email = _email.text.trim();
        final requestedAt = ref.read(appClockProvider).now();
        final sent = await controller.register(
          fullName: _name.text.trim(),
          email: email,
          password: _password.text,
          phone: _registration.phone.text.trim(),
          birthYear: _registration.birthDate!.year,
          username: _registration.username.text.trim(),
          identityNumber: _registration.identity.text.trim(),
        );
        if (sent != null && mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _verificationEmail = email;
            _verificationTtlSeconds = sent.emailVerificationExpiresInSeconds;
            _otpStep = true;
            _startVerificationCountdown(requestedAt);
          });
        }
      } else {
        final verified = await controller.verifyEmail(
          email: _verificationEmail,
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
      AuthPageMode.register => _otpStep ? 'Xác thực email' : 'Tạo tài khoản',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthFormLayout(
        title: title,
        description: description,
        isRegisterEntry: _isRegisterEntry,
        isEmailVerification: _isEmailVerification,
        onBack: () {
          if (_isEmailVerification) {
            _returnToRegistration();
          } else {
            context.canPop() ? context.pop() : context.go(AppRoutes.account);
          }
        },
        form: _buildForm(),
        message: session.message,
        activeTab: switch (widget.mode) {
          AuthPageMode.login => AuthLayoutTab.login,
          AuthPageMode.register => AuthLayoutTab.register,
          AuthPageMode.forgotPassword => null,
        },
        onLoginTabPressed: _isEmailVerification && _isSubmitting
            ? null
            : () => context.go(AppRoutes.login),
        onRegisterTabPressed: _isEmailVerification
            ? (_isSubmitting ? null : _returnToRegistration)
            : () => context.go(AppRoutes.register),
        submitButton: _buildSubmitButton(
          session.isSubmitting || _isSubmitting,
          actionLabel,
        ),
        secondaryActions: [
          if (widget.mode == AuthPageMode.login) _buildLoginActions(),
          if (_isEmailVerification)
            EmailVerificationActions(
              onBack: _isSubmitting ? null : _returnToRegistration,
              onResend: _isSubmitting || _verificationSecondsLeft > 0
                  ? null
                  : _resendVerification,
            ),
          if (widget.mode == AuthPageMode.forgotPassword) _buildReturnToLogin(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitting, String actionLabel) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _isEmailVerification
              ? 64
              : AppSizes.buttonHeight + AppSpacing.xs,
        ),
        child: FilledButton(
          key: const ValueKey('auth-submit'),
          onPressed: isSubmitting ? null : _handleSubmitTap,
          style: FilledButton.styleFrom(
            backgroundColor: _isRegisterEntry || _isEmailVerification
                ? AppColors.gold
                : AppColors.text,
            foregroundColor: AppColors.background,
            textStyle: _isRegisterEntry || _isEmailVerification
                ? Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  )
                : null,
            disabledBackgroundColor: AppColors.disabled,
            disabledForegroundColor: AppColors.textMuted,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: _isRegisterEntry || _isEmailVerification
                  ? BorderRadius.zero
                  : AppRadii.small,
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _isRegisterEntry
                            ? 'ĐĂNG KÝ'
                            : widget.mode == AuthPageMode.login
                            ? 'ĐĂNG NHẬP'
                            : actionLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      _isEmailVerification
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: _isRegisterEntry ? AppSizes.iconMedium : null,
                    ),
                  ],
                ),
        ),
      );

  Widget _buildReturnToLogin() => Column(
    children: [
      if (widget.mode == AuthPageMode.register)
        Text('Đã có tài khoản?', style: AppTextStyles.meta),
      TextButton.icon(
        onPressed: () => context.go(AppRoutes.login),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Về đăng nhập'),
      ),
    ],
  );

  Widget _buildLoginActions() => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final accountPrompt = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Chưa có tài khoản?', style: AppTextStyles.meta),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Đăng Ký Ngay'),
              ),
            ],
          );
          final forgotButton = TextButton(
            onPressed: () => context.go(AppRoutes.forgotPassword),
            child: const Text('Quên mật khẩu?'),
          );
          if (constraints.maxWidth < 600) {
            return Column(children: [accountPrompt, forgotButton]);
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [accountPrompt, forgotButton],
          );
        },
      ),
      TextButton(
        onPressed: () => context.go(AppRoutes.home),
        child: const Text('Tiếp tục với tư cách khách'),
      ),
    ],
  );

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.eyebrow),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildForm() {
    if (widget.mode == AuthPageMode.register) {
      // Keep the registration subtree mounted so back retains inputs, consent
      // and native control state. Only the active form is validated.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Offstage(
            offstage: _otpStep,
            child: ExcludeFocus(
              excluding: _otpStep,
              child: Form(
                key: _registrationFormKey,
                child: RegisterFormFields(
                  data: _registration,
                  name: _name,
                  email: _email,
                  password: _password,
                ),
              ),
            ),
          ),
          if (_otpStep)
            Form(
              key: _formKey,
              child: EmailVerificationForm(
                email: _verificationEmail,
                secondsLeft: _verificationSecondsLeft,
                otp: _otp,
                isSubmitting: _isSubmitting,
                onSubmit: _handleSubmitTap,
              ),
            ),
        ],
      );
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_otpStep)
            _buildLabeledField(
              label: 'ĐỊA CHỈ EMAIL',
              child: TextFormField(
                key: const ValueKey('auth-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'Nhập email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  errorMaxLines: 3,
                ),
                validator: (value) =>
                    !(value ?? '').contains('@') ? 'Email không hợp lệ' : null,
              ),
            ),
          if (_otpStep)
            _buildLabeledField(
              label: 'MÃ OTP',
              child: TextFormField(
                key: const ValueKey('auth-otp'),
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: 'Nhập mã OTP',
                  prefixIcon: Icon(Icons.password_rounded),
                  helperText: 'Nhập mã OTP đã được gửi đến email',
                  helperMaxLines: 3,
                  errorMaxLines: 3,
                ),
                validator: (value) =>
                    value?.length != 6 ? 'OTP gồm 6 chữ số' : null,
              ),
            ),
          if (widget.mode == AuthPageMode.login || _otpStep) ...[
            const SizedBox(height: AppSpacing.md),
            _buildLabeledField(
              label: widget.mode == AuthPageMode.forgotPassword
                  ? 'MẬT KHẨU MỚI'
                  : 'MẬT KHẨU BẢO MẬT',
              child: TextFormField(
                key: const ValueKey('auth-password'),
                controller: _password,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  hintText: widget.mode == AuthPageMode.forgotPassword
                      ? 'Nhập mật khẩu mới'
                      : 'Nhập mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
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
            ),
          ],
        ],
      ),
    );
  }
}
