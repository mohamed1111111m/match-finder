import 'package:equatable/equatable.dart';

class VenueEntity extends Equatable {
  final String id;
  final String name;
  final String sport; // football | padel | basketball | tennis
  final String address;
  final String city;
  final double pricePerHour;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final List<String> amenities;
  final String openTime;  // e.g. "08:00"
  final String closeTime; // e.g. "23:00"
  final String phone;
  final bool isVerified;
  final String? description;
  final double? lat;
  final double? lng;

  const VenueEntity({
    required this.id,
    required this.name,
    required this.sport,
    required this.address,
    required this.city,
    required this.pricePerHour,
    this.rating = 0,
    this.reviewCount = 0,
    this.images = const [],
    this.amenities = const [],
    this.openTime = '08:00',
    this.closeTime = '23:00',
    this.phone = '',
    this.isVerified = false,
    this.description,
    this.lat,
    this.lng,
  });

  String get sportAr {
    switch (sport) {
      case 'football':  return 'كورة قدم';
      case 'padel':     return 'بادل';
      case 'basketball':return 'كرة سلة';
      case 'tennis':    return 'تنس';
      default:          return sport;
    }
  }

  String get priceText => '${pricePerHour.toInt()} ج/ساعة';

  @override
  List<Object?> get props => [id, name, sport, address, city, pricePerHour];
}
