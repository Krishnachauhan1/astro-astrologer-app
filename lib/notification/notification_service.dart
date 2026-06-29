import 'dart:async';
import 'package:astrosarthi_vendor/calling/audio_call_screen.dart';
import 'package:astrosarthi_vendor/calling/video_call_screen.dart';
import 'package:astrosarthi_vendor/live_stream/live_controller.dart';
import 'package:astrosarthi_vendor/live_stream/live_host_chat_bridge.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:astrosarthi_vendor/utils/fcm_token_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

import '../notification/astrologer_notification_controller.dart';
import '../servicess/api_service.dart';
import '../utils/call_session_api.dart';
import '../utils/session_request_api.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic> _normalizeCallData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final rawCallType = data['callType'] ?? data['call_type'];
    String callType;
    if (rawCallType != null && rawCallType.toString().isNotEmpty) {
      callType = rawCallType.toString();
    } else if (type == 'video_call' || type == 'incoming_video_call') {
      callType = 'video';
    } else {
      callType = 'audio';
    }

    final callerName = 'User';

    // Backend sends `caller_uid` (the customer's user id) for the astrologer
    // to know who is calling. The astrologer side joins Agora with its OWN
    // user id (resolved from AuthController in AgoraController), so we do NOT
    // surface `caller_uid` as `uid` here.
    final callerUid = data['caller_uid'] ?? data['callerUid'];

    return {
      ...data,
      'agora_app_id':
          data['agora_app_id'] ?? data['appId'] ?? data['agoraAppId'],
      'agora_token':
          data['agora_token'] ?? data['token'] ?? data['agoraToken'],
      'channel':
          data['channel'] ?? data['agora_channel'] ?? data['channelId'],
      'session_id':
          data['session_id'] ?? data['sessionId'] ?? data['callSessionId'],
      'caller_uid': callerUid,
      'callerUid': callerUid,
      'rate_per_min': data['rate_per_min'] ?? data['ratePerMin'],
      'callerName': callerName,
      'caller_name': callerName,
      'astrologerName': callerName,
      'caller_image':
          data['caller_image'] ??
          data['callerImage'] ??
          data['astrologerPhoto'],
      'astrologerPhoto':
          data['astrologerPhoto'] ??
          data['caller_image'] ??
          data['callerImage'],
      'callType': callType,
    };
  }

  Future<void> initialize() async {
    final String? token = await resolveFcmToken();
    debugPrint('🔥 FCM TOKEN: $token');
    if (token != null) {
      try {
        final res = await ApiService.post('/user/update-fcm-token', {
          "fcm_token": token,
        });
        debugPrint('✅ FCM token updated: $res');
      } catch (e) {
        debugPrint('❌ FCM update error: $e');
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (!ApiService.isLoggedIn) return;
      try {
        await ApiService.post('/user/update-fcm-token', {"fcm_token": newToken});
      } catch (e) {
        debugPrint('FCM refresh update error: $e');
      }
    });

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      );

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onMessage.listen((message) {
      final data = _normalizeCallData(message.data);
      _refreshNotificationList();
      final type = (data['type'] ?? '').toString().toLowerCase();
      if (type.contains('chat') && !type.contains('accepted')) {
        _showChatRequestBanner(data);
        return;
      }
      if (_isCallMessage(data)) {
        if (_routeVideoToLiveHost(data)) return;
        showIncomingCallPopup(data, data['callType'].toString());
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = _normalizeCallData(message.data);
      if (_isCallMessage(data)) {
        _openCallScreen(data);
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final data = _normalizeCallData(initialMessage.data);
      if (_isCallMessage(data)) {
        Future.delayed(const Duration(seconds: 1), () {
          _openCallScreen(data);
        });
      }
    }

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
      );

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

  void _refreshNotificationList() {
    if (Get.isRegistered<AstrologerNotificationController>()) {
      Get.find<AstrologerNotificationController>().fetchNotifications();
    }
  }

  void _showChatRequestBanner(Map<String, dynamic> data) {
    if (_routeChatToLiveHost(data)) return;

    AppSnackbar.show(
      'Chat request',
      data['caller_name']?.toString() ?? 'A user wants to chat',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () async {
          Get.closeCurrentSnackbar();
          final sessionId = parseCallSessionId(data);
          if (sessionId != null) {
            await SessionRequestApi.acceptSession(sessionId, isChat: true);
          }
          await SessionRequestApi.openSessionFromNotification(data);
        },
        child: const Text('View', style: TextStyle(color: Colors.white)),
      ),
      );
  }

  bool _routeChatToLiveHost(Map<String, dynamic> data) {
    if (!Get.isRegistered<LiveController>()) return false;
    final live = Get.find<LiveController>();
    if (!live.isHostingLive) return false;

    if (LiveHostChatBridge.onIncomingChatWhileLive != null) {
      LiveHostChatBridge.onIncomingChatWhileLive!(data);
      return true;
    }
    live.setPendingChatRequest(data);
    return true;
  }

  bool _isCallMessage(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    return type == 'incoming_call' ||
        type == 'call' ||
        type == 'video_call' ||
        type == 'incoming_video_call' ||
        (data['agora_app_id'] != null && data['channel'] != null);
  }

  bool _routeVideoToLiveHost(Map<String, dynamic> data) {
    final callType = (data['callType'] ?? data['call_type'] ?? '')
        .toString()
        .toLowerCase();
    if (!callType.contains('video')) return false;

    if (!Get.isRegistered<LiveController>()) return false;
    final live = Get.find<LiveController>();
    if (!live.isHostingLive) return false;

    if (LiveHostChatBridge.onIncomingVideoWhileLive != null) {
      LiveHostChatBridge.onIncomingVideoWhileLive!(data);
      return true;
    }
    live.setPendingVideoCallRequest(data);
    return true;
  }

  Future<void> _acceptCall(Map<String, dynamic> data) async {
    var merged = Map<String, dynamic>.from(data);
    final sessionId = parseCallSessionId(data);
    if (sessionId != null) {
      try {
        final res = await ApiService.post('/$sessionId/accept', {});
        if (res['success'] == true && res['data'] is Map) {
          merged = {
            ...merged,
            ...Map<String, dynamic>.from(res['data'] as Map),
          };
        }
      } catch (_) {
        await acceptCallSession(sessionId);
      }
    }
    if (LiveHostChatBridge.tryOpenVideoOnLiveHost?.call(merged) == true) {
      if (Get.isDialogOpen == true) Get.back();
      return;
    }
    _openCallScreen(merged);
  }

  Future<void> _rejectCall(Map<String, dynamic> data) async {
    final sessionId = parseCallSessionId(data);
    if (sessionId != null) {
      await rejectCallSession(sessionId);
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _openCallScreen(Map<String, dynamic> data) {
    if (data['callType'] == 'video' &&
        LiveHostChatBridge.tryOpenVideoOnLiveHost?.call(data) == true) {
      return;
    }
    if (data['callType'] == 'video') {
      Get.to(() => const VideoCallScreen(), arguments: data);
    } else {
      Get.to(() => const AudioCallScreen(), arguments: data);
    }
  }

  void showIncomingCallUI(Map<String, dynamic> data) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.zero,        child: Container(
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
                    onTap: () => _rejectCall(data),
                    child: CircleAvatar(                      radius: 30,
                      child: Icon(Icons.call_end, color: Colors.white),
                    ),
                  ),

                  // ✅ Accept
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      _acceptCall(data);
                    },
                    child: CircleAvatar(                      radius: 30,
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
                          onTap: () => _rejectCall(data),
                        ),

                        /// ACCEPT
                        _callButton(
                          icon: Icons.videocam,
                          color: Colors.green,
                          label: "Accept",
                          onTap: () {
                            Get.back();
                            _acceptCall(data);
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
                          onTap: () => _rejectCall(data),

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
                            _acceptCall(data);
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
