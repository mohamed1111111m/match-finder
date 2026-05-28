import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../../teams/presentation/providers/team_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(leaderboardTeamsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ترتيب الفرق')),
      body: teams.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('مفيش فرق في الترتيب دلوقتي',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Top 3 podium
                if (teams.length >= 3)
                  SliverToBoxAdapter(
                    child: _Podium(top3: teams.take(3).toList()),
                  ),

                // Header row
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        SizedBox(width: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('الفريق',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text('فوز',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text('النقاط',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
                ),

                // List (rank 4+)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final team = teams[i + (teams.length >= 3 ? 3 : 0)];
                        final rank = i + (teams.length >= 3 ? 4 : 1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TeamRow(team: team, rank: rank)
                              .animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.05),
                        );
                      },
                      childCount: teams.length >= 3 ? teams.length - 3 : teams.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Podium top 3 ─────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<TeamEntity> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1)
            Expanded(
              child: _PodiumItem(team: top3[1], rank: 2, height: 90,
                medalColor: AppColors.rankSilver)
                  .animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumItem(team: top3[0], rank: 1, height: 120,
              medalColor: AppColors.rankGold)
                .animate().fadeIn().slideY(begin: 0.1),
          ),
          const SizedBox(width: 8),
          if (top3.length > 2)
            Expanded(
              child: _PodiumItem(team: top3[2], rank: 3, height: 70,
                medalColor: AppColors.rankBronze)
                  .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
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
  const _PodiumItem({required this.team, required this.rank,
    required this.height, required this.medalColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal badge
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: medalColor, shape: BoxShape.circle),
          child: Center(
            child: Text('$rank',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),

        // Team avatar
        CircleAvatar(
          radius: rank == 1 ? 30 : 24,
          backgroundColor: medalColor.withValues(alpha: 0.2),
          child: Text(
            team.name[0],
            style: TextStyle(
              color: medalColor, fontWeight: FontWeight.w800,
              fontSize: rank == 1 ? 22 : 18),
          ),
        ),
        const SizedBox(height: 6),

        Text(team.name,
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: rank == 1 ? 13 : 11,
            fontWeight: FontWeight.w700, color: medalColor)),
        Text('${team.points} نقطة',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 8),

        // Podium block
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [medalColor.withValues(alpha: 0.7), medalColor.withValues(alpha: 0.3)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text('${team.wins}W',
              style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
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
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text('#$rank',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(team.name[0],
              style: const TextStyle(color: AppColors.primary,
                fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 12),

          // Name + city
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${team.sportAr} • ${team.city}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),

          // Wins
          SizedBox(
            width: 36,
            child: Text('${team.wins}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
          ),

          // Points
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${team.points}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
