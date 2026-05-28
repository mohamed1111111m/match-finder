import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  TournamentRepositoryImpl({
    required TournamentRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await _remote.getTournaments(
        statusFilter: statusFilter,
        searchQuery: searchQuery,
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('getTournaments repo error', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, TournamentEntity>> watchTournament(
      String tournamentId) async* {
    try {
      yield* _remote.watchTournament(tournamentId).map((t) => Right(t));
    } on NotFoundException {
      yield const Left(ServerFailure('Tournament not found'));
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentById(
      String tournamentId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await _remote.getTournamentById(tournamentId);
      return Right(result);
    } on NotFoundException {
      return const Left(ServerFailure('Tournament not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinTournament({
    required String tournamentId,
    required String userId,
    required String? paymentId,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.joinTournament(tournamentId, userId, paymentId);
      return const Right(unit);
    } on ServerException catch (e) {
      if (e.message.contains('full')) return const Left(TournamentFullFailure());
      if (e.message.contains('Already')) return const Left(AlreadyJoinedFailure());
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createTournament(
      TournamentEntity tournament) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final id = await _remote.createTournament(tournament);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTournament(
      TournamentEntity tournament) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.updateTournament(tournament);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTournament(String tournamentId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.deleteTournament(tournamentId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateParticipantStatus({
    required String tournamentId,
    required String userId,
    required bool approved,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.updateParticipantStatus(tournamentId, userId, approved);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getUserTournaments(
      String userId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await _remote.getUserTournaments(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
