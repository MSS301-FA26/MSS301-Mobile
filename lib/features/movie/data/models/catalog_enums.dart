enum MovieStatus {
  upcoming('UPCOMING'),
  nowShowing('NOW_SHOWING'),
  ended('ENDED'),
  inactive('INACTIVE'),
  unknown('UNKNOWN');

  const MovieStatus(this.wireValue);
  final String wireValue;

  static MovieStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum ShowtimeStatus {
  scheduled('SCHEDULED'),
  open('OPEN'),
  cancelled('CANCELLED'),
  completed('COMPLETED'),
  unknown('UNKNOWN');

  const ShowtimeStatus(this.wireValue);
  final String wireValue;

  static ShowtimeStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum CatalogSeatType {
  normal('NORMAL'),
  standard('STANDARD'),
  vip('VIP'),
  couple('COUPLE'),
  unknown('UNKNOWN');

  const CatalogSeatType(this.wireValue);
  final String wireValue;

  CatalogSeatType get normalized => this == normal ? standard : this;

  static CatalogSeatType parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum SeatStatus {
  available('AVAILABLE'),
  unavailable('UNAVAILABLE'),
  maintenance('MAINTENANCE'),
  unknown('UNKNOWN');

  const SeatStatus(this.wireValue);
  final String wireValue;

  static SeatStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum SeatRuntimeStatus {
  available('AVAILABLE'),
  unavailable('UNAVAILABLE'),
  holding('HOLDING'),
  booked('BOOKED'),
  checkedIn('CHECKED_IN'),
  unknown('UNKNOWN');

  const SeatRuntimeStatus(this.wireValue);
  final String wireValue;

  static SeatRuntimeStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum TicketType {
  adult('ADULT'),
  child('CHILD'),
  student('STUDENT'),
  senior('SENIOR'),
  unknown('UNKNOWN');

  const TicketType(this.wireValue);
  final String wireValue;

  static TicketType parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum FoodItemStatus {
  active('ACTIVE'),
  lowStock('LOW_STOCK'),
  inactive('INACTIVE'),
  outOfStock('OUT_OF_STOCK'),
  unknown('UNKNOWN');

  const FoodItemStatus(this.wireValue);
  final String wireValue;

  static FoodItemStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}
