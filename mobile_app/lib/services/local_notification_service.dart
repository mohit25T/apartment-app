import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /* ===============================
     INITIALIZE NOTIFICATIONS
  =============================== */

  static Future<void> initialize() async {

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);

    /* ===============================
       🚨 SOS CHANNEL WITH ALARM
    =============================== */

    const AndroidNotificationChannel sosChannel = AndroidNotificationChannel(
      'sos_channel',
      'SOS Alerts',
      description: 'Emergency SOS alerts',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sos_alarm'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(sosChannel);
  }

  /* ===============================
     NORMAL NOTIFICATION
  =============================== */

  static Future<void> showNotification(String title, String body) async {

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  /* ===============================
     🚨 SOS NOTIFICATION WITH SIREN
  =============================== */

  static Future<void> showSOSNotification(
      String title,
      String body,
  ) async {

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sos_channel',
      'SOS Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sos_alarm'),
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1,
      title,
      body,
      details,
    );
  }
}