import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'core/navigation/navigation_service.dart';

/// Background notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // 🔐 Request notification permission (IMPORTANT)
  await NotificationService.requestPermission();

  // 📱 Get & print FCM token (IMPORTANT)
  await NotificationService.getFcmToken();

  // Initialize local notifications
  LocalNotificationService.initialize();

  // Initialize notification navigation handling
  NotificationService.initialize();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // Foreground notification handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      LocalNotificationService.showNotification(
        notification.title ?? '',
        notification.body ?? '',
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // required for notification navigation
      debugShowCheckedModeBanner: false,
      title: 'Apartment App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
