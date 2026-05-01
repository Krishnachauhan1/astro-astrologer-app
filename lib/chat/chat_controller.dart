import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];
  late String chatId;
  late String userName;
  late String currentUserId;
  final String astrologerId = "astrologer_1";
  final String initialChatId;
  final String initialUserName;
  ChatController({required this.initialChatId, required this.initialUserName});

  @override
  void onInit() {
    super.onInit();
    chatId = initialChatId;
    userName = initialUserName;
    print(" onInit called");
    print("chatId: $chatId");
    print(" userName: $userName");
    currentUserId = "astrologer_1";
    listenMessages();
    if (userName.isEmpty || userName == 'User') {
      fetchUserName();
    }
  }

  Future<void> fetchUserName() async {
    try {
      final doc = await _firestore
          .collection('chat_sessions')
          .doc(chatId)
          .get();

      if (doc.exists) {
        final fetchedName = doc.data()?['userName'] ?? '';
        if (fetchedName.isNotEmpty && fetchedName != 'User') {
          userName = fetchedName;
          print(" Real userName fetched: $userName");
          update();
        }
      }
    } catch (e) {
      print("fetchUserName error: $e");
    }
  }

  /// 🔁 Listen to messages (Realtime)
  void listenMessages() {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
          print("SNAPSHOT: ${snapshot.docs.length}");

          messages = snapshot.docs.map((doc) {
            final data = doc.data();

            return {
              'message': data['text'] ?? '',
              'isUser': data['senderType'] == 'user',
              'timestamp': data['createdAt'],
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
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    final sessionRef = _firestore.collection('chat_sessions').doc(chatId);
    final batch = _firestore.batch();

    ///  MESSAGE SAVE
    batch.set(msgRef, {
      'text': text,
      'senderType': 'astrologer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    /// SESSION CREATE / UPDATE
    batch.set(sessionRef, {
      'chatId': chatId,
      'userId': currentUserId,
      'userName': userName,
      'astrologerId': astrologerId,
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
    await batch.commit();
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final dt = timestamp.toDate().toLocal();

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return "$hour:$minute $period";
  }

  @override
  void onClose() {
    msgController.dispose();
    super.onClose();
  }
}
