import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/movie/data/repositories/remote_catalog_repository.dart';

void main() {
  test('remote seat map preserves real showtime id and availability', () async {
    final adapter = _Adapter();
    final repository = RemoteCatalogRepository(
      Dio()..httpClientAdapter = adapter,
    );

    final map = await repository.getSeatMap(987654);

    expect(adapter.path, '/api/v1/showtimes/987654/seat-map');
    expect(map.showtime.id, 987654);
    expect(map.seats.first.selectable, isTrue);
    expect(map.seats.last.selectable, isFalse);
  });
}

class _Adapter implements HttpClientAdapter {
  String? path;
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'showtime': {
            'id': 987654,
            'movieId': 7,
            'cinemaId': 3,
            'roomId': 5,
            'startTime': '2026-10-07T10:00:00',
            'endTime': '2026-10-07T12:35:00',
            'movieGenreNames': [],
            'weekendSurcharge': false,
            'holidaySurcharge': false,
            'status': 'OPEN',
          },
          'rowCount': 1,
          'columnCount': 2,
          'seats': [
            {
              'seatId': 71,
              'seatRowId': 8,
              'rowLabel': 'A',
              'displayOrder': 1,
              'seatNumber': 1,
              'displayColumn': 1,
              'startColumn': 1,
              'seatType': 'STANDARD',
              'seatStatus': 'AVAILABLE',
              'runtimeStatus': 'AVAILABLE',
              'unitPrice': 90000,
            },
            {
              'seatId': 72,
              'seatRowId': 8,
              'rowLabel': 'A',
              'displayOrder': 1,
              'seatNumber': 2,
              'displayColumn': 2,
              'startColumn': 1,
              'seatType': 'VIP',
              'seatStatus': 'AVAILABLE',
              'runtimeStatus': 'HOLDING',
              'holdExpiresAt': '2026-10-07T10:05:00',
              'unitPrice': 120000,
            },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
