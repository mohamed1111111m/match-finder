import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/venue_model.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/venue_entity.dart';

// ── Slot utilities ─────────────────────────────────────────────────────────────

/// Formats a DateTime to "YYYY-MM-DD"
String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Returns every 30-min slot from [startTime] up to (not including) [endTime].
List<String> slotsFromRange(String startTime, String endTime) {
  final slots = <String>[];
  var h = int.parse(startTime.split(':')[0]);
  var m = int.parse(startTime.split(':')[1]);
  final eh = int.parse(endTime.split(':')[0]);
  final em = int.parse(endTime.split(':')[1]);
  while (h < eh || (h == eh && m < em)) {
    slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    m += 30;
    if (m >= 60) { m = 0; h++; }
  }
  return slots;
}

// ── Admin venue management ─────────────────────────────────────────────────────

class AdminVenuesNotifier extends StateNotifier<List<VenueEntity>> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _sub;
  bool isLoading = true;

  AdminVenuesNotifier()
      : _firestore = FirebaseFirestore.instance,
        super([]) {
    _init();
  }

  void _init() {
    _sub = _firestore
        .collection(AppConstants.venuesCollection)
        .orderBy('name')
        .snapshots()
        .listen(
          (snap) {
            isLoading = false;
            state = snap.docs.map((d) => VenueModel.fromFirestore(d)).toList();
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

  Future<void> addVenue(VenueEntity venue) async {
    final model = VenueModel.fromEntity(venue);
    await _firestore
        .collection(AppConstants.venuesCollection)
        .add(model.toMap());
  }

  Future<void> removeVenue(String id) async {
    await _firestore
        .collection(AppConstants.venuesCollection)
        .doc(id)
        .delete();
  }

  Future<void> updateVenue(VenueEntity updated) async {
    final model = VenueModel.fromEntity(updated);
    await _firestore
        .collection(AppConstants.venuesCollection)
        .doc(updated.id)
        .update(model.toMap());
  }
}

final adminVenuesNotifierProvider =
    StateNotifierProvider<AdminVenuesNotifier, List<VenueEntity>>(
  (ref) => AdminVenuesNotifier(),
);

final venuesLoadingProvider = Provider<bool>((ref) {
  ref.watch(adminVenuesNotifierProvider);
  return ref.watch(adminVenuesNotifierProvider.notifier).isLoading;
});

final adminAllVenuesProvider = Provider<List<VenueEntity>>((ref) {
  return ref.watch(adminVenuesNotifierProvider);
});

final venueOpenStatusProvider =
    StateProvider.family<bool, String>((ref, venueId) => true);

final blockedSlotsProvider =
    StateProvider.family<Set<String>, String>((ref, venueId) => {});

// ── Venues list ────────────────────────────────────────────────────────────────

final venueFilterProvider = StateProvider<String>((ref) => 'all');

final venuesProvider = Provider<List<VenueEntity>>((ref) {
  final filter = ref.watch(venueFilterProvider);
  final all = ref
      .watch(adminVenuesNotifierProvider)
      .where((v) => ref.watch(venueOpenStatusProvider(v.id)))
      .toList();
  if (filter == 'all') return all;
  return all.where((v) => v.sport == filter).toList();
});

final venueByIdProvider = Provider.family<VenueEntity?, String>((ref, id) {
  try {
    return ref.watch(adminVenuesNotifierProvider).firstWhere((v) => v.id == id);
  } catch (_) {
    return null;
  }
});

// ── Real-time booked slots for a venue + date ──────────────────────────────────

/// Streams the set of start-time strings that are currently taken for a venue on a date.
/// e.g. {"09:00", "09:30", "11:00"} means those half-hour slots are occupied.
final venueBookedSlotsProvider = StreamProvider.autoDispose
    .family<Set<String>, ({String venueId, DateTime date})>((ref, p) {
  final docId = '${p.venueId}_${_dateKey(p.date)}';
  return FirebaseFirestore.instance
      .collection(AppConstants.venueSlotsCollection)
      .doc(docId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return <String>{};
        final booked =
            snap.data()!['bookedSlots'] as Map<String, dynamic>? ?? {};
        return booked.keys.toSet();
      });
});

// ── Booking creation ───────────────────────────────────────────────────────────

class BookingState {
  final bool isLoading;
  final bool success;
  final String? error;
  final String? bookingId;
  const BookingState({
    this.isLoading = false,
    this.success = false,
    this.error,
    this.bookingId,
  });
}

class BookingNotifier extends StateNotifier<BookingState> {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  BookingNotifier(this._storageService)
      : _firestore = FirebaseFirestore.instance,
        super(const BookingState());

  /// Atomically locks the time slot and creates the booking in one transaction.
  /// Throws `slot_taken` error if the slot is already occupied by another booking.
  Future<String?> createPendingBooking({
    required String venueId,
    required String venueName,
    required String userId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required double totalCost,
  }) async {
    state = const BookingState(isLoading: true);
    try {
      final occupied = slotsFromRange(startTime, endTime);
      final dateStr  = _dateKey(date);
      final slotDocId = '${venueId}_$dateStr';

      final slotDocRef = _firestore
          .collection(AppConstants.venueSlotsCollection)
          .doc(slotDocId);
      final bookingRef = _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(const Uuid().v4());

      await _firestore.runTransaction((tx) async {
        final slotSnap = await tx.get(slotDocRef);
        final existing = slotSnap.exists
            ? Map<String, dynamic>.from(
                slotSnap.data()!['bookedSlots'] as Map? ?? {})
            : <String, dynamic>{};

        // ── Check for conflicts ────────────────────────────────────────────
        for (final slot in occupied) {
          if (existing.containsKey(slot)) {
            throw Exception('slot_taken');
          }
        }

        // ── Lock slots ────────────────────────────────────────────────────
        final updated = Map<String, dynamic>.from(existing);
        for (final slot in occupied) {
          updated[slot] = bookingRef.id;
        }
        tx.set(slotDocRef, {
          'venueId': venueId,
          'date': dateStr,
          'bookedSlots': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ── Create booking ─────────────────────────────────────────────────
        tx.set(bookingRef, {
          'venueId': venueId,
          'venueName': venueName,
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'startTime': startTime,
          'endTime': endTime,
          'totalCost': totalCost,
          'status': AppConstants.bookingAwaitingPayment,
          'playerIds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      state = BookingState(success: true, bookingId: bookingRef.id);
      return bookingRef.id;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('slot_taken')) {
        state = const BookingState(error: 'slot_taken');
      } else {
        state = BookingState(error: errStr);
      }
      return null;
    }
  }

  /// Multi-slot booking: locks every individually-selected 30-min slot atomically.
  Future<String?> createPendingBookingSlots({
    required String venueId,
    required String venueName,
    required String userId,
    required DateTime date,
    required List<String> selectedSlots,
    required String startTime,
    required String endTime,
    required double totalCost,
  }) async {
    state = const BookingState(isLoading: true);
    try {
      final dateStr   = _dateKey(date);
      final slotDocId = '${venueId}_$dateStr';

      final slotDocRef = _firestore
          .collection(AppConstants.venueSlotsCollection)
          .doc(slotDocId);
      final bookingRef = _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(const Uuid().v4());

      await _firestore.runTransaction((tx) async {
        final slotSnap = await tx.get(slotDocRef);
        final existing = slotSnap.exists
            ? Map<String, dynamic>.from(
                slotSnap.data()!['bookedSlots'] as Map? ?? {})
            : <String, dynamic>{};

        for (final slot in selectedSlots) {
          if (existing.containsKey(slot)) throw Exception('slot_taken');
        }

        final updated = Map<String, dynamic>.from(existing);
        for (final slot in selectedSlots) {
          updated[slot] = bookingRef.id;
        }
        tx.set(slotDocRef, {
          'venueId': venueId,
          'date': dateStr,
          'bookedSlots': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(bookingRef, {
          'venueId': venueId,
          'venueName': venueName,
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'startTime': startTime,
          'endTime': endTime,
          'selectedSlots': selectedSlots,
          'totalCost': totalCost,
          'status': AppConstants.bookingAwaitingPayment,
          'playerIds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      state = BookingState(success: true, bookingId: bookingRef.id);
      return bookingRef.id;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('slot_taken')) {
        state = const BookingState(error: 'slot_taken');
      } else {
        state = BookingState(error: errStr);
      }
      return null;
    }
  }

  /// User confirms they've paid — uploads receipt (required) and moves to pending_verification.
  Future<bool> submitPaymentConfirmation({
    required String bookingId,
    required String paymentMethod,
    required File receiptFile,
  }) async {
    state = const BookingState(isLoading: true);
    try {
      final receiptUrl =
          await _storageService.uploadReceiptFile(receiptFile, bookingId);

      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': AppConstants.bookingPendingVerification,
        'paymentMethod': paymentMethod,
        'receiptUrl': receiptUrl,
        'paymentSubmittedAt': FieldValue.serverTimestamp(),
      });
      state = const BookingState(success: true);
      return true;
    } catch (e) {
      state = BookingState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const BookingState();
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, BookingState>(
  (ref) => BookingNotifier(ref.read(storageServiceProvider)),
);

// ── Real-time single booking stream ───────────────────────────────────────────

final bookingByIdStreamProvider =
    StreamProvider.autoDispose.family<BookingEntity?, String>((ref, bookingId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.bookingsCollection)
      .doc(bookingId)
      .snapshots()
      .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null);
});

// ── User bookings stream ───────────────────────────────────────────────────────

final userBookingsProvider =
    StreamProvider.autoDispose.family<List<BookingEntity>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection(AppConstants.bookingsCollection)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      }),
);

// ── Admin payment actions ──────────────────────────────────────────────────────

class AdminPaymentNotifier extends StateNotifier<bool> {
  AdminPaymentNotifier() : super(false);

  Future<void> confirmPayment(String bookingId) async {
    state = true;
    await FirebaseFirestore.instance
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .update({
      'status': AppConstants.bookingConfirmed,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    state = false;
  }

  /// Rejects a payment, frees the venue slots, and updates booking status.
  Future<void> rejectPayment(String bookingId, {String? reason}) async {
    state = true;
    try {
      final db = FirebaseFirestore.instance;
      final bookingRef =
          db.collection(AppConstants.bookingsCollection).doc(bookingId);

      // Read booking first (outside transaction — safe, we just need slot info)
      final bookingSnap = await bookingRef.get();
      if (!bookingSnap.exists) { state = false; return; }

      final d         = bookingSnap.data()!;
      final venueId   = d['venueId']   as String;
      final date      = (d['date'] as Timestamp).toDate();
      final startTime = d['startTime'] as String;
      final endTime   = d['endTime']   as String;
      final slotDocId = '${venueId}_${_dateKey(date)}';
      final slotDocRef =
          db.collection(AppConstants.venueSlotsCollection).doc(slotDocId);
      // Use explicitly stored selectedSlots if present; fall back to range derivation.
      final rawSlots = d['selectedSlots'];
      final toFree = rawSlots != null
          ? List<String>.from(rawSlots as List)
          : slotsFromRange(startTime, endTime);

      await db.runTransaction((tx) async {
        final slotSnap = await tx.get(slotDocRef);
        if (slotSnap.exists) {
          final existing = Map<String, dynamic>.from(
              slotSnap.data()!['bookedSlots'] as Map? ?? {});
          for (final slot in toFree) {
            if (existing[slot] == bookingId) existing.remove(slot);
          }
          tx.update(slotDocRef, {'bookedSlots': existing});
        }
        tx.update(bookingRef, {
          'status': AppConstants.bookingCancelled,
          if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
        });
      });
    } finally {
      state = false;
    }
  }
}

final adminPaymentNotifierProvider =
    StateNotifierProvider<AdminPaymentNotifier, bool>(
  (ref) => AdminPaymentNotifier(),
);

/// Live stream of bookings awaiting admin payment verification.
final adminPendingBookingsProvider =
    StreamProvider.autoDispose<List<BookingEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.bookingsCollection)
      .where('status', isEqualTo: AppConstants.bookingPendingVerification)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
        list.sort((a, b) {
          final at = a.paymentSubmittedAt ?? DateTime(0);
          final bt = b.paymentSubmittedAt ?? DateTime(0);
          return at.compareTo(bt);
        });
        return list;
      });
});

/// Live stream of all confirmed bookings (for admin summary).
final adminConfirmedBookingsProvider =
    StreamProvider.autoDispose<List<BookingEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.bookingsCollection)
      .where('status', isEqualTo: AppConstants.bookingConfirmed)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list.take(50).toList();
      });
});
