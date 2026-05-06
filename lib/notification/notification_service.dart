import 'dart:async';
import 'package:astrosarthi_konnect_astrologer_app/calling/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

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
  if (message.data['type'] == 'incoming_call') {
    Get.to(() => CallScreen(data: message.data));
  }
});

RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

if (initialMessage != null) {
  if (initialMessage.data['type'] == 'incoming_call') {
    Future.delayed(const Duration(seconds: 1), () {
      Get.to(() => CallScreen(data: initialMessage.data));
    });
  }
}
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
  // ignore: unused_element
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

void showIncomingCallUI(Map<String, dynamic> data) {
  Get.dialog(
    Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                data['caller_image'] ??
                    'https://via.placeholder.com/150',
              ),
            ),
            SizedBox(height: 20),

            Text(
              data['caller_name'] ?? "Unknown Caller",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),

            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ❌ Reject
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 30,
                    child: Icon(Icons.call_end, color: Colors.white),
                  ),
                ),

                // ✅ Accept
                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.to(() => CallScreen(data: data));
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 30,
                    child: Icon(Icons.call, color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}
