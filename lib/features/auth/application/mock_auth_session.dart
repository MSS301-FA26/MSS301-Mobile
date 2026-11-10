import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_scenario.dart';

class PendingBookingAction {
  const PendingBookingAction({
    required this.movieId,
    required this.showtimeId,
    required this.sourceRoute,
  });

  final int movieId;
  final int showtimeId;
  final String sourceRoute;
}

class MockAuthSessionState {
  const MockAuthSessionState({
    required this.isAuthenticated,
    this.userId,
    this.pendingBooking,
    this.isSubmitting = false,
    this.message,
  });

  final bool isAuthenticated;
  final int? userId;
  final PendingBookingAction? pendingBooking;
  final bool isSubmitting;
  final String? message;
}

class MockAuthSessionController extends Notifier<MockAuthSessionState> {
  @override
  MockAuthSessionState build() =>
      const MockAuthSessionState(isAuthenticated: true, userId: DemoIds.user);

  void requireBookingAuth(PendingBookingAction action) {
    state = MockAuthSessionState(
      isAuthenticated: state.isAuthenticated,
      userId: state.userId,
      pendingBooking: action,
    );
  }

  PendingBookingAction? signInAndTakePending() {
    final pending = state.pendingBooking;
    state = const MockAuthSessionState(
      isAuthenticated: true,
      userId: DemoIds.user,
    );
    return pending;
  }

  Future<PendingBookingAction?> signIn({
    required String email,
    required String password,
  }) async {
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      isSubmitting: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!email.contains('@') || password.length < 6) {
      state = MockAuthSessionState(
        isAuthenticated: false,
        pendingBooking: state.pendingBooking,
        message: 'Email hoặc mật khẩu không hợp lệ.',
      );
      return null;
    }
    return signInAndTakePending();
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      isSubmitting: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final valid =
        fullName.trim().length >= 2 &&
        email.contains('@') &&
        password.length >= 8;
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      message: valid
          ? 'Mã OTP mock đã được gửi.'
          : 'Vui lòng kiểm tra họ tên, email và mật khẩu tối thiểu 8 ký tự.',
    );
    return valid;
  }

  Future<bool> verifyOtp(String otp) async {
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      isSubmitting: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (otp != '123456') {
      state = MockAuthSessionState(
        isAuthenticated: false,
        pendingBooking: state.pendingBooking,
        message: 'OTP không đúng. Mã demo là 123456.',
      );
      return false;
    }
    signInAndTakePending();
    return true;
  }

  Future<bool> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final valid = email.contains('@');
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      message: valid
          ? 'OTP khôi phục mock đã được gửi.'
          : 'Email không hợp lệ.',
    );
    return valid;
  }

  Future<bool> resetPassword({
    required String otp,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final valid = otp == '123456' && password.length >= 8;
    state = MockAuthSessionState(
      isAuthenticated: false,
      pendingBooking: state.pendingBooking,
      message: valid
          ? 'Đổi mật khẩu thành công. Hãy đăng nhập.'
          : 'OTP hoặc mật khẩu mới không hợp lệ.',
    );
    return valid;
  }

  void signOut() {
    state = const MockAuthSessionState(isAuthenticated: false);
  }

  void clearPending() {
    state = MockAuthSessionState(
      isAuthenticated: state.isAuthenticated,
      userId: state.userId,
    );
  }
}

final mockAuthSessionProvider =
    NotifierProvider<MockAuthSessionController, MockAuthSessionState>(
      MockAuthSessionController.new,
    );
