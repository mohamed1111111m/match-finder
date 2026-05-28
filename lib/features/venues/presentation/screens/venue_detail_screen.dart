import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/payment_config.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/venue_entity.dart';
import '../providers/venue_provider.dart';

// ignore_for_file: avoid_dynamic_calls

class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final Set<String> _selectedSlots = {};
  int _slotInterval = 30; // 30 or 60 minutes

  static String _to12hr(String hhmm) {
    final parts = hhmm.split(':');
    var h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'ص' : 'م';
    if (h == 0) {
      h = 12;
    } else if (h > 12) {
      h -= 12;
    }
    return '$h:$m $period';
  }

  List<String> _slots(VenueEntity v) {
    final slots = <String>[];
    var h = int.parse(v.openTime.split(':')[0]);
    var m = int.parse(v.openTime.split(':')[1]);
    final eh = int.parse(v.closeTime.split(':')[0]);
    final em = int.parse(v.closeTime.split(':')[1]);
    while (h < eh || (h == eh && m <= em)) {
      slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      m += _slotInterval;
      if (m >= 60) { m -= 60; h++; }
    }
    return slots;
  }

  double _totalCost(double pricePerHour, double commissionPct) {
    if (_selectedSlots.isEmpty) return 0;
    final base = pricePerHour * _selectedSlots.length * (_slotInterval / 60);
    return base + (base * commissionPct / 100);
  }

  String _durationLabel() {
    final total = _selectedSlots.length * _slotInterval;
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '$m دقيقة';
    if (m == 0) return '$h ساعة';
    return '$h ساعة و$m دقيقة';
  }

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('ar', 'EG'),
      builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlots.clear();
      });
    }
  }

  void _toggleSlot(String slot) {
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        _selectedSlots.add(slot);
      }
    });
  }

  Future<void> _confirmBooking(VenueEntity venue, String userId) async {
    final cs = Theme.of(context).colorScheme;
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('اختار ميعاد واحد على الأقل'),
          backgroundColor: cs.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final commissionPct = ref.read(appSettingsProvider).valueOrNull
            ?.commissionPercent ??
        PaymentConfig.commissionPercent;
    final total = _totalCost(venue.pricePerHour, commissionPct);

    // Sort selected slots and derive start/end times
    final sorted = _selectedSlots.toList()..sort();
    final startTime = sorted.first;
    // end time = last slot + 30 min
    final lastParts = sorted.last.split(':');
    var eh = int.parse(lastParts[0]);
    var em = int.parse(lastParts[1]) + _slotInterval;
    if (em >= 60) { em -= 60; eh++; }
    final endTime = '${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BookingConfirmSheet(
        venue: venue,
        date: _selectedDate,
        startTime: startTime,
        endTime: endTime,
        durationLabel: _durationLabel(),
        total: total,
        commissionPercent: commissionPct,
        slotCount: _selectedSlots.length,
      ),
    );
    if (confirmed != true) return;

    // Pass each selected slot individually — the provider locks them all
    final bookingId = await ref
        .read(bookingNotifierProvider.notifier)
        .createPendingBookingSlots(
          venueId: venue.id,
          venueName: venue.name,
          userId: userId,
          date: _selectedDate,
          selectedSlots: sorted,
          startTime: startTime,
          endTime: endTime,
          totalCost: total,
        );

    if (!mounted) return;
    if (bookingId != null) {
      context.push('/booking/$bookingId');
    } else {
      final err = ref.read(bookingNotifierProvider).error;
      final msg = err == 'slot_taken'
          ? 'عذراً، بعض المواعيد دي اتحجزت للتو. اختار مواعيد تانية.'
          : 'حدث خطأ، حاول مرة أخرى';
      if (err == 'slot_taken') setState(() => _selectedSlots.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final venue        = ref.watch(venueByIdProvider(widget.venueId));
    final user         = ref.watch(currentUserProvider);
    final bookingState = ref.watch(bookingNotifierProvider);
    final commissionPct = ref.watch(appSettingsProvider).valueOrNull
            ?.commissionPercent ??
        PaymentConfig.commissionPercent;

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملعب')),
        body: Center(
          child: Text('الملعب مش موجود',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }

    final c     = _sportColor(venue.sport);
    final slots = _slots(venue);
    final total = _totalCost(venue.pricePerHour, commissionPct);

    // Real-time booked slots stream
    final bookedSlots = ref
        .watch(venueBookedSlotsProvider(
            (venueId: venue.id, date: _selectedDate)))
        .valueOrNull ?? {};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero banner ─────────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 240,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: venue.images.isNotEmpty
                  ? _ImageBanner(images: venue.images)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            c.withValues(alpha: 0.9),
                            c.withValues(alpha: 0.3)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Icon(_sportIcon(venue.sport),
                              color: Colors.white, size: 80),
                          const SizedBox(height: 8),
                          Text(venue.sportAr,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 15)),
                        ],
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(venue.name,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface)),
                        ),
                        if (venue.isVerified)
                          const Icon(Icons.verified_rounded,
                              color: AppColors.info, size: 22),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(venue.address,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
                        ),
                      ],
                    ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.rankGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.rankGold, size: 16),
                              const SizedBox(width: 4),
                              Text('${venue.rating}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface)),
                              Text(' (${venue.reviewCount})',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(venue.priceText,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ).animate(delay: 80.ms).fadeIn(),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(Icons.access_time_rounded,
                            '${_to12hr(venue.openTime)} – ${_to12hr(venue.closeTime)}'),
                        if (venue.phone.isNotEmpty)
                          _InfoChip(Icons.phone_outlined, venue.phone),
                      ],
                    ).animate(delay: 100.ms).fadeIn(),

                    if (venue.amenities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('المرافق',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: venue.amenities.map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(a,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant)),
                        )).toList(),
                      ).animate(delay: 120.ms).fadeIn(),
                    ],

                    if (venue.description != null &&
                        venue.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('عن الملعب',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 6),
                      Text(venue.description!,
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              height: 1.7)),
                    ],

                    const SizedBox(height: 24),
                    Divider(color: cs.outline, height: 1),
                    const SizedBox(height: 24),

                    // ── Booking section ──────────────────────────────────
                    Text('احجز دلوقتي',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface)),
                    const SizedBox(height: 16),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(_formatDate(_selectedDate),
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: cs.onSurface)),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down_rounded,
                                color: cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slot grid label
                    Row(
                      children: [
                        Text('اختار المواعيد',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: cs.onSurface)),
                        const Spacer(),
                        _LegendDot(color: AppColors.primary, label: 'متاح'),
                        const SizedBox(width: 10),
                        _LegendDot(color: AppColors.error, label: 'محجوز'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Slot interval toggle
                    Row(
                      children: [
                        Text('مدة الخانة:',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        _IntervalBtn(
                          label: '30 دقيقة',
                          selected: _slotInterval == 30,
                          onTap: () => setState(() {
                            _slotInterval = 30;
                            _selectedSlots.clear();
                          }),
                        ),
                        const SizedBox(width: 6),
                        _IntervalBtn(
                          label: 'ساعة',
                          selected: _slotInterval == 60,
                          onTap: () => setState(() {
                            _slotInterval = 60;
                            _selectedSlots.clear();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Slot chips grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((t) {
                        final isBooked = bookedSlots.contains(t);
                        final isSel    = _selectedSlots.contains(t);
                        return GestureDetector(
                          onTap: isBooked ? null : () => _toggleSlot(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? AppColors.error.withValues(alpha: 0.10)
                                  : isSel
                                      ? AppColors.primary
                                      : cs.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isBooked
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : isSel
                                        ? AppColors.primary
                                        : cs.outline,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_to12hr(t),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isBooked
                                            ? AppColors.error
                                            : isSel
                                                ? Colors.black
                                                : cs.onSurface)),
                                const SizedBox(height: 2),
                                Text(
                                  isBooked
                                      ? 'محجوز'
                                      : _slotInterval == 30 ? '30 دقيقة' : 'ساعة',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isBooked
                                        ? AppColors.error
                                        : isSel
                                            ? Colors.black54
                                            : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate(delay: 150.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Book button ──────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outline)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedSlots.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedSlots.length} خانة • ${_durationLabel()}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                        Text(
                          '${total.toInt()} جنيه',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: bookingState.isLoading
                        ? null
                        : () => _confirmBooking(venue, user?.uid ?? 'guest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: bookingState.isLoading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Text(
                            _selectedSlots.isEmpty
                                ? 'اختار ميعاد أولاً'
                                : 'احجز ${_selectedSlots.length} خانة',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const days = [
      'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء',
      'الخميس', 'الجمعة', 'السبت'
    ];
    return '${days[d.weekday % 7]}، ${d.day} ${months[d.month - 1]}';
  }
}

// ── Image banner ───────────────────────────────────────────────────────────────

class _ImageBanner extends StatefulWidget {
  final List<String> images;
  const _ImageBanner({required this.images});
  @override
  State<_ImageBanner> createState() => _ImageBannerState();
}

class _ImageBannerState extends State<_ImageBanner> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final p = widget.images[i];
            return p.startsWith('http')
                ? Image.network(p, fit: BoxFit.cover)
                : Image.file(File(p), fit: BoxFit.cover);
          },
        ),
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Legend dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _IntervalBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IntervalBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : cs.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : cs.onSurfaceVariant,
            )),
      ),
    );
  }
}

// ── Booking confirm sheet ──────────────────────────────────────────────────────

class _BookingConfirmSheet extends StatelessWidget {
  final VenueEntity venue;
  final DateTime date;
  final String startTime, endTime, durationLabel;
  final double total, commissionPercent;
  final int slotCount;
  const _BookingConfirmSheet({
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationLabel,
    required this.total,
    required this.commissionPercent,
    required this.slotCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text('تأكيد الحجز',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 20),

          _Row('الملعب',   venue.name),
          _Row('التاريخ',  dateStr),
          _Row('من',       startTime),
          _Row('إلى',      endTime),
          _Row('المدة',    durationLabel),
          _Row('عدد الخانات', '$slotCount خانة'),

          const SizedBox(height: 8),
          Divider(color: cs.outline),
          const SizedBox(height: 8),

          _Row('سعر الملعب',
              '${(total / (1 + commissionPercent / 100)).toInt()} جنيه'),
          _Row('عمولة المنصة (${commissionPercent.toInt()}%)',
              '${((total / (1 + commissionPercent / 100)) * commissionPercent / 100).toInt()} جنيه'),

          Divider(color: cs.outline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text('الإجمالي',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${total.toInt()} جنيه',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    side: BorderSide(color: cs.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('تأكيد الحجز',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
