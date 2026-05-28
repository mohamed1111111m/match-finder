import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/tournament_entity.dart';
import '../models/tournament_model.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({
    String? statusFilter,
    String? searchQuery,
    int limit,
    String? lastDocumentId,
  });

  Stream<TournamentModel> watchTournament(String tournamentId);
  Future<TournamentModel> getTournamentById(String tournamentId);
  Future<void> joinTournament(String tournamentId, String userId, String? paymentId);
  Future<String> createTournament(TournamentEntity tournament);
  Future<void> updateTournament(TournamentEntity tournament);
  Future<void> deleteTournament(String tournamentId);
  Future<void> updateParticipantStatus(
      String tournamentId, String userId, bool approved);
  Future<List<TournamentModel>> getUserTournaments(String userId);
}

class TournamentRemoteDataSourceImpl implements TournamentRemoteDataSource {
  final FirebaseFirestore _firestore;

  TournamentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.tournamentsCollection);

  @override
  Future<List<TournamentModel>> getTournaments({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      // Avoid composite index requirement: filter or sort, not both
      Query<Map<String, dynamic>> query;
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = _col.where('status', isEqualTo: statusFilter).limit(limit);
      } else {
        query = _col.orderBy('startDate', descending: false).limit(limit);
      }

      if (lastDocumentId != null && statusFilter == null) {
        final lastDoc = await _col.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      var models = snapshot.docs
          .map((doc) => TournamentModel.fromFirestore(doc))
          .toList();

      // Sort by startDate in Dart when status filter is active
      if (statusFilter != null && statusFilter.isNotEmpty) {
        models.sort((a, b) => a.startDate.compareTo(b.startDate));
      }

      // Client-side search filter (full-text search needs Algolia for production)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        models = models
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.game.toLowerCase().contains(q))
            .toList();
      }

      return models;
    } catch (e) {
      AppLogger.error('getTournaments failed', e);
      throw ServerException(message: 'Failed to load tournaments: $e');
    }
  }

  @override
  Stream<TournamentModel> watchTournament(String tournamentId) {
    return _col.doc(tournamentId).snapshots().map((doc) {
      if (!doc.exists) throw const NotFoundException();
      return TournamentModel.fromFirestore(doc);
    });
  }

  @override
  Future<TournamentModel> getTournamentById(String tournamentId) async {
    final doc = await _col.doc(tournamentId).get();
    if (!doc.exists) throw const NotFoundException(message: 'Tournament not found');
    return TournamentModel.fromFirestore(doc);
  }

  @override
  Future<void> joinTournament(
      String tournamentId, String userId, String? paymentId) async {
    final tournamentRef = _col.doc(tournamentId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(tournamentRef);
      if (!snap.exists) throw const NotFoundException(message: 'Tournament not found');

      final data = snap.data()!;
      final current = (data['currentParticipants'] as num).toInt();
      final max = (data['maxParticipants'] as num).toInt();
      final participants = List<String>.from(data['participantIds'] ?? []);

      if (current >= max) {
        throw const ServerException(message: 'Tournament is full');
      }
      if (participants.contains(userId)) {
        throw const ServerException(message: 'Already joined');
      }

      txn.update(tournamentRef, {
        'participantIds': FieldValue.arrayUnion([userId]),
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Save participation record for user
    if (paymentId != null) {
      await _col
          .doc(tournamentId)
          .collection(AppConstants.participantsSubcollection)
          .doc(userId)
          .set({
        'userId': userId,
        'paymentId': paymentId,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    }
  }

  @override
  Future<String> createTournament(TournamentEntity tournament) async {
    final model = TournamentModel.fromEntity(tournament);
    final ref = await _col.add(model.toMap());
    return ref.id;
  }

  @override
  Future<void> updateTournament(TournamentEntity tournament) async {
    final model = TournamentModel.fromEntity(tournament);
    final map = model.toMap()..remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(tournament.id).update(map);
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    await _col.doc(tournamentId).delete();
  }

  @override
  Future<void> updateParticipantStatus(
      String tournamentId, String userId, bool approved) async {
    final batch = _firestore.batch();
    final ref = _col.doc(tournamentId);

    if (approved) {
      batch.update(ref, {
        'pendingApprovalIds': FieldValue.arrayRemove([userId]),
        'participantIds': FieldValue.arrayUnion([userId]),
        'currentParticipants': FieldValue.increment(1),
      });
    } else {
      batch.update(ref, {
        'pendingApprovalIds': FieldValue.arrayRemove([userId]),
      });
    }

    await batch.commit();
  }

  @override
  Future<List<TournamentModel>> getUserTournaments(String userId) async {
    final snap = await _col
        .where('participantIds', arrayContains: userId)
        .orderBy('startDate', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => TournamentModel.fromFirestore(d)).toList();
  }
}
