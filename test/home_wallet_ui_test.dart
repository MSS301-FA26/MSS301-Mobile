import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_test_app.dart';

void main() {
  testWidgets('Home renders the wallet quick-booking hierarchy', (tester) async {
    await pumpTestApp(tester, size: const Size(430, 900));

    expect(find.text('MUA VÉ NHANH'), findsNWidgets(2));
    expect(find.text('PHIM ĐANG CHIẾU'), findsOneWidget);
    expect(find.text('RẠP CINEPREMIER'), findsOneWidget);
  });
}
