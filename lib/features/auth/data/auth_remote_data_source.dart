import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_mapper.dart';
import 'auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthSession> loginWithGoogle(String credential) async {
    const invalid = ApiException(
      type: ApiErrorType.unknown,
      message: 'Invalid Google login response',
    );
    if (credential.trim().isEmpty) {
      throw const ApiException(
        type: ApiErrorType.badRequest,
        message: 'Google credential is required',
      );
    }
    try {
      final response = await _dio.post(
        '/api/v1/auth/google',
        data: {'credential': credential},
        // An invalid Google credential must not trigger app-token refresh/retry.
        options: Options(
          extra: {'skipAuthRefresh': true, 'skipAuthorization': true},
        ),
      );
      final body = response.data;
      if (body is! Map || body['success'] != true) throw invalid;
      final data = body['data'];
      if (data is! Map<String, dynamic> ||
          !_nonBlank(data['accessToken']) ||
          !_nonBlank(data['refreshToken']) ||
          data['tokenType'] != 'Bearer' ||
          data['expiresInMs'] is! num ||
          (data['expiresInMs'] as num) <= 0 ||
          !_roles(data['roles'])) {
        throw invalid;
      }
      final user = data['user'];
      if (user is! Map<String, dynamic> ||
          user['id'] is! num ||
          !_nonBlank(user['email']) ||
          !_roles(user['roles'])) {
        throw invalid;
      }
      try {
        return AuthSession.fromJson(data);
      } catch (_) {
        throw invalid;
      }
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      throw ApiErrorMapper().fromDioException(error);
    }
  }

  bool _nonBlank(Object? value) => value is String && value.trim().isNotEmpty;
  bool _roles(Object? value) => value is List && value.every(_nonBlank);

  Future<Map<String, dynamic>> _data(Response<dynamic> response) async {
    final body = response.data;
    if (body is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid API response',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => AuthSession.fromJson(
    await _data(
      await _dio.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      ),
    ),
  );

  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
    String? username,
    String? identityNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: _registrationBody(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          birthYear: birthYear,
          username: username,
          identityNumber: identityNumber,
        ),
      );
      final body = response.data;
      if (body is! Map ||
          body['success'] != true ||
          body['data'] is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Invalid registration response',
        );
      }
      return RegistrationResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      throw ApiErrorMapper().fromDioException(error);
    }
  }

  Map<String, dynamic> _registrationBody({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
    String? username,
    String? identityNumber,
  }) => <String, dynamic>{
    'email': email,
    'password': password,
    'fullName': fullName,
    'phone': phone,
    'birthYear': birthYear,
    'username': username,
    'identityNumber': identityNumber,
  };

  Future<void> verifyEmail({required String email, required String otp}) =>
      _verificationRequest('/api/v1/auth/verify-email', {
        'email': email,
        'otp': otp,
      });

  Future<void> resendVerification(String email) => _verificationRequest(
    '/api/v1/auth/verify-email/request',
    {'email': email},
  );

  Future<void> _verificationRequest(
    String path,
    Map<String, String> request,
  ) async {
    try {
      final response = await _dio.post(path, data: request);
      final body = response.data;
      // Identity returns ApiResponse<Void>: success is required, data is not.
      if (body is! Map || body['success'] != true) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Invalid email verification response',
        );
      }
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      throw ApiErrorMapper().fromDioException(error);
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    final data = await _data(
      await _dio.post(
        '/api/v1/auth/password-reset/request',
        data: {'email': email},
      ),
    );
    return data['token']?.toString();
  }

  Future<void> verifyPasswordReset({
    required String email,
    required String otp,
  }) async {
    await _dio.post(
      '/api/v1/auth/password-reset/verify',
      data: {'email': email, 'otp': otp},
    );
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post(
      '/api/v1/auth/password-reset/confirm',
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      '/api/v1/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AuthSession> refresh(String refreshToken) async =>
      AuthSession.fromJson(
        await _data(
          await _dio.post(
            '/api/v1/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(extra: {'skipAuthRefresh': true}),
          ),
        ),
      );
}
