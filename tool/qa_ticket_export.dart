// Android/iOS export QA only. Uses an in-memory ticket; never calls BE or issues a real ticket.
// Run with: flutter run -t tool/qa_ticket_export.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/booking/presentation/pages/ticket_page.dart';
import 'package:mss301_mobile/features/orders/data/models/booking_dto.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_providers.dart';
import 'package:mss301_mobile/features/seat/data/repositories/seat_hold_repository.dart';

void main() => runApp(
  ProviderScope(
    overrides: [
      authSessionProvider.overrideWith(_QaAuth.new),
      seatHoldRepositoryProvider.overrideWithValue(_QaTickets()),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: const TicketPage(bookingId: 42),
    ),
  ),
);

class _QaAuth extends AuthSessionController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession(
      accessToken: 'QA-ONLY',
      refreshToken: 'QA-ONLY',
      tokenType: 'Bearer',
      expiresInMs: 1,
      roles: ['CUSTOMER'],
      user: AuthUser(
        id: 5101,
        email: 'qa@example.test',
        fullName: 'QA ONLY',
        roles: ['CUSTOMER'],
      ),
    ),
  );
}

class _QaTickets implements SeatHoldRepository {
  @override
  bool get canEnterMockCheckout => false;
  @override
  Future<BookingDto> getBooking(int id) async => BookingDto.fromJson({
    'id': 42,
    'bookingCode': 'QA-ONLY',
    'userId': 5101,
    'movieId': 2,
    'showtimeId': 1,
    'movieTitleSnapshot': 'QA ONLY — vé mẫu',
    'cinemaNameSnapshot': 'Rạp kiểm thử',
    'roomNameSnapshot': 'Phòng 1',
    'showtimeStartSnapshot': '2026-10-15T10:00:00',
    'subtotal': 100000,
    'discountAmount': 0,
    'totalAmount': 100000,
    'status': 'PAID',
    'qrCode': 'CINEMA:QA-ONLY:42',
    'createdAt': '2026-10-13T06:00:00Z',
    'seats': [
      {
        'id': 1,
        'seatId': 11,
        'showtimeId': 1,
        'rowLabel': 'A',
        'seatNumber': 1,
        'seatLabel': 'A1',
        'unitPrice': 100000,
        'seatType': 'STANDARD',
        'status': 'BOOKED',
      },
    ],
    'tickets': [],
    'foods': [],
  });
  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) =>
      throw UnsupportedError('QA export only');
  @override
  Future<BookingDto> cancel(int id) => throw UnsupportedError('QA export only');
}
