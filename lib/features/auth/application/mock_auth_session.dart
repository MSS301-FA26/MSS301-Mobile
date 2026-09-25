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
  });

  final bool isAuthenticated;
  final int? userId;
  final PendingBookingAction? pendingBooking;
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
