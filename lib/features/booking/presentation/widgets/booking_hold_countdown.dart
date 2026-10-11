import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../orders/data/models/booking_dto.dart';
import '../../../orders/data/models/booking_enums.dart';

class BookingHoldCountdown extends ConsumerStatefulWidget {
  const BookingHoldCountdown({super.key, required this.booking});

  final BookingDto? booking;

  @override
  ConsumerState<BookingHoldCountdown> createState() =>
      _BookingHoldCountdownState();
}

class _BookingHoldCountdownState extends ConsumerState<BookingHoldCountdown>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate from the server deadline after returning from VNPay.
      setState(() {});
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final deadline = booking?.holdExpiresAt;
    if (booking == null ||
        deadline == null ||
        !const [
          BookingStatus.holding,
          BookingStatus.pendingPayment,
          BookingStatus.expired,
        ].contains(booking.status)) {
      return const SizedBox.shrink();
    }
    final remaining = deadline.difference(ref.watch(appClockProvider).now());
    final seconds =
        booking.status == BookingStatus.expired || remaining.isNegative
        ? 0
        : (remaining.inMilliseconds + 999) ~/ 1000;
    final color = seconds <= 30 ? AppColors.adultBadge : AppColors.gold;
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return Container(
      key: const ValueKey('booking-hold-countdown'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              seconds == 0
                  ? 'Đã hết thời gian giữ ghế'
                  : 'Thời gian giữ ghế còn lại',
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
          Text(
            time,
            key: const ValueKey('booking-hold-time'),
            style: AppTextStyles.cardTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
