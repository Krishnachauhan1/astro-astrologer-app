import 'package:astrosarthi_konnect_astrologer_app/calling/audio_call_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/calling/video_call_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_host_chat_bridge.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:astrosarthi_konnect_astrologer_app/utils/call_session_api.dart';
import 'package:get/get.dart';
import 'app_snackbar.dart';

class SessionRequestApi {
  static List<Map<String, dynamic>> parseNotificationList(
    Map<String, dynamic> res,
  ) {
    final raw = res['data'] ?? res['notifications'] ?? res['items'] ?? res;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> item) {
    if (item['data'] is Map) {
      return Map<String, dynamic>.from(item['data'] as Map);
    }
    if (item['payload'] is Map) {
      return Map<String, dynamic>.from(item['payload'] as Map);
    }
    return item;
  }

  static bool isPendingSessionRequest(Map<String, dynamic> item) {
    final payload = _payload(item);
    final type = (item['type'] ??
            item['notification_type'] ??
            payload['type'] ??
            '')
        .toString()
        .toLowerCase();
    final status = (item['status'] ??
            item['session_status'] ??
            payload['status'] ??
            'pending')
        .toString()
        .toLowerCase();

    if (status != 'pending' && status != 'waiting' && status != 'requested') {
      return false;
    }

    return type.contains('call') ||
        type.contains('chat') ||
        type.contains('session') ||
        type == 'incoming_call' ||
        type == 'incoming_chat';
  }

  static int? parseSessionId(Map<String, dynamic> item) {
    final payload = _payload(item);
    return int.tryParse(
      (item['session_id'] ??
              item['sessionId'] ??
              payload['session_id'] ??
              payload['id'] ??
              item['id'] ??
              '')
          .toString(),
      );
  }

  static Future<bool> acceptSession(
    int sessionId, {
    bool isChat = false,
  }) =>
      isChat ? acceptChatSession(sessionId) : acceptCallSession(sessionId);

  static Future<bool> rejectSession(
    int sessionId, {
    bool isChat = false,
  }) =>
      isChat ? rejectChatSession(sessionId) : rejectCallSession(sessionId);

  static Map<String, dynamic> normalizeCallData(Map<String, dynamic> item) {
    final payload = _payload(item);
    final type = (item['type'] ?? payload['type'] ?? '').toString().toLowerCase();
    final callType = (payload['callType'] ??
            payload['call_type'] ??
            (type.contains('video') ? 'video' : 'audio'))
        .toString();

    return {
      ...payload,
      ...item,
      'agora_app_id':
          payload['agora_app_id'] ?? payload['appId'] ?? item['agora_app_id'],
      'agora_token':
          payload['agora_token'] ?? payload['token'] ?? item['agora_token'],
      'channel': payload['channel'] ??
          payload['agora_channel'] ??
          item['channel'],
      'session_id': parseSessionId(item),
      'caller_uid': payload['caller_uid'] ?? payload['user_id'] ?? payload['callerUid'],
      'caller_name':
          payload['caller_name'] ?? payload['user_name'] ?? item['title'] ?? 'User',
      'caller_image':
          payload['caller_image'] ?? payload['user_avatar'] ?? payload['callerImage'],
      'callType': callType.contains('video') ? 'video' : 'audio',
    };
  }

  static bool isChatRequest(Map<String, dynamic> item) {
    final type = (item['type'] ?? _payload(item)['type'] ?? '')
        .toString()
        .toLowerCase();
    return type.contains('chat');
  }

  static Future<void> openSessionFromNotification(Map<String, dynamic> item) async {
    if (isChatRequest(item)) {
      final sessionId = parseSessionId(item) ?? parseCallSessionId(item);
      if (sessionId != null) {
        await acceptChatSession(sessionId);
      }

      if (LiveHostChatBridge.tryOpenChatOnLiveHost?.call(item) == true) {
        return;
      }

      final payload = _payload(item);
      final chatId = _resolveFirebaseChatId(payload, item);
      final userName =
          payload['user_name']?.toString() ??
          payload['caller_name']?.toString() ??
          item['title']?.toString() ??
          'User';

      if (chatId == null) {
        AppSnackbar.show('Chat', 'Could not open this chat session.');
        return;
      }

      Get.put(
        ChatController(
          initialChatId: chatId,
          initialUserName: userName,
        ),
      );
      await Get.to(() => const ChatScreen());
      return;
    }

    final data = normalizeCallData(item);
    final sessionId = parseSessionId(item) ?? parseCallSessionId(item);
    if (sessionId != null) {
      await acceptCallSession(sessionId);
    }

    if (data['callType'] == 'video' &&
        LiveHostChatBridge.tryOpenVideoOnLiveHost?.call(data) == true) {
      return;
    }

    if (data['callType'] == 'video') {
      await Get.to(() => const VideoCallScreen(), arguments: data);
    } else {
      await Get.to(() => const AudioCallScreen(), arguments: data);
    }
  }

  static String? _resolveFirebaseChatId(
    Map<String, dynamic> payload,
    Map<String, dynamic> item,
  ) {
    if (Get.isRegistered<LiveController>()) {
      return Get.find<LiveController>().resolveFirebaseChatId({
        ...item,
        ...payload,
      });
    }

    final fromPayload =
        (payload['firebase_chat_id'] ?? item['firebase_chat_id'])
            ?.toString()
            .trim();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;
    return null;
  }
}
