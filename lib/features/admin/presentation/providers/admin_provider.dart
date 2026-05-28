import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../tournaments/domain/entities/tournament_entity.dart';
import '../../../tournaments/domain/repositories/tournament_repository.dart';
import '../../../tournaments/presentation/providers/tournament_provider.dart';

// ─── Dashboard stats ───────────────────────────────────────────────────────

class DashboardStats {
  final int totalUsers;
  final int totalTournaments;
  final double totalRevenue;
  final int activeTournaments;

  const DashboardStats({
    this.totalUsers = 0,
    this.totalTournaments = 0,
    this.totalRevenue = 0,
    this.activeTournaments = 0,
  });
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  if (AppConfig.isDemoMode) {
    return DashboardStats(
      totalUsers: 2,
      totalTournaments: MockData.tournaments.length,
      totalRevenue:
          MockData.payments.fold(0.0, (sum, p) => sum + p.amount),
      activeTournaments:
          MockData.tournaments.where((t) => t.status == 'live').length,
    );
  }

  final firestore = FirebaseFirestore.instance;

  final results = await Future.wait([
    firestore.collection(AppConstants.usersCollection).count().get(),
    firestore.collection(AppConstants.tournamentsCollection).count().get(),
    firestore
        .collection(AppConstants.tournamentsCollection)
        .where('status', isEqualTo: 'live')
        .count()
        .get(),
    firestore
        .collection(AppConstants.paymentsCollection)
        .where('status', isEqualTo: 'completed')
        .get(),
  ]);

  final userCount = (results[0] as AggregateQuerySnapshot).count ?? 0;
  final tournamentCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
  final activeCount = (results[2] as AggregateQuerySnapshot).count ?? 0;
  final paymentSnap = results[3] as QuerySnapshot;
  final revenue = paymentSnap.docs.fold<double>(
    0,
    (sum, doc) =>
        sum + ((doc.data() as Map)['amount'] as num? ?? 0).toDouble(),
  );

  return DashboardStats(
    totalUsers: userCount,
    totalTournaments: tournamentCount,
    totalRevenue: revenue,
    activeTournaments: activeCount,
  );
});

// ─── Admin users stream ────────────────────────────────────────────────────

final adminUsersProvider = StreamProvider.autoDispose<List<UserEntity>>((ref) {
  if (AppConfig.isDemoMode) {
    return Stream.value([MockData.demoUser, MockData.demoAdmin]);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
});

// ─── Admin payments stream ─────────────────────────────────────────────────

final adminPaymentsProvider =
    StreamProvider.autoDispose<List<PaymentEntity>>((ref) {
  if (AppConfig.isDemoMode) {
    return Stream.value(MockData.payments);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.paymentsCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
});

// ─── Create tournament notifier ────────────────────────────────────────────

class CreateTournamentState {
  final bool isLoading;
  final bool success;
  final String? error;
  final String? createdId;
  const CreateTournamentState(
      {this.isLoading = false,
      this.success = false,
      this.error,
      this.createdId});
}

class CreateTournamentNotifier extends StateNotifier<CreateTournamentState> {
  final TournamentRepository _repository;

  CreateTournamentNotifier(this._repository)
      : super(const CreateTournamentState());

  Future<bool> create(TournamentEntity tournament) async {
    state = const CreateTournamentState(isLoading: true);
    final result = await _repository.createTournament(tournament);
    return result.fold(
      (failure) {
        AppLogger.error('Create tournament failed', failure.message);
        state = CreateTournamentState(error: failure.message);
        return false;
      },
      (id) {
        state = CreateTournamentState(success: true, createdId: id);
        return true;
      },
    );
  }
}

final createTournamentProvider = StateNotifierProvider.autoDispose<
    CreateTournamentNotifier, CreateTournamentState>(
  (ref) =>
      CreateTournamentNotifier(ref.watch(tournamentRepositoryProvider)),
);

// ─── User management notifier ──────────────────────────────────────────────

class UserManagementNotifier extends StateNotifier<bool> {
  UserManagementNotifier() : super(false);

  Future<void> banUser(String userId) async {
    if (AppConfig.isDemoMode) return;
    state = true;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(
              {'banned': true, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.error('Ban user failed', e);
    } finally {
      state = false;
    }
  }

  Future<void> makeAdmin(String userId) async {
    if (AppConfig.isDemoMode) return;
    state = true;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Make admin failed', e);
    } finally {
      state = false;
    }
  }

  Future<void> removeAdmin(String userId) async {
    if (AppConfig.isDemoMode) return;
    state = true;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'role': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Remove admin failed', e);
    } finally {
      state = false;
    }
  }
}

final userManagementProvider =
    StateNotifierProvider.autoDispose<UserManagementNotifier, bool>(
  (ref) => UserManagementNotifier(),
);
