import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/repositories/tournament_repository.dart';

class DemoTournamentRepository implements TournamentRepository {
  // Local mutable copy so join/update work within the session
  final List<TournamentEntity> _tournaments =
      List.from(MockData.tournaments);

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var result = List<TournamentEntity>.from(_tournaments);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      result = result.where((t) => t.status == statusFilter).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.game.toLowerCase().contains(q))
          .toList();
    }
    return Right(result);
  }

  @override
  Stream<Either<Failure, TournamentEntity>> watchTournament(
      String tournamentId) async* {
    final t = _find(tournamentId);
    if (t == null) {
      yield const Left(ServerFailure('Tournament not found'));
    } else {
      yield Right(t);
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentById(
      String tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final t = _find(tournamentId);
    if (t == null) return const Left(ServerFailure('Tournament not found'));
    return Right(t);
  }

  @override
  Future<Either<Failure, Unit>> joinTournament({
    required String tournamentId,
    required String userId,
    required String? paymentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index == -1) return const Left(ServerFailure('Tournament not found'));

    final t = _tournaments[index];
    if (t.isFull) return const Left(TournamentFullFailure());
    if (t.isParticipant(userId)) return const Left(AlreadyJoinedFailure());

    _tournaments[index] = t.copyWith(
      participantIds: [...t.participantIds, userId],
      currentParticipants: t.currentParticipants + 1,
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, String>> createTournament(
      TournamentEntity tournament) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _tournaments.insert(0, tournament);
    return Right(tournament.id);
  }

  @override
  Future<Either<Failure, Unit>> updateTournament(
      TournamentEntity tournament) async {
    final index = _tournaments.indexWhere((t) => t.id == tournament.id);
    if (index != -1) _tournaments[index] = tournament;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteTournament(String tournamentId) async {
    _tournaments.removeWhere((t) => t.id == tournamentId);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateParticipantStatus({
    required String tournamentId,
    required String userId,
    required bool approved,
  }) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getUserTournaments(
      String userId) async {
    final result =
        _tournaments.where((t) => t.isParticipant(userId)).toList();
    return Right(result);
  }

  TournamentEntity? _find(String id) {
    try {
      return _tournaments.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
