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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> sessions = [];
  bool isLoading = true;

  @override
  void onInit() {
    super.onInit();
    listenToSessions();
  }

  void listenToSessions() {
    _firestore
        .collection('chat_sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            sessions = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            print(" Sessions: ${sessions.length}");
            isLoading = false;
            update();
          },
          onError: (e) {
            print("Stream Error: $e");
            isLoading = false;
            update();
          },
        );
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
