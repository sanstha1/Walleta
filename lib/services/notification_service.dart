import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:spensr/config/api_config.dart';
import 'package:spensr/services/token_service.dart';

// ── Must be top-level (not inside a class) ────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background FCM: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging               _messaging          = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _channelDesc = 'Spensr Payment Alerts';

  static Future<void> initialize() async {
    // 1. Register background handler FIRST
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission
    final settings = await _messaging.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      announcement:  false,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Notification permission denied');
      return;
    }

    // 3. Initialize local notifications — v20 uses named 'settings:' parameter
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );
await _localNotifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.deleteNotificationChannel(channelId: _channelId);
   
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName, 
           description: _channelDesc,
        importance: Importance.max,        
        playSound: true,                  
        enableVibration: true,           
        enableLights: true,              
          ),
        );

    // 5. Save FCM token to backend
    final token = await _messaging.getToken();
    debugPrint('📱 FCM Token: $token');
    if (token != null) await _saveTokenToBackend(token);

    // Refresh token listener
    _messaging.onTokenRefresh.listen(_saveTokenToBackend);

    // 6. Show local popup when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      debugPrint('📩 Foreground FCM: ${notification.title}');

      showLocalNotification(
        title: notification.title ?? 'Notification',
        body:  notification.body  ?? '',
      );
    });

    debugPrint('✅ NotificationService initialized');
  }
// notification_service.dart — add this method
static Future<void> syncFcmToken() async {
  final token = await _messaging.getToken();
  debugPrint('📱 Syncing FCM Token post-login: $token');
  if (token != null) await _saveTokenToBackend(token);
}
  // ── Save device FCM token to backend ─────────────────────────────────────
  static Future<void> _saveTokenToBackend(String fcmToken) async {
    try {
      final jwt = await TokenService.getToken();
      if (jwt == null) {
        debugPrint('⚠️ No JWT — skipping FCM token save');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/fcm-token'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token saved to backend');
      } else {
        debugPrint('❌ FCM token save failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FCM token save error: $e');
    }
  }

  // ── Show local notification (foreground + called from eSewa.dart) ─────────
  // v20: show() uses named parameters — id:, title:, body:, notificationDetails:
  static void showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _localNotifications.show(
      id:                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title:               title,
      body:                body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance:         Importance.max,
          priority:           Priority.high,
          icon:               '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<String?> getToken() async => _messaging.getToken();
}