import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  late FirebaseMessaging _firebaseMessaging;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    await _firebaseMessaging.requestPermission();

    String? token = await _firebaseMessaging.getToken();
    print("FCM Token============ $token");

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidInit);

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
    _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true,);

  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'This is important channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // 👈 unique id
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      details,
    );
  }
}