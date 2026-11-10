import '../../../../core/contracts/json_parsers.dart';

class CinemaDto {
  const CinemaDto({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.active,
    this.phone,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final bool active;
  final String? phone;

  factory CinemaDto.fromJson(Map<String, Object?> json) => CinemaDto(
    id: intFromJson(json['id'], field: 'cinema.id'),
    name: json['name']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    phone: json['phone']?.toString(),
    active: json['status']?.toString().toUpperCase() == 'ACTIVE',
  );
}
