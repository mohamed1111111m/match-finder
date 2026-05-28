import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/tournament_entity.dart';

class TournamentModel extends TournamentEntity {
  const TournamentModel({
    required super.id,
    required super.title,
    required super.description,
    required super.game,
    required super.format,
    required super.status,
    required super.entryFee,
    required super.prizePool,
    required super.maxParticipants,
    required super.currentParticipants,
    required super.startDate,
    required super.endDate,
    super.imageUrl,
    required super.createdBy,
    required super.participantIds,
    required super.pendingApprovalIds,
    required super.createdAt,
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      game: data['game'] as String? ?? '',
      format: data['format'] as String? ?? '',
      status: data['status'] as String? ?? 'upcoming',
      entryFee: (data['entryFee'] as num?)?.toDouble() ?? 0,
      prizePool: (data['prizePool'] as num?)?.toDouble() ?? 0,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 0,
      currentParticipants: (data['currentParticipants'] as num?)?.toInt() ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      pendingApprovalIds: List<String>.from(data['pendingApprovalIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'game': game,
      'format': format,
      'status': status,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'participantIds': participantIds,
      'pendingApprovalIds': pendingApprovalIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static TournamentModel fromEntity(TournamentEntity entity) {
    return TournamentModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      game: entity.game,
      format: entity.format,
      status: entity.status,
      entryFee: entity.entryFee,
      prizePool: entity.prizePool,
      maxParticipants: entity.maxParticipants,
      currentParticipants: entity.currentParticipants,
      startDate: entity.startDate,
      endDate: entity.endDate,
      imageUrl: entity.imageUrl,
      createdBy: entity.createdBy,
      participantIds: entity.participantIds,
      pendingApprovalIds: entity.pendingApprovalIds,
      createdAt: entity.createdAt,
    );
  }
}
