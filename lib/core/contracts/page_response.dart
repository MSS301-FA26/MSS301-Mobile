import 'json_parsers.dart';

class PageResponse<T> {
  const PageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
  final bool first;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?> value) parseItem,
  ) {
    return PageResponse(
      items: listFromJson(json['items'], parseItem),
      page: intFromJson(json['page'], field: 'page'),
      size: intFromJson(json['size'], field: 'size'),
      totalItems: intFromJson(json['totalItems'], field: 'totalItems'),
      totalPages: intFromJson(json['totalPages'], field: 'totalPages'),
      first: boolFromJson(json['first']),
      last: boolFromJson(json['last']),
    );
  }
}
