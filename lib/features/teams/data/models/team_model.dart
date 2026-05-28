import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_entity.dart';

class TeamModel extends TeamEntity {
  const TeamModel({
    required super.id,
    required super.name,
    required super.sport,
    required super.captainId,
    required super.captainName,
    super.playerIds,
    super.playerNames,
    super.teamSize,
    super.wins,
    super.losses,
    super.draws,
    super.points,
    super.city,
    super.logoUrl,
    super.description,
    required super.createdAt,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      sport: d['sport'] as String? ?? 'football',
      captainId: d['captainId'] as String? ?? '',
      captainName: d['captainName'] as String? ?? '',
      playerIds: List<String>.from(d['playerIds'] ?? []),
      playerNames: List<String>.from(d['playerNames'] ?? []),
      teamSize: (d['teamSize'] as num?)?.toInt() ?? 5,
      wins: (d['wins'] as num?)?.toInt() ?? 0,
      losses: (d['losses'] as num?)?.toInt() ?? 0,
      draws: (d['draws'] as num?)?.toInt() ?? 0,
      points: (d['points'] as num?)?.toInt() ?? 0,
      city: d['city'] as String? ?? 'الإسماعيلية',
      logoUrl: d['logoUrl'] as String?,
      description: d['description'] as String?,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory TeamModel.fromEntity(TeamEntity e) => TeamModel(
        id: e.id,
        name: e.name,
        sport: e.sport,
        captainId: e.captainId,
        captainName: e.captainName,
        playerIds: e.playerIds,
        playerNames: e.playerNames,
        teamSize: e.teamSize,
        wins: e.wins,
        losses: e.losses,
        draws: e.draws,
        points: e.points,
        city: e.city,
        logoUrl: e.logoUrl,
        description: e.description,
        createdAt: e.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'sport': sport,
        'captainId': captainId,
        'captainName': captainName,
        'playerIds': playerIds,
        'playerNames': playerNames,
        'teamSize': teamSize,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'points': points,
        'city': city,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (description != null) 'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
