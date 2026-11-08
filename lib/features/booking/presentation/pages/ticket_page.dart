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
import '../../../../shared/widgets/checkout_summary.dart';
import '../../../../shared/widgets/cinema_ticket_surface.dart';
import '../../../orders/presentation/widgets/booking_status_badge.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../../application/ticket_export_service.dart';
import '../../../auth/application/auth_session.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../widgets/resume_booking_banner.dart';

class TicketPage extends ConsumerStatefulWidget {
  const TicketPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends ConsumerState<TicketPage> {
  bool _exporting = false;
  int get bookingId => widget.bookingId;

  Future<void> _export(bool share, Rect origin) async {
    if (_exporting) return;
    final userId = ref.read(authSessionProvider).session?.user.id;
    setState(() => _exporting = true);
    try {
      final fresh = await ref.refresh(ticketBookingProvider(bookingId).future);
      if (!mounted ||
          userId != ref.read(authSessionProvider).session?.user.id) {
        return;
      }
      if (fresh == null) throw StateError('Không thể tải vé.');
      final document = await ref
          .read(ticketDocumentBuilderProvider)
          .build(fresh);
      if (!mounted ||
          userId != ref.read(authSessionProvider).session?.user.id) {
        return;
      }
      final exporter = ref.read(ticketExportServiceProvider);
      final result = share
          ? await exporter.share(document, origin)
          : await exporter.save(document);
      if (!mounted ||
          userId != ref.read(authSessionProvider).session?.user.id) {
        return;
      }
      final message = switch (result) {
        TicketExportResult.saved => 'Đã lưu vé PDF.',
        TicketExportResult.shared => 'Đã chia sẻ vé.',
        TicketExportResult.unavailable => 'Đã mở bảng chia sẻ.',
        TicketExportResult.cancelled => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted && userId == ref.read(authSessionProvider).session?.user.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể lưu/chia sẻ vé. Vui lòng tải lại đơn và thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(ticketBookingProvider(bookingId));
    return AppShell(
      currentIndex: 3,
      showBottomNavigation: false,
      body: bookingState.when(
        loading: () => const RepositoryStatePane.loading(
          layout: RepositorySkeleton.poster,
          title: 'Đang tải vé…',
        ),
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
          final showtimeStart =
              booking.showtimeStartSnapshot ?? booking.showtimeStart;
          final showtimeEnd =
              booking.showtimeEnd ??
              showtimeStart?.add(const Duration(minutes: 120));
          final showtimeEnded =
              showtimeEnd != null && !DateTime.now().isBefore(showtimeEnd);
          final refunded =
              booking.status == BookingStatus.refunded ||
              booking.refundedAt != null;
          final cancelled = booking.status == BookingStatus.cancelled;
          final checkedIn =
              booking.status == BookingStatus.used ||
              booking.checkedInAt != null ||
              booking.seats.any(
                (seat) => seat.status == BookingSeatStatus.checkedIn,
              );
          final canShowQr =
              !refunded &&
              !cancelled &&
              !showtimeEnded &&
              (booking.status == BookingStatus.paid || checkedIn) &&
              booking.qrCode?.trim().isNotEmpty == true;
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
                CinemaTicketSurface(
                  key: const ValueKey('ticket-shaped-pass'),
                  borderColor: AppColors.goldBorder,
                  details: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: Column(
                      children: [
                        BookingStatusBadge(status: booking.status),
                        const SizedBox(height: AppSpacing.sm),
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
                        if (canShowQr)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.maxWidth.clamp(
                                0.0,
                                240.0,
                              );
                              final code = QrValidator.validate(
                                data: booking.qrCode!,
                                version: QrVersions.auto,
                                errorCorrectionLevel: QrErrorCorrectLevel.L,
                              ).qrCode;
                              // Reserve four modules of white quiet zone on each side.
                              final quietZone =
                                  size * 4 / ((code?.moduleCount ?? 25) + 8);
                              return QrImageView(
                                key: const ValueKey('ticket-qr'),
                                data: booking.qrCode!,
                                size: size,
                                padding: EdgeInsets.all(quietZone),
                                backgroundColor: Colors.white,
                                semanticsLabel:
                                    'Mã QR vé ${booking.bookingCode}',
                              );
                            },
                          )
                        else
                          Text(
                            refunded
                                ? 'Vé đã được hoàn tiền và mã QR không còn hiệu lực.'
                                : cancelled
                                ? 'Suất chiếu đã hủy và mã QR không còn hiệu lực.'
                                : showtimeEnded
                                ? 'Suất chiếu đã kết thúc. Mã QR không còn hiệu lực.'
                                : booking.status == BookingStatus.paid ||
                                      checkedIn
                                ? 'Đã thanh toán. Mã QR chưa được cập nhật; vui lòng tải lại đơn.'
                                : 'Đơn chưa có vé có thể sử dụng.',
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Mã đơn', style: AppTextStyles.caption),
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
                  stub: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_movies_outlined,
                              size: 17,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'THÔNG TIN VÉ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckoutLine(
                          'Rạp',
                          booking.cinemaNameSnapshot ??
                              booking.cinemaName ??
                              '—',
                        ),
                        CheckoutLine(
                          'Phòng',
                          booking.roomNameSnapshot ?? booking.roomName ?? '—',
                        ),
                        if (booking.tickets.isEmpty)
                          CheckoutLine(
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
                            CheckoutLine(
                              _ticketLabel(type),
                              booking.tickets
                                  .where((ticket) => ticket.ticketType == type)
                                  .map(
                                    (ticket) =>
                                        booking.seats
                                            .where(
                                              (seat) =>
                                                  seat.seatId == ticket.seatId,
                                            )
                                            .firstOrNull
                                            ?.seatLabel ??
                                        'Ghế ${ticket.seatId}',
                                  )
                                  .join(', '),
                            ),
                        CheckoutLine(
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
                          CheckoutLine(
                            '${food.productName} × ${food.quantity}',
                            food.lineTotal.format(),
                          ),
                        const Divider(color: AppColors.borderStrong),
                        const SizedBox(height: 6),
                        CheckoutLine(
                          'Tổng tiền',
                          booking.totalAmount.format(),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (booking.status == BookingStatus.holding ||
                    booking.status == BookingStatus.pendingPayment)
                  AppButton(
                    label: 'Tiếp tục đặt vé',
                    onPressed: () => resumeBooking(context, ref, booking.id),
                  ),
                if ((booking.status == BookingStatus.used || canShowQr) &&
                    !showtimeEnded) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackActions =
                          constraints.maxWidth < 330 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18;
                      final save = _TicketActionButton(
                        key: const ValueKey('ticket-save'),
                        label: _exporting ? 'Đang xử lý…' : 'Lưu vé PDF',
                        icon: Icons.download_rounded,
                        primary: true,
                        onPressed: _exporting
                            ? null
                            : () => _export(false, Rect.zero),
                      );
                      final share = Builder(
                        builder: (context) => _TicketActionButton(
                          key: const ValueKey('ticket-share'),
                          label: 'Chia sẻ vé',
                          icon: Icons.share_rounded,
                          onPressed: _exporting
                              ? null
                              : () {
                                  final box =
                                      context.findRenderObject() as RenderBox;
                                  _export(
                                    true,
                                    box.localToGlobal(Offset.zero) & box.size,
                                  );
                                },
                        ),
                      );
                      if (stackActions) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [save, const SizedBox(height: 10), share],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: save),
                          const SizedBox(width: 10),
                          Expanded(child: share),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(color: AppColors.border),
                const SizedBox(height: 2),
                if (booking.status == BookingStatus.used)
                  TextButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.movieReviews(booking.movieId)),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Xem đánh giá phim'),
                  ),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('ticket-refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tải lại đơn'),
                    onPressed: _exporting
                        ? null
                        : () {
                            ref.invalidate(ticketBookingProvider(bookingId));
                            ref.invalidate(ordersProvider);
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  refunded
                      ? 'Vé đã được hoàn tiền vào CineWallet.'
                      : cancelled
                      ? 'Suất chiếu đã bị hủy. Mã QR không còn hiệu lực.'
                      : showtimeEnded
                      ? 'Suất chiếu đã kết thúc. Mã QR không còn hiệu lực.'
                      : checkedIn
                      ? 'Vé đã check-in. Mã QR sẽ ngừng hiển thị khi suất chiếu kết thúc.'
                      : booking.status == BookingStatus.paid
                      ? booking.qrCode?.trim().isNotEmpty == true
                            ? 'Đưa mã QR này tại cổng soát vé. Chỉ chia sẻ với người sử dụng vé.'
                            : 'Vui lòng tải lại đơn để lấy mã QR.'
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

class _TicketActionButton extends StatelessWidget {
  const _TicketActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.disabled;
          return primary ? AppColors.gold : AppColors.surfaceRaised;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
          return primary ? AppColors.background : AppColors.text;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: primary ? AppColors.gold : AppColors.goldBorder),
        ),
      ),
    ),
  );
}

String _ticketLabel(TicketType type) => switch (type) {
  TicketType.child => 'Vé trẻ em',
  TicketType.student => 'Vé sinh viên',
  _ => 'Vé người lớn',
};

String _dateTime(DateTime value) => formatVietnamDateTime(value);
