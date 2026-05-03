import 'dart:async';

import 'package:astrosarthi_konnect_astrologer_app/calling/agora_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
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


class CallScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const CallScreen({super.key, required this.data});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;

  int seconds = 0;
  Timer? timer;
late AgoraController agora;

@override
void initState() {
  super.initState();

  agora = Get.put(
    AgoraController(
      astrologerId: int.parse(widget.data['astrologer_id'].toString()),
      isVideoCall: widget.data['type'] == 'video',
      astrologerName: widget.data['caller_name'] ?? '',
    ),
  );

  /// 🔥 CALL START
  agora.initiateCall();
}

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  String formatTime(int sec) {
    final minutes = (sec ~/ 60).toString().padLeft(2, '0');
    final seconds = (sec % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void endCall() {
    timer?.cancel();
    Get.back(); // close screen
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.data['caller_name'] ?? "User";
    final callerImage = widget.data['caller_image'] ??
        "https://via.placeholder.com/150";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 40),

            /// 👤 Caller Image
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(callerImage),
            ),

            const SizedBox(height: 20),

            /// 📛 Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// ⏱ Timer
            Text(
              formatTime(seconds),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const Spacer(),

            /// 🎛 Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                /// 🔇 Mute
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            isMuted ? Colors.white : Colors.grey.shade800,
                        child: Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          color: isMuted ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Mute", style: TextStyle(color: Colors.white)),
                  ],
                ),

                /// 🔊 Speaker
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isSpeakerOn = !isSpeakerOn;
                        });
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: isSpeakerOn
                            ? Colors.white
                            : Colors.grey.shade800,
                        child: Icon(
                          Icons.volume_up,
                          color:
                              isSpeakerOn ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Speaker",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),

                /// ❌ End Call
                Column(
                  children: [
                    GestureDetector(
                      onTap: endCall,
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.call_end, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("End",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}