import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_exception.dart';
import 'auth_models.dart';
import 'auth_remote_data_source.dart';
import 'auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._remote, this._storage);
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;
  int _googleGeneration = 0;
  Future<void>? _googleTokenWrite;

  @override
  Future<AuthSession> loginWithGoogle(String credential) async {
    final generation = _googleGeneration;
    final session = await _remote.loginWithGoogle(credential);
    if (generation != _googleGeneration) {
      throw const ApiException(
        type: ApiErrorType.cancelled,
        message: 'Login cancelled',
      );
    }
    final write = _saveGoogleSession(session);
    _googleTokenWrite = write;
    try {
      await write;
    } finally {
      _googleTokenWrite = null;
    }
    if (generation != _googleGeneration) {
      throw const ApiException(
        type: ApiErrorType.cancelled,
        message: 'Login cancelled',
      );
    }
    return session;
  }

  Future<void> _saveGoogleSession(AuthSession session) async {
    try {
      await _save(session);
    } catch (_) {
      await _storage.clear();
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final session = await _remote.login(username: username, password: password);
    await _save(session);
    return session;
  }

  Future<void> _save(AuthSession session) async {
    await _storage.saveAccessToken(session.accessToken);
    await _storage.saveRefreshToken(session.refreshToken);
  }

  @override
  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
    String? username,
    String? identityNumber,
  }) => _remote.register(
    email: email,
    password: password,
    fullName: fullName,
    phone: phone,
    birthYear: birthYear,
    username: username,
    identityNumber: identityNumber,
  );

  @override
  Future<void> verifyEmail({required String email, required String otp}) =>
      _remote.verifyEmail(email: email, otp: otp);

  @override
  Future<void> resendVerification(String email) =>
      _remote.resendVerification(email);

  @override
  Future<String?> requestPasswordReset(String email) =>
      _remote.requestPasswordReset(email);

  @override
  Future<void> verifyPasswordReset({
    required String email,
    required String otp,
  }) => _remote.verifyPasswordReset(email: email, otp: otp);

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) => _remote.confirmPasswordReset(
    email: email,
    otp: otp,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );

  @override
  Future<AuthSession?> restoreSession() async {
    final access = await _storage.getAccessToken();
    final refresh = await _storage.getRefreshToken();
    if (access == null || refresh == null) return null;
    return null;
  }

  Future<AuthSession?> refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;
    final session = await _remote.refresh(refreshToken);
    await _save(session);
    return session;
  }

  @override
  Future<void> logout() async {
    _googleGeneration++;
    // Do not wait for the Google picker or Backend request. Only finish an
    // already-started token write before the existing logout clears storage.
    try {
      await _googleTokenWrite;
    } catch (_) {
      // Google login reports write failures; logout must still clear storage.
    }
    final refreshToken = await _storage.getRefreshToken();
    try {
      if (refreshToken != null) await _remote.logout(refreshToken);
    } finally {
      await _storage.clear();
    }
  }
}
