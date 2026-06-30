import 'dart:async';
import 'package:astrosarthi_vendor/authentication/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AssistantChatController extends GetxController {
  static const int freeMessageLimit = 5;

  final String sessionId;
  AssistantChatController({String? sessionId})
    : sessionId = sessionId ?? _defaultSessionId();

  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;

  int freeUsed = 0;
  DateTime? paidUntil;
  bool isLoading = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _quotaSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _msgSub;

  static String _defaultSessionId() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final id = auth.user?.id;
      if (id != null && id > 0) return id.toString();
    }
    return 'guest';
  }

  /// Similar to `chat_sessions`, but for assistant usage tracking + list view.
  DocumentReference<Map<String, dynamic>> get _sessionRef =>
      _firestore.collection('assistant_chat_sessions').doc(sessionId);

  /// Similar to `chats/{chatId}/messages`, but for assistant thread.
  CollectionReference<Map<String, dynamic>> get _messagesRef => _firestore
      .collection('assistant_chats')
      .doc(sessionId)
      .collection('messages');

  bool get isPaid =>
      paidUntil != null && paidUntil!.isAfter(DateTime.now().toUtc());

  int get freeRemaining =>
      (freeMessageLimit - freeUsed).clamp(0, freeMessageLimit);

  bool get canSend => isPaid || freeUsed < freeMessageLimit;

  @override
  void onInit() {
    super.onInit();
    _listenQuota();
    _listenMessages();
  }

  @override
  void onClose() {
    _quotaSub?.cancel();
    _msgSub?.cancel();
    msgController.dispose();
    super.onClose();
  }

  void _listenQuota() {
    _quotaSub = _sessionRef.snapshots().listen((snap) {
      final data = snap.data() ?? {};
      freeUsed = (data['freeUsed'] is int)
          ? data['freeUsed'] as int
          : int.tryParse('${data['freeUsed'] ?? 0}') ?? 0;

      final ts = data['paidUntil'];
      if (ts is Timestamp) {
        paidUntil = ts.toDate().toUtc();
      } else {
        paidUntil = null;
      }
      update();
    });
  }

  void _listenMessages() {
    _msgSub = _messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snap) {
            messages = snap.docs.map((d) {
              final data = d.data();
              return {
                'message': (data['text'] ?? '').toString(),
                'isUser': (data['sender'] ?? 'user') == 'user',
                'createdAt': data['createdAt'],
              };
            }).toList();
            isLoading = false;
            update();
          },
          onError: (_) {
            isLoading = false;
            update();
          },
        );
  }

  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;
    if (!canSend) {
      await _showLimitReached();
      return;
    }

    msgController.clear();

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final userName = (auth?.user?.name ?? 'Astrologer').toString();
    final userId = auth?.user?.id;

    await _sessionRef.set({
      'userId': userId,
      'userName': userName,
      'freeUsed': freeUsed,
      'status': 'active',
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _messagesRef.add({
      'text': text,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    isTyping = true;
    update();

    await Future.delayed(const Duration(milliseconds: 600));

    final reply = _makeReply(text);
    await _messagesRef.add({
      'text': reply,
      'sender': 'assistant',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!isPaid) {
      await _sessionRef.set({
        'freeUsed': FieldValue.increment(1),
        'lastMessage': reply,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    isTyping = false;
    update();
  }

  /// Astrologer-side: send a message as "Assistant" for this session.
  /// This does NOT consume free quota (free quota is for user messages).
  Future<void> sendAssistantMessage(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    await _messagesRef.add({
      'text': cleaned,
      'sender': 'assistant',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sessionRef.set({
      'lastMessage': cleaned,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
  }

  Future<void> _showLimitReached() async {
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Assistant limit reached'),
        content: const Text(
          'You have used 5 free assistant messages.\n\nUser can purchase chat time from the User app to continue.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
      barrierDismissible: true,
    );
  }

  String _makeReply(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('career')) {
      return [
        'Option 1: I can guide you—please share your DOB, time, and place, plus your current job situation.',
        'Option 2: Let’s check near-term opportunities. Are you looking for a switch, promotion, or business start?',
        'Option 3: I’ll suggest remedies after analysis. For now, avoid hasty decisions for 2–3 weeks and focus on skill upgrades.',
      ].join('\n\n');
    }
    if (p.contains('marriage') || p.contains('relationship')) {
      return [
        'Option 1: I’ll check compatibility and timing—please share both DOB/time/place.',
        'Option 2: Tell me the main concern (delay, conflicts, or commitment) so I can guide precisely.',
        'Option 3: For peace, do a short daily prayer/meditation; I’ll share a tailored remedy after chart review.',
      ].join('\n\n');
    }
    return 'I can help you draft a professional reply. Share the user’s question and any details you want to include.';
  }
}
