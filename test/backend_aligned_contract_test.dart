import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/contracts/api_response.dart';
import 'package:mss301_mobile/core/contracts/page_response.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/time/app_clock.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/models/account_enums.dart';
import 'package:mss301_mobile/features/account/data/repositories/mock_account_repositories.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/movie/data/models/food_quote_dto.dart';
import 'package:mss301_mobile/features/movie/data/repositories/mock_catalog_repository.dart';
import 'package:mss301_mobile/features/orders/data/mappers/seat_contract_mapper.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_enums.dart';
import 'package:mss301_mobile/features/orders/data/repositories/booking_repository.dart';
import 'package:mss301_mobile/features/orders/data/repositories/mock_booking_repository.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_dto.dart';
import 'package:mss301_mobile/features/payment/data/models/payment_enums.dart';
import 'package:mss301_mobile/features/payment/data/repositories/mock_payment_repository.dart';
import 'package:mss301_mobile/features/showtime/data/models/showtime_dto.dart';

void main() {
  group('backend-shaped contracts', () {
    test('parses ApiResponse and PageResponse wrappers', () {
      final response = ApiResponse<int>.fromJson({
        'success': true,
        'data': 7,
        'message': 'ok',
        'timestamp': '2026-09-25T12:00:00Z',
      }, (value) => value! as int);
      final page = PageResponse<int>.fromJson({
        'items': [
          {'value': 1},
          {'value': 2},
        ],
        'page': 0,
        'size': 20,
        'totalItems': 2,
        'totalPages': 1,
        'first': true,
        'last': true,
      }, (item) => item['value']! as int);

      expect(response.data, 7);
      expect(response.timestamp.isUtc, isTrue);
      expect(page.items, [1, 2]);
      expect(page.last, isTrue);
    });

    test('keeps VND exact and normalizes catalog seat values', () {
      expect(
        const VndMoney(180000) + const VndMoney(89000),
        const VndMoney(269000),
      );
      expect(const VndMoney(269000).format(), '269.000đ');

      final seat = ShowtimeSeatDto.fromJson({
        'seatId': 1,
        'seatRowId': 2,
        'rowLabel': 'A',
        'displayOrder': 1,
        'seatNumber': 1,
        'displayColumn': 1,
        'startColumn': 1,
        'seatType': 'NORMAL',
        'seatStatus': 'AVAILABLE',
        'runtimeStatus': 'UNAVAILABLE',
        'unitPrice': 90000,
      });

      expect(seat.seatType.normalized, CatalogSeatType.standard);
      expect(seat.runtimeStatus, SeatRuntimeStatus.unavailable);
      expect(seat.selectable, isFalse);
      expect(
        mapCatalogSeatTypeToBooking(seat.seatType),
        BookingSeatType.standard,
      );
      expect(MovieStatus.parse('A_FUTURE_STATUS'), MovieStatus.unknown);
    });

    test('parses quote, booking, payment and account snapshots', () {
      final quote = CheckoutQuoteDto.fromJson({
        'quoteId': 'quote-1',
        'validUntil': '2026-09-25T12:03:00Z',
        'showtime': {
          'showtimeId': 1001,
          'movieId': 1,
          'movieTitle': 'Inception',
          'startTime': '2026-09-26T20:30:00',
        },
        'seats': const [],
        'tickets': const [],
        'foods': const [],
        'foodItems': const [],
        'ticketSubtotal': 180000,
        'foodSubtotal': 89000,
        'subtotal': 269000,
        'discount': 0,
        'cinePointsDiscount': 0,
        'fees': 0,
        'tax': 0,
        'total': 269000,
        'movie': {
          'id': 1,
          'title': 'Inception',
          'ageRating': '16+',
          'durationMinutes': 148,
        },
        'cinema': {'id': 1, 'name': 'CineAI Central', 'roomName': 'Phòng C'},
      });
      final booking = BookingDto.fromJson({
        'id': 5001,
        'bookingCode': 'CP-5001',
        'userId': 1,
        'showtimeId': 1001,
        'movieId': 1,
        'subtotal': 269000,
        'discountAmount': 0,
        'loyaltyPointsRedeemed': 0,
        'totalAmount': 269000,
        'status': 'HOLDING',
        'seats': const [],
        'tickets': const [],
        'foods': const [],
        'createdAt': '2026-09-25T12:00:00Z',
      });
      final payment = PaymentDto.fromJson({
        'id': 6001,
        'bookingId': 5001,
        'userId': 1,
        'provider': 'VNPAY',
        'amount': 269000,
        'status': 'SUCCESS',
        'refundAmount': 0,
        'createdAt': '2026-09-25T12:00:00Z',
      });
      final profile = UserProfileDto.fromJson({
        'id': 1,
        'email': 'user@example.com',
        'fullName': 'Nguyễn Minh',
        'status': 'ACTIVE',
        'emailVerified': true,
        'phoneVerified': false,
        'roles': ['USER'],
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-09-25T12:00:00Z',
      });

      expect(quote.movie?.durationMinutes, 148);
      expect(quote.cinema?.roomName, 'Phòng C');
      expect(booking.status, BookingStatus.holding);
      expect(payment.status, PaymentStatus.success);
      expect(profile.roles, ['USER']);
      expect(UserStatus.parse('NEW_STATUS'), UserStatus.unknown);
    });
  });

  group('backend-aligned mock repositories', () {
    test(
      'runs quote, hold, checkout and two-step payment confirmation',
      () async {
        final clock = FakeAppClock(DateTime.utc(2026, 9, 25, 12));
        final catalog = MockCatalogRepository(scenario: DemoScenario(clock));
        final bookings = MockBookingRepository(clock, catalog);
        final payments = MockPaymentRepository(clock, bookings);
        const foods = [FoodSelectionDto(productId: 4101, isCombo: true)];
        final quote = await catalog.createCheckoutQuote(
          const CheckoutQuoteRequestDto(
            showtimeId: DemoIds.showtimeInception,
            seatIds: [DemoIds.seatC4, DemoIds.seatC5],
            foods: [QuoteFoodRequestDto(productId: 4101, isCombo: true)],
          ),
        );

        expect(quote.total, const VndMoney(269000));
        expect(quote.movie?.title, 'Inception');
        expect(quote.cinema?.id, DemoIds.cinemaCentral);

        final held = await bookings.holdSeats(
          DemoIds.user,
          const HoldSeatsRequestDto(
            showtimeId: DemoIds.showtimeInception,
            seatIds: [DemoIds.seatC4, DemoIds.seatC5],
            foods: foods,
          ),
        );
        expect(held.status, BookingStatus.holding);
        expect(held.holdExpiresAt, clock.now().add(const Duration(minutes: 3)));
        expect(
          () => bookings.holdSeats(
            DemoIds.user + 1,
            const HoldSeatsRequestDto(
              showtimeId: DemoIds.showtimeInception,
              seatIds: [DemoIds.seatC4],
            ),
          ),
          throwsA(isA<BookingConflictException>()),
        );

        final pending = await bookings.checkout(
          held.id,
          const UpdateHoldingBookingRequestDto(foods: foods),
        );
        expect(pending.status, BookingStatus.pendingPayment);

        final createdPayment = await payments.createPayment(
          DemoIds.user,
          CreatePaymentRequestDto(bookingId: held.id),
        );
        expect(createdPayment.status, PaymentStatus.pending);
        await payments.markSuccess(createdPayment.id);
        expect(
          (await bookings.getBooking(held.id))?.status,
          BookingStatus.pendingPayment,
        );

        await payments.confirmSuccessfulBooking(createdPayment.id);
        final paid = await bookings.getBooking(held.id);
        expect(paid?.status, BookingStatus.paid);
        expect(paid?.qrCode, 'MOCK-BOOKING-QR-${held.id}');
        expect(
          paid?.seats.every((seat) => seat.status == BookingSeatStatus.booked),
          isTrue,
        );
      },
    );

    test('expires holds from the injected clock and releases seats', () async {
      final clock = FakeAppClock(DateTime.utc(2026, 9, 25, 12));
      final catalog = MockCatalogRepository(scenario: DemoScenario(clock));
      final bookings = MockBookingRepository(clock, catalog);
      const request = HoldSeatsRequestDto(
        showtimeId: DemoIds.showtimeInception,
        seatIds: [DemoIds.seatC4],
      );
      final held = await bookings.holdSeats(DemoIds.user, request);

      clock.advance(const Duration(minutes: 3, seconds: 1));
      expect(
        (await bookings.getBooking(held.id))?.status,
        BookingStatus.expired,
      );

      final next = await bookings.holdSeats(DemoIds.user + 1, request);
      expect(next.status, BookingStatus.holding);
    });

    test('updates account wallet, withdrawal and loyalty mock state', () async {
      final clock = FakeAppClock(DateTime.utc(2026, 9, 25, 12));
      final account = MockAccountStore(clock: clock);

      final profile = await account.updateProfile(
        DemoIds.user,
        const UserProfileUpdateDto(fullName: 'Nguyễn Minh Anh'),
      );
      final withdrawal = await account.createWithdrawal(
        DemoIds.user,
        const WithdrawalCreateRequestDto(
          amount: VndMoney(100000),
          bankName: 'VCB',
          accountNumber: '0123456789',
          accountHolder: 'NGUYEN MINH ANH',
        ),
      );

      expect(profile.fullName, 'Nguyễn Minh Anh');
      expect(withdrawal.status, WithdrawalStatus.pending);
      expect(
        (await account.getWallet(DemoIds.user)).balance,
        const VndMoney(400000),
      );
      expect(
        (await account.getTransactions(DemoIds.user)).single.type,
        WalletTransactionType.withdrawalHold,
      );
      expect((await account.getLoyalty(DemoIds.user)).points, 1250);
      expect(
        (await account.getConfiguration()).redemptionValueVnd,
        const VndMoney(1000),
      );
    });
  });
}
