import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/auth_session.dart';
import '../../application/google_auth_provider.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button.dart';

class GoogleLoginButton extends ConsumerStatefulWidget {
  const GoogleLoginButton({super.key, required this.busy});
  final bool busy;

  @override
  ConsumerState<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends ConsumerState<GoogleLoginButton> {
  StreamSubscription<String?>? _subscription;
  bool _webReady = false;
  bool _webInitializing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) unawaited(_initializeWeb());
  }

  Future<void> _initializeWeb() async {
    if (_webInitializing || _webReady) return;
    setState(() => _webInitializing = true);
    try {
      final adapter = ref.read(googleAuthAdapterProvider);
      await adapter.initialize();
      if (!mounted) return;
      _subscription = adapter.credentials.listen(
        (credential) => unawaited(_signIn(() async => credential)),
        onError: (Object error) => unawaited(_signIn(() async => throw error)),
      );
      setState(() => _webReady = true);
    } catch (error) {
      if (mounted) await _signIn(() async => throw error);
    } finally {
      if (mounted) setState(() => _webInitializing = false);
    }
  }

  Future<void> _signIn(Future<String?> Function() obtainCredential) async {
    if (!mounted || widget.busy) return;
    await ref.read(authSessionProvider.notifier).loginWithGoogle(() async {
      final credential = await obtainCredential();
      // Leaving Login while the picker is open must not start an exchange.
      return mounted ? credential : null;
    });
    // AuthPage observes the normal authenticated state and uses its existing
    // successful-login redirect. No separate Google navigation/session.
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _webReady && !widget.busy) {
      // The Web SDK requires its visible button. Replace it while busy instead
      // of overlaying/IgnorePointer: HTML platform views own pointer events.
      // https://pub.dev/packages/google_sign_in_web#authentication
      return SizedBox(
        key: const ValueKey('auth-google-web'),
        height: AppSizes.buttonHeight,
        child: LayoutBuilder(
          builder: (_, constraints) =>
              Center(child: googleWebButton(constraints.maxWidth)),
        ),
      );
    }
    final busy = widget.busy || _webInitializing;
    final enabled = !busy;
    return Semantics(
      label: busy ? 'Đang đăng nhập bằng Google' : 'Đăng nhập bằng Google',
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: OutlinedButton(
          key: const ValueKey('auth-google-login'),
          onPressed: enabled
              ? () => kIsWeb
                    ? _initializeWeb()
                    : _signIn(ref.read(googleAuthAdapterProvider).authenticate)
              : null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderStrong),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
          ),
          child: busy
              ? const SizedBox(
                  key: ValueKey('auth-google-loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'G',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('ĐĂNG NHẬP BẰNG GOOGLE', style: AppTextStyles.label),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
