import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/astrologer_identity.dart';
import '../utils/user_privacy.dart';

class AssistantChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> sessions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  String? _listeningKey;

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

  void reset() {
    _sessionsSub?.cancel();
    _sessionsSub = null;
    _listeningKey = null;
    sessions = [];
    isLoading = true;
    update();
  }

  void ensureListening() {
    final key = _currentListenKey();
    if (key == null) {
      sessions = [];
      isLoading = true;
      update();
      return;
    }
    if (_listeningKey == key && _sessionsSub != null) return;

    _listeningKey = key;
    _sessionsSub?.cancel();
    sessions = [];
    isLoading = true;
    update();
    listenSessions();
  }

  String? _currentListenKey() {
    final uid = AstrologerIdentity.userId;
    final rid = AstrologerIdentity.recordId;
    if (uid == null && rid == null) return null;
    return '$uid|$rid';
  }

  int? get _queryAstrologerId =>
      AstrologerIdentity.userId ?? AstrologerIdentity.recordId;

  void listenSessions() {
    final astroId = _queryAstrologerId;
    if (astroId == null) {
      sessions = [];
      isLoading = false;
      update();
      return;
    }

    _sessionsSub = _firestore
        .collection('assistant_chat_sessions')
        .where('astrologerId', isEqualTo: astroId)
        .snapshots()
        .listen(
      (snap) {
        sessions = _sortSessions(_mapSessions(snap.docs));
        isLoading = false;
        update();
      },
      onError: (e) {
        debugPrint('Assistant chat list query error: $e');
        _listenAllAndFilterClientSide();
      },
    );
  }

  void _listenAllAndFilterClientSide() {
    _sessionsSub?.cancel();
    _sessionsSub = _firestore
        .collection('assistant_chat_sessions')
        .snapshots()
        .listen(
      (snap) {
        sessions = _sortSessions(_mapSessions(snap.docs));
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

  int _updatedAtMillis(Map<String, dynamic> session) {
    final updatedAt = session['updatedAt'];
    if (updatedAt is Timestamp) return updatedAt.millisecondsSinceEpoch;
    return 0;
  }

  List<Map<String, dynamic>> _sortSessions(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) => _updatedAtMillis(b).compareTo(_updatedAtMillis(a)));
    return sorted;
  }

  List<Map<String, dynamic>> _mapSessions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((d) {
          final data = stripUserContactFields(d.data());
          data['id'] = d.id;
          return data;
        })
        .where(
          (s) => AstrologerIdentity.sessionBelongsToLoggedInAstrologer(
            s,
            docId: s['id']?.toString(),
          ),
        )
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
