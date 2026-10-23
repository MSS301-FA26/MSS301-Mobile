import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/cinema/application/cinema_preferences.dart';
import 'package:mss301_mobile/features/cinema/presentation/providers/cinema_providers.dart';
import 'package:mss301_mobile/features/movie/data/models/cinema_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

import 'support/fake_auth_session.dart';
import 'support/pump_test_app.dart';

class _CinemaRepository extends MockCatalogRepository {
  _CinemaRepository() : super(scenario: DemoScenario(const SystemAppClock()));

  int? lastCinemaId;

  @override
  Future<List<CinemaDto>> getCinemas() async => const [
    CinemaDto(
      id: 1,
      name: 'CinePremier',
      address: '12 Nguyễn Huệ',
      city: 'TP. Hồ Chí Minh',
      active: true,
    ),
    CinemaDto(
      id: 2,
      name: 'CinePremier',
      address: '9 Quang Trung',
      city: 'Thành phố Hồ Chí Minh',
      active: true,
      phone: '02812345678',
    ),
  ];

  @override
  Future<CinemaDto?> getCinema(int cinemaId) async {
    if (cinemaId == 3) {
      return const CinemaDto(
        id: 3,
        name: 'Rạp tạm đóng',
        address: '',
        city: '',
        active: false,
      );
    }
    for (final cinema in await getCinemas()) {
      if (cinema.id == cinemaId) return cinema;
    }
    return null;
  }

  @override
  Future<List<ShowtimeDto>> getShowtimes({
    int? movieId,
    int? cinemaId,
    DateTime? date,
  }) async {
    lastCinemaId = cinemaId;
    return super.getShowtimes(movieId: movieId, cinemaId: cinemaId, date: date);
  }
}

class _MemoryCinemaPreferences implements CinemaPreferenceStore {
  final values = <String, int>{};

  @override
  Future<int?> read(String scope) async => values[scope];

  @override
  Future<void> write(String scope, int? cinemaId) async {
    if (cinemaId == null) {
      values.remove(scope);
    } else {
      values[scope] = cinemaId;
    }
  }
}

void main() {
  test('city and search comparison ignore common spelling differences', () {
    expect(normalizedCinemaCity('TP. HCM'), 'ho chi minh');
    expect(normalizedCinemaCity('Thành phố Hồ Chí Minh'), 'ho chi minh');
    expect(normalizedCinemaSearch('NGUYỄN  HUỆ'), 'nguyen hue');
  });

  test(
    'preferred cinema is scoped separately for guest and signed-in user',
    () async {
      final store = _MemoryCinemaPreferences();
      final container = ProviderContainer(
        overrides: [
          cinemaPreferenceStoreProvider.overrideWithValue(store),
          authSessionProvider.overrideWith(
            () => FakeAuthSessionController(authenticatedCustomerState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(preferredCinemaProvider.future);
      await container.read(preferredCinemaProvider.notifier).choose(2);
      expect(store.values['user_5101'], 2);
      await container.read(authSessionProvider.notifier).logout();
      expect(await container.read(preferredCinemaProvider.future), isNull);
      await container.read(preferredCinemaProvider.notifier).choose(1);
      expect(store.values['guest'], 1);
      expect(store.values['user_5101'], 2);
    },
  );

  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets(
      'directory opens correct cinema and filtered schedule at $width',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repository = _CinemaRepository();
        final store = _MemoryCinemaPreferences();
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.cinemas,
          size: Size(width, 950),
          providerOverrides: [
            mockCatalogRepositoryProvider.overrideWithValue(repository),
            cinemaPreferenceStoreProvider.overrideWithValue(store),
          ],
        );
        expect(find.byKey(const ValueKey('cinema-card-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('cinema-card-2')), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNWidgets(2));

        await tester.enterText(
          find.byKey(const ValueKey('cinema-search')),
          'Quang Trung',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('cinema-card-1')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('cinema-card-2')));
        await tester.pumpAndSettle();
        expect(find.text('9 Quang Trung'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('cinema-preferred')));
        await tester.pumpAndSettle();
        expect(store.values['user_5101'], 2);
        await tester.tap(find.byKey(const ValueKey('cinema-showtimes')));
        await tester.pumpAndSettle();
        expect(repository.lastCinemaId, 2);
        expect(
          find.byKey(const ValueKey('showtime-cinema-filter')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('inactive cinema has no booking or preferred action', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.cinemaDetail(3),
      providerOverrides: [
          mockCatalogRepositoryProvider.overrideWithValue(_CinemaRepository()),
        cinemaPreferenceStoreProvider.overrideWithValue(
          _MemoryCinemaPreferences(),
        ),
      ],
    );
    expect(find.text('Rạp hiện chưa mở bán vé.'), findsOneWidget);
    final showtimes = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('cinema-showtimes')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(showtimes.onPressed, isNull);
  });
}
