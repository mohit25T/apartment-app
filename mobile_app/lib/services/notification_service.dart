import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/navigation/navigation_service.dart';

class NotificationService {
  static String? fcmToken;

  /// 🔥 Prevent double navigation
  static bool openedFromNotification = false;

  /* ===============================
     🔐 GET TOKEN SAFE
  =============================== */
  static Future<String?> getFcmTokenOnly() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("❌ FCM TOKEN ERROR: $e");
      return null;
    }
  }

  /* ===============================
     1️⃣ INIT FCM
  =============================== */
  static Future<void> initFcm() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔐 Notification permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    if (token != null) {
      debugPrint("📱 FCM TOKEN: $token");
      fcmToken = token;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM TOKEN REFRESHED: $newToken");
      fcmToken = newToken;
    });

    _setupMessageHandlers();
  }

  /* ===============================
     2️⃣ SETUP MESSAGE HANDLERS
  =============================== */
  static void _setupMessageHandlers() {
    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint("🚀 Opened from terminated via notification");
        _handleNotificationNavigation(message);
      }
    });

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("🚀 Opened from background via notification");
      _handleNotificationNavigation(message);
    });

    // Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("📩 Foreground message received");
      debugPrint("📦 Data: ${message.data}");
    });
  }

  /* ===============================
     3️⃣ HANDLE NAVIGATION
  =============================== */
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    debugPrint("🔔 Notification Clicked");
    debugPrint("📦 Payload: $data");

    if (data.isEmpty) {
      debugPrint("❌ No data payload found");
      return;
    }

    openedFromNotification = true;

    final type = data['type'];

    // Small delay ensures navigator is ready
    Future.delayed(const Duration(milliseconds: 400), () {
      switch (type) {
        /* ================= VISITOR ================= */
        case "VISITOR_ARRIVED":
        case "OTP_VERIFIED":
          navigatorKey.currentState?.pushReplacementNamed(
            '/resident-visitors',
            arguments: data['visitorId'],
          );
          break;

        /* ================= COMPLAINT ================= */
        case "COMPLAINT_CREATED":
        case "COMPLAINT_UPDATED":
          navigatorKey.currentState?.pushReplacementNamed(
            '/complaints',
            arguments: data['complaintId'],
          );
          break;

        /* ================= MAINTENANCE ================= */
        case "MAINTENANCE_GENERATED":
        case "MAINTENANCE_PAID":
          navigatorKey.currentState?.pushReplacementNamed(
            '/maintenance',
          );
          break;

        /* ================= DEFAULT ================= */
        default:
          navigatorKey.currentState?.pushReplacementNamed('/dashboard');
      }
    });
  }
}
