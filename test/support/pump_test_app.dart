import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/movie/data/repositories/catalog_providers.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_providers.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_repository.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_repository.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';

import 'fake_auth_session.dart';

Future<ProviderContainer> pumpTestApp(
  WidgetTester tester, {
  AuthState? authState,
  String initialLocation = AppRoutes.home,
  Size? size,
  List<dynamic> providerOverrides = const [],
}) async {
  appRouter.go(initialLocation);
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWith(
          (ref) => ref.watch(mockCatalogRepositoryProvider),
        ),
        authSessionProvider.overrideWith(
          () => FakeAuthSessionController(
            authState ?? authenticatedCustomerState(),
          ),
        ),
        seatHoldRepositoryProvider.overrideWith(
          (ref) =>
              _FakeSeatHoldRepository(ref.watch(bookingRepositoryProvider)),
        ),
        ...providerOverrides,
      ],
      child: const CinePremierApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(CinePremierApp)));
}

class _FakeSeatHoldRepository implements SeatHoldRepository {
  _FakeSeatHoldRepository(this._booking);
  final BookingRepository _booking;
  @override
  bool get canEnterMockCheckout => true;
  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) async {
    try {
      return await _booking.holdSeats(DemoIds.user, request);
    } on BookingConflictException catch (error) {
      throw ApiException(type: ApiErrorType.conflict, message: error.message);
    }
  }

  @override
  Future<BookingDto> getBooking(int bookingId) async =>
      (await _booking.getBooking(bookingId))!;
  @override
  Future<BookingDto> cancel(int bookingId) => _booking.cancel(bookingId);
}
