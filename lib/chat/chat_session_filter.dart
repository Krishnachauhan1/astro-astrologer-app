/// Helpers to show only sessions belonging to the logged-in astrologer.
class ChatSessionFilter {
  static int? parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : null;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// `chat_sessions` doc id is often `{userId}_{astrologerId}` (user app).
  static bool chatIdBelongsToAstrologer(String chatId, int astrologerId) {
    final parts = chatId.split('_');
    if (parts.length != 2) return false;
    final a = parseId(parts[0]);
    final b = parseId(parts[1]);
    return a == astrologerId || b == astrologerId;
  }

  static bool belongsToAstrologer(
    Map<String, dynamic> data, {
    required int astrologerId,
    String? docId,
  }) {
    final fieldId = parseId(data['astrologerId'] ?? data['astrologer_id']);
    if (fieldId == astrologerId) return true;

    final id = (docId ?? data['id'] ?? data['chatId'] ?? '').toString();
    if (id.isNotEmpty && chatIdBelongsToAstrologer(id, astrologerId)) {
      return true;
    }

    return false;
  }

  static bool isAssistantSession(Map<String, dynamic> data) {
    final t = (data['type'] ?? data['sessionType'] ?? '').toString().toLowerCase();
    return data['isAssistant'] == true || t == 'assistant';
  }
}
