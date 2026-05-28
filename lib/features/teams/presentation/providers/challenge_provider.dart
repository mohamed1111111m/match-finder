import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/team_challenge_model.dart';
import '../../domain/entities/team_challenge_entity.dart';
import '../../domain/entities/team_entity.dart';
import 'team_provider.dart';

// ── Challenges list ──────────────────────────────────────────────────────────

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<TeamChallengeEntity>>(
  (ref) => ChallengesNotifier(ref),
);

class ChallengesNotifier extends StateNotifier<List<TeamChallengeEntity>> {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _sub;

  ChallengesNotifier(this._ref)
      : _firestore = FirebaseFirestore.instance,
        super([]) {
    _init();
  }

  void _init() {
    _sub = _firestore
        .collection(AppConstants.teamChallengesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            state = snap.docs
                .map((d) => TeamChallengeModel.fromFirestore(d))
                .toList();
          },
          onError: (_) => state = [],
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> sendChallenge({
    required TeamEntity challenger,
    required TeamEntity challenged,
    required String createdBy,
    String? message,
    String? location,
    DateTime? proposedDate,
    String? proposedTime,
  }) async {
    final entity = TeamChallengeEntity(
      id: const Uuid().v4(),
      challengerTeamId: challenger.id,
      challengerTeamName: challenger.name,
      challengedTeamId: challenged.id,
      challengedTeamName: challenged.name,
      sport: challenger.sport,
      city: challenger.city,
      location: location,
      proposedDate: proposedDate,
      proposedTime: proposedTime,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      message: message,
    );
    final model = TeamChallengeModel.fromEntity(entity);
    try {
      await _firestore
          .collection(AppConstants.teamChallengesCollection)
          .add(model.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> respond(String challengeId, bool accept) async {
    await _firestore
        .collection(AppConstants.teamChallengesCollection)
        .doc(challengeId)
        .update({'status': accept ? 'accepted' : 'declined'});
  }

  Future<void> recordResult(String challengeId, String winnerTeamId) async {
    final ref = _firestore
        .collection(AppConstants.teamChallengesCollection)
        .doc(challengeId);

    final snap = await ref.get();
    if (!snap.exists) return;

    await ref.update({'status': 'done', 'winnerId': winnerTeamId});

    final data = snap.data()!;
    final challengerTeamId = data['challengerTeamId'] as String;
    final challengedTeamId = data['challengedTeamId'] as String;
    final loserId =
        winnerTeamId == challengerTeamId ? challengedTeamId : challengerTeamId;

    await _ref.read(teamsProvider.notifier).applyMatchResult(
          winnerTeamId: winnerTeamId,
          loserTeamId: loserId,
        );
  }

  List<TeamChallengeEntity> forTeam(String teamId) => state
      .where((c) =>
          c.challengerTeamId == teamId || c.challengedTeamId == teamId)
      .toList();

  List<TeamChallengeEntity> pendingFor(String teamId) => state
      .where((c) => c.challengedTeamId == teamId && c.isPending)
      .toList();
}

final teamChallengesProvider =
    Provider.family<List<TeamChallengeEntity>, String>((ref, teamId) {
  final challenges = ref.watch(challengesProvider);
  return challenges
      .where((c) =>
          c.challengerTeamId == teamId || c.challengedTeamId == teamId)
      .toList();
});

final pendingChallengesProvider =
    Provider.family<List<TeamChallengeEntity>, String>((ref, teamId) {
  final challenges = ref.watch(challengesProvider);
  return challenges
      .where((c) => c.challengedTeamId == teamId && c.isPending)
      .toList();
});
