import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/ticket_payload_card.dart';
import '../widgets/ticket_receipt_summary.dart';

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
          if (booking == null || booking.status != BookingStatus.paid) {
            return Center(
              child: SingleChildScrollView(
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Đóng vé',
                          constraints: const BoxConstraints(
                            minWidth: AppSizes.buttonHeight,
                            minHeight: AppSizes.buttonHeight,
                          ),
                          onPressed: () => context.go(AppRoutes.orders),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: const Text(
                              'Vé xem phim',
                              style: AppTextStyles.screenTitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSurface(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      borderColor: AppColors.goldBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MÃ ĐẶT VÉ', style: AppTextStyles.eyebrow),
                          const SizedBox(height: AppSpacing.sm),
                          SelectableText(
                            booking.bookingCode,
                            style: AppTextStyles.emphasis.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Semantics(
                            header: true,
                            child: Text(
                              booking.movieTitleSnapshot ??
                                  booking.movieTitle ??
                                  'Phim',
                              style: AppTextStyles.screenTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TicketLine(
                            'Rạp',
                            booking.cinemaNameSnapshot ??
                                booking.cinemaName ??
                                '—',
                          ),
                          _TicketLine(
                            'Phòng',
                            booking.roomNameSnapshot ?? booking.roomName ?? '—',
                          ),
                          _TicketLine(
                            'Ghế',
                            booking.seats
                                .map((seat) => seat.seatLabel)
                                .join(', '),
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
                                    .where(
                                      (ticket) => ticket.ticketType == type,
                                    )
                                    .map(
                                      (ticket) => booking.seats
                                          .firstWhere(
                                            (seat) =>
                                                seat.seatId == ticket.seatId,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TicketPayloadCard(
                      payload: booking.qrCode ?? booking.bookingCode,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      children: [
                        AppSurface(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          borderRadius: AppRadii.small,
                          child: Semantics(
                            container: true,
                            child: const Wrap(
                              spacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: AppSizes.iconMedium,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  'Đã thanh toán',
                                  style: AppTextStyles.emphasis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TicketReceiptSummary(booking: booking),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Không chia sẻ mã vé cho người khác. Giữ mã đặt vé để đối chiếu với nhân viên rạp.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: AppTextStyles.emphasis),
      ],
    ),
  );
}

String _dateTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} • '
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
