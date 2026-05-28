import 'package:equatable/equatable.dart';

class TournamentEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String game;
  final String format;         // e.g. "1v1", "5v5", "Battle Royale"
  final String status;         // upcoming | live | finished | cancelled
  final double entryFee;       // in EGP (0 = free)
  final double prizePool;      // in EGP
  final int maxParticipants;
  final int currentParticipants;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String createdBy;      // admin uid
  final List<String> participantIds;
  final List<String> pendingApprovalIds;
  final DateTime createdAt;

  const TournamentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.game,
    required this.format,
    required this.status,
    required this.entryFee,
    required this.prizePool,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    required this.createdBy,
    required this.participantIds,
    required this.pendingApprovalIds,
    required this.createdAt,
  });

  bool get isFree => entryFee == 0;
  bool get isFull => currentParticipants >= maxParticipants;
  bool get isUpcoming => status == 'upcoming';
  bool get isLive => status == 'live';
  bool get isFinished => status == 'finished';
  bool get isCancelled => status == 'cancelled';
  bool get isJoinable => isUpcoming && !isFull;

  double get fillPercentage =>
      maxParticipants == 0 ? 0 : currentParticipants / maxParticipants;

  bool isParticipant(String uid) => participantIds.contains(uid);
  bool isPendingApproval(String uid) => pendingApprovalIds.contains(uid);

  TournamentEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? game,
    String? format,
    String? status,
    double? entryFee,
    double? prizePool,
    int? maxParticipants,
    int? currentParticipants,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? createdBy,
    List<String>? participantIds,
    List<String>? pendingApprovalIds,
    DateTime? createdAt,
  }) {
    return TournamentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      game: game ?? this.game,
      format: format ?? this.format,
      status: status ?? this.status,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      participantIds: participantIds ?? this.participantIds,
      pendingApprovalIds: pendingApprovalIds ?? this.pendingApprovalIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, status, entryFee, currentParticipants, startDate];
}
