import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../application/booking_completion_controller.dart';

class TicketPage extends ConsumerWidget {
  const TicketPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(ticketBookingProvider(bookingId));
    return AppShell(
      currentIndex: 3,
      showBottomNavigation: false,
      body: bookingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (booking) {
          if (booking == null || booking.status != BookingStatus.paid) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 52),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Vé chỉ được phát hành khi booking đã PAID.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Về Đơn của tôi',
                      onPressed: () => context.go(AppRoutes.orders),
                    ),
                  ],
                ),
              ),
            );
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Đóng vé',
                      onPressed: () => context.go(AppRoutes.orders),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Vé xem phim',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.card,
                  ),
                  child: Column(
                    children: [
                      Text(
                        booking.movieTitleSnapshot ??
                            booking.movieTitle ??
                            'Phim',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        booking.qrCode ?? booking.bookingCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TicketLine(
                  'Rạp',
                  booking.cinemaNameSnapshot ?? booking.cinemaName ?? '—',
                ),
                _TicketLine(
                  'Phòng',
                  booking.roomNameSnapshot ?? booking.roomName ?? '—',
                ),
                _TicketLine(
                  'Ghế',
                  booking.seats.map((seat) => seat.seatLabel).join(', '),
                ),
                for (final type in const [
                  TicketType.adult,
                  TicketType.student,
                  TicketType.child,
                ])
                  if (booking.tickets.any(
                    (ticket) => ticket.ticketType == type,
                  ))
                    _TicketLine(
                      _ticketLabel(type),
                      booking.tickets
                          .where((ticket) => ticket.ticketType == type)
                          .map(
                            (ticket) => booking.seats
                                .firstWhere(
                                  (seat) => seat.seatId == ticket.seatId,
                                )
                                .seatLabel,
                          )
                          .join(', '),
                    ),
                _TicketLine(
                  'Suất chiếu',
                  booking.showtimeStartSnapshot == null &&
                          booking.showtimeStart == null
                      ? '—'
                      : _dateTime(
                          booking.showtimeStartSnapshot ??
                              booking.showtimeStart!,
                        ),
                ),
                _TicketLine('Trạng thái', 'Đã thanh toán'),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Đưa mã QR này tại cổng soát vé. Không chia sẻ mã vé cho người khác.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _ticketLabel(TicketType type) => switch (type) {
  TicketType.child => 'Vé trẻ em',
  TicketType.student => 'Vé sinh viên',
  _ => 'Vé người lớn',
};

// Legacy renderer retained for test fixtures; production displays backend QR payload text.
// ignore: unused_element
class _MockQr extends StatelessWidget {
  const _MockQr({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final seed = data.codeUnits.fold<int>(
      17,
      (value, unit) => value * 31 + unit,
    );
    return Semantics(
      label: 'Mã QR booking $data',
      image: true,
      child: Container(
        width: 190,
        height: 190,
        padding: const EdgeInsets.all(14),
        color: Colors.white,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 21,
          ),
          itemCount: 441,
          itemBuilder: (_, index) {
            final dark = ((seed >> (index % 24)) ^ (index * 37)) & 1 == 1;
            return ColoredBox(color: dark ? Colors.black : Colors.white);
          },
        ),
      ),
    );
  }
}

class _TicketLine extends StatelessWidget {
  const _TicketLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _dateTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} • '
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
