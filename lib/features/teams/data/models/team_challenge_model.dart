import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_challenge_entity.dart';

class TeamChallengeModel extends TeamChallengeEntity {
  const TeamChallengeModel({
    required super.id,
    required super.challengerTeamId,
    required super.challengerTeamName,
    required super.challengedTeamId,
    required super.challengedTeamName,
    required super.sport,
    required super.city,
    super.location,
    super.proposedDate,
    super.proposedTime,
    super.status,
    super.winnerId,
    required super.createdBy,
    required super.createdAt,
    super.message,
  });

  factory TeamChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamChallengeModel(
      id: doc.id,
      challengerTeamId: d['challengerTeamId'] as String? ?? '',
      challengerTeamName: d['challengerTeamName'] as String? ?? '',
      challengedTeamId: d['challengedTeamId'] as String? ?? '',
      challengedTeamName: d['challengedTeamName'] as String? ?? '',
      sport: d['sport'] as String? ?? 'football',
      city: d['city'] as String? ?? '',
      location: d['location'] as String?,
      proposedDate: d['proposedDate'] != null
          ? (d['proposedDate'] as Timestamp).toDate()
          : null,
      proposedTime: d['proposedTime'] as String?,
      status: d['status'] as String? ?? 'pending',
      winnerId: d['winnerId'] as String?,
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      message: d['message'] as String?,
    );
  }

  factory TeamChallengeModel.fromEntity(TeamChallengeEntity e) =>
      TeamChallengeModel(
        id: e.id,
        challengerTeamId: e.challengerTeamId,
        challengerTeamName: e.challengerTeamName,
        challengedTeamId: e.challengedTeamId,
        challengedTeamName: e.challengedTeamName,
        sport: e.sport,
        city: e.city,
        location: e.location,
        proposedDate: e.proposedDate,
        proposedTime: e.proposedTime,
        status: e.status,
        winnerId: e.winnerId,
        createdBy: e.createdBy,
        createdAt: e.createdAt,
        message: e.message,
      );

  Map<String, dynamic> toMap() => {
        'challengerTeamId': challengerTeamId,
        'challengerTeamName': challengerTeamName,
        'challengedTeamId': challengedTeamId,
        'challengedTeamName': challengedTeamName,
        'sport': sport,
        'city': city,
        if (location != null) 'location': location,
        if (proposedDate != null) 'proposedDate': Timestamp.fromDate(proposedDate!),
        if (proposedTime != null) 'proposedTime': proposedTime,
        'status': status,
        if (winnerId != null) 'winnerId': winnerId,
        'createdBy': createdBy,
        if (message != null) 'message': message,
        // Both team IDs in an array for arrayContains queries
        'teamIds': [challengerTeamId, challengedTeamId],
        'createdAt': FieldValue.serverTimestamp(),
      };
}
