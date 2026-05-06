import 'dart:async';
import 'package:astrosarthi_konnect_astrologer_app/calling/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../servicess/api_service.dart';

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
    if (token != null) {
      try {
        final res = await ApiService.post('/user/update-fcm-token', {
          "fcm_token": token,
        });
        print("✅ FCM token updated: $res");
      } catch (e) {
        print("❌ FCM update error: $e");
      }

      // 🔄 Token refresh (IMPORTANT)
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print("🔄 NEW TOKEN: $newToken");
        // 👉 Backend API call karke save karo
      });

      // 🔔 Local notification init
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidInit,
      );

      await _localNotifications.initialize(settings);

      // 📩 FOREGROUND MESSAGE
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("FULL MESSAGE DATA = ${message.data}");
        print("FULL MESSAGE DATA = ${message.notification}");
        if (message.data['type'] == 'incoming_call') {
          Future.delayed(Duration(milliseconds: 300), () {
            showGeneralDialog(
              context: Get.context!,
              barrierDismissible: false,
              barrierLabel: "Incoming Call",
              transitionDuration: Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) {
                return SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xff1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            /// Caller Image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.greenAccent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade800,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            SizedBox(width: 14),

                            /// Caller Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Incoming Call",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    message.data['title'] ?? "User Calling",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    message.data['body'] ?? "Audio Call",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Decline Button
                            GestureDetector(
                              onTap: () {
                                Get.back();
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.call_end,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),

                            /// Accept Button
                            GestureDetector(
                              onTap: () {
                                Get.back();
                                Get.to(() => CallScreen(data: message.data));
                                print(
                                  'printing message data: ${message.data.toString()}',
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),

                                child: Icon(Icons.call, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },

              transitionBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: Offset(0, -1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            );
          });
        }
      });
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        if (initialMessage.data['type'] == 'incoming_call') {
          Future.delayed(const Duration(seconds: 1), () {
            showIncomingCallUI(initialMessage.data);
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

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

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
                  data['caller_image'] ?? 'https://via.placeholder.com/150',
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
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
