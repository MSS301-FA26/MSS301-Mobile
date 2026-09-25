import '../../../movie/data/models/catalog_enums.dart';
import '../models/booking_enums.dart';

BookingSeatType mapCatalogSeatTypeToBooking(CatalogSeatType value) =>
    switch (value.normalized) {
      CatalogSeatType.standard => BookingSeatType.standard,
      CatalogSeatType.vip => BookingSeatType.vip,
      CatalogSeatType.couple => BookingSeatType.couple,
      _ => BookingSeatType.unknown,
    };
