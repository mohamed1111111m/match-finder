import 'package:equatable/equatable.dart';

class TeamEntity extends Equatable {
  final String id;
  final String name;
  final String sport;
  final String captainId;
  final String captainName;
  final List<String> playerIds;
  final List<String> playerNames;
  final int teamSize;
  final int wins;
  final int losses;
  final int draws;
  final int points;
  final String city;
  final String? logoUrl;
  final String? description;
  final DateTime createdAt;

  const TeamEntity({
    required this.id,
    required this.name,
    required this.sport,
    required this.captainId,
    required this.captainName,
    this.playerIds = const [],
    this.playerNames = const [],
    this.teamSize = 5,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.points = 0,
    this.city = 'الإسماعيلية',
    this.logoUrl,
    this.description,
    required this.createdAt,
  });

  int get totalMatches => wins + losses + draws;
  bool isMember(String uid) => playerIds.contains(uid);
  bool isCaptain(String uid) => captainId == uid;
  bool get isFull => playerIds.length >= teamSize;

  String get sportAr {
    switch (sport) {
      case 'football':   return 'كورة قدم';
      case 'padel':      return 'بادل';
      case 'basketball': return 'كرة سلة';
      default:           return sport;
    }
  }

  // ── Rank tier based on points ─────────────────────────────────────────
  String get rankTier {
    if (points >= 5000) return 'ماسي';
    if (points >= 3000) return 'بلاتين';
    if (points >= 1500) return 'ذهب';
    if (points >= 500)  return 'فضة';
    return 'برونز';
  }

  int get rankTierLevel {
    if (points >= 5000) return 5;
    if (points >= 3000) return 4;
    if (points >= 1500) return 3;
    if (points >= 500)  return 2;
    return 1;
  }

  TeamEntity copyWith({
    List<String>? playerIds,
    List<String>? playerNames,
    int? wins,
    int? losses,
    int? draws,
    int? points,
  }) {
    return TeamEntity(
      id: id, name: name, sport: sport,
      captainId: captainId, captainName: captainName,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      teamSize: teamSize,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      points: points ?? this.points,
      city: city, logoUrl: logoUrl, description: description,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, sport, captainId, points];
}
