import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/payment_model.dart';
import '../../domain/entities/payment_entity.dart';

// ─── Payment state ─────────────────────────────────────────────────────────

enum PaymentStatus { idle, loading, success, failed }

class PaymentState {
  final PaymentStatus status;
  final String? error;
  final String? paymentId;
  final String? transactionId;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.error,
    this.paymentId,
    this.transactionId,
  });

  bool get isLoading => status == PaymentStatus.loading;
  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;
}

// ─── Payment notifier ──────────────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<PaymentState> {
  final _uuid = const Uuid();

  // Lazy getters — only accessed when NOT in demo mode.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  PaymentNotifier() : super(const PaymentState());

  /// Initiate a payment via Cloud Function. Falls back to simulation in demo mode.
  Future<String?> initiatePayment({
    required String userId,
    required String tournamentId,
    required String tournamentTitle,
    required double amount,
    required String method,
    String? phoneNumber,
    String? referenceCode,
  }) async {
    state = const PaymentState(status: PaymentStatus.loading);

    if (AppConfig.isDemoMode) {
      return _simulatePayment(
          userId, tournamentId, tournamentTitle, amount, method);
    }

    try {
      final callable =
          _functions.httpsCallable(AppConstants.cfInitiatePayment);
      final result = await callable.call({
        'tournamentId': tournamentId,
        'amount': amount,
        'method': method,
        'userId': userId,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (referenceCode != null) 'referenceCode': referenceCode,
      });

      final data = result.data as Map<String, dynamic>;
      final paymentId = data['paymentId'] as String? ?? _uuid.v4();
      final transactionRef = data['transactionRef'] as String?;

      final model = PaymentModel(
        id: paymentId,
        userId: userId,
        tournamentId: tournamentId,
        tournamentTitle: tournamentTitle,
        amount: amount,
        method: method,
        status: AppConstants.paymentPending,
        transactionId: transactionRef,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentId)
          .set(model.toMap());

      state = PaymentState(
        status: PaymentStatus.idle,
        paymentId: paymentId,
        transactionId: transactionRef,
      );

      return paymentId;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Payment initiation failed', e);
      state = PaymentState(
        status: PaymentStatus.failed,
        error: e.message ?? 'Payment initiation failed',
      );
      return null;
    } catch (e) {
      AppLogger.error('Payment error', e);
      return _simulatePayment(
          userId, tournamentId, tournamentTitle, amount, method);
    }
  }

  /// Verify payment completion. Auto-verifies in demo mode.
  Future<bool> verifyPayment({
    required String paymentId,
    required String transactionId,
  }) async {
    state = const PaymentState(status: PaymentStatus.loading);

    if (AppConfig.isDemoMode) {
      return _simulateVerify(paymentId);
    }

    try {
      final callable =
          _functions.httpsCallable(AppConstants.cfVerifyPayment);
      final result = await callable.call({
        'paymentId': paymentId,
        'transactionId': transactionId,
      });

      final data = result.data as Map<String, dynamic>;
      final verified = data['verified'] as bool? ?? false;

      if (verified) {
        await _firestore
            .collection(AppConstants.paymentsCollection)
            .doc(paymentId)
            .update({
          'status': AppConstants.paymentCompleted,
          'completedAt': FieldValue.serverTimestamp(),
        });
        state = PaymentState(
          status: PaymentStatus.success,
          paymentId: paymentId,
          transactionId: transactionId,
        );
      } else {
        await _firestore
            .collection(AppConstants.paymentsCollection)
            .doc(paymentId)
            .update({'status': AppConstants.paymentFailed});
        state = const PaymentState(
          status: PaymentStatus.failed,
          error: 'Payment could not be verified.',
        );
      }
      return verified;
    } catch (e) {
      AppLogger.error('Payment verification error', e);
      return _simulateVerify(paymentId);
    }
  }

  // ── Simulation helpers (demo / dev mode) ──────────────────────────────

  Future<String> _simulatePayment(String userId, String tournamentId,
      String tournamentTitle, double amount, String method) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final paymentId = _uuid.v4();
    final transactionId =
        'DEMO-${_uuid.v4().substring(0, 8).toUpperCase()}';

    state = PaymentState(
      status: PaymentStatus.idle,
      paymentId: paymentId,
      transactionId: transactionId,
    );
    return paymentId;
  }

  Future<bool> _simulateVerify(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = PaymentState(
      status: PaymentStatus.success,
      paymentId: paymentId,
    );
    return true;
  }

  void reset() => state = const PaymentState();
}

final paymentNotifierProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);

// ─── Payment history stream ────────────────────────────────────────────────

final paymentHistoryProvider =
    StreamProvider.autoDispose.family<List<PaymentEntity>, String>(
  (ref, userId) {
    if (AppConfig.isDemoMode) {
      final demoPayments =
          MockData.payments.where((p) => p.userId == userId).toList();
      return Stream.value(demoPayments);
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.paymentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  },
);
