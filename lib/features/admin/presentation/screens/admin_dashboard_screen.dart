import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Protect: only admins allowed
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: const Center(
          child: Text('غير مصرح. المدراء فقط.'),
        ),
      );
    }

    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Text(
                'أهلاً يا ${user.username}',
                style: context.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text('لوحة تحكم الإدارة',
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary))
                  .animate()
                  .fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Stats
              statsAsync.when(
                loading: () => const ShimmerList(count: 2, itemHeight: 100),
                error: (e, _) => AppErrorWidget(message: e.toString()),
                data: (stats) => _StatsGrid(stats: stats),
              ),

              const SizedBox(height: 24),

              // Quick actions
              Text('الإجراءات السريعة',
                      style: context.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 12),

              _AdminActionCard(
                icon: Icons.stadium_outlined,
                title: 'إدارة الملاعب',
                subtitle: 'إضافة وتعديل وحذف الملاعب',
                color: AppColors.success,
                onTap: () => context.push('/admin/venues'),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.add_circle_outline,
                title: 'إنشاء بطولة',
                subtitle: 'إضافة بطولة جديدة للاعبين',
                color: AppColors.primary,
                onTap: () => context.push('/admin/create-tournament'),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.people_outline,
                title: 'إدارة المستخدمين',
                subtitle: 'عرض وحظر وترقية اللاعبين',
                color: AppColors.info,
                onTap: () => context.push('/admin/users'),
              ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'المعاملات المالية',
                subtitle: 'الوارد والصادر وتحويلات الملاك',
                color: AppColors.accent,
                onTap: () => context.push('/admin/payments'),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.emoji_events_outlined,
                title: 'البطولات',
                subtitle: 'عرض وإدارة جميع البطولات',
                color: AppColors.secondary,
                onTap: () => context.push('/admin/tournaments'),
              ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.campaign_outlined,
                title: 'الإعلانات',
                subtitle: 'إضافة وحذف إعلانات الصفحة الرئيسية',
                color: const Color(0xFF7C4DFF),
                onTap: () => context.push('/admin/ads'),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _AdminActionCard(
                icon: Icons.support_agent_outlined,
                title: 'رسائل الدعم',
                subtitle: 'الرد على استفسارات المستخدمين',
                color: AppColors.info,
                onTap: () => context.push('/admin/support'),
              ).animate().fadeIn(delay: 650.ms).slideX(begin: 0.05),

              const SizedBox(height: 10),

              _CommissionCard()
                  .animate()
                  .fadeIn(delay: 700.ms)
                  .slideX(begin: 0.05),

              const SizedBox(height: 10),

              const _CleanupCard()
                  .animate()
                  .fadeIn(delay: 750.ms)
                  .slideX(begin: 0.05),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'المستخدمين',
          value: stats.totalUsers.toString(),
          icon: Icons.people,
          color: AppColors.info,
        ),
        _StatCard(
          label: 'البطولات',
          value: stats.totalTournaments.toString(),
          icon: Icons.emoji_events,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'جارية الآن',
          value: stats.activeTournaments.toString(),
          icon: Icons.live_tv,
          color: AppColors.liveColor,
        ),
        _StatCard(
          label: 'الإيرادات',
          value: stats.totalRevenue.egpShort,
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.accent,
        ),
      ].asMap().entries.map((e) => e.value.animate(delay: (e.key * 80).ms).fadeIn().scale(begin: const Offset(0.9, 0.9))).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
              Text(label,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Commission settings card ───────────────────────────────────────────────

class _CommissionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isSaving = ref.watch(appSettingsNotifierProvider);
    final current = settings.valueOrNull?.commissionPercent ?? 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.percent_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('عمولة المنصة',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text('الحالية: ${current.toInt()}% من كل حجز',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: () =>
                      _showCommissionDialog(context, ref, current),
                  child: const Text('تعديل',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }

  Future<void> _showCommissionDialog(
      BuildContext context, WidgetRef ref, double current) async {
    final controller =
        TextEditingController(text: current.toInt().toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل نسبة العمولة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل نسبة العمولة كنسبة مئوية (مثال: 10)'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffix: Text('%'),
                border: OutlineInputBorder(),
                labelText: 'النسبة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (confirmed != true) return;
    final val = double.tryParse(controller.text.trim());
    if (val == null || val < 0 || val > 100) return;
    await ref.read(appSettingsNotifierProvider.notifier).setCommission(val);
  }
}

// ── Cleanup card ──────────────────────────────────────────────────────────────

class _CleanupCard extends StatefulWidget {
  const _CleanupCard();

  @override
  State<_CleanupCard> createState() => _CleanupCardState();
}

class _CleanupCardState extends State<_CleanupCard> {
  bool _deleting = false;

  Future<void> _deleteCollection(String name, String collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف كل $name؟'),
        content: Text('سيتم حذف جميع $name نهائياً ولا يمكن التراجع عن ذلك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection(collection).get();
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف كل $name ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text('تنظيف البيانات',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('احذف البيانات التجريبية قبل النشر على المتجر',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (_deleting)
            const Center(child: CircularProgressIndicator(color: AppColors.error))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DeleteChip(
                  label: 'البطولات',
                  onTap: () => _deleteCollection('البطولات', AppConstants.tournamentsCollection),
                ),
                _DeleteChip(
                  label: 'الفرق',
                  onTap: () => _deleteCollection('الفرق', AppConstants.teamsCollection),
                ),
                _DeleteChip(
                  label: 'الملاعب',
                  onTap: () => _deleteCollection('الملاعب', AppConstants.venuesCollection),
                ),
                _DeleteChip(
                  label: 'المدفوعات',
                  onTap: () => _deleteCollection('المدفوعات', AppConstants.paymentsCollection),
                ),
                _DeleteChip(
                  label: 'الحجوزات',
                  onTap: () => _deleteCollection('الحجوزات', AppConstants.bookingsCollection),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DeleteChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DeleteChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
