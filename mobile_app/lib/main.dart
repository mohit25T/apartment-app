import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';

import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'core/navigation/navigation_service.dart'; // ✅ USING SAME KEY
import 'core/network/internet_checker.dart';
import 'core/services/sos_alarm_service.dart';
import 'core/services/socket_service.dart';
import 'core/widgets/global_popup.dart';

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

      // 🔊 PLAY SIREN
      await SOSAlarmService.playAlarm();

      // 📳 VIBRATION
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000], duration: 1000);
      }

      // 🚨 SHOW SOS NOTIFICATION
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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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

    /// 🔌 SOCKET SOS LISTENER
    SocketService().sosStream.listen((data) async {
      // 🔊 PLAY SIREN
      await SOSAlarmService.playAlarm();

      // 📳 VIBRATION
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000], duration: 1000);
      }

      // 🚨 SHOW SOS POPUP
      if (navigatorKey.currentContext != null) {
        GlobalPopup.show(
          navigatorKey.currentContext!,
          title: "🚨 EMERGENCY SOS",
          message: data["message"] ?? "Emergency Alert Received",
          type: "SOS",
        );
      }
    });

    /// 🔌 SOCKET VISITOR LISTENER (Local Popups)
    SocketService().visitorStream.listen((data) {
      if (navigatorKey.currentContext == null) return;

      final String status = data["status"] ?? "";
      final String name = data["personName"] ?? "A visitor";

      if (status == "APPROVED") {
        GlobalPopup.show(
          navigatorKey.currentContext!,
          title: "Visitor Approved ✅",
          message: "$name has been approved for entry.",
          type: "SUCCESS",
        );
      } else if (status == "REJECTED") {
        GlobalPopup.show(
          navigatorKey.currentContext!,
          title: "Visitor Rejected ❌",
          message: "$name was rejected entry by the resident.",
          type: "REJECT",
        );
      } else if (status == "PENDING") {
        // Only show arrival popup for residents (backend handles room routing usually)
        GlobalPopup.show(
          navigatorKey.currentContext!,
          title: "Visitor Arrived 🚪",
          message: "$name is waiting at the gate.",
          type: "INFO",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // 🔥 SAME KEY USED EVERYWHERE
      debugShowCheckedModeBanner: false,
      title: 'Door Pass',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
