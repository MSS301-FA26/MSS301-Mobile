import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/home_section_heading.dart';
import 'package:mss301_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/presentation/providers/movies_provider.dart';

import 'support/pump_test_app.dart';

void main() {
  testWidgets('Home visual evidence', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Inter',
      )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    const phase = String.fromEnvironment('HOME_PHASE', defaultValue: 'after');
    const evidenceDirectory = String.fromEnvironment(
      'HOME_EVIDENCE_DIR',
      defaultValue: 'build/ui-r091-evidence',
    );
    for (final width in [320.0, 430.0, 768.0]) {
      final container = await pumpTestApp(
        tester,
        size: Size(width, 900),
        providerOverrides: [
          // Contract-shaped test fixtures only, never a production fallback.
          homeCinemasProvider.overrideWith(
            (ref) async => [
              for (var id = 1; id <= 6; id++)
                CinemaDto(
                  id: id,
                  name: 'CinePremier — Cụm rạp $id',
                  address:
                      'Tầng 3, trung tâm thương mại — Địa chỉ từ fixture $id',
                  city: [
                    'TP. Hồ Chí Minh',
                    'Hà Nội',
                    'Đà Nẵng',
                    'Cần Thơ',
                  ][id % 4],
                  active: true,
                ),
            ],
          ),
        ],
      );
      final assets = container
          .read(moviesProvider)
          .requireValue
          .map((m) => m.posterAsset)
          .toSet();
      final imageContext = tester.element(
        find.byKey(const ValueKey('home-scroll')),
      );
      // Resolve fixture images before capturing; pumpAndSettle does not await I/O.
      // https://api.flutter.dev/flutter/widgets/precacheImage.html
      await tester.runAsync(() async {
        for (final asset in assets) {
          await precacheImage(AssetImage(asset), imageContext);
        }
      });
      final app = tester.widget<ProviderScope>(find.byType(ProviderScope));
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('home-visual-boundary'),
          child: app,
        ),
      );
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('home-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      for (final section in [
        'hero',
        'now-showing',
        'coming-soon',
        'cinemas',
        'end',
      ]) {
        final title = switch (section) {
          'now-showing' => 'PHIM ĐANG CHIẾU',
          'coming-soon' => 'PHIM SẮP CHIẾU',
          'cinemas' => 'RẠP CINEPREMIER',
          _ => null,
        };
        if (title != null) {
          await Scrollable.ensureVisible(
            tester.element(
              find.ancestor(
                of: find.text(title),
                matching: find.byType(HomeSectionHeading),
              ),
            ),
            alignment: 0,
          );
          await tester.pumpAndSettle();
        }
        if (section == 'end') {
          final position = tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find.byKey(const ValueKey('home-scroll')),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('home-visual-boundary')),
        );
        await tester.runAsync(() async {
          final picture = await boundary.toImage(pixelRatio: 1);
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory(evidenceDirectory);
          await directory.create(recursive: true);
          await File(
            '${directory.path}/home-$phase-${width.toInt()}-$section.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          picture.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    }
  });
}
