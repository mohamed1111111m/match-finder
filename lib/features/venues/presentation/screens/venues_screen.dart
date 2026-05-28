import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/venue_entity.dart';
import '../providers/venue_provider.dart';

class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(venueFilterProvider);
    final venues    = ref.watch(venuesProvider);
    final isLoading = ref.watch(venuesLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملاعب'),
      ),
      body: Column(
        children: [
          // Sport filter chips
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

          // List
          Expanded(
            child: isLoading
                ? _ShimmerList()
                : venues.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: venues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _VenueTile(venue: venues[i])
                            .animate(delay: (i * 50).ms)
                            .fadeIn()
                            .slideY(begin: 0.04),
                      ),
          ),
        ],
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
      onTap: () => ref.read(venueFilterProvider.notifier).state = value,
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

// ── Venue tile ────────────────────────────────────────────────────────────────

class _VenueTile extends StatelessWidget {
  final VenueEntity venue;
  const _VenueTile({required this.venue});

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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _sportColor(venue.sport);
    final hasPhoto = venue.images.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/venues/${venue.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo / banner at top ───────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: venue.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _SportBanner(c: c, icon: _sportIcon(venue.sport)),
                      )
                    : _SportBanner(c: c, icon: _sportIcon(venue.sport)),
              ),
            ),

            // ── Info below photo ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(venue.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ),
                      if (venue.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.verified_rounded,
                              color: AppColors.info, size: 16),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(venue.priceText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(venue.address,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.rankGold, size: 14),
                      const SizedBox(width: 3),
                      Text('${venue.rating}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                      Text(' (${venue.reviewCount})',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text('${venue.openTime}–${venue.closeTime}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  if (venue.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: venue.amenities.take(4).map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(a,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportBanner extends StatelessWidget {
  final Color c;
  final IconData icon;
  const _SportBanner({required this.c, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 64),
      ),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 100,
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
            child: Icon(Icons.stadium_outlined,
                size: 36, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('مفيش ملاعب في الوقت ده',
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('هيتم إضافة ملاعب قريباً',
              style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13)),
        ],
      ),
    );
  }
}
