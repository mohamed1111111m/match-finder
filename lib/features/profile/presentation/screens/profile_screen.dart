import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../../../venues/domain/entities/booking_entity.dart';
import '../../../venues/presentation/providers/venue_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingWidget();

    if (user.isAdmin || user.isSupport) {
      return _AdminProfileView(user: user);
    }
    return _UserProfileView(user: user);
  }
}

// ─── User profile ─────────────────────────────────────────────────────────────

class _UserProfileView extends ConsumerWidget {
  final UserEntity user;
  const _UserProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A1F0A),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.push('/profile/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _confirmLogout(context, ref),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHero(user: user),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsCard(user: user),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const _SectionLabel('عني'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Text(
                            user.bio!,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                              height: 1.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // My Team
                      _MyTeamSection(userId: user.uid),

                      // My Bookings
                      const _SectionLabel('حجوزاتي'),
                      const SizedBox(height: 8),
                      _BookingsSection(userId: user.uid),
                      const SizedBox(height: 20),

                      // Settings
                      const _SectionLabel('الإعدادات'),
                      const SizedBox(height: 8),
                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.badge_outlined,
                            iconColor: AppColors.secondary,
                            label: 'تغيير الاسم',
                            onTap: () => _showChangeNameSheet(context, ref, user),
                          ),
                          _SettingRow(
                            icon: Icons.add_a_photo_outlined,
                            iconColor: AppColors.success,
                            label: 'تغيير الصورة',
                            onTap: () => _changePhoto(context, ref, user),
                          ),
                          _SettingRow(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.accent,
                            label: 'الإشعارات',
                            badge: unread > 0 ? unread : null,
                            onTap: () => context.push('/notifications'),
                          ),
                          _SettingRow(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFF7C4DFF),
                            label: 'تغيير المظهر',
                            onTap: () => _showThemePicker(context, ref),
                          ),
                          _SettingRow(
                            icon: Icons.headset_mic_outlined,
                            iconColor: AppColors.info,
                            label: 'مساعدة ودعم',
                            onTap: () => context.push('/support'),
                            last: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: cs.onSurfaceVariant,
                            label: 'سياسة الخصوصية',
                            onTap: () => context.push('/privacy-policy'),
                          ),
                          _SettingRow(
                            icon: Icons.article_outlined,
                            iconColor: cs.onSurfaceVariant,
                            label: 'شروط الاستخدام',
                            onTap: () => context.push('/terms'),
                            last: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.logout_rounded,
                            iconColor: AppColors.error,
                            label: 'تسجيل الخروج',
                            labelColor: AppColors.error,
                            onTap: () => _confirmLogout(context, ref),
                          ),
                          _SettingRow(
                            icon: Icons.delete_forever_rounded,
                            iconColor: AppColors.error,
                            label: 'حذف الحساب',
                            labelColor: AppColors.error,
                            onTap: () => _confirmDeleteAccount(context, ref),
                            last: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'eKora v1.0.0',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref, UserEntity user) async {
    final success = await ref
        .read(profileNotifierProvider.notifier)
        .uploadAvatar(user.uid);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الملف الشخصي')),
      );
    }
  }

  void _showChangeNameSheet(BuildContext context, WidgetRef ref, UserEntity user) {
    final ctrl = TextEditingController(text: user.displayName ?? user.username);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تغيير الاسم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'الاسم الجديد',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(profileNotifierProvider.notifier)
                      .updateProfile(
                        userId: user.uid,
                        username: ctrl.text.trim(),
                      );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث الملف الشخصي')),
                    );
                  }
                },
                child: const Text('حفظ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائيًا'),
        content: const Text(
            'سيتم حذف حسابك وجميع بياناتك بشكل دائم ولا يمكن التراجع.\n\nهل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final ok = await ref.read(authNotifierProvider.notifier).deleteAccount();
    if (!context.mounted) return;

    if (ok) {
      context.go(AppRoutes.login);
      return;
    }

    final errorMsg = ref.read(authNotifierProvider).errorMessage;
    if (errorMsg == 'requires-recent-login') {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تحقق من هويتك'),
          content: const Text(
              'لحماية حسابك، سجّل الخروج وأعد تسجيل الدخول، ثم حاول مرة أخرى.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authNotifierProvider.notifier).signOut();
                if (ctx.mounted) context.go(AppRoutes.login);
              },
              child: const Text('تسجيل الخروج الآن'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

// ─── Profile hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final UserEntity user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1F0A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 30, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 52),

                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.3),
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              (user.username.isNotEmpty
                                      ? user.username[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1)),

                const SizedBox(height: 12),

                Text(
                  user.displayName ?? user.username,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 3),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alternate_email_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                if (user.globalRank > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.leaderboard_rounded,
                            size: 13, color: AppColors.rankGold),
                        const SizedBox(width: 5),
                        Text(
                          'المرتبة #${user.globalRank}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final UserEntity user;
  const _StatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(value: '${user.wins}',   label: 'انتصارات',  icon: Icons.emoji_events_rounded, color: AppColors.success),
          _StatDivider(),
          _StatItem(value: '${user.losses}', label: 'هزائم',     icon: Icons.close_rounded,        color: AppColors.error),
          _StatDivider(),
          _StatItem(value: '${user.points}', label: 'النقاط',    icon: Icons.star_rounded,         color: AppColors.accent),
          _StatDivider(),
          _StatItem(
            value: '${user.winRate.toStringAsFixed(0)}%',
            label: 'معدل الفوز',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(width: 1, height: 40, color: cs.outline);
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Settings helpers ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final int? badge;
  final bool last;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.badge,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? cs.onSurface,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (!last)
          Divider(height: 1, indent: 66, endIndent: 0, color: cs.outline),
      ],
    );
  }
}

// ─── Admin / Support profile ──────────────────────────────────────────────────

class _AdminProfileView extends ConsumerWidget {
  final UserEntity user;
  const _AdminProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A1F0A),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('خروج',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHero(user: user),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsCard(user: user),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('الإعدادات'),
                      const SizedBox(height: 8),
                      _SettingsGroup(children: [
                        _SettingRow(
                          icon: Icons.dark_mode_outlined,
                          iconColor: const Color(0xFF7C4DFF),
                          label: 'تغيير المظهر',
                          onTap: () => _showThemePicker(context, ref),
                        ),
                        _SettingRow(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.accent,
                          label: 'الإشعارات',
                          badge: unread > 0 ? unread : null,
                          onTap: () => context.push('/notifications'),
                        ),
                        _SettingRow(
                          icon: Icons.headset_mic_outlined,
                          iconColor: AppColors.info,
                          label: 'مساعدة ودعم',
                          onTap: () => context.push('/support'),
                          last: true,
                        ),
                      ]),

                      if (user.isAdmin) ...[
                        const SizedBox(height: 20),
                        const _SectionLabel('لوحة التحكم'),
                        const SizedBox(height: 8),
                        _AdminCard(
                          icon: Icons.dashboard_outlined,
                          title: 'الإدارة',
                          subtitle: 'إحصائيات وإجراءات سريعة',
                          onTap: () => context.push('/admin'),
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        _AdminCard(
                          icon: Icons.stadium_outlined,
                          title: 'إدارة الملاعب',
                          subtitle: 'إضافة وتعديل وحذف الملاعب',
                          onTap: () => context.push('/admin/venues'),
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 10),
                        _AdminCard(
                          icon: Icons.add_circle_outline,
                          title: 'إنشاء بطولة',
                          subtitle: 'إضافة بطولة جديدة',
                          onTap: () =>
                              context.push('/admin/create-tournament'),
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 10),
                        _AdminCard(
                          icon: Icons.people_outline,
                          title: 'إدارة المستخدمين',
                          subtitle: 'عرض وإدارة اللاعبين والمشرفين',
                          onTap: () => context.push('/admin/users'),
                          color: AppColors.info,
                        ),
                        const SizedBox(height: 10),
                        _AdminCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'المعاملات المالية',
                          subtitle: 'الوارد والصادر وتحويلات الملاك',
                          onTap: () => context.push('/admin/payments'),
                          color: AppColors.accent,
                        ),
                      ],

                      if (user.isSupport) ...[
                        const SizedBox(height: 20),
                        const _SectionLabel('أدوات الدعم'),
                        const SizedBox(height: 8),
                        _AdminCard(
                          icon: Icons.support_agent_outlined,
                          title: 'محادثات الدعم',
                          subtitle: 'الرد على استفسارات المستخدمين',
                          onTap: () => context.push('/support'),
                          color: AppColors.info,
                        ),
                      ],

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'eKora v1.0.0',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Team section ──────────────────────────────────────────────────────────

class _MyTeamSection extends ConsumerWidget {
  final String userId;
  const _MyTeamSection({required this.userId});

  Color _sportColor(String s) {
    switch (s) {
      case 'football':   return AppColors.football;
      case 'padel':      return AppColors.padel;
      case 'basketball': return AppColors.basketball;
      default:           return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final team = ref.watch(userTeamProvider(userId));

    if (team == null) return const SizedBox.shrink();

    final color = _sportColor(team.sport);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('فريقي'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/teams/${team.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.4)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      team.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(team.name,
                              style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (team.isCaptain(userId))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.rankGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('قائد',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.rankGold,
                                  fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${team.sportAr} • ${team.playerIds.length}/${team.teamSize} لاعب • ${team.points} نقطة',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── My Bookings section ──────────────────────────────────────────────────────

class _BookingsSection extends ConsumerWidget {
  final String userId;
  const _BookingsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bookingsAsync = ref.watch(userBookingsProvider(userId));

    return bookingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 36, color: cs.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('لا توجد حجوزات بعد',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          );
        }

        final recent = bookings.take(3).toList();
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: recent.asMap().entries.map((e) {
                    final b = e.value;
                    final isLast = e.key == recent.length - 1;
                    return Column(
                      children: [
                        _BookingTile(booking: b),
                        if (!isLast)
                          Divider(
                              height: 1, indent: 66, endIndent: 0,
                              color: cs.outline),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            if (bookings.length > 3) ...[
              const SizedBox(height: 6),
              Text(
                '+ ${bookings.length - 3} حجوزات أخرى',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingEntity booking;
  const _BookingTile({required this.booking});

  Color get _statusColor {
    if (booking.isConfirmed) return AppColors.success;
    if (booking.isPendingVerification) return AppColors.accent;
    if (booking.isCancelled || booking.isExpired) return AppColors.error;
    return AppColors.textSecondary;
  }

  Future<void> _openReceipt(BuildContext context) async {
    final uri = Uri.tryParse(booking.receiptUrl ?? '');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الإيصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasReceipt = booking.receiptUrl != null &&
        (booking.isPendingVerification || booking.isConfirmed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stadium_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.venueName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(booking.dateText,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(booking.statusAr,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
            ],
          ),
          if (hasReceipt) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openReceipt(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 54),
                  Icon(Icons.receipt_long_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('عرض الإيصال',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Admin card ───────────────────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Color color;
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

// ─── Theme picker ─────────────────────────────────────────────────────────────

void _showThemePicker(BuildContext context, WidgetRef ref) {
  final current = ref.read(themeModeProvider);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            Text(
              'تغيير المظهر',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _ThemeOption(
                  label: 'داكن',
                  icon: Icons.dark_mode_rounded,
                  preview: const Color(0xFF0D0D0D),
                  iconColor: const Color(0xFF7C4DFF),
                  selected: current == ThemeMode.dark,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  label: 'فاتح',
                  icon: Icons.light_mode_rounded,
                  preview: const Color(0xFFF2F2F7),
                  iconColor: const Color(0xFFFF9500),
                  selected: current == ThemeMode.light,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color preview;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.preview,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : cs.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: preview,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outline),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : cs.onSurfaceVariant,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.black, size: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
