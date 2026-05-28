import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String venueId;
  final String venueName;
  final String userId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double totalCost;

  /// Booking lifecycle status.
  /// Values: awaiting_payment | pending_verification | confirmed | cancelled | expired
  final String status;

  /// Which manual payment method the user chose.
  /// Values: instapay | orange_cash | vodafone_cash
  final String? paymentMethod;

  /// When the user tapped "I've paid" and moved to pending_verification.
  final DateTime? paymentSubmittedAt;

  final String? sessionId;
  final List<String> playerIds;
  final DateTime createdAt;
  final String? receiptUrl;
  final String? rejectionReason;

  const BookingEntity({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalCost,
    this.status = 'awaiting_payment',
    this.paymentMethod,
    this.paymentSubmittedAt,
    this.sessionId,
    this.playerIds = const [],
    required this.createdAt,
    this.receiptUrl,
    this.rejectionReason,
  });

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get isAwaitingPayment    => status == 'awaiting_payment';
  bool get isPendingVerification => status == 'pending_verification';
  bool get isConfirmed          => status == 'confirmed';
  bool get isCancelled          => status == 'cancelled';

  bool get isExpired {
    if (status == 'expired') return true;
    if (status != 'awaiting_payment') return false;
    return DateTime.now().difference(createdAt).inMinutes >= 15;
  }

  String get statusAr {
    if (isExpired) return 'منتهية الصلاحية';
    switch (status) {
      case 'awaiting_payment':     return 'في انتظار الدفع';
      case 'pending_verification': return 'قيد المراجعة';
      case 'confirmed':            return 'مؤكد';
      case 'cancelled':            return 'ملغي';
      case 'expired':              return 'منتهية الصلاحية';
      // legacy value kept for old bookings
      case 'pending':              return 'في الانتظار';
      default:                     return status;
    }
  }

  String get paymentMethodAr {
    switch (paymentMethod) {
      case 'instapay':      return 'إنستاباي';
      case 'orange_cash':   return 'أورانج كاش';
      case 'vodafone_cash': return 'فودافون كاش';
      default:              return '—';
    }
  }

  String get dateText {
    final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  List<Object?> get props =>
      [id, venueId, userId, date, startTime, endTime, status, paymentMethod, receiptUrl];
}
