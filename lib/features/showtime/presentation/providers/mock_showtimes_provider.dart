import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/showtime_models.dart';

final mockShowtimesProvider = Provider<List<MovieShowtime>>(
  (ref) => const [
    MovieShowtime(
      movieId: 'inception',
      rooms: [
        ShowtimeRoom(
          id: 'room-a-imax',
          name: 'Phòng A',
          formatBadge: 'IMAX Laser',
          screenDetail: 'Màn chiếu 22m • Laser 4K',
          slots: [
            ShowtimeSlot(
              id: 'slot-inc-a-1',
              time: '16:30',
              endTime: '~18:58',
              priceDisplay: 'Từ 110.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-inc-a-2',
              time: '19:30',
              endTime: '~21:58',
              priceDisplay: 'Từ 130.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-inc-a-3',
              time: '22:15',
              endTime: '~00:43',
              priceDisplay: 'Từ 95.000đ',
            ),
          ],
        ),
        ShowtimeRoom(
          id: 'room-c-dolby',
          name: 'Phòng C',
          formatBadge: 'Dolby Atmos',
          screenDetail: 'Âm thanh 64 kênh 3D',
          slots: [
            ShowtimeSlot(
              id: 'slot-inc-c-1',
              time: '18:00',
              endTime: '~20:28',
              priceDisplay: 'Từ 90.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-inc-c-2',
              time: '20:30',
              endTime: '~22:58',
              priceDisplay: '90.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-inc-c-3',
              time: '23:00',
              endTime: 'Hết chỗ',
              priceDisplay: '0 ghế trống',
              isSoldOut: true,
            ),
          ],
        ),
      ],
    ),
    MovieShowtime(
      movieId: 'avengers-endgame',
      rooms: [
        ShowtimeRoom(
          id: 'room-b-standard',
          name: 'Phòng B',
          formatBadge: 'Standard 2D',
          screenDetail: 'Phụ đề tiếng Việt',
          slots: [
            ShowtimeSlot(
              id: 'slot-avg-b-1',
              time: '17:00',
              endTime: '~20:01',
              priceDisplay: '85.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-avg-b-2',
              time: '20:45',
              endTime: '~23:46',
              priceDisplay: '90.000đ',
            ),
          ],
        ),
      ],
    ),
    MovieShowtime(
      movieId: 'spider-verse',
      rooms: [
        ShowtimeRoom(
          id: 'room-a-spiderman',
          name: 'Phòng A',
          formatBadge: 'IMAX Laser',
          screenDetail: 'Lồng tiếng chuẩn rạp',
          slots: [
            ShowtimeSlot(
              id: 'slot-sp-a-1',
              time: '15:00',
              endTime: '~16:57',
              priceDisplay: '100.000đ',
            ),
            ShowtimeSlot(
              id: 'slot-sp-a-2',
              time: '18:15',
              endTime: '~20:12',
              priceDisplay: '110.000đ',
            ),
          ],
        ),
      ],
    ),
  ],
);
