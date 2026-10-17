import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../orders/data/models/booking_dto.dart';
import '../../../payment/data/models/payment_dto.dart';

class PaymentBookingSummary extends StatelessWidget {
  const PaymentBookingSummary({super.key, this.payment, this.booking});

  final PaymentDto? payment;
  final BookingDto? booking;

  @override
  Widget build(BuildContext context) {
    final movie = booking?.movieTitleSnapshot ?? booking?.movieTitle;
    final cinema = booking?.cinemaNameSnapshot ?? booking?.cinemaName;
    final room = booking?.roomNameSnapshot ?? booking?.roomName;
    final start = booking?.showtimeStartSnapshot ?? booking?.showtimeStart;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (payment != null) ...[
            const Text('Số tiền thanh toán', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              payment!.amount.format(),
              key: const ValueKey('payment-amount'),
              style: AppTextStyles.displayTitle.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryLine('Phương thức', payment!.provider.wireValue),
            _SummaryLine('Mã giao dịch', '${payment!.id}'),
            _SummaryLine('Trạng thái giao dịch', payment!.status.wireValue),
            if (payment!.transactionId?.isNotEmpty ?? false)
              _SummaryLine('Tham chiếu', payment!.transactionId!),
          ],
          if (booking != null) ...[
            if (payment != null) ...[
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
            ],
            Semantics(
              header: true,
              child: Text(
                'Booking #${booking!.id}',
                style: AppTextStyles.cardTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryLine('Mã đặt vé', booking!.bookingCode),
            if (movie?.trim().isNotEmpty ?? false) _SummaryLine('Phim', movie!),
            if (cinema?.trim().isNotEmpty ?? false)
              _SummaryLine('Rạp', cinema!),
            if (room?.trim().isNotEmpty ?? false) _SummaryLine('Phòng', room!),
            if (start != null)
              _SummaryLine(
                'Suất chiếu',
                '${_two(start.hour)}:${_two(start.minute)} · '
                    '${_two(start.day)}/${_two(start.month)}/${start.year}',
              ),
            if (booking!.seats.isNotEmpty)
              _SummaryLine(
                'Ghế',
                booking!.seats.map((seat) => seat.seatLabel).join(', '),
              ),
            for (final food in booking!.foods)
              _SummaryLine(
                'Bắp nước',
                '${food.quantity} × ${food.productName}',
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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

String _two(int value) => value.toString().padLeft(2, '0');
