import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.tournamentId,
    required super.tournamentTitle,
    required super.amount,
    required super.method,
    required super.status,
    super.transactionId,
    super.failureReason,
    required super.createdAt,
    super.completedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      tournamentId: data['tournamentId'] as String? ?? '',
      tournamentTitle: data['tournamentTitle'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: data['method'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      transactionId: data['transactionId'] as String?,
      failureReason: data['failureReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tournamentId': tournamentId,
      'tournamentTitle': tournamentTitle,
      'amount': amount,
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }
}
