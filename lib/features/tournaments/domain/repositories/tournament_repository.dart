import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/tournament_entity.dart';

abstract class TournamentRepository {
  /// Paginated tournament list with optional status filter and search query.
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
    String? lastDocumentId,
  });

  /// Real-time stream of a single tournament.
  Stream<Either<Failure, TournamentEntity>> watchTournament(String tournamentId);

  /// Get a single tournament by ID.
  Future<Either<Failure, TournamentEntity>> getTournamentById(String tournamentId);

  /// Join a tournament (free or after payment).
  Future<Either<Failure, Unit>> joinTournament({
    required String tournamentId,
    required String userId,
    required String? paymentId, // null if free
  });

  /// Admin: create tournament.
  Future<Either<Failure, String>> createTournament(TournamentEntity tournament);

  /// Admin: update tournament.
  Future<Either<Failure, Unit>> updateTournament(TournamentEntity tournament);

  /// Admin: delete tournament.
  Future<Either<Failure, Unit>> deleteTournament(String tournamentId);

  /// Admin: approve or reject a pending participant.
  Future<Either<Failure, Unit>> updateParticipantStatus({
    required String tournamentId,
    required String userId,
    required bool approved,
  });

  /// Get tournaments a specific user has joined.
  Future<Either<Failure, List<TournamentEntity>>> getUserTournaments(String userId);
}
