import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });
  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
  });
  Future<void> verifyEmail({required String email, required String otp});
  Future<void> resendVerification(String email);
  Future<String?> requestPasswordReset(String email);
  Future<void> verifyPasswordReset({
    required String email,
    required String otp,
  });
  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
  Future<AuthSession?> restoreSession();
  Future<void> logout();
}
