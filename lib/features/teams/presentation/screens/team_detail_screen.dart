import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/entities/team_challenge_entity.dart';
import '../providers/challenge_provider.dart';
import '../providers/team_provider.dart';
import 'team_chat_screen.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);
    final isLoading = ref.watch(teamsLoadingProvider);
    final teamOrNull = teams.cast<TeamEntity?>()
        .firstWhere((t) => t?.id == teamId, orElse: () => null);

    if (teamOrNull == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text('الفريق مش موجود'),
        ),
      );
    }
    final team = teamOrNull;
    final user = ref.watch(currentUserProvider);
    final challenges = ref.watch(teamChallengesProvider(teamId));
    final pending = ref.watch(pendingChallengesProvider(teamId));

    final isMember  = user != null && team.isMember(user.uid);
    final isCaptain = user != null && team.isCaptain(user.uid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _tierColor(team.rankTier),
                      _tierColor(team.rankTier).withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white24,
                        child: Text(team.name[0],
                          style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900,
                            color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      Text(team.name,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      _TierBadge(tier: team.rankTier),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    _StatBox('فوز', '${team.wins}', AppColors.primary),
                    const SizedBox(width: 8),
                    _StatBox('هزيمة', '${team.losses}', AppColors.error),
                    const SizedBox(width: 8),
                    _StatBox('تعادل', '${team.draws}', AppColors.textMuted),
                    const SizedBox(width: 8),
                    _StatBox('نقاط', '${team.points}', _tierColor(team.rankTier)),
                  ],
                ).animate().fadeIn(),
                const SizedBox(height: 16),

                // Info row
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _InfoChip(Icons.sports, team.sportAr),
                    _InfoChip(Icons.location_city_outlined, team.city),
                    _InfoChip(Icons.people_outline,
                      '${team.playerIds.length}/${team.teamSize} لاعب'),
                  ],
                ).animate(delay: 60.ms).fadeIn(),
                const SizedBox(height: 16),

                if (team.description != null) ...[
                  Text(team.description!,
                    style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.6)),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 12),

                // Members section
                Row(
                  children: [
                    const Text('اللاعبين',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (isCaptain)
                      TextButton.icon(
                        onPressed: () => _showInviteDialog(context, team),
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('دعوة'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(team.playerNames.length, (i) {
                  final name = team.playerNames[i];
                  final uid  = team.playerIds[i];
                  final isCap = uid == team.captainId;
                  final isMe  = user?.uid == uid;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isCap
                          ? AppColors.rankGold.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.15),
                      child: Text(name[0],
                        style: TextStyle(
                          color: isCap ? AppColors.rankGold : AppColors.primary,
                          fontWeight: FontWeight.w700)),
                    ),
                    title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: isCap
                        ? const Text('قائد الفريق',
                            style: TextStyle(color: AppColors.rankGold, fontSize: 11))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMe)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline,
                              color: AppColors.secondary, size: 20),
                            onPressed: () => context.push(
                              '/chat/$uid?name=${Uri.encodeComponent(name)}'),
                          ),
                        if (isCaptain && !isMe && !isCap)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18,
                              color: AppColors.textMuted),
                            onSelected: (val) {
                              if (val == 'remove') {
                                _confirmRemovePlayer(context, ref, team, uid, name);
                              } else if (val == 'promote') {
                                _confirmPromoteCaptain(context, ref, team, uid, name);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'promote',
                                child: Row(children: [
                                  Icon(Icons.star_outline,
                                    color: AppColors.rankGold, size: 18),
                                  SizedBox(width: 8),
                                  Text('ارفعه قائد'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(children: [
                                  Icon(Icons.person_remove_outlined,
                                    color: AppColors.error, size: 18),
                                  SizedBox(width: 8),
                                  Text('أزله من الفريق',
                                    style: TextStyle(color: AppColors.error)),
                                ]),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Pending challenges (for captain)
                if (pending.isNotEmpty && isCaptain) ...[
                  Row(
                    children: [
                      const Text('تحديات واردة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                        child: Text('${pending.length}',
                          style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((c) => _ChallengeCard(
                    challenge: c, teamId: teamId, isCaptain: true)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                ],

                // All challenges history
                if (challenges.isNotEmpty) ...[
                  const Text('سجل التحديات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...challenges.map((c) => _ChallengeCard(
                    challenge: c, teamId: teamId, isCaptain: isCaptain)),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      // Action buttons
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (!isMember && !team.isFull) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _joinTeam(context, ref, team, user?.uid ?? ''),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('انضم للفريق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary),
                  ),
                ),
              ],
              if (isMember) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamChatScreen(team: team)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('دردشة الفريق'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendChallenge(context, ref, team),
                    icon: const Icon(Icons.sports_kabaddi_rounded, size: 18),
                    label: const Text('تحدّي فريق'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'ماسي':   return const Color(0xFF00BCD4);
      case 'بلاتين': return const Color(0xFF9C27B0);
      case 'ذهب':    return AppColors.rankGold;
      case 'فضة':    return AppColors.rankSilver;
      default:        return AppColors.rankBronze;
    }
  }

  Future<void> _confirmRemovePlayer(BuildContext context, WidgetRef ref,
      TeamEntity team, String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الإزالة',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هتشيل $name من الفريق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، شيله',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(teamsProvider.notifier).removePlayer(team.id, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إزالة $name من الفريق')));
      }
    }
  }

  Future<void> _confirmPromoteCaptain(BuildContext context, WidgetRef ref,
      TeamEntity team, String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ترقية قائد',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هتخلي $name هو القائد الجديد للفريق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، رقّيه',
                style: TextStyle(color: AppColors.rankGold)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(teamsProvider.notifier).updateCaptain(team.id, uid, name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name أصبح القائد الجديد ⭐')));
      }
    }
  }

  Future<void> _joinTeam(BuildContext context, WidgetRef ref,
      TeamEntity team, String userId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ok = await ref.read(teamsProvider.notifier)
        .joinTeam(team.id, user.uid, user.displayName ?? user.username);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انضممت لفريق ${team.name}! 🎉')));
    }
  }

  void _showInviteDialog(BuildContext context, TeamEntity team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('دعوة لاعب', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('شارك كود الانضمام ده مع اللاعب:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(team.id.substring(0, 8).toUpperCase(),
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  letterSpacing: 4, color: AppColors.primary)),
            ),
            const SizedBox(height: 8),
            const Text('اللاعب يدخل الكود في صفحة الفرق',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  void _sendChallenge(BuildContext context, WidgetRef ref, TeamEntity myTeam) {
    final teams = ref.read(teamsProvider)
        .where((t) => t.id != myTeam.id && t.sport == myTeam.sport)
        .toList();

    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مفيش فرق تانية في نفس الرياضة')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ChallengeSheet(
        myTeam: myTeam, opponents: teams, ref: ref),
    );
  }
}

// ── Tier badge ────────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  Color _c(String t) {
    switch (t) {
      case 'ماسي':   return const Color(0xFF00BCD4);
      case 'بلاتين': return const Color(0xFF9C27B0);
      case 'ذهب':    return AppColors.rankGold;
      case 'فضة':    return AppColors.rankSilver;
      default:        return AppColors.rankBronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text('⭐ $tier',
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Challenge card ────────────────────────────────────────────────────────────

class _ChallengeCard extends ConsumerWidget {
  final TeamChallengeEntity challenge;
  final String teamId;
  final bool isCaptain;
  const _ChallengeCard({
    required this.challenge, required this.teamId, required this.isCaptain});

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':  return AppColors.warning;
      case 'accepted': return AppColors.primary;
      case 'declined': return AppColors.error;
      case 'done':     return AppColors.textMuted;
      default:         return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChallenger = challenge.challengerTeamId == teamId;
    final otherName = isChallenger
        ? challenge.challengedTeamName
        : challenge.challengerTeamName;
    final sc = _statusColor(challenge.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_kabaddi_rounded, size: 16, color: sc),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isChallenger
                      ? 'تحدّيت فريق $otherName'
                      : 'فريق $otherName تحدّاك',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(challenge.statusAr,
                  style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (challenge.message != null) ...[
            const SizedBox(height: 4),
            Text(challenge.message!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          // Accept/decline if pending and this team was challenged
          if (challenge.isPending && !isChallenger && isCaptain) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(challengesProvider.notifier)
                        .respond(challenge.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(challengesProvider.notifier)
                        .respond(challenge.id, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36)),
                    child: const Text('قبول'),
                  ),
                ),
              ],
            ),
          ],
          // Record result if accepted and captain
          if (challenge.isAccepted && isCaptain) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _recordResult(context, ref),
                icon: const Icon(Icons.emoji_events_outlined, size: 16),
                label: const Text('سجّل النتيجة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  backgroundColor: AppColors.rankGold,
                  foregroundColor: Colors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _recordResult(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('مين اتكسب؟',
          style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultBtn(challenge.challengerTeamName, () {
              Navigator.pop(ctx);
              ref.read(challengesProvider.notifier)
                  .recordResult(challenge.id, challenge.challengerTeamId);
            }),
            const SizedBox(height: 8),
            _ResultBtn(challenge.challengedTeamName, () {
              Navigator.pop(ctx);
              ref.read(challengesProvider.notifier)
                  .recordResult(challenge.id, challenge.challengedTeamId);
            }),
          ],
        ),
      ),
    );
  }
}

class _ResultBtn extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ResultBtn(this.name, this.onTap);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
        child: Text(name),
      ),
    );
  }
}

// ── Challenge sheet ───────────────────────────────────────────────────────────

class _ChallengeSheet extends ConsumerStatefulWidget {
  final TeamEntity myTeam;
  final List<TeamEntity> opponents;
  final WidgetRef ref;
  const _ChallengeSheet({
    required this.myTeam, required this.opponents, required this.ref});
  @override
  ConsumerState<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends ConsumerState<_ChallengeSheet> {
  TeamEntity? _selected;
  final _msgCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_selected == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    await ref.read(challengesProvider.notifier).sendChallenge(
      challenger: widget.myTeam,
      challenged: _selected!,
      createdBy: user.uid,
      message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال التحدي لفريق ${_selected!.name}! ⚔️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('تحدّي فريق ⚔️',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('اختار الفريق',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          ...widget.opponents.map((t) => GestureDetector(
            onTap: () => setState(() => _selected = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selected?.id == t.id
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selected?.id == t.id
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.outline,
                  width: _selected?.id == t.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${t.points} نقطة • ${t.rankTier}',
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (_selected?.id == t.id)
                    const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            decoration: const InputDecoration(
              hintText: 'رسالة اختيارية...',
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selected == null || _loading ? null : _send,
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Text('إرسال التحدي'),
          ),
        ],
      ),
    );
  }
}
