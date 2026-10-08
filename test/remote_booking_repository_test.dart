import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/orders/data/repositories/remote_booking_repository.dart';

void main() {
  test('history uses JWT-scoped page endpoint without customer id', () async {
    final adapter = _Adapter();
    final bookings = await RemoteBookingRepository(
      Dio()..httpClientAdapter = adapter,
    ).getBookings(999);
    expect(adapter.path, '/api/v1/bookings');
    expect(adapter.query, {'page': '0', 'size': '20'});
    expect(adapter.method, 'GET');
    expect(bookings.single.id, 741852);
    expect(bookings.single.status.wireValue, 'PAID');
  });

  test('detail preserves booking id, total and backend QR fields', () async {
    final adapter = _Adapter();
    final booking = await RemoteBookingRepository(
      Dio()..httpClientAdapter = adapter,
    ).getBooking(741852);
    expect(adapter.path, '/api/v1/bookings/741852');
    expect(booking!.id, 741852);
    expect(booking.totalAmount.amount, 123456);
    expect(booking.qrCode, 'CINEMA:BK-741852:741852');
    expect(booking.seats.single.ticketCode, 'BK-741852-A1');
  });
}

class _Adapter implements HttpClientAdapter {
  String? method;
  String? path;
  Map<String, String>? query;
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
    query = options.uri.queryParameters;
    final data = _booking;
    final body = options.path == '/api/v1/bookings'
        ? {
            'content': [data],
            'totalElements': 1,
            'totalPages': 1,
            'number': 0,
            'size': 20,
          }
        : data;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': body}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

const _booking = {
  'id': 741852,
  'bookingCode': 'BK-741852',
  'userId': 19,
  'showtimeId': 92831,
  'movieId': 7,
  'subtotal': 123456,
  'discountAmount': 0,
  'loyaltyPointsRedeemed': 0,
  'totalAmount': 123456,
  'status': 'PAID',
  'holdExpiresAt': null,
  'paidAt': '2026-10-07T10:03:00',
  'qrCode': 'CINEMA:BK-741852:741852',
  'seats': [
    {
      'id': 1,
      'seatId': 441,
      'showtimeId': 92831,
      'rowLabel': 'A',
      'seatNumber': 1,
      'seatLabel': 'A1',
      'seatType': 'STANDARD',
      'unitPrice': 123456,
      'status': 'BOOKED',
      'ticketCode': 'BK-741852-A1',
      'qrCode': 'TICKET:BK-741852-A1',
      'ticketType': 'ADULT',
    },
  ],
  'tickets': [],
  'foods': [],
  'createdAt': '2026-10-07T10:00:00',
};
