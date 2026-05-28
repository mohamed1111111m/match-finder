import 'package:equatable/equatable.dart';

class TeamChallengeEntity extends Equatable {
  final String id;
  final String challengerTeamId;
  final String challengerTeamName;
  final String challengedTeamId;
  final String challengedTeamName;
  final String sport;
  final String city;
  final String? location;
  final DateTime? proposedDate;
  final String? proposedTime;
  final String status; // pending | accepted | declined | done
  final String? winnerId; // team id of winner after match
  final String createdBy; // captain uid
  final DateTime createdAt;
  final String? message; // optional challenge message

  const TeamChallengeEntity({
    required this.id,
    required this.challengerTeamId,
    required this.challengerTeamName,
    required this.challengedTeamId,
    required this.challengedTeamName,
    required this.sport,
    required this.city,
    this.location,
    this.proposedDate,
    this.proposedTime,
    this.status = 'pending',
    this.winnerId,
    required this.createdBy,
    required this.createdAt,
    this.message,
  });

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDone     => status == 'done';

  String get statusAr {
    switch (status) {
      case 'pending':  return 'في الانتظار';
      case 'accepted': return 'مقبول';
      case 'declined': return 'مرفوض';
      case 'done':     return 'منتهي';
      default:         return status;
    }
  }

  TeamChallengeEntity copyWith({String? status, String? winnerId, String? location,
    DateTime? proposedDate, String? proposedTime}) {
    return TeamChallengeEntity(
      id: id, challengerTeamId: challengerTeamId,
      challengerTeamName: challengerTeamName,
      challengedTeamId: challengedTeamId, challengedTeamName: challengedTeamName,
      sport: sport, city: city,
      location: location ?? this.location,
      proposedDate: proposedDate ?? this.proposedDate,
      proposedTime: proposedTime ?? this.proposedTime,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      createdBy: createdBy, createdAt: createdAt, message: message,
    );
  }

  @override
  List<Object?> get props => [id, challengerTeamId, challengedTeamId, status];
}
