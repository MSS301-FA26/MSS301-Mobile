import 'package:flutter/material.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/vietnam_time.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/food_quote_dto.dart';
import '../../../movie/data/models/movie_dto.dart';
import '../../../orders/data/models/booking_dto.dart';

String? checkoutText(Iterable<String?> values) => values
    .whereType<String>()
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .firstOrNull;
String checkoutTicketLabel(TicketType type) => switch (type) {
  TicketType.child => 'Vé trẻ em',
  TicketType.student => 'Vé sinh viên',
  _ => 'Vé người lớn',
};

String _ageMeaning(String age) {
  final value = age.trim().toUpperCase();
  if (value == 'P') return 'Phù hợp với mọi độ tuổi.';
  if (value == 'K') {
    return 'Khán giả dưới 13 tuổi cần đi cùng cha mẹ hoặc người giám hộ.';
  }
  final minimum = RegExp(r'^(?:T)?(13|16|18)(?:\+)?$')
      .firstMatch(value)
      ?.group(1);
  if (minimum != null) {
    return 'Phim dành cho khán giả từ đủ $minimum tuổi trở lên.';
  }
  if (value == 'C') return 'Phim không được phép phổ biến.';
  return 'Vui lòng kiểm tra phân loại độ tuổi trước khi thanh toán.';
}

class CheckoutMovieSummary extends StatelessWidget {
  const CheckoutMovieSummary({
    super.key,
    required this.quote,
    required this.booking,
    this.metadata,
  });
  final CheckoutQuoteDto quote;
  final BookingDto booking;
  final MovieDto? metadata;
  @override
  Widget build(BuildContext context) {
    final snapshot = quote.movie?.id == quote.showtime.movieId
        ? quote.movie
        : null;
    final extra = metadata?.id == quote.showtime.movieId ? metadata : null;
    final title =
        checkoutText([
          snapshot?.title,
          quote.showtime.movieTitle,
          booking.movieTitleSnapshot,
          booking.movieTitle,
          extra?.title,
        ]) ??
        'Thông tin phim đang cập nhật';
    final poster =
        checkoutText([
          snapshot?.posterUrl,
          quote.showtime.posterUrl,
          booking.moviePosterSnapshot,
          booking.posterUrl,
          extra?.posterUrl,
          extra?.avatarUrl,
        ]) ??
        '';
    final age = checkoutText([snapshot?.ageRating, extra?.ageRating]);
    final duration = snapshot?.durationMinutes ?? extra?.durationMinutes;
    final cinema = checkoutText([
      quote.cinema?.name,
      quote.showtime.cinemaName,
      booking.cinemaNameSnapshot,
      booking.cinemaName,
    ]);
    final room = checkoutText([
      quote.cinema?.roomName,
      quote.showtime.roomName,
      booking.roomNameSnapshot,
      booking.roomName,
    ]);
    return CheckoutSection(
      title: 'Thông tin suất chiếu',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              height: 114,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.control,
              ),
              child: AppImage(
                key: const ValueKey('checkout-movie-poster'),
                asset: poster,
                fit: BoxFit.contain,
                semanticLabel: 'Poster $title',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const ValueKey('checkout-movie-title'),
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (age != null) AgeBadge(rating: age),
                      if (duration != null && duration > 0)
                        Text('$duration phút', style: AppTextStyles.body),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (age != null) ...[
          const SizedBox(height: 14),
          Text(
            _ageMeaning(age),
            style: AppTextStyles.body.copyWith(color: AppColors.gold),
          ),
        ],
        const SizedBox(height: 16),
        CheckoutLine('Rạp', cinema ?? 'Chưa có thông tin'),
        if (checkoutText([quote.cinema?.address]) != null)
          CheckoutLine('Địa chỉ', quote.cinema!.address!, stacked: true),
        CheckoutLine('Phòng', room ?? 'Chưa có thông tin'),
        CheckoutLine(
          'Suất chiếu',
          formatVietnamDateTime(quote.showtime.startTime),
        ),
        CheckoutLine('Số ghế', '${quote.seats.length}'),
        if (quote.seats.isNotEmpty)
          CheckoutLine(
            'Ghế',
            quote.seats
                .map(
                  (seat) => seat.seatLabel.isEmpty
                      ? '#${seat.seatId}'
                      : seat.seatLabel,
                )
                .join(', '),
          ),
      ],
    );
  }
}

class CheckoutTicketSummary extends StatelessWidget {
  const CheckoutTicketSummary({super.key, required this.quote});
  final CheckoutQuoteDto quote;
  @override
  Widget build(BuildContext context) {
    final seats = {for (final seat in quote.seats) seat.seatId: seat};
    return CheckoutSection(
      title: 'Chi tiết vé theo ghế',
      children: [
        if (quote.tickets.isEmpty)
          const Text(
            'Chi tiết loại vé chưa được cung cấp. Tiền vé vẫn theo báo giá bên dưới.',
            style: AppTextStyles.body,
          ),
        for (final ticket in quote.tickets)
          Container(
            key: ValueKey('checkout-ticket-${ticket.seatId}'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.control,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: AppRadii.small,
                      ),
                      child: Text(
                        checkoutText([seats[ticket.seatId]?.seatLabel]) ??
                            'Ghế #${ticket.seatId}',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    Text(
                      checkoutTicketLabel(ticket.ticketType),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CheckoutLine(
                  'Đơn giá × số lượng',
                  '${ticket.unitPrice.format()} × ${ticket.quantity}',
                ),
                CheckoutLine(
                  'Thành tiền',
                  ticket.lineTotal.format(),
                  emphasized: true,
                ),
              ],
            ),
          ),
        const Text(
          'Giá vé hiển thị theo báo giá của suất chiếu.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class CheckoutFoodSummaryLine extends StatelessWidget {
  const CheckoutFoodSummaryLine({
    super.key,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isCombo,
    this.imageUrl,
  });
  final String name;
  final int quantity;
  final VndMoney unitPrice, lineTotal;
  final bool isCombo;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.control,
              ),
              child: _FoodThumbnail(url: imageUrl, combo: isCombo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCombo ? 'COMBO' : 'SẢN PHẨM',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(name, style: AppTextStyles.cardTitle),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CheckoutLine('Đơn giá × số lượng', '${unitPrice.format()} × $quantity'),
        CheckoutLine('Thành tiền', lineTotal.format(), emphasized: true),
      ],
    ),
  );
}

class _FoodThumbnail extends StatelessWidget {
  const _FoodThumbnail({required this.url, required this.combo});
  final String? url;
  final bool combo;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    final fallback = Center(
      child: Icon(
        combo ? Icons.fastfood_rounded : Icons.local_drink_rounded,
        color: AppColors.gold,
      ),
    );
    if (uri == null ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return fallback;
    }
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
