import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController msgController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> messages = [];

  late String chatId;

  @override
  void onInit() {
    super.onInit();

    // Replace with real IDs
    chatId = "demo_chat";

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
        .listen((snapshot) {

      messages = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'message': data['message'] ?? '',
          'isUser': data['isUser'] ?? false,
          'timestamp': data['timestamp'],
        };
      }).toList();

      update();
    });
  }

  /// 📤 Send message
  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    msgController.clear();

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'message': text,
      'isUser': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    /// Optional: update chat meta
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}