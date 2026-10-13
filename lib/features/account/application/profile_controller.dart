import 'dart:ui' show instantiateImageCodec;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_session.dart';
import '../../auth/data/auth_models.dart';
import '../data/models/account_dto.dart';
import '../data/repositories/account_providers.dart';
import '../data/repositories/remote_profile_repository.dart';
import '../presentation/providers/account_summary_provider.dart';

final remoteProfileRepositoryProvider = Provider(
  (ref) => RemoteProfileRepository(ref.watch(dioProvider)),
);

final currentProfileProvider = FutureProvider.autoDispose<UserProfileDto>((
  ref,
) async {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) {
    throw const ApiException(
      type: ApiErrorType.unauthorized,
      message: 'Vui lòng đăng nhập lại.',
    );
  }
  final repository = ref.watch(profileRepositoryProvider);
  final cancel = CancelToken();
  ref.onDispose(() => cancel.cancel());
  final profile = repository is RemoteProfileRepository
      ? await repository.getProfile(userId, cancelToken: cancel)
      : await repository.getProfile(userId);
  if (repository is RemoteProfileRepository && profile.id != userId) {
    throw const ApiException(
      type: ApiErrorType.forbidden,
      message: 'Hồ sơ không thuộc tài khoản hiện tại.',
    );
  }
  return profile;
});

String? profileNameError(String value) =>
    value.trim().isEmpty ? 'Vui lòng nhập họ tên.' : null;
String? profilePhoneError(String value) =>
    value.trim().isNotEmpty &&
        !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value.trim())
    ? 'Số điện thoại cần 10–15 chữ số, có thể bắt đầu bằng +.'
    : null;
String? profileBirthYearError(String value, int currentYear) {
  if (value.trim().isEmpty) return null;
  final year = int.tryParse(value.trim());
  return year == null || year < 1900 || year > currentYear || year > 2100
      ? 'Năm sinh không hợp lệ.'
      : null;
}

String? newPasswordError(String value) =>
    !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$')
        .hasMatch(value)
    ? 'Cần ít nhất 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.'
    : null;

String profileErrorMessage(Object error) => error is ApiException
    ? switch (error.type) {
        ApiErrorType.unauthorized =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        ApiErrorType.network ||
        ApiErrorType.timeout => 'Không thể kết nối. Vui lòng thử lại.',
        ApiErrorType.badRequest || ApiErrorType.validation => error.message,
        ApiErrorType.forbidden =>
          'Tài khoản chưa được phép thực hiện thao tác này.',
        _ => 'Không thể cập nhật thông tin lúc này. Vui lòng thử lại.',
      }
    : 'Không thể cập nhật thông tin lúc này. Vui lòng thử lại.';

class AvatarVerifier {
  Future<void> verify(String url, {CancelToken? cancelToken}) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: 'Vui lòng nhập URL ảnh http hoặc https hợp lệ.',
      );
    }
    final cancel = cancelToken ?? CancelToken();
    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ).get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancel,
          onReceiveProgress: (count, total) {
            if (count > 5 * 1024 * 1024 || total > 5 * 1024 * 1024) {
              cancel.cancel();
            }
          },
        );
    final codec = await instantiateImageCodec(
      Uint8List.fromList(response.data!),
    );
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
  }
}

final avatarVerifierProvider = Provider((ref) => AvatarVerifier());

class ProfileMutationState {
  const ProfileMutationState({this.busy = false, this.message, this.operation});
  final bool busy;
  final String? message;
  final String? operation;
}

class ProfileMutationController extends Notifier<ProfileMutationState> {
  int _generation = 0;
  CancelToken? _cancel;
  @override
  ProfileMutationState build() {
    _cancel?.cancel();
    _generation++;
    ref.onDispose(() => _cancel?.cancel());
    ref.watch(authSessionProvider.select((auth) => auth.session?.user.id));
    return const ProfileMutationState();
  }

  Future<bool> _run(
    Future<UserProfileDto?> Function(int, CancelToken) mutation,
    String success, {
    String operation = 'profile',
  }) async {
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (userId == null || state.busy) return false;
    final generation = _generation;
    final cancel = CancelToken();
    _cancel = cancel;
    state = ProfileMutationState(busy: true, operation: operation);
    try {
      final profile = await mutation(userId, cancel);
      if (!ref.mounted || generation != _generation) return false;
      if (profile != null) {
        if (profile.id != userId &&
            ref.read(profileRepositoryProvider) is RemoteProfileRepository) {
          throw const ApiException(
            type: ApiErrorType.forbidden,
            message: 'Sai tài khoản.',
          );
        }
        final current = ref.read(authSessionProvider).session!.user;
        ref
            .read(authSessionProvider.notifier)
            .updateUserProfile(
              AuthUser(
                id: current.id,
                email: profile.email,
                fullName: profile.fullName,
                roles: current.roles,
                phone: profile.phone,
                avatarUrl: profile.avatarUrl,
                birthYear: profile.birthYear,
                status: profile.status.wireValue,
                emailVerified: profile.emailVerified,
                phoneVerified: profile.phoneVerified,
              ),
            );
        ref.invalidate(currentProfileProvider);
        ref.invalidate(accountSummaryProvider);
      }
      state = ProfileMutationState(message: success, operation: operation);
      return true;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = ProfileMutationState(
          message: profileErrorMessage(error),
          operation: operation,
        );
      }
      return false;
    }
  }

  Future<bool> save(UserProfileUpdateDto request) => _run((id, cancel) {
    final repo = ref.read(profileRepositoryProvider);
    return repo is RemoteProfileRepository
        ? repo.updateProfile(id, request, cancelToken: cancel)
        : repo.updateProfile(id, request);
  }, 'Đã lưu hồ sơ.');
  Future<bool> avatar(String url) => _run(
    (_, cancel) async {
      await ref.read(avatarVerifierProvider).verify(url, cancelToken: cancel);
      if (cancel.isCancelled) throw StateError('Phiên đã thay đổi.');
      return ref
          .read(remoteProfileRepositoryProvider)
          .updateAvatar(url, cancelToken: cancel);
    },
    'Đã cập nhật ảnh đại diện.',
    operation: 'avatar',
  );
  Future<bool> password(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) => _run(
    (_, cancel) async {
      await ref
          .read(remoteProfileRepositoryProvider)
          .changePassword(
            oldPassword,
            newPassword,
            confirmPassword,
            cancelToken: cancel,
          );
      return null;
    },
    'Đã đổi mật khẩu.',
    operation: 'password',
  );
}

final profileMutationProvider =
    NotifierProvider<ProfileMutationController, ProfileMutationState>(
      ProfileMutationController.new,
    );
