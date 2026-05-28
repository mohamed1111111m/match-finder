import 'package:equatable/equatable.dart';

class MatchSessionEntity extends Equatable {
  final String id;
  final String sport;
  final String creatorId;
  final String creatorName;
  final String city;
  final String location;
  final DateTime date;
  final String time;
  final int currentPlayers;
  final int neededPlayers;
  final int totalPlayers;
  final String? description;
  final List<String> playerIds;
  final Map<String, String> playerNames; // uid → displayName
  final String status; // open | full | cancelled | done
  final String? venueId;
  final String? venueName;
  final double? pricePerPlayer;
  final DateTime createdAt;

  const MatchSessionEntity({
    required this.id,
    required this.sport,
    required this.creatorId,
    required this.creatorName,
    required this.city,
    required this.location,
    required this.date,
    required this.time,
    required this.currentPlayers,
    required this.neededPlayers,
    required this.totalPlayers,
    this.description,
    this.playerIds = const [],
    this.playerNames = const {},
    this.status = 'open',
    this.venueId,
    this.venueName,
    this.pricePerPlayer,
    required this.createdAt,
  });

  bool get isFull => currentPlayers >= totalPlayers;
  bool get isOpen => status == 'open' && !isFull;
  int get spotsLeft => totalPlayers - currentPlayers;

  bool isPlayer(String uid) => playerIds.contains(uid);

  String get sportAr {
    switch (sport) {
      case 'football':   return 'كورة قدم';
      case 'padel':      return 'بادل';
      case 'basketball': return 'كرة سلة';
      case 'tennis':     return 'تنس';
      default:           return sport;
    }
  }

  String get statusAr {
    switch (status) {
      case 'open':      return 'مفتوح';
      case 'full':      return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'done':      return 'منتهي';
      default:          return status;
    }
  }

  String get dateText {
    final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${date.day} ${months[date.month - 1]}';
  }

  MatchSessionEntity copyWith({
    int? currentPlayers,
    List<String>? playerIds,
    Map<String, String>? playerNames,
    String? status,
  }) {
    return MatchSessionEntity(
      id: id, sport: sport, creatorId: creatorId, creatorName: creatorName,
      city: city, location: location, date: date, time: time,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      neededPlayers: neededPlayers, totalPlayers: totalPlayers,
      description: description,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      status: status ?? this.status,
      venueId: venueId, venueName: venueName,
      pricePerPlayer: pricePerPlayer, createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, sport, creatorId, city, date, time, currentPlayers];
}
