import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/astrologer_identity.dart';
import 'chat_session_filter.dart';

class ChatController extends GetxController {
  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];
  late String chatId;
  late String userName;
  int? customerUserId;
  int? astrologerId;
  DateTime? sessionExpiresAt;
  Timer? _sessionTimer;
  final String initialChatId;
  final String initialUserName;
  ChatController({required this.initialChatId, required this.initialUserName});

  Duration get sessionRemaining {
    if (sessionExpiresAt == null) return Duration.zero;
    final rem = sessionExpiresAt!.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }

  String get countdownLabel {
    final totalSec = sessionRemaining.inSeconds.clamp(0, 9999);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get showSessionTimer =>
      sessionExpiresAt != null && sessionRemaining > Duration.zero;

  @override
  void onInit() {
    super.onInit();
    chatId = initialChatId;
    userName = initialUserName;
    astrologerId = _loggedInAstrologerId();
    _loadSessionMeta();
    _listenSessionTimer();
    listenMessages();
  }

  void _listenSessionTimer() {
    _firestore.collection('chat_sessions').doc(chatId).snapshots().listen((
      doc,
    ) {
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      DateTime? nextExpiry;

      final expiresAt = data['expiresAt'];
      if (expiresAt is Timestamp) {
        nextExpiry = expiresAt.toDate();
      } else if (expiresAt != null) {
        nextExpiry = DateTime.tryParse(expiresAt.toString());
      }

      if (data['status'] == 'paused') {
        final remSec = data['remainingSeconds'];
        final secs = remSec is int ? remSec : int.tryParse('$remSec') ?? 0;
        if (secs > 0) {
          nextExpiry = DateTime.now().add(Duration(seconds: secs));
        }
      }

      if (nextExpiry != sessionExpiresAt) {
        sessionExpiresAt = nextExpiry;
        _startSessionTimer();
        update();
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    if (sessionExpiresAt == null) return;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sessionRemaining <= Duration.zero) {
        _sessionTimer?.cancel();
      }
      update();
    });
  }

  int? _loggedInAstrologerId() =>
      AstrologerIdentity.userId ?? AstrologerIdentity.recordId;

  Future<void> _loadSessionMeta() async {
    try {
      final doc = await _firestore
          .collection('chat_sessions')
          .doc(chatId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};

      final fetchedName = (data['userName'] ?? '').toString();
      if (fetchedName.isNotEmpty && fetchedName != 'User') {
        userName = fetchedName;
      }

      customerUserId = ChatSessionFilter.parseId(data['userId']);
      final sessionAstroId = ChatSessionFilter.parseId(
        data['astrologerId'] ?? data['astrologer_id'],
      );
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
    _sessionTimer?.cancel();
    msgController.dispose();
    super.onClose();
  }
}
