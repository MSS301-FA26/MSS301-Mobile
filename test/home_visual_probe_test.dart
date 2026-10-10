import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_test_app.dart';

void main() {
  testWidgets('Home visual evidence', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Inter',
      )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
      final bytes = await File(
        'D:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    });
    const phase = String.fromEnvironment('HOME_PHASE', defaultValue: 'before');
    for (final width in [320.0, 430.0, 768.0]) {
      await pumpTestApp(tester, size: Size(width, 900));
      final app = tester.widget<ProviderScope>(find.byType(ProviderScope));
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('home-visual-boundary'),
          child: app,
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 1);
        final data = await picture.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('D:/FPTK9/MSS/ui-r09-evidence');
        await directory.create(recursive: true);
        await File('${directory.path}/home-$phase-${width.toInt()}.png')
            .writeAsBytes(data!.buffer.asUint8List());
        picture.dispose();
      });
    }
  });
}
