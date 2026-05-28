import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationsNotifier
    extends StateNotifier<List<AppNotificationEntity>> {
  NotificationsNotifier() : super(_seed());

  static List<AppNotificationEntity> _seed() {
    final now = DateTime.now();
    return [
      AppNotificationEntity(
        id: 'notif-001',
        title: 'طلب انضمام للفريق',
        body: 'أحمد محمد طلب الانضمام لفريقك "نسور الإسماعيلية"',
        type: AppNotificationType.match,
        createdAt: now.subtract(const Duration(minutes: 25)),
        actionRoute: '/teams',
      ),
      AppNotificationEntity(
        id: 'notif-002',
        title: 'تأكيد الحجز',
        body: 'تم تأكيد حجزك في ملعب النادي الإسماعيلي — غداً الساعة 6 مساءً',
        type: AppNotificationType.booking,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionRoute: '/venues',
      ),
      AppNotificationEntity(
        id: 'notif-003',
        title: 'بطولة جديدة',
        body: 'تم إضافة بطولة رمضان الإسماعيلي 2026 — سجّل الآن!',
        type: AppNotificationType.tournament,
        createdAt: now.subtract(const Duration(hours: 5)),
        actionRoute: '/tournaments',
      ),
      AppNotificationEntity(
        id: 'notif-004',
        title: 'تحدي فريق',
        body: 'فريق صقور القناة يتحداكم! قبل التحدي قبل انتهاء الوقت',
        type: AppNotificationType.match,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        actionRoute: '/teams',
      ),
      AppNotificationEntity(
        id: 'notif-005',
        title: 'رد من الدعم',
        body: 'شكراً لتواصلك! تم الرد على استفسارك',
        type: AppNotificationType.support,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
        actionRoute: '/support',
      ),
      AppNotificationEntity(
        id: 'notif-006',
        title: 'تحديث التطبيق',
        body: 'تم إضافة ميزة تقسيم الفاتورة في صفحة دور لاعبين',
        type: AppNotificationType.system,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  void markAsRead(String id) {
    state =
        state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotificationEntity>>(
  (ref) => NotificationsNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
