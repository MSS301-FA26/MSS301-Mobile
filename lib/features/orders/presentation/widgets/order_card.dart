import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _PulseDot(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                order.ticketCode,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (onCancel == null && onOpenTicket == null) ...[
            const Text(
              'Mã vé và hoàn/đổi đang tạm khóa trong bản mock.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.control,
                child: SizedBox(
                  width: 80,
                  height: 112,
                  child: AppImage(asset: order.moviePoster),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AgeBadge(
                                rating: order.ageRating,
                                variant: AgeBadgeVariant.hero,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.format,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.lavender,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            order.movieTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.cinemaLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.dateTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Ghế: ${order.seats.join(', ')} (${order.seatsTypeLabel})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (order.concessionsSummary != 'Không kèm F&B') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadii.control,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fastfood_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Bắp nước: ${order.concessionsSummary}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Hoàn / Đổi vé',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.secondary,
                  height: 44,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  label: 'Mở mã vé',
                  icon: Icons.qr_code_rounded,
                  height: 44,
                  onPressed: onOpenTicket,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: AppRadii.small,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(order.statusLabel, style: AppTextStyles.caption),
              ),
              const Spacer(),
              Text(
                order.ticketCode,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ClipRRect(
                borderRadius: AppRadii.control,
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: AppImage(asset: order.moviePoster),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.movieTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.cinemaLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.dateTime,
                      style: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ghế ${order.seats.join(', ')} • ${order.totalPrice.format()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Đặt lại vé',
                  icon: Icons.replay_rounded,
                  variant: AppButtonVariant.secondary,
                  height: 38,
                  onPressed: onBookAgain,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton(
                label: onRate == null ? 'Đánh giá • Sắp có' : 'Đánh giá',
                icon: Icons.star_rounded,
                variant: AppButtonVariant.secondary,
                height: 38,
                onPressed: onRate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
    );
  }
}
