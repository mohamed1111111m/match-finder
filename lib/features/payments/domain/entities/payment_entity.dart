import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String userId;
  final String tournamentId;
  final String tournamentTitle;
  final double amount;       // in EGP
  final String method;       // vodafone_cash | fawry | credit_card
  final String status;       // pending | completed | failed | refunded
  final String? transactionId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PaymentEntity({
    required this.id,
    required this.userId,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [id, status, amount, method];
}
