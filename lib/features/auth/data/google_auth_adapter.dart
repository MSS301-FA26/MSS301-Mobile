import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Returns only the ID token expected by the Gateway, never OAuth access tokens.
abstract interface class GoogleAuthAdapter {
  Future<void> initialize();
  Future<String?> authenticate();
  Stream<String?> get credentials;
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);
  final String message;
}

class GoogleOAuthConfig {
  const GoogleOAuthConfig({
    required this.serverClientId,
    this.iosClientId = '',
  });
  factory GoogleOAuthConfig.fromDartDefines() => const GoogleOAuthConfig(
    serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    iosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
  );
  final String serverClientId;
  final String iosClientId;
}

class GoogleSignInAuthAdapter implements GoogleAuthAdapter {
  GoogleSignInAuthAdapter(this.config);
  final GoogleOAuthConfig config;
  final GoogleSignIn _google = GoogleSignIn.instance;
  Future<void>? _initialization;
  Future<String?>? _authentication;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (config.serverClientId.trim().isEmpty ||
        (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.iOS &&
            config.iosClientId.trim().isEmpty)) {
      throw const GoogleAuthException(
        'Đăng nhập Google chưa được cấu hình cho ứng dụng này.',
      );
    }
    if (!kIsWeb &&
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      throw const GoogleAuthException(
        'Đăng nhập Google hỗ trợ Android, iOS và trình duyệt Web.',
      );
    }
    try {
      // Web requires clientId and rejects serverClientId; Android uses the
      // Backend Web client as serverClientId to obtain the expected audience.
      // https://pub.dev/packages/google_sign_in_web#authentication
      // https://pub.dev/packages/google_sign_in_android#integration
      await _google.initialize(
        clientId: kIsWeb
            ? config.serverClientId
            : defaultTargetPlatform == TargetPlatform.iOS
            ? config.iosClientId
            : null,
        serverClientId: kIsWeb ? null : config.serverClientId,
      );
    } catch (_) {
      throw const GoogleAuthException(
        'Không thể khởi tạo đăng nhập Google. Vui lòng kiểm tra cấu hình ứng dụng.',
      );
    }
  }

  @override
  Future<String?> authenticate() {
    if (_authentication != null) {
      return Future.error(
        const GoogleAuthException(
          'Vui lòng hoàn tất hoặc đóng cửa sổ Google hiện tại trước khi thử lại.',
        ),
      );
    }
    final authentication = _authenticate();
    _authentication = authentication;
    return authentication.whenComplete(() => _authentication = null);
  }

  Future<String?> _authenticate() async {
    await initialize();
    try {
      if (!_google.supportsAuthenticate()) {
        throw const GoogleAuthException(
          'Vui lòng sử dụng nút Google trên trình duyệt.',
        );
      }
      // Avoid reusing SDK account/token state on a later app-login attempt.
      // https://pub.dev/documentation/google_sign_in/latest/google_sign_in/GoogleSignInAccount-class.html
      await _google.signOut();
      final account = await _google.authenticate();
      return _idToken(account);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const GoogleAuthException(
        'Không thể đăng nhập Google. Vui lòng thử lại.',
      );
    }
  }

  String _idToken(GoogleSignInAccount account) {
    final token = account.authentication.idToken;
    if (token == null || token.trim().isEmpty) {
      throw const GoogleAuthException(
        'Google chưa cung cấp thông tin xác thực hợp lệ. Vui lòng thử lại.',
      );
    }
    return token;
  }

  @override
  Stream<String?> get credentials => _google.authenticationEvents
      .where((event) => event is GoogleSignInAuthenticationEventSignIn)
      .map(
        (event) =>
            _idToken((event as GoogleSignInAuthenticationEventSignIn).user),
      )
      .handleError((Object error) {
        if (error is GoogleSignInException &&
            error.code == GoogleSignInExceptionCode.canceled) {
          return;
        }
        throw const GoogleAuthException(
          'Không thể đăng nhập Google. Vui lòng thử lại.',
        );
      });
}
