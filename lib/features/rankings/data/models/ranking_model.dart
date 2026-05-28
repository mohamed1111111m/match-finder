import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ranking_entity.dart';

class RankingModel extends RankingEntity {
  const RankingModel({
    required super.userId,
    required super.username,
    super.photoUrl,
    required super.rank,
    required super.points,
    required super.wins,
    required super.losses,
    required super.totalMatches,
    super.favoriteGame,
  });

  factory RankingModel.fromUserDoc(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingModel(
      userId: doc.id,
      username: data['username'] as String? ?? 'Unknown',
      photoUrl: data['photoUrl'] as String?,
      rank: rank,
      points: (data['points'] as num?)?.toInt() ?? 0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      totalMatches: (data['totalMatches'] as num?)?.toInt() ?? 0,
      favoriteGame: data['favoriteGame'] as String?,
    );
  }
}
