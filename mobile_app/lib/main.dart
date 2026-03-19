import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'core/navigation/navigation_service.dart';
import 'core/network/internet_checker.dart';
import 'core/services/sos_alarm_service.dart'; // 🔥 ADD THIS

/// =================================
/// BACKGROUND NOTIFICATION HANDLER
/// =================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// ✅ Initialize local notifications
  await LocalNotificationService.initialize();

  /// ✅ FCM initialization
  await NotificationService.initFcm();

  /// Background notifications
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  /// =================================
  /// 🔥 FOREGROUND NOTIFICATIONS HANDLER
  /// =================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

    final notification = message.notification;
    final data = message.data;

    /// 🚨 SOS ALERT
    if (data["type"] == "SOS_ALERT") {

      // 🔊 PLAY SIREN (bypass silent mode)
      await SOSAlarmService.playAlarm();

      // 📳 START VIBRATION
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000], duration: 1000);
      }

      // 🚨 SHOW SOS NOTIFICATION (custom channel)
      await LocalNotificationService.showSOSNotification(
        notification?.title ?? "🚨 SOS Emergency",
        notification?.body ?? "Emergency Alert",
      );
    } else {
      /// 🔔 NORMAL NOTIFICATION
      if (notification != null) {
        await LocalNotificationService.showNotification(
          notification.title ?? '',
          notification.body ?? '',
        );
      }
    }
  });

  runApp(const MyApp());
}

/// =================================
/// MAIN APP
/// =================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    /// Start internet checker AFTER UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InternetChecker.startListening(navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Door Pass',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
