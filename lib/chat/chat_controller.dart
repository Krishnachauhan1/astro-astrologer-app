import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_session_filter.dart';

class ChatController extends GetxController {
  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];
  late String chatId;
  late String userName;
  int? customerUserId;
  int? astrologerId;
  final String initialChatId;
  final String initialUserName;
  ChatController({required this.initialChatId, required this.initialUserName});

  @override
  void onInit() {
    super.onInit();
    chatId = initialChatId;
    userName = initialUserName;
    astrologerId = _loggedInAstrologerId();
    _loadSessionMeta();
    listenMessages();
  }

  int? _loggedInAstrologerId() {
    if (!Get.isRegistered<AuthController>()) return null;
    return ChatSessionFilter.parseId(Get.find<AuthController>().user?.id);
  }

  Future<void> _loadSessionMeta() async {
    try {
      final doc = await _firestore.collection('chat_sessions').doc(chatId).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};

      final fetchedName = (data['userName'] ?? '').toString();
      if (fetchedName.isNotEmpty && fetchedName != 'User') {
        userName = fetchedName;
      }

      customerUserId = ChatSessionFilter.parseId(data['userId']);
      final sessionAstroId =
          ChatSessionFilter.parseId(data['astrologerId'] ?? data['astrologer_id']);
      if (sessionAstroId != null) {
        astrologerId = sessionAstroId;
      }
      update();
    } catch (e) {
      debugPrint('loadSessionMeta error: $e');
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
      if (customerUserId != null) 'userId': customerUserId,
      'userName': userName,
      if (astrologerId != null) 'astrologerId': astrologerId,
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
