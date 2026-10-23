import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';

final cinemaDetailProvider = FutureProvider.family<CinemaDto?, int>(
  (ref, id) => ref.watch(catalogRepositoryProvider).getCinema(id),
);

String normalizedCinemaSearch(String text) {
  var value = text.trim().toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final letter in entry.value.split('')) {
      value = value.replaceAll(letter, entry.key);
    }
  }
  return value.replaceAll(RegExp(r'\s+'), ' ');
}

String normalizedCinemaCity(String city) {
  final value = normalizedCinemaSearch(city)
      .replaceFirst(RegExp(r'^(thanh pho|tp)\.?\s*'), '')
      .replaceAll(RegExp(r'[.\-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (value == 'hcm' || value == 'tphcm') return 'ho chi minh';
  if (value == 'hn') return 'ha noi';
  return value;
}
