import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_test_app.dart';

void main() {
  testWidgets('Home renders the wallet quick-booking hierarchy', (
    tester,
  ) async {
    await pumpTestApp(tester, size: const Size(430, 900));

    expect(find.text('MUA VÉ NHANH'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('home-category-NOW_SHOWING')),
      findsOneWidget,
    );
    expect(find.text('RẠP CINEPREMIER'), findsOneWidget);
  });

  testWidgets('movie chooser presents a clear selection header', (
    tester,
  ) async {
    await pumpTestApp(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('home-quick-step-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-choice-header')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-choice-header')),
        matching: find.text('Chọn phim'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-choice-header')),
        matching: find.textContaining('phim khả dụng'),
      ),
      findsOneWidget,
    );
  });
}
