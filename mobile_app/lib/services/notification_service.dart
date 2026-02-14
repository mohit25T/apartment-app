import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/navigation/navigation_service.dart';

class NotificationService {
  /// Cache token in memory
  static String? fcmToken;

  /// ===============================
  /// Get FCM token (SAFE)
  /// ===============================
  static Future<String?> getFcmTokenOnly() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("❌ FCM TOKEN ERROR: $e");
      return null;
    }
  }

  /// ===============================
  /// 1️⃣ Init FCM (SAFE for installed APK)
  /// ===============================
  static Future<void> initFcm() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔐 Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      '🔐 Notification permission: ${settings.authorizationStatus}',
    );

    // ⚠️ Initial token MAY be null
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint("📱 FCM TOKEN (initial): $token");
      fcmToken = token;
    } else {
      debugPrint("⏳ FCM token not ready yet");
    }

    // 🔄 This is the MOST IMPORTANT part
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM TOKEN REFRESHED: $newToken");
      fcmToken = newToken;
    });
  }

  /// ===============================
  /// 2️⃣ Notification navigation
  /// ===============================
  static void initialize() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message);
    });
  }

  /// ===============================
  /// 3️⃣ Handle navigation
  /// ===============================
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    final String? type = data['type'];
    final String? visitorId = data['visitorId'];

    debugPrint('🔔 Notification tapped');
    debugPrint('➡️ Type: $type');
    debugPrint('➡️ Visitor ID: $visitorId');

    if (type == "VISITOR_ARRIVED" || type == "OTP_VERIFIED") {
      navigatorKey.currentState?.pushNamed(
        '/resident-visitors',
        arguments: visitorId,
      );
    }
  }
}