import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/screens/admin_ads_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../matchmaking/domain/entities/match_session_entity.dart';
import '../../../matchmaking/presentation/providers/matchmaking_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/presentation/providers/venue_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final venues   = ref.watch(venuesProvider);
    final sessions = ref.watch(filteredSessionsProvider);
    final unread   = ref.watch(unreadCountProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              userName: user?.displayName ?? user?.username ?? 'لاعب',
              unread: unread,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AdsBanner(),
                const SizedBox(height: 20),

                _QuickActions(),
                const SizedBox(height: 28),

                _SectionHeader(
                  title: 'ملاعب متاحة',
                  onSeeAll: () => context.push('/venues'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: venues.isEmpty
                      ? const _EmptySlot('لا توجد ملاعب متاحة')
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: venues.length > 6 ? 6 : venues.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (ctx, i) =>
                              _VenueCard(venue: venues[i])
                                  .animate(delay: (i * 60).ms)
                                  .fadeIn()
                                  .slideX(begin: 0.08),
                        ),
                ),
                const SizedBox(height: 28),

                _SectionHeader(
                  title: 'ماتشات مفتوحة',
                  onSeeAll: () => context.push('/matchmaking'),
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  const _EmptySlot('لا توجد ماتشات مفتوحة')
                else
                  ...sessions.take(3).toList().asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SessionCard(session: e.value)
                          .animate(delay: (e.key * 70).ms)
                          .fadeIn()
                          .slideY(begin: 0.05),
                    ),
                  ),
                const SizedBox(height: 28),

                _SectionHeader(
                  title: 'ترتيب الفرق',
                  onSeeAll: () => context.push('/tournaments'),
                ),
                const SizedBox(height: 12),
                _LeaderboardPreview(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String userName;
  final int unread;
  const _HeroHeader({required this.userName, required this.unread});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0A1F0A), const Color(0xFF0D2818), scaffoldBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، $userName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'إيه اللعبة النهارده؟',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _IconBtn(
                    icon: Icons.notifications_outlined,
                    badge: unread,
                    onTap: (ctx) => ctx.push('/notifications'),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.person_outline_rounded,
                    onTap: (ctx) => ctx.push('/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Search bar
              GestureDetector(
                onTap: () => context.push('/venues'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Text('ابحث عن ملعب...',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final void Function(BuildContext) onTap;
  const _IconBtn({required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Stack(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 20),
          ),
          // reuse icon parameter
          Positioned.fill(
            child: Center(child: Icon(icon, color: Colors.white, size: 20)),
          ),
          if (badge > 0)
            Positioned(
              top: 3, right: 3,
              child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: Center(
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ads Banner ────────────────────────────────────────────────────────────────

class _AdsBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends ConsumerState<_AdsBanner> {
  final _pageCtrl = PageController();
  int _page = 0;
  Timer? _timer;
  int _adCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startTimer(int count) {
    if (_timer != null || count < 2) return;
    _adCount = count;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _adCount;
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final adsAsync = ref.watch(adsStreamProvider);
    return adsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (ads) {
        final active = ads.where((a) => a.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        _startTimer(active.length);

        return Column(
          children: [
            SizedBox(
              height: 76,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: active.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final ad = active[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF7C4DFF)
                              .withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded,
                            color: Color(0xFF7C4DFF), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ad.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (ad.body.isNotEmpty)
                                Text(ad.body,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (active.length > 1) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(active.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? const Color(0xFF7C4DFF)
                          : const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _QA('احجز ملعب',  Icons.sports_soccer_rounded,  AppColors.football,   '/venues'),
      _QA('دور لاعبين', Icons.people_alt_rounded,      AppColors.info,       '/matchmaking'),
      _QA('فريقي',      Icons.shield_rounded,           AppColors.warning,    '/teams'),
      _QA('بطولات',     Icons.emoji_events_rounded,     AppColors.gold,       '/tournaments'),
    ];

    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: _QATile(qa: items[i])
              .animate(delay: (i * 60).ms)
              .fadeIn()
              .scale(begin: const Offset(0.88, 0.88)),
        ),
      );
    }

    return Row(children: children);
  }
}

class _QA {
  final String label; final IconData icon; final Color color; final String route;
  const _QA(this.label, this.icon, this.color, this.route);
}

class _QATile extends StatelessWidget {
  final _QA qa;
  const _QATile({required this.qa});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.go(qa.route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: qa.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: qa.color.withValues(alpha: 0.2)),
            ),
            child: Center(child: Icon(qa.icon, color: qa.color, size: 26)),
          ),
          const SizedBox(height: 6),
          Text(qa.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text('عرض الكل',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Empty slot ────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final String msg;
  const _EmptySlot(this.msg);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Text(msg,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
    );
  }
}

// ── Venue card (horizontal scroll) ───────────────────────────────────────────

class _VenueCard extends StatelessWidget {
  final VenueEntity venue;
  const _VenueCard({required this.venue});

  Color _color(String s) {
    switch (s) {
      case 'football': return AppColors.football;
      case 'padel':    return AppColors.padel;
      default:         return AppColors.primary;
    }
  }

  IconData _icon(String s) {
    switch (s) {
      case 'football':   return Icons.sports_soccer;
      case 'padel':      return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball;
      default:           return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _color(venue.sport);
    return GestureDetector(
      onTap: () => context.push('/venues/${venue.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: venue.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: venue.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _VenueCardBanner(c: c, icon: _icon(venue.sport)),
                      )
                    : _VenueCardBanner(c: c, icon: _icon(venue.sport)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(venue.city,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.rankGold, size: 13),
                      const SizedBox(width: 2),
                      Text('${venue.rating}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const Spacer(),
                      Text(venue.priceText,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueCardBanner extends StatelessWidget {
  final Color c;
  final IconData icon;
  const _VenueCardBanner({required this.c, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 44)),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final MatchSessionEntity session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/matchmaking'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_soccer,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.location,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${session.dateText} • ${session.time}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('فاضل ${session.spotsLeft}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard preview ───────────────────────────────────────────────────────

class _LeaderboardPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final teams = ref.watch(teamsProvider).take(3).toList();
    if (teams.isEmpty) {
      return const _EmptySlot('لا توجد فرق مسجلة بعد');
    }
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: teams.asMap().entries.map((e) {
          final t = e.value;
          final rank = e.key + 1;
          final medal = rank == 1 ? AppColors.rankGold
              : rank == 2 ? AppColors.rankSilver : AppColors.rankBronze;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: medal.withValues(alpha: 0.18),
              child: Text('$rank',
                  style: TextStyle(
                      color: medal,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
            title: Text(t.name,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface)),
            subtitle: Text('${t.wins} فوز • ${t.city}',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: Text('${t.points} نقطة',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 14)),
          );
        }).toList(),
      ),
    );
  }
}
