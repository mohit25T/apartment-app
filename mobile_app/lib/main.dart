import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
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

  await Firebase.initializeApp();

  LocalNotificationService.initialize();
  NotificationService.initialize();

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

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
      title: 'Door Pass',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
