import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/features/movie/data/models/catalog_enums.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/seat/data/repositories/remote_seat_hold_repository.dart';

void main() {
  const bookingId = 741852;
  const showtimeId = 92831;
  final expiry = DateTime.utc(2026, 10, 7, 10, 3);

  test(
    'POST hold preserves backend identifiers and request contract',
    () async {
      final adapter = _Adapter.success(
        _bookingEnvelope(
          bookingId: bookingId,
          showtimeId: showtimeId,
          expiry: expiry,
        ),
      );
      final repository = RemoteSeatHoldRepository(
        Dio()..httpClientAdapter = adapter,
      );

      final booking = await repository.hold(
        const HoldSeatsRequestDto(
          showtimeId: showtimeId,
          seatIds: [441, 442],
          holiday: true,
          loyaltyPointsToRedeem: 120,
          tickets: [
            TicketSelectionDto(
              seatId: 441,
              ticketType: TicketType.adult,
              viewerAge: 30,
            ),
            TicketSelectionDto(
              seatId: 442,
              ticketType: TicketType.student,
              viewerAge: 20,
            ),
          ],
          foods: [FoodSelectionDto(productId: 77, isCombo: true, quantity: 2)],
        ),
      );

      expect(adapter.method, 'POST');
      expect(adapter.path, '/api/v1/bookings/hold');
      expect(adapter.data, {
        'showtimeId': showtimeId,
        'seatIds': [441, 442],
        'tickets': [
          {
            'seatId': 441,
            'ticketType': 'ADULT',
            'viewerAge': 30,
            'quantity': 1,
          },
          {
            'seatId': 442,
            'ticketType': 'STUDENT',
            'viewerAge': 20,
            'quantity': 1,
          },
        ],
        'foods': [
          {'productId': 77, 'isCombo': true, 'quantity': 2},
        ],
        'holiday': true,
        'loyaltyPointsToRedeem': 120,
      });
      expect(adapter.data!.containsKey('userId'), isFalse);
      expect(adapter.data!.containsKey('customerId'), isFalse);
      expect(adapter.data!.containsKey('authorization'), isFalse);
      expect(booking.id, bookingId);
      expect(booking.holdExpiresAt, expiry);
    },
  );

  test(
    'GET booking preserves the authoritative booking id and expiry',
    () async {
      final adapter = _Adapter.success(
        _bookingEnvelope(
          bookingId: bookingId,
          showtimeId: showtimeId,
          expiry: expiry,
        ),
      );
      final repository = RemoteSeatHoldRepository(
        Dio()..httpClientAdapter = adapter,
      );

      final booking = await repository.getBooking(bookingId);

      expect(adapter.method, 'GET');
      expect(adapter.path, '/api/v1/bookings/$bookingId');
      expect(booking.id, bookingId);
      expect(booking.showtimeId, showtimeId);
      expect(booking.holdExpiresAt, expiry);
    },
  );

  test('DELETE booking uses the exact authoritative booking id', () async {
    final adapter = _Adapter.success(
      _bookingEnvelope(
        bookingId: bookingId,
        showtimeId: showtimeId,
        expiry: expiry,
      ),
    );
    final repository = RemoteSeatHoldRepository(
      Dio()..httpClientAdapter = adapter,
    );

    final booking = await repository.cancel(bookingId);

    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/api/v1/bookings/$bookingId');
    expect(booking.id, bookingId);
  });

  test(
    'maps conflict and generic HTTP errors through the shared API mapper',
    () async {
      final conflictAdapter = _Adapter.error(409, {
        'message': 'Seat unavailable',
      });
      final genericAdapter = _Adapter.error(500, {
        'message': 'Unexpected failure',
      });
      final conflictRepository = RemoteSeatHoldRepository(
        _mappedDio(conflictAdapter),
      );
      final genericRepository = RemoteSeatHoldRepository(
        _mappedDio(genericAdapter),
      );

      await expectLater(
        conflictRepository.getBooking(bookingId),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.conflict,
          ),
        ),
      );
      await expectLater(
        genericRepository.getBooking(bookingId),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.server,
          ),
        ),
      );
    },
  );

  test('rejects invalid successful booking envelopes', () async {
    final repository = RemoteSeatHoldRepository(
      Dio()..httpClientAdapter = _Adapter.success({'success': true}),
    );

    await expectLater(
      repository.getBooking(bookingId),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.unknown,
        ),
      ),
    );
  });

  test('production repository never enters mock checkout', () {
    expect(RemoteSeatHoldRepository(Dio()).canEnterMockCheckout, isFalse);
  });
}

Dio _mappedDio(HttpClientAdapter adapter) => createDioClient(
  ApiConfig(
    appConfig: AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://example.test',
    ),
  ),
)..httpClientAdapter = adapter;

Map<String, Object?> _bookingEnvelope({
  required int bookingId,
  required int showtimeId,
  required DateTime expiry,
}) => {
  'success': true,
  'data': {
    'id': bookingId,
    'bookingCode': 'BK-$bookingId',
    'userId': 19,
    'showtimeId': showtimeId,
    'movieId': 7,
    'subtotal': 180000,
    'discountAmount': 0,
    'loyaltyPointsRedeemed': 0,
    'totalAmount': 180000,
    'status': 'HOLDING',
    'holdExpiresAt': expiry.toIso8601String(),
    'seats': [],
    'tickets': [],
    'foods': [],
    'createdAt': DateTime.utc(2026, 10, 7, 10).toIso8601String(),
  },
};

class _Adapter implements HttpClientAdapter {
  _Adapter.success(this._body) : _statusCode = 200;
  _Adapter.error(this._statusCode, this._body);

  final int _statusCode;
  final Object _body;
  String? method;
  String? path;
  Map<String, Object?>? data;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    data = options.data is Map
        ? Map<String, Object?>.from(options.data as Map)
        : null;
    return ResponseBody.fromString(
      jsonEncode(_body),
      _statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
