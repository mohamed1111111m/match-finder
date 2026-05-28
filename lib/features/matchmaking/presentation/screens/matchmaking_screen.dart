import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/match_session_entity.dart';
import '../providers/matchmaking_provider.dart';
import 'session_chat_screen.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(sessionSportFilterProvider);
    final sessions  = ref.watch(filteredSessionsProvider);
    final isLoading = ref.watch(sessionsLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('دور لاعبين')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _Chip(label: 'الكل',      value: 'all',        selected: filter == 'all',        ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '⚽ كورة',  value: 'football',   selected: filter == 'football',   ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '🎾 بادل',  value: 'padel',      selected: filter == 'padel',      ref: ref),
                const SizedBox(width: 8),
                _Chip(label: '🏀 سلة',   value: 'basketball', selected: filter == 'basketball', ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: isLoading
                ? _ShimmerList()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(sessionsProvider);
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: sessions.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: _EmptyState(),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: sessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _SessionCard(session: sessions[i])
                                .animate(delay: (i * 50).ms)
                                .fadeIn()
                                .slideY(begin: 0.04),
                          ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/matchmaking/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب لاعبين +',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final WidgetRef ref;
  const _Chip({required this.label, required this.value,
    required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => ref.read(sessionSportFilterProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : cs.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.primary : cs.outline,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.black : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          )),
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends ConsumerWidget {
  final MatchSessionEntity session;
  const _SessionCard({required this.session});

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
    final cs = Theme.of(context).colorScheme;
    final user         = ref.watch(currentUserProvider);
    final c            = _sportColor(session.sport);
    final alreadyJoined = user != null && session.isPlayer(user.uid);
    final isCreator    = user != null && session.creatorId == user.uid;
    final progress     = session.currentPlayers / session.totalPlayers;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: c,
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20)),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Creator row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: c.withValues(alpha: 0.2),
                          child: Text(
                            session.creatorName.isNotEmpty
                                ? session.creatorName[0].toUpperCase()
                                : '؟',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: c,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(session.creatorName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: session.isOpen
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            session.isOpen
                                ? 'فاضل ${session.spotsLeft} مكان'
                                : 'اكتمل',
                            style: TextStyle(
                              color: session.isOpen
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Sport label
                    Row(
                      children: [
                        Icon(_sportIcon(session.sport), color: c, size: 14),
                        const SizedBox(width: 4),
                        Text(session.sportAr,
                            style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(session.location,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${session.dateText} • ${session.time}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                        const Spacer(),
                        if (session.pricePerPlayer != null)
                          Text('${session.pricePerPlayer!.toInt()} ج/لاعب',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            )),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(c),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${session.currentPlayers}/${session.totalPlayers} لاعب',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),

                    // ── Players list — visible to EVERYONE ─────────────
                    if (session.playerIds.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _PlayersRow(session: session, isCreator: isCreator),
                    ],

                    // Bill split
                    if (session.pricePerPlayer != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.receipt_long_outlined, size: 13, color: c),
                          const SizedBox(width: 6),
                          Text('تقسيم: ${session.totalPlayers} × ${session.pricePerPlayer!.toInt()} ج',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700, color: c)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'نصيبك ${session.pricePerPlayer!.toInt()} ج',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Buttons row
                    Row(
                      children: [
                        if (alreadyJoined || isCreator)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionChatScreen(session: session),
                                ),
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 16),
                              label: const Text('دردشة'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c,
                                side: BorderSide(color: c),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),

                        if (isCreator)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                              tooltip: 'حذف الإعلان',
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: const Text('حذف الإعلان؟',
                                        style: TextStyle(fontWeight: FontWeight.w800)),
                                    content: const Text('هتشيل الإعلان ده نهائياً؟'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('لا')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('نعم، احذفه',
                                            style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await ref
                                      .read(sessionsProvider.notifier)
                                      .deleteSession(session.id);
                                }
                              },
                            ),
                          ),

                        const Spacer(),

                        if (alreadyJoined && !isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Text('انضممت ✓',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              )),
                          )
                        else if (session.isOpen && !isCreator)
                          _JoinButton(session: session),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Players row — shows all players with remove button for creator ─────────────

class _PlayersRow extends ConsumerWidget {
  final MatchSessionEntity session;
  final bool isCreator;
  const _PlayersRow({required this.session, required this.isCreator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final players = session.playerIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اللاعبون (${players.length})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: players.map((uid) {
            final name = session.playerNames[uid] ??
                (uid == session.creatorId ? session.creatorName : uid.substring(0, 6));
            final isOwner = uid == session.creatorId;
            return _PlayerChip(
              name: name,
              isOwner: isOwner,
              canRemove: isCreator && !isOwner,
              onRemove: () async {
                final ok = await ref
                    .read(sessionsProvider.notifier)
                    .removePlayer(session.id, uid);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حصل خطأ')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PlayerChip extends StatefulWidget {
  final String name;
  final bool isOwner, canRemove;
  final VoidCallback onRemove;
  const _PlayerChip({
    required this.name,
    required this.isOwner,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_PlayerChip> createState() => _PlayerChipState();
}

class _PlayerChipState extends State<_PlayerChip> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isOwner
            ? AppColors.primary.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isOwner
              ? AppColors.primary.withValues(alpha: 0.3)
              : cs.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isOwner ? Icons.star_rounded : Icons.person_rounded,
            size: 13,
            color: widget.isOwner ? AppColors.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(widget.name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isOwner ? AppColors.primary : cs.onSurface)),
          if (widget.canRemove) ...[
            const SizedBox(width: 6),
            _loading
                ? const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.error))
                : GestureDetector(
                    onTap: () async {
                      setState(() => _loading = true);
                      widget.onRemove();
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted) setState(() => _loading = false);
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.error),
                  ),
          ],
        ],
      ),
    );
  }
}

// ── Join button ───────────────────────────────────────────────────────────────

class _JoinButton extends ConsumerStatefulWidget {
  final MatchSessionEntity session;
  const _JoinButton({required this.session});

  @override
  ConsumerState<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<_JoinButton> {
  bool _loading = false;

  Future<void> _join() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(sessionsProvider.notifier)
        .joinSession(
          widget.session.id,
          user.uid,
          user.displayName ?? user.username,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الانضمام للماتش! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _join,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(88, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: _loading
          ? const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2))
          : const Text('انضم',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surface,
      highlightColor: cs.surfaceContainerHighest,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 180,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 36, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('مفيش ماتشات مفتوحة دلوقتي',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
          const SizedBox(height: 8),
          Text('ابدأ ماتش جديد بالضغط على الزر',
            style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13)),
        ],
      ),
    );
  }
}
