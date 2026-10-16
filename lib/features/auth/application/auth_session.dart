import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_models.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
import '../data/remote_auth_repository.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initializing,
    this.session,
    this.message,
    this.isSubmitting = false,
  });
  final AuthStatus status;
  final AuthSession? session;
  final String? message;
  final bool isSubmitting;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? message,
    bool clearMessage = false,
    bool? isSubmitting,
  }) => AuthState(
    status: status ?? this.status,
    session: session ?? this.session,
    message: clearMessage ? null : message ?? this.message,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );
}

final tokenStorageProvider = secureTokenStorageProvider;
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => RemoteAuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final authSessionProvider = NotifierProvider<AuthSessionController, AuthState>(
  AuthSessionController.new,
);

class AuthSessionController extends Notifier<AuthState> {
  int _googleOperation = 0;
  bool _googlePending = false;
  @override
  AuthState build() {
    Future.microtask(bootstrap);
    return const AuthState();
  }

  Future<void> bootstrap() async {
    try {
      final repository =
          ref.read(authRepositoryProvider) as RemoteAuthRepository;
      final session =
          await repository.restoreSession() ?? await repository.refresh();
      state = session == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, session: session);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<RegistrationResult?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
    String? username,
    String? identityNumber,
  }) async {
    try {
      final registration = await ref
          .read(authRepositoryProvider)
          .register(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            birthYear: birthYear,
            username: username,
            identityNumber: identityNumber,
          );
      state = const AuthState(status: AuthStatus.unauthenticated);
      return registration;
    } catch (error) {
      state = state.copyWith(message: _message(error));
      return null;
    }
  }

  Future<bool> verifyEmail({required String email, required String otp}) async {
    state = state.copyWith(clearMessage: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(email: email, otp: otp);
      return true;
    } catch (error) {
      state = state.copyWith(
        message: error is ApiException ? error.message : _message(error),
      );
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(email);
      state = state.copyWith(clearMessage: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        message: error is ApiException ? error.message : _message(error),
      );
      return false;
    }
  }

  void clearVerificationMessage() {
    state = state.copyWith(clearMessage: true);
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      return true;
    } catch (error) {
      state = state.copyWith(message: _message(error));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPasswordReset(
            email: email,
            otp: otp,
            newPassword: password,
            confirmPassword: password,
          );
      return true;
    } catch (error) {
      state = state.copyWith(message: _message(error));
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_googlePending) return false;
    state = state.copyWith(
      message: null,
      clearMessage: true,
      isSubmitting: true,
    );
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = AuthState(status: AuthStatus.authenticated, session: session);
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        message: _message(error),
      );
      return false;
    }
  }

  void updateUserProfile(AuthUser user) {
    final session = state.session;
    if (session == null || session.user.id != user.id) return;
    state = state.copyWith(
      session: AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        tokenType: session.tokenType,
        expiresInMs: session.expiresInMs,
        user: user,
        roles: session.roles,
      ),
      clearMessage: true,
    );
  }

  Future<bool> logout() async {
    _googleOperation++;
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      _googlePending = false;
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    return true;
  }

  Future<void> signOut() async {
    await logout();
  }

  Future<bool> loginWithGoogle(
    Future<String?> Function() obtainCredential,
  ) async {
    if (_googlePending ||
        state.isSubmitting ||
        state.status == AuthStatus.initializing ||
        state.isAuthenticated) {
      return false;
    }
    _googlePending = true;
    final operation = ++_googleOperation;
    state = state.copyWith(clearMessage: true, isSubmitting: true);
    bool isCurrent() => ref.mounted && operation == _googleOperation;
    try {
      final credential = await obtainCredential();
      if (!isCurrent()) return false;
      if (credential == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return false;
      }
      final session = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(credential);
      if (!isCurrent()) return false;
      state = AuthState(status: AuthStatus.authenticated, session: session);
      return true;
    } catch (error) {
      if (isCurrent()) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          message: _googleErrorMessage(error),
        );
      }
      return false;
    } finally {
      if (operation == _googleOperation) _googlePending = false;
    }
  }

  String? _googleErrorMessage(Object error) {
    if (error is ApiException) {
      return switch (error.type) {
        ApiErrorType.cancelled => null,
        ApiErrorType.unauthorized || ApiErrorType.forbidden => 'Thông tin Google không hợp lệ hoặc tài khoản không được phép đăng nhập. Vui lòng thử lại.',
        ApiErrorType.conflict => 'Không thể đăng nhập tài khoản Google này. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
        ApiErrorType.network || ApiErrorType.timeout =>
          'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.',
        ApiErrorType.badRequest => 'Đăng nhập Google chưa được cấu hình đúng hoặc thông tin xác thực không hợp lệ.',
        ApiErrorType.tooManyRequests =>
          'Có quá nhiều yêu cầu. Vui lòng thử lại sau.',
        _ => 'Không thể đăng nhập Google lúc này. Vui lòng thử lại.',
      };
    }
    return 'Không thể đăng nhập Google lúc này. Vui lòng thử lại.';
  }

  String _message(Object error) =>
      error.toString().replaceFirst('ApiException(', '');
}
