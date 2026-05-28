import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/match_session_entity.dart';

class MatchSessionModel extends MatchSessionEntity {
  const MatchSessionModel({
    required super.id,
    required super.sport,
    required super.creatorId,
    required super.creatorName,
    required super.city,
    required super.location,
    required super.date,
    required super.time,
    required super.currentPlayers,
    required super.neededPlayers,
    required super.totalPlayers,
    super.description,
    super.playerIds,
    super.playerNames,
    super.status,
    super.venueId,
    super.venueName,
    super.pricePerPlayer,
    required super.createdAt,
  });

  factory MatchSessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MatchSessionModel(
      id: doc.id,
      sport: d['sport'] as String? ?? 'football',
      creatorId: d['creatorId'] as String? ?? '',
      creatorName: d['creatorName'] as String? ?? '',
      city: d['city'] as String? ?? '',
      location: d['location'] as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      time: d['time'] as String? ?? '',
      currentPlayers: (d['currentPlayers'] as num).toInt(),
      neededPlayers: (d['neededPlayers'] as num).toInt(),
      totalPlayers: (d['totalPlayers'] as num).toInt(),
      description: d['description'] as String?,
      playerIds: List<String>.from(d['playerIds'] ?? []),
      playerNames: Map<String, String>.from(
          (d['playerNames'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v.toString()))),
      status: d['status'] as String? ?? 'open',
      venueId: d['venueId'] as String?,
      venueName: d['venueName'] as String?,
      pricePerPlayer: d['pricePerPlayer'] != null
          ? (d['pricePerPlayer'] as num).toDouble()
          : null,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MatchSessionModel.fromEntity(MatchSessionEntity e) =>
      MatchSessionModel(
        id: e.id,
        sport: e.sport,
        creatorId: e.creatorId,
        creatorName: e.creatorName,
        city: e.city,
        location: e.location,
        date: e.date,
        time: e.time,
        currentPlayers: e.currentPlayers,
        neededPlayers: e.neededPlayers,
        totalPlayers: e.totalPlayers,
        description: e.description,
        playerIds: e.playerIds,
        playerNames: e.playerNames,
        status: e.status,
        venueId: e.venueId,
        venueName: e.venueName,
        pricePerPlayer: e.pricePerPlayer,
        createdAt: e.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'sport': sport,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'city': city,
        'location': location,
        'date': Timestamp.fromDate(date),
        'time': time,
        'currentPlayers': currentPlayers,
        'neededPlayers': neededPlayers,
        'totalPlayers': totalPlayers,
        if (description != null) 'description': description,
        'playerIds': playerIds,
        'playerNames': playerNames,
        'status': status,
        if (venueId != null) 'venueId': venueId,
        if (venueName != null) 'venueName': venueName,
        if (pricePerPlayer != null) 'pricePerPlayer': pricePerPlayer,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
