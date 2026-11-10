import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/features/home/presentation/pages/home_page.dart';

import 'support/fake_auth_session.dart';
import 'support/pump_test_app.dart';

void main() {
  testWidgets('guest can leave login after a booking redirect', (tester) async {
    await pumpTestApp(
      tester,
      authState: unauthenticatedState,
      initialLocation: AppRoutes.loginWithRedirect(AppRoutes.seatSelection(1002)),
    );
    expect(find.byType(AuthPage), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AuthPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
