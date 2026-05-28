import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data.dart';
import '../../data/models/ranking_model.dart';
import '../../domain/entities/ranking_entity.dart';

// Real-time global leaderboard — falls back to mock data in demo mode.
final globalRankingsProvider =
    StreamProvider.autoDispose<List<RankingEntity>>((ref) {
  if (AppConfig.isDemoMode) {
    return Stream.value(MockData.rankings);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .orderBy('points', descending: true)
      .limit(AppConstants.rankingsPageSize)
      .snapshots()
      .map((snap) => snap.docs
          .asMap()
          .entries
          .map((e) => RankingModel.fromUserDoc(e.value, e.key + 1))
          .toList());
});

// Tournament-specific rankings
final tournamentRankingsProvider =
    StreamProvider.autoDispose.family<List<RankingEntity>, String>(
  (ref, tournamentId) {
    if (AppConfig.isDemoMode) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('tournamentIds', arrayContains: tournamentId)
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .asMap()
            .entries
            .map((e) => RankingModel.fromUserDoc(e.value, e.key + 1))
            .toList());
  },
);
