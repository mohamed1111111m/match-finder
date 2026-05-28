import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/team_entity.dart';
import '../providers/team_provider.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(teamSportFilterProvider);
    final teams     = ref.watch(filteredTeamsProvider);
    final isLoading = ref.watch(teamsLoadingProvider);
    final user      = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الفرق')),
      body: Column(
        children: [
          // Sport filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _Chip(label: 'الكل',    value: 'all',        selected: filter == 'all',        ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '⚽ كورة', value: 'football',   selected: filter == 'football',   ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '🎾 بادل', value: 'padel',      selected: filter == 'padel',      ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '🏀 سلة',  value: 'basketball', selected: filter == 'basketball', ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(teamsProvider);
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: teams.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_outlined,
                                        size: 64, color: AppColors.textMuted),
                                    SizedBox(height: 12),
                                    Text('مفيش فرق في الوقت ده',
                                        style: TextStyle(
                                            color: AppColors.textMuted, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: teams.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) =>
                                _TeamTile(team: teams[i], userId: user?.uid ?? '')
                                    .animate(delay: (i * 50).ms)
                                    .fadeIn()
                                    .slideY(begin: 0.05),
                          ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teams/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إنشاء فريق', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final WidgetRef ref;
  const _Chip({required this.label, required this.value, required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ref.read(teamSportFilterProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.secondary : Theme.of(context).colorScheme.outline),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          )),
      ),
    );
  }
}

// ── Team tile ────────────────────────────────────────────────────────────────

class _TeamTile extends ConsumerWidget {
  final TeamEntity team;
  final String userId;
  const _TeamTile({required this.team, required this.userId});

  Color _sportColor(String s) {
    switch (s) {
      case 'football':   return AppColors.football;
      case 'padel':      return AppColors.padel;
      case 'basketball': return AppColors.basketball;
      default:           return AppColors.primary;
    }
  }

  IconData _sportIcon(String s) {
    switch (s) {
      case 'football':   return Icons.sports_soccer;
      case 'padel':      return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball;
      default:           return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = _sportColor(team.sport);
    final isMember  = team.isMember(userId);
    final isCaptain = team.isCaptain(userId);

    return GestureDetector(
      onTap: () => context.push('/teams/${team.id}'),
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Sport badge
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.withValues(alpha: 0.85), c.withValues(alpha: 0.4)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_sportIcon(team.sport), color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(team.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (isCaptain)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.rankGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('قائد',
                                style: TextStyle(fontSize: 11, color: AppColors.rankGold,
                                  fontWeight: FontWeight.w700)),
                            )
                          else if (isMember)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('عضو',
                                style: TextStyle(fontSize: 11, color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${team.sportAr} • ${team.city}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _StatBadge(label: 'فوز', value: '${team.wins}', color: AppColors.primary),
                const SizedBox(width: 8),
                _StatBadge(label: 'هزيمة', value: '${team.losses}', color: AppColors.error),
                const SizedBox(width: 8),
                _StatBadge(label: 'تعادل', value: '${team.draws}', color: AppColors.textMuted),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${team.points} نقطة',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                    Text('${team.playerIds.length}/${team.teamSize} لاعب',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Join button
            if (!isMember && !team.isFull)
              SizedBox(
                width: double.infinity,
                child: _JoinButton(team: team, userId: userId),
              )
            else if (team.isFull && !isMember)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: const Text('الفريق مكتمل',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
          ],
        ),
      ),
    ));
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _JoinButton extends ConsumerStatefulWidget {
  final TeamEntity team;
  final String userId;
  const _JoinButton({required this.team, required this.userId});

  @override
  ConsumerState<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<_JoinButton> {
  bool _loading = false;

  Future<void> _join() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    final ok = await ref.read(teamsProvider.notifier)
        .joinTeam(widget.team.id, user.uid, user.displayName ?? user.username);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انضممت لفريق ${widget.team.name}! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _join,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 42),
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _loading
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('انضم للفريق', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
