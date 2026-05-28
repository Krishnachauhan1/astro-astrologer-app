import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AssistantChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> sessions = [];

  @override
  void onInit() {
    super.onInit();
    listenSessions();
  }

  void listenSessions() {
    _firestore
        .collection('assistant_chat_sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snap) {
      sessions = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
      isLoading = false;
      update();
    }, onError: (_) {
      isLoading = false;
      update();
    });
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
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

