import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      '🔐 Notification permission status: ${settings.authorizationStatus}',
    );
  }

  static Future<void> getFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM TOKEN: $token');
  }
}
