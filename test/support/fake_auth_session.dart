import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';

AuthState authenticatedCustomerState() => AuthState(
  status: AuthStatus.authenticated,
  session: const AuthSession(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    tokenType: 'Bearer',
    expiresInMs: 3600000,
    user: AuthUser(
      id: 5101,
      email: 'customer@example.test',
      fullName: 'Test Customer',
      roles: ['CUSTOMER'],
    ),
    roles: ['CUSTOMER'],
  ),
);

const unauthenticatedState = AuthState(status: AuthStatus.unauthenticated);

class FakeAuthSessionController extends AuthSessionController {
  FakeAuthSessionController(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;

  @override
  Future<bool> login({required String username, required String password}) async {
    state = authenticatedCustomerState();
    return true;
  }

  @override
  Future<bool> logout() async {
    state = unauthenticatedState;
    return true;
  }
}
