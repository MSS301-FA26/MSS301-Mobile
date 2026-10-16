import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/booking_enums.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      BookingStatus.holding => (
        'Đang giữ ghế',
        AppColors.gold,
        Icons.timer_outlined,
      ),
      BookingStatus.pendingPayment => (
        'Chờ thanh toán',
        AppColors.gold,
        Icons.schedule,
      ),
      BookingStatus.paid => (
        'Đã thanh toán',
        const Color(0xFF62D9A3),
        Icons.check_circle_outline,
      ),
      BookingStatus.used => (
        'Đã sử dụng',
        const Color(0xFF92B9FF),
        Icons.verified_outlined,
      ),
      BookingStatus.cancelled => (
        'Đã hủy',
        const Color(0xFFFF9393),
        Icons.cancel_outlined,
      ),
      BookingStatus.expired => (
        'Đã hết hạn',
        AppColors.textMuted,
        Icons.timer_off_outlined,
      ),
      BookingStatus.refunded => (
        'Đã hoàn tiền',
        AppColors.lavender,
        Icons.undo,
      ),
      _ => ('Chưa xác định', AppColors.textMuted, Icons.help_outline),
    };
    return StatusBadge(label: label, color: color, icon: icon);
  }
}
