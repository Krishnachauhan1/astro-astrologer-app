import '../servicess/api_service.dart';

int? parseCallSessionId(Map<String, dynamic> data) {
  return int.tryParse(
    (data['session_id'] ?? data['sessionId'] ?? data['callSessionId'] ?? '')
        .toString(),
  );
}

Future<bool> acceptCallSession(int sessionId) async {
  try {
    final res = await ApiService.post('/$sessionId/accept', {});
    return res['success'] == true;
  } catch (_) {
    return false;
  }
}

Future<bool> rejectCallSession(int sessionId) async {
  try {
    final res = await ApiService.post('/$sessionId/reject', {});
    return res['success'] == true;
  } catch (_) {
    return false;
  }
}

Future<bool> acceptChatSession(int sessionId) async {
  try {
    final res = await ApiService.post('/chat/$sessionId/accept', {});
    return res['success'] == true;
  } catch (_) {
    return false;
  }
}

Future<bool> rejectChatSession(int sessionId) async {
  try {
    final res = await ApiService.post('/chat/$sessionId/reject', {});
    return res['success'] == true;
  } catch (_) {
    return false;
  }
}

Future<void> endCallSession(int sessionId) async {
  try {
    await ApiService.post('/$sessionId/end', {});
  } catch (_) {}
}
