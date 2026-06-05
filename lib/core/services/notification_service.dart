import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../router/app_router.dart';

/// Background message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('FCM background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _fcm;
  FirebaseFirestore? _firestore;
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (AppConfig.isDemoMode) return;

    _fcm = FirebaseMessaging.instance;
    _firestore = FirebaseFirestore.instance;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNavigation(data);
          } catch (e) {
            AppLogger.error('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Request permission (iOS & Android 13+)
    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _initToken();
    }

    // Subscribe to global topic
    await _fcm!.subscribeToTopic(AppConstants.fcmTopicAll);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  Future<void> _initToken() async {
    _fcmToken = await _fcm!.getToken();
    AppLogger.info('FCM token: $_fcmToken');

    _fcm!.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      AppLogger.info('FCM token refreshed');
    });
  }

  Future<void> saveTokenForUser(String userId) async {
    if (_fcmToken == null || _firestore == null) return;
    try {
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(
              {'fcmToken': _fcmToken, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.error('Failed to save FCM token', e);
    }
  }

  Future<void> subscribeToTournament(String tournamentId) async {
    await _fcm?.subscribeToTopic('tournament_$tournamentId');
  }

  Future<void> unsubscribeFromTournament(String tournamentId) async {
    await _fcm?.unsubscribeFromTopic('tournament_$tournamentId');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('FCM foreground: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF2E7D32), // green #2E7D32
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    AppLogger.info('Notification tapped: ${message.data}');
    _handleNavigation(message.data);
  }

  void _handleNavigation(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    final context = rootNavigatorKey.currentContext;
    if (route != null && context != null) {
      context.push(route);
    }
  }

  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_firestore == null) return;
    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.notificationsCollection)
        .add({
      'title': title,
      'body': body,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
