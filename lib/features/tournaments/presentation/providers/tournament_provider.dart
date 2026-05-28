import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_info.dart';
import '../../data/datasources/tournament_remote_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/repositories/tournament_repository.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepositoryImpl(
    remote: TournamentRemoteDataSourceImpl(),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ─── Filter state ──────────────────────────────────────────────────────────

class TournamentFilter {
  final String? statusFilter;
  final String searchQuery;
  const TournamentFilter({this.statusFilter, this.searchQuery = ''});

  TournamentFilter copyWith({String? statusFilter, String? searchQuery}) {
    return TournamentFilter(
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final tournamentFilterProvider =
    StateProvider<TournamentFilter>((ref) => const TournamentFilter());

// ─── Tournament list with pagination ──────────────────────────────────────

class TournamentsState {
  final List<TournamentEntity> tournaments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const TournamentsState({
    this.tournaments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  TournamentsState copyWith({
    List<TournamentEntity>? tournaments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return TournamentsState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class TournamentsNotifier extends StateNotifier<TournamentsState> {
  final TournamentRepository _repository;
  String? _lastDocumentId;

  TournamentsNotifier(this._repository) : super(const TournamentsState()) {
    load();
  }

  TournamentFilter _currentFilter = const TournamentFilter();

  Future<void> load({TournamentFilter? filter}) async {
    if (filter != null) _currentFilter = filter;
    _lastDocumentId = null;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTournaments(
      statusFilter: _currentFilter.statusFilter,
      searchQuery: _currentFilter.searchQuery.isEmpty
          ? null
          : _currentFilter.searchQuery,
      lastDocumentId: null,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (tournaments) {
        _lastDocumentId = tournaments.isNotEmpty ? tournaments.last.id : null;
        state = state.copyWith(
          tournaments: tournaments,
          isLoading: false,
          hasMore: tournaments.length == 20,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _lastDocumentId == null) return;
    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getTournaments(
      statusFilter: _currentFilter.statusFilter,
      searchQuery: _currentFilter.searchQuery.isEmpty
          ? null
          : _currentFilter.searchQuery,
      lastDocumentId: _lastDocumentId,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false),
      (more) {
        _lastDocumentId = more.isNotEmpty ? more.last.id : null;
        state = state.copyWith(
          tournaments: [...state.tournaments, ...more],
          isLoadingMore: false,
          hasMore: more.length == 20,
        );
      },
    );
  }

  Future<void> refresh() => load();
}

final tournamentsNotifierProvider =
    StateNotifierProvider.autoDispose<TournamentsNotifier, TournamentsState>(
  (ref) {
    final repo = ref.watch(tournamentRepositoryProvider);
    return TournamentsNotifier(repo);
  },
);

// ─── Single tournament stream ──────────────────────────────────────────────

final tournamentDetailProvider =
    StreamProvider.autoDispose.family<TournamentEntity, String>(
  (ref, tournamentId) {
    final repo = ref.watch(tournamentRepositoryProvider);
    return repo.watchTournament(tournamentId).map((either) {
      return either.fold(
        (failure) => throw Exception(failure.message),
        (tournament) => tournament,
      );
    });
  },
);

// ─── Join tournament notifier ──────────────────────────────────────────────

class JoinTournamentState {
  final bool isLoading;
  final bool success;
  final String? error;
  const JoinTournamentState(
      {this.isLoading = false, this.success = false, this.error});
}

class JoinTournamentNotifier extends StateNotifier<JoinTournamentState> {
  final TournamentRepository _repository;
  JoinTournamentNotifier(this._repository)
      : super(const JoinTournamentState());

  Future<bool> join(String tournamentId, String userId,
      {String? paymentId}) async {
    state = const JoinTournamentState(isLoading: true);
    final result = await _repository.joinTournament(
      tournamentId: tournamentId,
      userId: userId,
      paymentId: paymentId,
    );
    return result.fold(
      (failure) {
        state = JoinTournamentState(error: failure.message);
        return false;
      },
      (_) {
        state = const JoinTournamentState(success: true);
        return true;
      },
    );
  }
}

final joinTournamentProvider = StateNotifierProvider.autoDispose
    .family<JoinTournamentNotifier, JoinTournamentState, String>(
  (ref, tournamentId) =>
      JoinTournamentNotifier(ref.watch(tournamentRepositoryProvider)),
);
