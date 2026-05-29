import 'dart:async';

import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_session_filter.dart';

class AssistantChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> sessions = [];
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
    listenSessions(astroId);
  }

  void listenSessions(int astroId) {
    isLoading = true;
    update();

    _sessionsSub = _firestore
        .collection('assistant_chat_sessions')
        .where('astrologerId', isEqualTo: astroId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        sessions = _mapSessions(snap.docs, astroId);
        isLoading = false;
        update();
      },
      onError: (e) {
        debugPrint('Assistant chat list query error: $e');
        _listenAllAndFilterClientSide(astroId);
      },
    );
  }

  void _listenAllAndFilterClientSide(int astroId) {
    _sessionsSub?.cancel();
    _sessionsSub = _firestore
        .collection('assistant_chat_sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        sessions = _mapSessions(snap.docs, astroId);
        isLoading = false;
        update();
      },
      onError: (e) {
        debugPrint('Assistant chat list stream error: $e');
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
        .map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        })
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
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
