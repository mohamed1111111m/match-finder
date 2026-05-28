import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/match_session_model.dart';
import '../../domain/entities/match_session_entity.dart';

// ── Sessions list ───────────────────────────────────────────────────────────

final sessionSportFilterProvider = StateProvider<String>((ref) => 'all');

final sessionsProvider = StateNotifierProvider<SessionsNotifier, List<MatchSessionEntity>>(
  (ref) => SessionsNotifier(),
);

class SessionsNotifier extends StateNotifier<List<MatchSessionEntity>> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _sub;
  bool isLoading = true;

  SessionsNotifier()
      : _firestore = FirebaseFirestore.instance,
        super([]) {
    _init();
  }

  void _init() {
    _sub = _firestore
        .collection(AppConstants.matchmakingCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .listen(
          (snap) {
            isLoading = false;
            state = snap.docs
                .map((d) => MatchSessionModel.fromFirestore(d))
                .toList();
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

  Future<bool> joinSession(String sessionId, String userId, String userName) async {
    final ref = _firestore
        .collection(AppConstants.matchmakingCollection)
        .doc(sessionId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) throw Exception('not found');
        final data = snap.data()!;
        final current = (data['currentPlayers'] as num).toInt();
        final total = (data['totalPlayers'] as num).toInt();
        final players = List<String>.from(data['playerIds'] ?? []);
        if (current >= total || players.contains(userId)) {
          throw Exception('cannot join');
        }
        txn.update(ref, {
          'playerIds': FieldValue.arrayUnion([userId]),
          'playerNames.$userId': userName,
          'currentPlayers': FieldValue.increment(1),
          'status': current + 1 >= total ? 'full' : 'open',
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePlayer(String sessionId, String userId) async {
    final ref = _firestore
        .collection(AppConstants.matchmakingCollection)
        .doc(sessionId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) throw Exception('not found');
        final data = snap.data()!;
        final players = List<String>.from(data['playerIds'] ?? []);
        if (!players.contains(userId)) throw Exception('not a player');
        final newCount = ((data['currentPlayers'] as num).toInt() - 1).clamp(0, 999);
        txn.update(ref, {
          'playerIds': FieldValue.arrayRemove([userId]),
          'playerNames.$userId': FieldValue.delete(),
          'currentPlayers': newCount,
          'status': 'open',
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createSession(MatchSessionEntity session) async {
    final model = MatchSessionModel.fromEntity(session);
    final ref = await _firestore
        .collection(AppConstants.matchmakingCollection)
        .add(model.toMap());
    return ref.id;
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      await _firestore
          .collection(AppConstants.matchmakingCollection)
          .doc(sessionId)
          .delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sessionsLoadingProvider = Provider<bool>((ref) {
  ref.watch(sessionsProvider);
  return ref.watch(sessionsProvider.notifier).isLoading;
});

final filteredSessionsProvider = Provider<List<MatchSessionEntity>>((ref) {
  final sport = ref.watch(sessionSportFilterProvider);
  final sessions = ref.watch(sessionsProvider);
  if (sport == 'all') return sessions.where((s) => s.status == 'open').toList();
  return sessions.where((s) => s.sport == sport && s.status == 'open').toList();
});

// ── Create session state ────────────────────────────────────────────────────

class CreateSessionState {
  final bool isLoading;
  final bool success;
  final String? error;
  const CreateSessionState({this.isLoading = false, this.success = false, this.error});
}

class CreateSessionNotifier extends StateNotifier<CreateSessionState> {
  final Ref _ref;
  CreateSessionNotifier(this._ref) : super(const CreateSessionState());

  Future<bool> create({
    required String sport,
    required String creatorId,
    required String creatorName,
    required String city,
    required String location,
    required DateTime date,
    required String time,
    required int totalPlayers,
    required int currentPlayers,
    String? description,
    double? pricePerPlayer,
  }) async {
    state = const CreateSessionState(isLoading: true);
    try {
      final session = MatchSessionEntity(
        id: const Uuid().v4(),
        sport: sport,
        creatorId: creatorId,
        creatorName: creatorName,
        city: city,
        location: location,
        date: date,
        time: time,
        currentPlayers: currentPlayers,
        neededPlayers: totalPlayers - currentPlayers,
        totalPlayers: totalPlayers,
        description: description,
        playerIds: [creatorId],
        status: 'open',
        pricePerPlayer: pricePerPlayer,
        createdAt: DateTime.now(),
      );
      await _ref.read(sessionsProvider.notifier).createSession(session);
      state = const CreateSessionState(success: true);
      return true;
    } catch (e) {
      state = CreateSessionState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const CreateSessionState();
}

final createSessionProvider =
    StateNotifierProvider.autoDispose<CreateSessionNotifier, CreateSessionState>(
  (ref) => CreateSessionNotifier(ref),
);

// ── Session chat ────────────────────────────────────────────────────────────

class SessionChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  const SessionChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory SessionChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'لاعب',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final sessionMessagesProvider = StreamProvider.autoDispose
    .family<List<SessionChatMessage>, String>((ref, sessionId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.matchmakingCollection)
      .doc(sessionId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(SessionChatMessage.fromFirestore).toList());
});

class SessionChatNotifier extends StateNotifier<bool> {
  SessionChatNotifier() : super(false);

  Future<void> send({
    required String sessionId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    state = true;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.matchmakingCollection)
          .doc(sessionId)
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

final sessionChatProvider =
    StateNotifierProvider.autoDispose<SessionChatNotifier, bool>(
  (_) => SessionChatNotifier(),
);
