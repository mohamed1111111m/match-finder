import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.venueId,
    required super.venueName,
    required super.userId,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.totalCost,
    super.status,
    super.paymentMethod,
    super.paymentSubmittedAt,
    super.sessionId,
    super.playerIds,
    required super.createdAt,
    super.receiptUrl,
    super.rejectionReason,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      venueId:     d['venueId']    as String? ?? '',
      venueName:   d['venueName']  as String? ?? '',
      userId:      d['userId']     as String? ?? '',
      date:        (d['date'] as Timestamp).toDate(),
      startTime:   d['startTime']  as String? ?? '',
      endTime:     d['endTime']    as String? ?? '',
      totalCost:   (d['totalCost'] as num?)?.toDouble() ?? 0,
      status:      d['status']     as String? ?? 'awaiting_payment',
      paymentMethod:      d['paymentMethod'] as String?,
      paymentSubmittedAt: (d['paymentSubmittedAt'] as Timestamp?)?.toDate(),
      sessionId:   d['sessionId']  as String?,
      playerIds:   List<String>.from(d['playerIds'] ?? []),
      createdAt:   d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      receiptUrl:       d['receiptUrl']       as String?,
      rejectionReason:  d['rejectionReason']  as String?,
    );
  }

  factory BookingModel.fromEntity(BookingEntity e) => BookingModel(
    id:                 e.id,
    venueId:            e.venueId,
    venueName:          e.venueName,
    userId:             e.userId,
    date:               e.date,
    startTime:          e.startTime,
    endTime:            e.endTime,
    totalCost:          e.totalCost,
    status:             e.status,
    paymentMethod:      e.paymentMethod,
    paymentSubmittedAt: e.paymentSubmittedAt,
    sessionId:          e.sessionId,
    playerIds:          e.playerIds,
    createdAt:          e.createdAt,
    receiptUrl:         e.receiptUrl,
    rejectionReason:    e.rejectionReason,
  );

  Map<String, dynamic> toMap() => {
    'venueId':   venueId,
    'venueName': venueName,
    'userId':    userId,
    'date':      Timestamp.fromDate(date),
    'startTime': startTime,
    'endTime':   endTime,
    'totalCost': totalCost,
    'status':    status,
    if (paymentMethod != null)      'paymentMethod': paymentMethod,
    if (paymentSubmittedAt != null) 'paymentSubmittedAt': Timestamp.fromDate(paymentSubmittedAt!),
    if (sessionId != null)          'sessionId': sessionId,
    if (receiptUrl != null)         'receiptUrl': receiptUrl,
    if (rejectionReason != null)    'rejectionReason': rejectionReason,
    'playerIds': playerIds,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
