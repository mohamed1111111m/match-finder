import 'package:equatable/equatable.dart';

class RankingEntity extends Equatable {
  final String userId;
  final String username;
  final String? photoUrl;
  final int rank;
  final int points;
  final int wins;
  final int losses;
  final int totalMatches;
  final String? favoriteGame;

  const RankingEntity({
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.rank,
    required this.points,
    required this.wins,
    required this.losses,
    required this.totalMatches,
    this.favoriteGame,
  });

  double get winRate =>
      totalMatches == 0 ? 0 : (wins / totalMatches) * 100;

  @override
  List<Object?> get props => [userId, rank, points];
}
