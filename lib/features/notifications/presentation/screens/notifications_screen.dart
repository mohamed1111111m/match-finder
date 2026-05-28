import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    final today = <AppNotificationEntity>[];
    final yesterday = <AppNotificationEntity>[];
    final older = <AppNotificationEntity>[];

    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inHours < 24) {
        today.add(n);
      } else if (diff.inHours < 48) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('الإشعارات'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text('تحديد الكل كمقروء',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('مفيش إشعارات دلوقتي',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (today.isNotEmpty) ...[
                  _SectionLabel(label: 'اليوم'),
                  ...today.asMap().entries.map((e) => _NotifTile(
                        notif: e.value,
                        index: e.key,
                        ref: ref,
                      )),
                ],
                if (yesterday.isNotEmpty) ...[
                  _SectionLabel(label: 'أمس'),
                  ...yesterday.asMap().entries.map((e) => _NotifTile(
                        notif: e.value,
                        index: e.key + today.length,
                        ref: ref,
                      )),
                ],
                if (older.isNotEmpty) ...[
                  _SectionLabel(label: 'سابقاً'),
                  ...older.asMap().entries.map((e) => _NotifTile(
                        notif: e.value,
                        index: e.key + today.length + yesterday.length,
                        ref: ref,
                      )),
                ],
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotificationEntity notif;
  final int index;
  final WidgetRef ref;
  const _NotifTile(
      {required this.notif, required this.index, required this.ref});

  IconData _icon() {
    switch (notif.type) {
      case AppNotificationType.match:
        return Icons.sports_soccer_outlined;
      case AppNotificationType.booking:
        return Icons.stadium_outlined;
      case AppNotificationType.tournament:
        return Icons.emoji_events_outlined;
      case AppNotificationType.support:
        return Icons.support_agent_outlined;
      case AppNotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _color() {
    switch (notif.type) {
      case AppNotificationType.match:
        return AppColors.football;
      case AppNotificationType.booking:
        return AppColors.success;
      case AppNotificationType.tournament:
        return AppColors.primary;
      case AppNotificationType.support:
        return AppColors.info;
      case AppNotificationType.system:
        return AppColors.textMuted;
    }
  }

  String _timeLabel() {
    final diff = DateTime.now().difference(notif.createdAt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} أيام';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return GestureDetector(
      onTap: () {
        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
        if (notif.actionRoute != null && context.mounted) {
          context.push(notif.actionRoute!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? Theme.of(context).colorScheme.outline
                : c.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: c, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: c, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeLabel(),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 40).ms).fadeIn().slideY(begin: 0.04),
    );
  }
}
