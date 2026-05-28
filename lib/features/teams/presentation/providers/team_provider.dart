import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/team_model.dart';
import '../../domain/entities/team_entity.dart';

// ── Teams list ──────────────────────────────────────────────────────────────

final teamSportFilterProvider = StateProvider<String>((ref) => 'all');

final teamsProvider = StateNotifierProvider<TeamsNotifier, List<TeamEntity>>(
  (ref) => TeamsNotifier(),
);

class TeamsNotifier extends StateNotifier<List<TeamEntity>> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _sub;
  bool isLoading = true;

  TeamsNotifier()
      : _firestore = FirebaseFirestore.instance,
        super([]) {
    _init();
  }

  void _init() {
    _sub = _firestore
        .collection(AppConstants.teamsCollection)
        .orderBy('points', descending: true)
        .snapshots()
        .listen(
          (snap) {
            isLoading = false;
            state = snap.docs.map((d) => TeamModel.fromFirestore(d)).toList();
          },
          onError: (_) {
            isLoading = false;
            state = [];
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> joinTeam(String teamId, String userId, String userName) async {
    final ref = _firestore.collection(AppConstants.teamsCollection).doc(teamId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) throw Exception('not found');
        final data = snap.data()!;
        final players = List<String>.from(data['playerIds'] ?? []);
        final teamSize = (data['teamSize'] as num?)?.toInt() ?? 5;
        if (players.length >= teamSize || players.contains(userId)) {
          throw Exception('cannot join');
        }
        txn.update(ref, {
          'playerIds': FieldValue.arrayUnion([userId]),
          'playerNames': FieldValue.arrayUnion([userName]),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePlayer(String teamId, String userId) async {
    final ref = _firestore.collection(AppConstants.teamsCollection).doc(teamId);
    try {
      final snap = await ref.get();
      final data = snap.data()!;
      final idx = List<String>.from(data['playerIds'] ?? []).indexOf(userId);
      final names = List<String>.from(data['playerNames'] ?? []);
      final name = idx >= 0 && idx < names.length ? names[idx] : '';
      await ref.update({
        'playerIds':   FieldValue.arrayRemove([userId]),
        'playerNames': FieldValue.arrayRemove([name]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCaptain(String teamId, String newCaptainId, String newCaptainName) async {
    try {
      await _firestore.collection(AppConstants.teamsCollection).doc(teamId).update({
        'captainId':   newCaptainId,
        'captainName': newCaptainName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createTeam(TeamEntity team) async {
    final model = TeamModel.fromEntity(team);
    final ref = await _firestore
        .collection(AppConstants.teamsCollection)
        .add(model.toMap());
    return ref.id;
  }

  Future<void> applyMatchResult({
    required String winnerTeamId,
    required String loserTeamId,
  }) async {
    final col = _firestore.collection(AppConstants.teamsCollection);
    final batch = _firestore.batch();
    batch.update(col.doc(winnerTeamId), {
      'wins': FieldValue.increment(1),
      'points': FieldValue.increment(3),
    });
    batch.update(col.doc(loserTeamId), {
      'losses': FieldValue.increment(1),
    });
    await batch.commit();
  }

  TeamEntity? userTeam(String userId) {
    try {
      return state.firstWhere((t) => t.isMember(userId));
    } catch (_) {
      return null;
    }
  }
}

final teamsLoadingProvider = Provider<bool>((ref) {
  ref.watch(teamsProvider);
  return ref.watch(teamsProvider.notifier).isLoading;
});

final filteredTeamsProvider = Provider<List<TeamEntity>>((ref) {
  final sport = ref.watch(teamSportFilterProvider);
  final teams = ref.watch(teamsProvider);
  if (sport == 'all') return teams;
  return teams.where((t) => t.sport == sport).toList();
});

final leaderboardTeamsProvider = Provider<List<TeamEntity>>((ref) {
  final teams = List<TeamEntity>.from(ref.watch(teamsProvider));
  teams.sort((a, b) => b.points.compareTo(a.points));
  return teams;
});

final userTeamProvider = Provider.family<TeamEntity?, String>((ref, userId) {
  final teams = ref.watch(teamsProvider);
  try {
    return teams.firstWhere((t) => t.isMember(userId));
  } catch (_) {
    return null;
  }
});

// ── Create team ─────────────────────────────────────────────────────────────

class CreateTeamState {
  final bool isLoading;
  final bool success;
  final String? error;
  const CreateTeamState({this.isLoading = false, this.success = false, this.error});
}

class CreateTeamNotifier extends StateNotifier<CreateTeamState> {
  final Ref _ref;
  CreateTeamNotifier(this._ref) : super(const CreateTeamState());

  Future<bool> create({
    required String name,
    required String sport,
    required String captainId,
    required String captainName,
    required int teamSize,
    required String city,
    String? description,
  }) async {
    state = const CreateTeamState(isLoading: true);
    try {
      final team = TeamEntity(
        id: const Uuid().v4(),
        name: name,
        sport: sport,
        captainId: captainId,
        captainName: captainName,
        playerIds: [captainId],
        playerNames: [captainName],
        teamSize: teamSize,
        city: city,
        description: description,
        createdAt: DateTime.now(),
      );
      await _ref.read(teamsProvider.notifier).createTeam(team);
      state = const CreateTeamState(success: true);
      return true;
    } catch (e) {
      state = CreateTeamState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const CreateTeamState();
}

final createTeamProvider =
    StateNotifierProvider.autoDispose<CreateTeamNotifier, CreateTeamState>(
  (ref) => CreateTeamNotifier(ref),
);

// ── Team chat ────────────────────────────────────────────────────────────────

class TeamChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  const TeamChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory TeamChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'لاعب',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final teamMessagesProvider = StreamProvider.autoDispose
    .family<List<TeamChatMessage>, String>((ref, teamId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.teamsCollection)
      .doc(teamId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(TeamChatMessage.fromFirestore).toList());
});

class TeamChatNotifier extends StateNotifier<bool> {
  TeamChatNotifier() : super(false);

  Future<void> send({
    required String teamId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    state = true;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.teamsCollection)
          .doc(teamId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      state = false;
    }
  }
}

final teamChatProvider =
    StateNotifierProvider.autoDispose<TeamChatNotifier, bool>(
  (_) => TeamChatNotifier(),
);
