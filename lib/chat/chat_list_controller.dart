// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:astrosarthi_konnect_astrologer_app/chat/chat_model.dart';
// import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';

// class ChatListController extends GetxController {
//   List<dynamic> sessions = [];
//   List<ChatMessage> messages = [];

//   bool isLoading = false;
//   int? sessionId;

//   final TextEditingController msgController = TextEditingController();

//   int currentUserId = 1;
//   String currentUserRole = 'user';

//   @override
//   void onInit() {
//     super.onInit();a
//     fetchSessions();
//   }

//   // ✅ FETCH SESSIONS (FIXED)
//   Future<void> fetchSessions() async {
//     print('🚀 Fetching sessions...');

//     try {
//       isLoading = true;
//       update();

//       final res = await ApiService.get('/chat/astrologer/sessions');

//       print("✅ API RESPONSE: $res");

//       if (res['data'] != null && res['data'] is List) {
//         sessions = List.from(res['data']);
//       } else {
//         print("⚠️ No data found");
//         sessions = [];
//       }
//     } catch (e) {
//       print("❌ ERROR: $e");
//       sessions = [];
//     } finally {
//       isLoading = false;
//       update();
//     }
//   }

//   // ✅ SEND MESSAGE (SAFE)
//   Future<void> sendMessage() async {
//     final text = msgController.text.trim();

//     if (text.isEmpty || sessionId == null) {
//       print("⚠️ Message empty OR sessionId null");
//       return;
//     }

//     final optimistic = ChatMessage(id: DateTime.now().millisecondsSinceEpoch, message: text, senderType: currentUserRole, senderId: currentUserId, createdAt: DateTime.now().toIso8601String());

//     messages.add(optimistic);
//     msgController.clear();
//     update();

//     try {
//       await ApiService.post('/chat/$sessionId/message', {'message': text, 'type': 'text'});

//       print("✅ Message sent successfully");
//     } catch (e) {
//       print("❌ ERROR sending message: $e");
//     }
//   }

//   @override
//   void onClose() {
//     msgController.dispose();
//     super.onClose();
//   }
// }

import 'dart:async';

import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_session_filter.dart';

class ChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> sessions = [];
  bool isLoading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  int? _listeningForAstroId;

  int? get _astrologerId {
    if (!Get.isRegistered<AuthController>()) return null;
    return ChatSessionFilter.parseId(Get.find<AuthController>().user?.id);
  }

  @override
  void onInit() {
    super.onInit();
    ensureListening();
  }

  @override
  void onClose() {
    _sessionsSub?.cancel();
    super.onClose();
  }

  /// Call after login/profile load so list binds to the correct astrologer.
  void ensureListening() {
    final astroId = _astrologerId;
    if (astroId == null) {
      sessions = [];
      isLoading = true;
      update();
      return;
    }
    if (_listeningForAstroId == astroId && _sessionsSub != null) return;
    _listeningForAstroId = astroId;
    _sessionsSub?.cancel();
    listenToSessions(astroId);
  }

  void listenToSessions(int astroId) {
    isLoading = true;
    update();

    // Prefer server-side filter; only this astrologer's chats.
    _sessionsSub = _firestore
        .collection('chat_sessions')
        .where('astrologerId', isEqualTo: astroId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            sessions = _mapSessions(snapshot.docs, astroId);
            isLoading = false;
            update();
          },
          onError: (e) {
            debugPrint('Chat list query error: $e');
            _listenAllAndFilterClientSide(astroId);
          },
        );
  }

  void _listenAllAndFilterClientSide(int astroId) {
    _sessionsSub?.cancel();
    _sessionsSub = _firestore
        .collection('chat_sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            sessions = _mapSessions(snapshot.docs, astroId);
            isLoading = false;
            update();
          },
          onError: (e) {
            debugPrint('Stream Error: $e');
            isLoading = false;
            update();
          },
        );
  }

  List<Map<String, dynamic>> _mapSessions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int astroId,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        })
        .where((s) => !ChatSessionFilter.isAssistantSession(s))
        .where((s) => ChatSessionFilter.belongsToAstrologer(
              s,
              astrologerId: astroId,
              docId: s['id']?.toString(),
            ))
        .toList();
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate().toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);

      if (msgDay == today) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }
}
