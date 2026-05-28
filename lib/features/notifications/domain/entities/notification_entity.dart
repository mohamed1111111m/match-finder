enum AppNotificationType { match, booking, tournament, system, support }

class AppNotificationEntity {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;

  const AppNotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  AppNotificationEntity copyWith({bool? isRead}) {
    return AppNotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
    );
  }
}
