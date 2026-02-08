import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/navigation/navigation_service.dart';

class NotificationService {
  /// ===============================
  /// 1️⃣ Request notification permission
  /// ===============================
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

  /// ===============================
  /// 2️⃣ Get FCM token
  /// ===============================
  static Future<void> getFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM TOKEN: $token');
  }

  /// ===============================
  /// 3️⃣ Initialize notification handlers
  /// ===============================
  static void initialize() {
    /// App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });

    /// App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message);
    });
  }

  /// ===============================
  /// 4️⃣ Handle notification navigation
  /// ===============================
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    final String? type = data['type'];
    final String? visitorId = data['visitorId'];

    debugPrint('🔔 Notification tapped');
    debugPrint('➡️ Type: $type');
    debugPrint('➡️ Visitor ID: $visitorId');

    /// Resident approval flow
    if (type == "VISITOR_ARRIVED" || type == "OTP_VERIFIED") {
      navigatorKey.currentState?.pushNamed(
        '/visitor-approval',
        arguments: visitorId,
      );
    }
  }
}
