import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 🔐 Permission
    await _firebaseMessaging.requestPermission();

    // 📲 TOKEN
    String? token = await _firebaseMessaging.getToken();
    print("🔥 FCM TOKEN: $token");

    // 🔄 Token refresh (IMPORTANT)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔄 NEW TOKEN: $newToken");
      // 👉 Backend API call karke save karo
    });

    // 🔔 Local notification init
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _localNotifications.initialize(settings);

    // 📩 FOREGROUND MESSAGE
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 FOREGROUND MESSAGE: ${message.data}");

      if (message.data.isNotEmpty) {
        _showNotification(message);
      }
    });

    // 👆 APP OPEN FROM NOTIFICATION
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 CLICKED NOTIFICATION: ${message.data}");
    });

    // ⚠️ iOS support
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 🔔 SHOW LOCAL NOTIFICATION
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'calls_channel',
      'Calls',
      channelDescription: 'Incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.data['title'] ?? 'Incoming Call',
      message.data['body'] ?? 'Someone is calling you',
      details,
    );
  }
}