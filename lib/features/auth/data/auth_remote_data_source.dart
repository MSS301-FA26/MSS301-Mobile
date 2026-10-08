import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

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
  }) async => RegistrationResult.fromJson(
    await _data(
      await _dio.post(
        '/api/v1/auth/register',
        data: _registrationBody(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          birthYear: birthYear,
        ),
      ),
    ),
  );

  Map<String, dynamic> _registrationBody({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? birthYear,
  }) {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (birthYear != null) body['birthYear'] = birthYear;
    return body;
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    await _dio.post(
      '/api/v1/auth/verify-email',
      data: {'email': email, 'otp': otp},
    );
  }

  Future<void> resendVerification(String email) async {
    await _dio.post(
      '/api/v1/auth/verify-email/request',
      data: {'email': email},
    );
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
