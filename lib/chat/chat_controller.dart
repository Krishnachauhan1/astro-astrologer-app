import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_model.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';

class ChatController extends GetxController {
  List<dynamic> sessions = []; // Chat sessions
  List<ChatMessage> messages = []; // Messages for selected session
  bool isLoading = false;
  int? sessionId;
  final TextEditingController msgController = TextEditingController();

  int currentUserId = 1;
  String currentUserRole = 'user';

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
  }

  // Fetch all active sessions
  Future<void> fetchSessions() async {
    print('fetching session');
    sessions.clear();
    isLoading = true;
    update();

    final res = await ApiService.get('/chat/astrologer/sessions');

    if (res['data'] != null) {
      sessions = List.from(res['data']);
    }

    isLoading = false;  // 👈 yaha rakho
    update();           // 👈 IMPORTANT
  }
  // Fetch messages for a specific session
  Future<void> fetchMessages(int sessionId) async {
    this.sessionId = sessionId;
    final res = await ApiService.get('/chat/$sessionId/messages');
    if (res['data'] != null) {
      messages = (res['data'] as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList();
    } else {
      messages = [];
    }
    update();
  }

  // Send message
  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty || sessionId == null) return;

    final optimistic = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      message: text,
      senderType: currentUserRole,
      senderId: currentUserId,
      createdAt: DateTime.now().toIso8601String(),
    );

    messages.add(optimistic);
    msgController.clear();
    update();

    await ApiService.post('/chat/$sessionId/message', {
      'message': text,
      'type': 'text',
    });

    await fetchMessages(sessionId!);
  }

  @override
  void onClose() {
    msgController.dispose();
    super.onClose();
  }
}