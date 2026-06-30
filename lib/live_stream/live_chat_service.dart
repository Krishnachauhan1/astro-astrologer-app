import 'package:astrosarthi_vendor/servicess/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Matches user app [LiveChatService] Firestore paths.
class LiveChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> streamDoc(int streamId) =>
      _firestore.collection('live_streams').doc('$streamId');

  static CollectionReference<Map<String, dynamic>> commentsRef(int streamId) =>
      streamDoc(streamId).collection('comments');

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchComments(
    int streamId,
  ) {
    return commentsRef(streamId)
        .orderBy('createdAt', descending: false)
        .limit(150)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchCommentsFallback(
    int streamId,
  ) {
    return commentsRef(streamId).limit(150).snapshots();
  }

  static Future<void> postCommentApi({
    required int streamId,
    required String text,
    bool isHost = true,
  }) async {
    await ApiService.post('/live-streams/$streamId/comments', {
      'text': text,
      'message': text,
      'is_host': isHost,
    });
  }

  static Future<void> writeCommentFirestore({
    required int streamId,
    required String text,
    required String userName,
    String? userId,
    int? astrologerId,
    String? astrologerName,
    bool isHost = true,
    String? apiCommentId,
  }) async {
    final commentRef = apiCommentId != null && apiCommentId.isNotEmpty
        ? commentsRef(streamId).doc(apiCommentId)
        : commentsRef(streamId).doc();

    final batch = _firestore.batch();

    batch.set(commentRef, {
      'text': text,
      'userName': userName,
      'userId': userId,
      'userPhoto': '',
      'isHost': isHost,
      'senderType': isHost ? 'host' : 'user',
      if (astrologerId != null) 'astrologerId': astrologerId,
      'apiSynced': apiCommentId != null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      streamDoc(streamId),
      {
        'streamId': streamId,
        if (astrologerId != null) 'astrologerId': astrologerId,
        if (astrologerName != null) 'astrologerName': astrologerName,
        'lastMessage': text,
        'lastUserName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'live',
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static String? extractCommentId(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) {
      final id = data['id'] ?? data['comment_id'];
      if (id != null) return id.toString();
    }
    final id = res['id'] ?? res['comment_id'];
    return id?.toString();
  }

  static Future<void> sendHostComment({
    required int streamId,
    required String text,
    required String userName,
    String? userId,
    int? astrologerId,
    String? astrologerName,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    String? apiId;
    try {
      final res = await ApiService.post('/live-streams/$streamId/comments', {
        'text': cleaned,
        'message': cleaned,
        'is_host': true,
      });
      apiId = extractCommentId(res);
    } catch (e) {
      // Firestore still delivers message to viewers if API fails.
    }

    await writeCommentFirestore(
      streamId: streamId,
      text: cleaned,
      userName: userName,
      userId: userId,
      astrologerId: astrologerId,
      astrologerName: astrologerName,
      isHost: true,
      apiCommentId: apiId,
    );
  }

  static List<Map<String, String>> mapAndSortCommentDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final entries = docs.map((d) {
      final m = d.data();
      final createdAt = m['createdAt'];
      int millis = 0;
      if (createdAt is Timestamp) {
        millis = createdAt.millisecondsSinceEpoch;
      }
      final name =
          (m['userName'] ?? m['senderName'] ?? m['sender'] ?? 'User')
              .toString();
      final text = (m['text'] ?? m['message'] ?? '').toString();
      return (millis, {'user': name, 'msg': text});
    }).toList();

    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return entries.map((e) => e.$2).toList();
  }
}
