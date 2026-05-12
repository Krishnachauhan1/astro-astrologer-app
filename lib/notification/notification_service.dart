import 'dart:async';
import 'package:astrosarthi_konnect_astrologer_app/calling/call_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/calling/video_call_screen.dart';
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
  Map<String, dynamic> _normalizeCallData(Map<String, dynamic> data) {
    return {
      ...data,
      'channel': data['channel'] ?? data['agora_channel'] ?? data['channelId'],
      'callerName':
          data['callerName'] ??
          data['caller_name'] ??
          data['title'] ??
          'Unknown Caller',
      'caller_image': data['caller_image'] ?? data['callerImage'],
      'callType':
          data['callType'] ?? data['call_type'] ?? data['type'] ?? 'audio',
    };
  }

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
      FirebaseMessaging.onMessage.listen((message) {
        print("MESSAGE RECEIVED");
        print("MESSAGE = ${message.data}");
        final data = _normalizeCallData(message.data);
        if (data['type'] == 'incoming_call' || data['type'] == 'call') {
          showIncomingCallPopup(data, data['callType'].toString());
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final data = _normalizeCallData(message.data);
        if (data['type'] == 'incoming_call' || data['type'] == 'call') {
          _openCallScreen(data);
        }
      });

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        final data = _normalizeCallData(initialMessage.data);
        if (data['type'] == 'call') {
          Future.delayed(const Duration(seconds: 1), () {
            _openCallScreen(data);
          });
        }
      }

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

  void _openCallScreen(Map<String, dynamic> data) {
    if (data['callType'] == 'video') {
      Get.to(() => const VideoCallScreen(), arguments: data);
    } else {
      Get.to(() => CallScreen(data: data));
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

  void showIncomingCallPopup(Map<String, dynamic> data, String callType) {
    final callerName =
        data['callerName'] ?? data['caller_name'] ?? 'Unknown Caller';

    final callerImage = data['caller_image'] ?? 'https://i.pravatar.cc/300';

    /// =========================
    /// VIDEO CALL UI
    /// =========================
    if (callType == 'video') {
      Get.dialog(
        PopScope(
          canPop: false,

          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.92),

            body: SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),

                child: Column(
                  children: [
                    /// TITLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: const Text(
                        'Incoming Video Call',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// IMAGE
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),

                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(callerImage),
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// NAME
                    Text(
                      callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Video calling...',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),

                    const Spacer(),

                    /// BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                      children: [
                        /// DECLINE
                        _callButton(
                          icon: Icons.call_end,
                          color: Colors.red,
                          label: "Decline",
                          onTap: () {
                            Get.back();
                          },
                        ),

                        /// ACCEPT
                        _callButton(
                          icon: Icons.videocam,
                          color: Colors.green,
                          label: "Accept",
                          onTap: () {
                            Get.back();

                            Get.to(
                              () => const VideoCallScreen(),
                              arguments: data,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),

        barrierDismissible: false,
      );
    }
    /// =========================
    /// AUDIO CALL UI
    /// =========================
    else {
      Future.delayed(const Duration(milliseconds: 200), () {
        showGeneralDialog(
          context: Get.context!,
          barrierDismissible: false,
          barrierLabel: "Incoming Audio Call",

          transitionDuration: const Duration(milliseconds: 350),

          pageBuilder: (_, __, ___) {
            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,

                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xff1E1E1E),
                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Material(
                    color: Colors.transparent,

                    child: Row(
                      children: [
                        /// IMAGE
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(callerImage),
                        ),

                        const SizedBox(width: 14),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            mainAxisSize: MainAxisSize.min,

                            children: [
                              const Text(
                                "Incoming Audio Call",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                callerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// DECLINE
                        GestureDetector(
                          onTap: () {
                            Get.back();
                          },

                          child: Container(
                            padding: const EdgeInsets.all(12),

                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// ACCEPT
                        GestureDetector(
                          onTap: () {
                            Get.back();

                            Get.to(() => CallScreen(data: data));
                          },

                          child: Container(
                            padding: const EdgeInsets.all(12),

                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(Icons.call, color: Colors.white),
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
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),

              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      });
    }
  }

  /// =========================
  /// COMMON BUTTON WIDGET
  /// =========================
  Widget _callButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,

          child: Container(
            height: 72,
            width: 72,

            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }
}
