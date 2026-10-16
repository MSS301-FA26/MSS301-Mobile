import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../models/ticket_order.dart';
import '../../data/models/booking_enums.dart';
import 'booking_status_badge.dart';

class UpcomingOrderCard extends StatelessWidget {
  const UpcomingOrderCard({
    super.key,
    required this.order,
    required this.onCancel,
    required this.onOpenTicket,
  });
  final TicketOrder order;
  final VoidCallback? onCancel, onOpenTicket;

  @override
  Widget build(BuildContext context) => _OrderCard(
    order: order,
    actions: [
      if (onCancel != null && order.status == BookingStatus.paid)
        AppButton(
          label: 'Hoàn / Đổi vé',
          icon: Icons.cancel_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: onCancel,
        ),
      AppButton(
        label: order.status == BookingStatus.paid
            ? 'Mở mã vé'
            : 'Tiếp tục đặt vé',
        icon: order.status == BookingStatus.paid
            ? Icons.qr_code_rounded
            : Icons.arrow_forward,
        onPressed: order.isUpcoming ? onOpenTicket : null,
      ),
    ],
  );
}

class CompletedOrderCard extends StatelessWidget {
  const CompletedOrderCard({
    super.key,
    required this.order,
    required this.onBookAgain,
    required this.onRate,
  });
  final TicketOrder order;
  final VoidCallback? onBookAgain, onRate;

  @override
  Widget build(BuildContext context) => _OrderCard(
    order: order,
    actions: [
      AppButton(
        label: 'Đặt lại vé',
        icon: Icons.replay_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: onBookAgain,
      ),
      if (onRate != null && order.status == BookingStatus.used)
        AppButton(
          label: 'Xem đánh giá',
          icon: Icons.star_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: onRate,
        ),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.actions});
  final TicketOrder order;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: BookingStatusBadge(status: order.status),
        ),
        const SizedBox(height: 8),
        Text(
          'Mã đơn: ${order.ticketCode}',
          style: AppTextStyles.caption.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.movieTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 8),
                if (order.ageRating.isNotEmpty || order.format.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (order.ageRating.isNotEmpty)
                        AgeBadge(rating: order.ageRating),
                      if (order.format.isNotEmpty)
                        Text(order.format, style: AppTextStyles.caption),
                    ],
                  ),
                Text(
                  order.cinemaLocation,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  order.dateTime,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gold,
                    fontSize: 14,
                  ),
                ),
              ],
            );
            final poster = SizedBox(
              width: 72,
              height: 104,
              child: AppImage(asset: order.moviePoster, fit: BoxFit.contain),
            );
            if (constraints.maxWidth < 280 &&
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [poster, const SizedBox(height: 10), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                poster,
                const SizedBox(width: 12),
                Expanded(child: details),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Ghế: ${order.seats.join(', ')}',
          style: AppTextStyles.body.copyWith(fontSize: 14),
        ),
        Text(order.seatsTypeLabel, style: AppTextStyles.caption),
        if (order.concessionsSummary != 'Không kèm F&B') ...[
          const SizedBox(height: 8),
          Text(
            'Bắp nước: ${order.concessionsSummary}',
            style: AppTextStyles.caption,
          ),
        ],
        const Divider(height: 24, color: AppColors.border),
        Text(
          order.totalPrice.format(),
          style: AppTextStyles.sectionTitle.copyWith(color: AppColors.gold),
        ),
        const SizedBox(height: 12),
        // Stacked actions keep long labels usable with system text scaling.
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          actions[i],
        ],
      ],
    ),
  );
}
