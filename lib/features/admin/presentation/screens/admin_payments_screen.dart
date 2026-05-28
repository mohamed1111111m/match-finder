import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../venues/domain/entities/booking_entity.dart';
import '../../../venues/presentation/providers/venue_provider.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _methodFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync  = ref.watch(adminPendingBookingsProvider);
    final confirmedAsync = ref.watch(adminConfirmedBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات المالية'),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_top_rounded, size: 16),
                text: 'قيد المراجعة'),
            Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                text: 'مؤكدة'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Summary banner ─────────────────────────────────────────────
          confirmedAsync.when(
            loading: () => const _SummaryBanner(confirmed: 0, total: 0),
            error: (_, __) => const _SummaryBanner(confirmed: 0, total: 0),
            data: (confirmed) {
              final total =
                  confirmed.fold<double>(0, (s, b) => s + b.totalCost);
              return _SummaryBanner(
                      confirmed: confirmed.length, total: total)
                  .animate()
                  .fadeIn()
                  .scale(begin: const Offset(0.97, 0.97));
            },
          ),

          const SizedBox(height: 8),

          // ── Method filter chips ───────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                    label: 'الكل',
                    value: 'all',
                    selected: _methodFilter == 'all',
                    onTap: () => setState(() => _methodFilter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'إنستاباي',
                    value: 'instapay',
                    selected: _methodFilter == 'instapay',
                    onTap: () =>
                        setState(() => _methodFilter = 'instapay')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'أورانج كاش',
                    value: 'orange_cash',
                    selected: _methodFilter == 'orange_cash',
                    onTap: () =>
                        setState(() => _methodFilter = 'orange_cash')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'فودافون كاش',
                    value: 'vodafone_cash',
                    selected: _methodFilter == 'vodafone_cash',
                    onTap: () =>
                        setState(() => _methodFilter = 'vodafone_cash')),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tab views ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Pending verification tab
                pendingAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  data: (bookings) {
                    final filtered = _methodFilter == 'all'
                        ? bookings
                        : bookings
                            .where((b) =>
                                b.paymentMethod == _methodFilter)
                            .toList();
                    if (filtered.isEmpty) {
                      return const _Empty('مفيش طلبات في انتظار التأكيد');
                    }
                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _PendingTile(
                        booking: filtered[i],
                        index: i,
                      ),
                    );
                  },
                ),

                // Confirmed tab
                confirmedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  data: (bookings) {
                    final filtered = _methodFilter == 'all'
                        ? bookings
                        : bookings
                            .where((b) =>
                                b.paymentMethod == _methodFilter)
                            .toList();
                    if (filtered.isEmpty) {
                      return const _Empty('مفيش حجوزات مؤكدة');
                    }
                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _ConfirmedTile(
                        booking: filtered[i],
                        index: i,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int confirmed;
  final double total;
  const _SummaryBanner({required this.confirmed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _Col(
            label: 'حجوزات مؤكدة',
            value: '$confirmed',
            icon: Icons.check_circle_rounded,
            iconColor: Colors.greenAccent),
        _Div(),
        _Col(
            label: 'إجمالي الإيرادات',
            value: '${total.toInt()} ج',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.white),
      ]),
    );
  }
}

class _Col extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const _Col(
      {required this.label,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                fontFamily: 'Cairo')),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontFamily: 'Cairo')),
      ]),
    );
  }
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 48,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ── Pending verification tile ─────────────────────────────────────────────────

class _PendingTile extends ConsumerWidget {
  final BookingEntity booking;
  final int index;
  const _PendingTile({required this.booking, required this.index});

  Future<void> _confirmReject(
      BuildContext context, WidgetRef ref, String bookingId) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض (اختياري)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('تأكيد الرفض',
                style: TextStyle(color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    await ref
        .read(adminPaymentNotifierProvider.notifier)
        .rejectPayment(bookingId, reason: reason.isEmpty ? null : reason);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(adminPaymentNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.venueName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  Text('${booking.dateText}  •  '
                      '${booking.startTime} – ${booking.endTime}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('+${booking.totalCost.toInt()} ج',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primary)),
              _MethodBadge(booking.paymentMethod),
            ]),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Receipt image
          if (booking.receiptUrl != null) ...[
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(booking.receiptUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: booking.receiptUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: AppColors.warning.withValues(alpha: 0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Text('عرض الإيصال',
                            style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _confirmReject(context, ref, booking.id),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('رفض'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side:
                      const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(adminPaymentNotifierProvider.notifier)
                        .confirmPayment(booking.id),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('تأكيد الدفع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.05);
  }
}

// ── Confirmed tile ────────────────────────────────────────────────────────────

class _ConfirmedTile extends StatelessWidget {
  final BookingEntity booking;
  final int index;
  const _ConfirmedTile({required this.booking, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.venueName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text('${booking.dateText}  •  '
                    '${booking.startTime} – ${booking.endTime}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                _MethodBadge(booking.paymentMethod),
              ]),
        ),
        Text('+${booking.totalCost.toInt()} ج',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.success)),
      ]),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.04);
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  final String? method;
  const _MethodBadge(this.method);

  Color get _color {
    switch (method) {
      case 'instapay':      return const Color(0xFF00897B);
      case 'orange_cash':   return const Color(0xFFFF6D00);
      case 'vodafone_cash': return const Color(0xFFE53935);
      default:              return AppColors.textMuted;
    }
  }

  String get _label {
    switch (method) {
      case 'instapay':      return 'إنستاباي';
      case 'orange_cash':   return 'أورانج كاش';
      case 'vodafone_cash': return 'فودافون كاش';
      default:              return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _color)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outline),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);
  @override
  Widget build(BuildContext context) => Center(
      child: Text(message,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 15)));
}
