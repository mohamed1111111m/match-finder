import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../../teams/presentation/providers/challenge_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../../domain/entities/tournament_entity.dart';
import '../providers/tournament_provider.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String? _statusFilter;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(tournamentsNotifierProvider.notifier).loadMore();
    }
  }

  void _setFilter(String? status) {
    setState(() => _statusFilter = status);
    ref
        .read(tournamentsNotifierProvider.notifier)
        .load(filter: TournamentFilter(statusFilter: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البطولات'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Cairo'),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 12, fontFamily: 'Cairo'),
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_outlined, size: 17), text: 'البطولات'),
            Tab(icon: Icon(Icons.leaderboard_outlined,  size: 17), text: 'الترتيب'),
            Tab(icon: Icon(Icons.sports_soccer,         size: 17), text: 'المباريات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TournamentsTab(
            statusFilter: _statusFilter,
            setFilter: _setFilter,
            scrollCtrl: _scrollCtrl,
          ),
          const _LeaderboardTab(),
          const _MatchesTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Tournaments
// ══════════════════════════════════════════════════════════════════════════════

class _TournamentsTab extends ConsumerWidget {
  final String? statusFilter;
  final ValueChanged<String?> setFilter;
  final ScrollController scrollCtrl;
  const _TournamentsTab(
      {required this.statusFilter,
      required this.setFilter,
      required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentsNotifierProvider);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _Chip(
                label: 'الكل',
                selected: statusFilter == null,
                onTap: () => setFilter(null)),
            const SizedBox(width: 8),
            _Chip(
                label: 'قادمة',
                selected: statusFilter == 'upcoming',
                color: AppColors.info,
                onTap: () => setFilter('upcoming')),
            const SizedBox(width: 8),
            _Chip(
                label: 'مباشر',
                selected: statusFilter == 'live',
                color: AppColors.error,
                onTap: () => setFilter('live')),
            const SizedBox(width: 8),
            _Chip(
                label: 'منتهية',
                selected: statusFilter == 'finished',
                color: AppColors.textMuted,
                onTap: () => setFilter('finished')),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : state.error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(state.error!,
                              style: const TextStyle(
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(tournamentsNotifierProvider.notifier)
                                .refresh(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : state.tournaments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('مفيش بطولات دلوقتي',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 15)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref
                              .read(tournamentsNotifierProvider.notifier)
                              .refresh(),
                          child: ListView.separated(
                            controller: scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            itemCount: state.tournaments.length +
                                (state.isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              if (i == state.tournaments.length) {
                                return const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ));
                              }
                              return _TournamentTile(
                                tournament: state.tournaments[i],
                                onTap: () => ctx.push(
                                    '/tournaments/${state.tournaments[i].id}'),
                              )
                                  .animate(delay: (i * 50).ms)
                                  .fadeIn()
                                  .slideY(begin: 0.05);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Leaderboard
// ══════════════════════════════════════════════════════════════════════════════

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(leaderboardTeamsProvider);

    if (teams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('مفيش فرق في الترتيب دلوقتي',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (teams.length >= 3)
          SliverToBoxAdapter(
            child: _Podium(top3: teams.take(3).toList()),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              SizedBox(width: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text('الفريق',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ),
              SizedBox(
                width: 36,
                child: Text('فوز',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ),
              SizedBox(
                width: 60,
                child: Text('النقاط',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final offset = teams.length >= 3 ? 3 : 0;
                final team   = teams[i + offset];
                final rank   = i + offset + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TeamRow(team: team, rank: rank)
                      .animate(delay: (i * 40).ms)
                      .fadeIn()
                      .slideX(begin: 0.05),
                );
              },
              childCount: teams.length >= 3 ? teams.length - 3 : teams.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — Live Matches (accepted + done challenges)
// ══════════════════════════════════════════════════════════════════════════════

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(challengesProvider);
    final matches = all
        .where((c) => c.isAccepted || c.isDone)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('مفيش مباريات جارية دلوقتي',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            SizedBox(height: 8),
            Text('ابعت تحدي لفريق وابدأ المباراة',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final c      = matches[i];
        final isLive = c.isAccepted;
        final isDone = c.isDone;
        final liveColor = isLive ? AppColors.error : AppColors.textMuted;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLive
                  ? AppColors.error.withValues(alpha: 0.35)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            children: [
              // ── header ─────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: liveColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Row(children: [
                  Icon(
                    isLive
                        ? Icons.radio_button_checked
                        : Icons.check_circle_outline,
                    size: 14,
                    color: liveColor,
                  ),
                  const SizedBox(width: 6),
                  Text(isLive ? 'مباشر الآن' : 'انتهت',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: liveColor)),
                  const Spacer(),
                  Text(
                    c.sport == 'football'
                        ? '⚽ كورة قدم'
                        : c.sport == 'padel'
                            ? '🎾 بادل'
                            : '🏀 سلة',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ]),
              ),

              // ── teams row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Challenger
                  Expanded(
                    child: Column(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(c.challengerTeamName[0],
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20)),
                      ),
                      const SizedBox(height: 6),
                      Text(c.challengerTeamName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      if (isDone && c.winnerId == c.challengerTeamId)
                        const Text('🏆 فائز',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.rankGold,
                                fontWeight: FontWeight.w700)),
                    ]),
                  ),

                  // VS / pulsing dot
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(children: [
                      Text(isDone ? 'FT' : 'VS',
                          style: TextStyle(
                              fontSize: isLive ? 22 : 16,
                              fontWeight: FontWeight.w900,
                              color: isLive
                                  ? AppColors.error
                                  : AppColors.textMuted)),
                      if (isLive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fadeOut(duration: 700.ms)
                            .then()
                            .fadeIn(duration: 700.ms),
                    ]),
                  ),

                  // Challenged
                  Expanded(
                    child: Column(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.15),
                        child: Text(c.challengedTeamName[0],
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20)),
                      ),
                      const SizedBox(height: 6),
                      Text(c.challengedTeamName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      if (isDone && c.winnerId == c.challengedTeamId)
                        const Text('🏆 فائز',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.rankGold,
                                fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),

              // ── location / time ────────────────────────────────────────
              if (c.location != null || c.proposedTime != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(children: [
                    if (c.location != null) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(c.location!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                    if (c.proposedTime != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(c.proposedTime!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ]),
                ),
            ],
          ),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : Theme.of(context).colorScheme.outline),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }
}

// ── Tournament tile ───────────────────────────────────────────────────────────

class _TournamentTile extends StatelessWidget {
  final TournamentEntity tournament;
  final VoidCallback onTap;
  const _TournamentTile({required this.tournament, required this.onTap});

  Color _sc(String s) {
    switch (s) {
      case 'live':      return AppColors.error;
      case 'upcoming':  return AppColors.info;
      case 'finished':  return AppColors.textMuted;
      case 'cancelled': return AppColors.warning;
      default:          return AppColors.primary;
    }
  }

  String _sar(String s) {
    switch (s) {
      case 'live':      return '🔴 مباشر';
      case 'upcoming':  return '🔜 قادمة';
      case 'finished':  return '✅ منتهية';
      case 'cancelled': return '❌ ملغية';
      default:          return s;
    }
  }

  String _fd(DateTime d) {
    const m = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final sc = _sc(tournament.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.rankGold, size: 18),
              const SizedBox(width: 6),
              Text(tournament.game,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_sar(tournament.status),
                    style: TextStyle(
                        color: sc,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tournament.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                        '${_fd(tournament.startDate)} — ${_fd(tournament.endDate)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    Text(tournament.format,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tournament.fillPercentage,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                        '${tournament.currentParticipants}/${tournament.maxParticipants} مشارك',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const Spacer(),
                    if (tournament.isFree)
                      const Text('مجاني',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary))
                    else
                      Text('رسوم ${tournament.entryFee.toInt()} ج',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    if (tournament.prizePool > 0) ...[
                      const Text('  •  ',
                          style:
                              TextStyle(color: AppColors.textMuted)),
                      Text('جائزة ${tournament.prizePool.toInt()} ج',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rankGold)),
                    ],
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<TeamEntity> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1)
            Expanded(
              child: _PodiumItem(
                      team: top3[1],
                      rank: 2,
                      height: 90,
                      medalColor: AppColors.rankSilver)
                  .animate(delay: 150.ms)
                  .fadeIn()
                  .slideY(begin: 0.2),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumItem(
                    team: top3[0],
                    rank: 1,
                    height: 120,
                    medalColor: AppColors.rankGold)
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
          ),
          const SizedBox(width: 8),
          if (top3.length > 2)
            Expanded(
              child: _PodiumItem(
                      team: top3[2],
                      rank: 3,
                      height: 70,
                      medalColor: AppColors.rankBronze)
                  .animate(delay: 250.ms)
                  .fadeIn()
                  .slideY(begin: 0.3),
            ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final TeamEntity team;
  final int rank;
  final double height;
  final Color medalColor;
  const _PodiumItem(
      {required this.team,
      required this.rank,
      required this.height,
      required this.medalColor});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28,
        height: 28,
        decoration:
            BoxDecoration(color: medalColor, shape: BoxShape.circle),
        child: Center(
          child: Text('$rank',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
      ),
      const SizedBox(height: 6),
      CircleAvatar(
        radius: rank == 1 ? 30 : 24,
        backgroundColor: medalColor.withValues(alpha: 0.2),
        child: Text(team.name[0],
            style: TextStyle(
                color: medalColor,
                fontWeight: FontWeight.w800,
                fontSize: rank == 1 ? 22 : 18)),
      ),
      const SizedBox(height: 6),
      Text(team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: rank == 1 ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: medalColor)),
      Text('${team.points} نقطة',
          style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted)),
      const SizedBox(height: 8),
      Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              medalColor.withValues(alpha: 0.7),
              medalColor.withValues(alpha: 0.3)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Text('${team.wins}W',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

// ── Team row (rank 4+) ────────────────────────────────────────────────────────

class _TeamRow extends StatelessWidget {
  final TeamEntity team;
  final int rank;
  const _TeamRow({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text('#$rank',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(team.name[0],
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(team.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text('${team.sportAr} • ${team.city}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        SizedBox(
          width: 36,
          child: Text('${team.wins}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${team.points}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
        ),
      ]),
    );
  }
}
