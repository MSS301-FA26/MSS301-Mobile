import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../orders/data/models/booking_dto.dart';
import 'booking_progress.dart';

class ConcessionBookingHeader extends StatelessWidget {
  const ConcessionBookingHeader({
    super.key,
    this.booking,
    required this.onBack,
  });

  final BookingDto? booking;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final movieTitle = booking?.movieTitle ?? booking?.movieTitleSnapshot;
    final cinemaName = booking?.cinemaName ?? booking?.cinemaNameSnapshot;
    final roomName = booking?.roomName ?? booking?.roomNameSnapshot;
    final start = booking?.showtimeStart ?? booking?.showtimeStartSnapshot;
    final location = [
      if (cinemaName?.trim().isNotEmpty ?? false) cinemaName!,
      if (roomName?.trim().isNotEmpty ?? false) roomName!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'Bắp nước',
                          style: AppTextStyles.screenTitle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      const Text(
                        'Không bắt buộc • Có thể bỏ qua',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const BookingProgress(currentStep: 2),
        if (booking != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movieTitle?.trim().isNotEmpty ?? false)
                  Text(movieTitle!, style: AppTextStyles.cardTitle),
                if (location.isNotEmpty)
                  Text(location, style: AppTextStyles.body),
                if (start != null)
                  Text(
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} · '
                    '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}',
                    style: AppTextStyles.caption,
                  ),
                if (booking!.bookingCode.isNotEmpty)
                  Text(booking!.bookingCode, style: AppTextStyles.caption),
                if (booking!.seats.isNotEmpty)
                  Text(
                    'Ghế ${booking!.seats.map((seat) => seat.seatLabel).join(', ')}',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
        const AppSectionHeader(title: 'Thực đơn'),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}
