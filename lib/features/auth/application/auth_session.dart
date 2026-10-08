import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
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

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, fullName: fullName);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (error) {
      state = state.copyWith(message: _message(error));
      return false;
    }
  }

  Future<bool> verifyEmail({required String email, required String otp}) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(email: email, otp: otp);
      return true;
    } catch (error) {
      state = state.copyWith(message: _message(error));
      return false;
    }
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

  Future<bool> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    return true;
  }

  Future<void> signOut() async {
    await logout();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('ApiException(', '');
}
