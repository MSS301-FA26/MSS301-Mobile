import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/account_dto.dart';
import 'account_repositories.dart';

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this.dio);
  final Dio dio;

  Future<Map<String, Object?>?> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final body = (await call()).data;
      if (body is! Map || body['success'] != true) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Phản hồi hồ sơ không hợp lệ.',
        );
      }
      return body['data'] == null
          ? null
          : Map<String, Object?>.from(body['data'] as Map);
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }

  UserProfileDto _profile(Map<String, Object?>? data) {
    if (data == null) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Không nhận được hồ sơ người dùng.',
      );
    }
    return UserProfileDto.fromJson(data);
  }

  @override
  Future<UserProfileDto> getProfile(
    int userId, {
    CancelToken? cancelToken,
  }) async => _profile(
    await _request(() => dio.get('/api/v1/users/me', cancelToken: cancelToken)),
  );

  @override
  Future<UserProfileDto> updateProfile(
    int userId,
    UserProfileUpdateDto request, {
    CancelToken? cancelToken,
  }) async => _profile(
    await _request(
      () => dio.put(
        '/api/v1/users/me',
        cancelToken: cancelToken,
        data: {
          'fullName': request.fullName,
          'phone': request.phone,
          'birthYear': request.birthYear,
        },
      ),
    ),
  );

  Future<UserProfileDto> updateAvatar(
    String url, {
    CancelToken? cancelToken,
  }) async => _profile(
    await _request(
      () => dio.post(
        '/api/v1/users/me/avatar',
        cancelToken: cancelToken,
        data: FormData.fromMap({'avatarUrl': url}),
      ),
    ),
  );

  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword, {
    CancelToken? cancelToken,
  }) async {
    await _request(
      () => dio.post(
        '/api/v1/users/me/password',
        cancelToken: cancelToken,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      ),
    );
  }
}
