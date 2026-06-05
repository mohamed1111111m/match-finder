import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/venue_entity.dart';

class VenueModel extends VenueEntity {
  const VenueModel({
    required super.id,
    required super.name,
    required super.sport,
    required super.address,
    required super.city,
    required super.pricePerHour,
    super.rating,
    super.reviewCount,
    super.images,
    super.amenities,
    super.openTime,
    super.closeTime,
    super.phone,
    super.isVerified,
    super.description,
    super.lat,
    super.lng,
  });

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VenueModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      sport: d['sport'] as String? ?? 'football',
      address: d['address'] as String? ?? '',
      city: d['city'] as String? ?? '',
      pricePerHour: (d['pricePerHour'] as num?)?.toDouble() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      images: List<String>.from(d['images'] ?? []),
      amenities: List<String>.from(d['amenities'] ?? []),
      openTime: d['openTime'] as String? ?? '00:00',
      closeTime: d['closeTime'] as String? ?? '23:30',
      phone: d['phone'] as String? ?? '',
      isVerified: d['isVerified'] as bool? ?? false,
      description: d['description'] as String?,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }

  factory VenueModel.fromEntity(VenueEntity e) => VenueModel(
        id: e.id,
        name: e.name,
        sport: e.sport,
        address: e.address,
        city: e.city,
        pricePerHour: e.pricePerHour,
        rating: e.rating,
        reviewCount: e.reviewCount,
        images: e.images,
        amenities: e.amenities,
        openTime: e.openTime,
        closeTime: e.closeTime,
        phone: e.phone,
        isVerified: e.isVerified,
        description: e.description,
        lat: e.lat,
        lng: e.lng,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'sport': sport,
        'address': address,
        'city': city,
        'pricePerHour': pricePerHour,
        'rating': rating,
        'reviewCount': reviewCount,
        'images': images,
        'amenities': amenities,
        'openTime': openTime,
        'closeTime': closeTime,
        'phone': phone,
        'isVerified': isVerified,
        if (description != null) 'description': description,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}
