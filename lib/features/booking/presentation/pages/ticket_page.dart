import '../../../../core/time/vietnam_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/resume_booking_banner.dart';

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
        loading: () => const RepositoryStatePane.loading(),
        error: (_, _) => RepositoryStatePane.error(
          onRetry: () => ref.invalidate(ticketBookingProvider(bookingId)),
        ),
        data: (booking) {
          if (booking == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 52),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Không tìm thấy đơn đặt vé.',
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
                    Expanded(
                      child: Text(
                        booking.status == BookingStatus.paid ||
                                booking.status == BookingStatus.used
                            ? 'Vé xem phim'
                            : 'Chi tiết đơn',
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
                    color: AppColors.surfaceRaised,
                    borderRadius: AppRadii.card,
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        booking.movieTitleSnapshot ??
                            booking.movieTitle ??
                            'Phim',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (booking.status == BookingStatus.paid &&
                          booking.qrCode?.isNotEmpty == true)
                        QrImageView(
                          key: const ValueKey('ticket-qr'),
                          data: booking.qrCode!,
                          size: 220,
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          semanticsLabel: 'Mã QR vé ${booking.bookingCode}',
                        )
                      else
                        Text(
                          booking.status == BookingStatus.used
                              ? 'Vé đã được sử dụng'
                              : 'Đơn chưa có vé có thể sử dụng.',
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          color: AppColors.text,
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
                for (final food in booking.foods)
                  _TicketLine(
                    '${food.productName} × ${food.quantity}',
                    food.lineTotal.format(),
                  ),
                _TicketLine('Tổng tiền', booking.totalAmount.format()),
                _TicketLine('Trạng thái', _statusLabel(booking.status)),
                if (booking.status == BookingStatus.holding ||
                    booking.status == BookingStatus.pendingPayment)
                  AppButton(
                    label: 'Tiếp tục đặt vé',
                    onPressed: () => resumeBooking(context, ref, booking.id),
                  ),
                AppButton(
                  label: 'Tải lại đơn',
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      ref.invalidate(ticketBookingProvider(bookingId)),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  booking.status == BookingStatus.used
                      ? 'Vé đã được soát và không thể sử dụng lại.'
                      : booking.status == BookingStatus.paid
                      ? 'Đưa mã QR này tại cổng soát vé. Không chia sẻ mã vé cho người khác.'
                      : 'Vé chỉ được phát hành sau khi đơn được xác nhận thanh toán.',
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _dateTime(DateTime value) => formatVietnamDateTime(value);

String _statusLabel(BookingStatus status) => switch (status) {
  BookingStatus.holding => 'Đang giữ ghế',
  BookingStatus.pendingPayment => 'Chờ thanh toán',
  BookingStatus.paid => 'Đã thanh toán',
  BookingStatus.used => 'Đã sử dụng',
  BookingStatus.cancelled => 'Đã hủy',
  BookingStatus.expired => 'Đã hết hạn',
  BookingStatus.refunded => 'Đã hoàn tiền',
  BookingStatus.unknown => 'Chưa xác định',
};
