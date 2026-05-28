import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/tournament_entity.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_status_badge.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return tournamentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(message: 'Loading tournament...'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(tournamentDetailProvider(tournamentId)),
        ),
      ),
      data: (tournament) => _TournamentDetailContent(tournament: tournament),
    );
  }
}

class _TournamentDetailContent extends ConsumerWidget {
  final TournamentEntity tournament;
  const _TournamentDetailContent({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isParticipant =
        user != null && tournament.isParticipant(user.uid);
    final isPending =
        user != null && tournament.isPendingApproval(user.uid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible app bar with cover image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tournament.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              background: tournament.imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: tournament.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.5)),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(Icons.emoji_events,
                            color: Colors.black38, size: 80),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Game
                  Row(
                    children: [
                      TournamentStatusBadge(status: tournament.status),
                      const SizedBox(width: 8),
                      _InfoChip(tournament.game, Icons.sports_esports),
                      const SizedBox(width: 8),
                      _InfoChip(tournament.format, Icons.group),
                    ],
                  ).animate().fadeIn(),

                  const SizedBox(height: 20),

                  // Stats grid
                  _StatsGrid(tournament: tournament)
                      .animate()
                      .fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // Description
                  Text('عن البطولة',
                      style: context.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    tournament.description,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.6),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Schedule
                  Text('المواعيد',
                      style: context.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _ScheduleRow(
                    label: 'البداية',
                    date: tournament.startDate.formattedDateTime,
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _ScheduleRow(
                    label: 'النهاية',
                    date: tournament.endDate.formattedDateTime,
                    icon: Icons.stop_circle_outlined,
                    color: AppColors.error,
                  ),

                  const SizedBox(height: 24),

                  // Participants progress
                  Text('المشاركين',
                      style: context.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${tournament.currentParticipants} / ${tournament.maxParticipants}',
                        style: context.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        tournament.isFull ? 'مكتملة' : 'أماكن متاحة',
                        style: TextStyle(
                          color: tournament.isFull
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: tournament.fillPercentage,
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
                      valueColor: AlwaysStoppedAnimation(
                        tournament.isFull ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: _buildBottomBar(
          context, user, isParticipant, isPending),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, UserEntity? user, bool isParticipant, bool isPending) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16).copyWith(
          bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          // Price column
          if (!tournament.isFree) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رسوم الاشتراك',
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(
                  tournament.entryFee.egpShort,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],

          // Join / status button
          Expanded(
            child: _JoinButton(
              tournament: tournament,
              userId: user.uid,
              isParticipant: isParticipant,
              isPending: isPending,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends ConsumerWidget {
  final TournamentEntity tournament;
  final String userId;
  final bool isParticipant;
  final bool isPending;

  const _JoinButton({
    required this.tournament,
    required this.userId,
    required this.isParticipant,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isParticipant) {
      return AppButton(
        label: 'مشترك بالفعل',
        onPressed: null,
        icon: Icons.check_circle_outline,
        backgroundColor: AppColors.success.withValues(alpha:0.2),
        foregroundColor: AppColors.success,
      );
    }

    if (isPending) {
      return AppButton(
        label: 'في انتظار القبول',
        onPressed: null,
        icon: Icons.hourglass_empty,
        backgroundColor: AppColors.warning.withValues(alpha:0.2),
        foregroundColor: AppColors.warning,
      );
    }

    if (!tournament.isJoinable) {
      return AppButton(
        label: tournament.isFull ? 'البطولة مكتملة' : 'مغلقة',
        onPressed: null,
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textSecondary,
      );
    }

    final joinState = ref.watch(joinTournamentProvider(tournament.id));

    return AppButton(
      label: tournament.isFree ? 'اشترك مجاناً' : 'اشترك والدفع',
      onPressed: joinState.isLoading
          ? null
          : () => _handleJoin(context, ref),
      isLoading: joinState.isLoading,
      icon: tournament.isFree ? Icons.sports_esports : Icons.payment,
    );
  }

  Future<void> _handleJoin(BuildContext context, WidgetRef ref) async {
    if (tournament.isFree) {
      final notifier = ref.read(joinTournamentProvider(tournament.id).notifier);
      final success = await notifier.join(tournament.id, userId);
      if (success && context.mounted) {
        context.showSnackBar('تم الاشتراك في البطولة بنجاح!');
      } else if (context.mounted) {
        final err = ref.read(joinTournamentProvider(tournament.id)).error;
        context.showSnackBar(err ?? 'فشل الاشتراك، حاول مرة أخرى', isError: true);
      }
    } else {
      // Navigate to payment screen
      context.push('/payment/${tournament.id}');
    }
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final TournamentEntity tournament;
  const _StatsGrid({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatItem(
          label: 'جائزة البطولة',
          value: tournament.prizePool.egpShort,
          icon: Icons.emoji_events,
          color: AppColors.accent,
        ),
        _StatItem(
          label: 'رسوم الاشتراك',
          value: tournament.isFree ? 'مجاني' : tournament.entryFee.egpShort,
          icon: Icons.payment,
          color: tournament.isFree ? AppColors.success : AppColors.primary,
        ),
        _StatItem(
          label: 'النظام',
          value: tournament.format,
          icon: Icons.group,
          color: AppColors.secondary,
        ),
        _StatItem(
          label: 'الرياضة',
          value: tournament.game,
          icon: Icons.sports_esports,
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final Color color;

  const _ScheduleRow(
      {required this.label,
      required this.date,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text('$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        Text(date,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
