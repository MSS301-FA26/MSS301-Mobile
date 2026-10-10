import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../models/ticket_order.dart';

class UpcomingOrderCard extends StatelessWidget {
  const UpcomingOrderCard({
    super.key,
    required this.order,
    required this.onCancel,
    required this.onOpenTicket,
  });

  final TicketOrder order;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenTicket;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrderDetails(order: order),
        if (onCancel == null && onOpenTicket == null) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Mã vé và hoàn/đổi đang tạm khóa trong bản mock.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: ValueKey('order-ticket-${order.id}'),
          label: 'Mở mã vé',
          icon: Icons.qr_code_rounded,
          fullWidth: true,
          onPressed: onOpenTicket,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: ValueKey('order-refund-${order.id}'),
          label: 'Hoàn / Đổi vé',
          icon: Icons.cancel_outlined,
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: onCancel,
        ),
      ],
    ),
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
  final VoidCallback? onBookAgain;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrderDetails(order: order),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: ValueKey('order-book-again-${order.id}'),
          label: 'Đặt lại vé',
          icon: Icons.replay_rounded,
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: onBookAgain,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: ValueKey('order-review-${order.id}'),
          label: onRate == null ? 'Đánh giá • Sắp có' : 'Đánh giá',
          icon: Icons.star_rounded,
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: onRate,
        ),
      ],
    ),
  );
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final TicketOrder order;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(children: [_OrderStatus(order: order)]),
      const SizedBox(height: AppSpacing.xs),
      const Text('Mã đặt vé', style: AppTextStyles.caption),
      const SizedBox(height: AppSpacing.xxs),
      Text(order.ticketCode, style: AppTextStyles.emphasis),
      const SizedBox(height: AppSpacing.md),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadii.control,
            child: SizedBox(
              width: AppSpacing.headerHeight,
              child: AppImage(
                asset: order.moviePoster,
                aspectRatio: AppSizes.posterAspectRatio,
                semanticLabel: 'Poster ${order.movieTitle}',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(order.movieTitle, style: AppTextStyles.cardTitle),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Text(order.cinemaLocation, style: AppTextStyles.body),
      if (order.roomName.trim().isNotEmpty &&
          !order.cinemaLocation.contains(order.roomName)) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(order.roomName, style: AppTextStyles.body),
      ],
      const SizedBox(height: AppSpacing.xs),
      Text(
        order.dateTime,
        style: AppTextStyles.emphasis.copyWith(color: AppColors.gold),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Ghế: ${order.seats.join(', ')} (${order.seatsTypeLabel})',
        style: AppTextStyles.body,
      ),
      if (order.concessionsSummary != 'Không kèm F&B') ...[
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.fastfood_rounded,
              size: AppSizes.iconSmall,
              color: AppColors.gold,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Bắp nước: ${order.concessionsSummary}',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      const Text('Tổng tiền', style: AppTextStyles.caption),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        order.totalPrice.format(),
        key: ValueKey('order-amount-${order.id}'),
        style: AppTextStyles.price.copyWith(color: AppColors.gold),
      ),
    ],
  );
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.order});

  final TicketOrder order;

  @override
  Widget build(BuildContext context) {
    final foreground = order.isUpcoming
        ? AppColors.gold
        : AppColors.textSecondary;
    return Semantics(
      key: ValueKey('order-status-${order.id}'),
      container: true,
      label: 'Trạng thái đặt vé: ${order.statusLabel}',
      excludeSemantics: true,
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.xs),
        color: AppColors.surfaceRaised,
        borderColor: order.isUpcoming ? AppColors.gold : AppColors.border,
        borderRadius: AppRadii.small,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: AppSizes.iconSmall,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                order.statusLabel,
                style: AppTextStyles.label.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
