import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];
  late String chatId;
  late String userName;
  @override
  void onInit() {
    super.onInit();

    // chatId = "demo_chat";
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    chatId = args['chatId'] ?? 'demo_chat';
    userName = args['userName'] ?? 'User';

    listenMessages();
  }

  /// 🔁 Listen to messages (Realtime)
  void listenMessages() {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            messages = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'message': data['message'] ?? '',
                'isUser': data['isUser'] ?? false,
                'timestamp': data['timestamp'],
              };
            }).toList();
            update();
          },
          onError: (e) {
            print("Message Stream Error==== $e");
          },
        );
  }

  /// 📤 Send message
  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;
    msgController.clear();
    final batch = _firestore.batch();
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'message': text,
      'isUser': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final sessionRef = _firestore.collection('chat_sessions').doc(chatId);
    batch.set(sessionRef, {
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  void onClose() {
    msgController.dispose();
    super.onClose();
  }
}
