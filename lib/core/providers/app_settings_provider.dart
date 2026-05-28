import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../config/payment_config.dart';

// ── App settings model ─────────────────────────────────────────────────────

class AppSettings {
  final double commissionPercent;

  const AppSettings({required this.commissionPercent});

  factory AppSettings.defaults() =>
      const AppSettings(commissionPercent: PaymentConfig.commissionPercent);

  factory AppSettings.fromMap(Map<String, dynamic> data) => AppSettings(
        commissionPercent:
            (data['commissionPercent'] as num?)?.toDouble() ??
                PaymentConfig.commissionPercent,
      );

  double applyCommission(double base) => base + (base * commissionPercent / 100);
  double commissionAmount(double base) => base * commissionPercent / 100;
}

// ── Provider ───────────────────────────────────────────────────────────────

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.settingsCollection)
      .doc('app')
      .snapshots()
      .map((snap) => snap.exists && snap.data() != null
          ? AppSettings.fromMap(snap.data()!)
          : AppSettings.defaults());
});

// ── Notifier for admin writes ──────────────────────────────────────────────

class AppSettingsNotifier extends StateNotifier<bool> {
  AppSettingsNotifier() : super(false);

  Future<void> setCommission(double percent) async {
    state = true;
    await FirebaseFirestore.instance
        .collection(AppConstants.settingsCollection)
        .doc('app')
        .set({'commissionPercent': percent}, SetOptions(merge: true));
    state = false;
  }
}

final appSettingsNotifierProvider =
    StateNotifierProvider<AppSettingsNotifier, bool>(
  (ref) => AppSettingsNotifier(),
);
