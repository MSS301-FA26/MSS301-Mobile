import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/home/data/home_banner_repository.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/movie_coverflow.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/popbot_banner.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/promotional_banner_carousel.dart';
import 'package:mss301_mobile/features/home/presentation/widgets/quick_actions.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/presentation/models/movie.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'Home handles long text and broken poster at $width with large text',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var openedChat = false;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(1.8),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const QuickActions(),
                      PopBotBanner(onOpen: () => openedChat = true),
                      MovieCoverflow(
                        movies: const [
                          Movie(
                            id: 1,
                            title: 'Một bộ phim có tên rất dài để kiểm tra giao diện trên màn hình nhỏ',
                            ageRating: 'T18',
                            duration: '138 phút',
                            rating: 0,
                            genre: 'Gia đình',
                            tagline: '',
                            posterAsset: 'assets/missing-poster.jpg',
                            genreTags: ['Gia đình', 'Tâm lý', 'Phiêu lưu'],
                            trailerUrl: 'https://example.test/trailer',
                            status: MovieStatus.nowShowing,
                          ),
                        ],
                        colorLoader: (_) async => Colors.blue,
                        onOpen: (_) {},
                        onBook: (_) {},
                        onTrailer: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cards = [
          'Bắp & Nước',
          'PopBot AI',
          'Ưu đãi VIP',
          'CinePoints',
        ].map((label) => find.byKey(ValueKey('quick-action-$label'))).toList();
        final top = tester.getTopLeft(cards.first).dy;
        for (final card in cards) {
          expect(tester.getTopLeft(card).dy, top);
        }
        await tester.ensureVisible(find.text('Trò chuyện với PopBot'));
        await tester.tap(find.text('Trò chuyện với PopBot'));
        expect(openedChat, isTrue);
        await tester.ensureVisible(find.text('Xem trailer'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'enabling reduced motion stops banner autoplay and allows manual selection',
    (tester) async {
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeBannersProvider.overrideWith(
              (ref) async => const [
                HomeBanner(
                  id: 1,
                  image: 'assets/mock/movies/inception-banner.jpg',
                  title: 'One',
                ),
                HomeBanner(
                  id: 2,
                  image: 'assets/mock/movies/inception-banner.jpg',
                  title: 'Two',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: reduced,
              builder: (context, value, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: value),
                child: child!,
              ),
              child: const Scaffold(body: PromotionalBannerCarousel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pages = tester
          .widget<PageView>(
            find.byKey(const ValueKey('home-promotion-carousel')),
          )
          .controller!;
      reduced.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(pages.page, 0);
      await tester.tap(find.bySemanticsLabel('Banner 2 / 2'));
      await tester.pumpAndSettle();
      expect(pages.page, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
