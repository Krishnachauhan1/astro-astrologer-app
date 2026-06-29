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

  static bool _matchesAstrologerId(
    int fieldId, {
    required int? userId,
    required int? recordId,
  }) {
    if (userId != null && fieldId == userId) return true;
    if (recordId != null && fieldId == recordId) return true;
    return false;
  }

  static bool belongsToLoggedInAstrologer(
    Map<String, dynamic> data, {
    required int? userId,
    required int? recordId,
    String? docId,
  }) {
    if (userId == null && recordId == null) return false;

    final fieldId = parseId(data['astrologerId'] ?? data['astrologer_id']);
    if (fieldId != null) {
      return _matchesAstrologerId(fieldId, userId: userId, recordId: recordId);
    }

    final customerId = parseId(
      data['userId'] ??
          data['user_id'] ??
          data['customerId'] ??
          data['customer_id'],
    );
    if (customerId == null) return false;

    final id = (docId ?? data['id'] ?? data['chatId'] ?? '').toString();
    if (id.isEmpty) return false;

    final parts = id.split('_');
    if (parts.length != 2) return false;

    final a = parseId(parts[0]);
    final b = parseId(parts[1]);
    if (a == null || b == null) return false;

    final astroIds = <int>{
      if (userId != null) userId,
      if (recordId != null) recordId,
    };

    // Doc id is `{customerId}_{astrologerId}` in either order.
    final hasCustomerAndAstro = astroIds.any(
      (astroId) =>
          (a == customerId && b == astroId) ||
          (b == customerId && a == astroId),
    );
    return hasCustomerAndAstro;
  }

  /// Legacy helper — prefer [belongsToLoggedInAstrologer].
  static bool belongsToAstrologer(
    Map<String, dynamic> data, {
    required int astrologerId,
    String? docId,
  }) {
    return belongsToLoggedInAstrologer(
      data,
      userId: astrologerId,
      recordId: null,
      docId: docId,
    );
  }

  static bool isAssistantSession(Map<String, dynamic> data) {
    final t =
        (data['type'] ?? data['sessionType'] ?? '').toString().toLowerCase();
    return data['isAssistant'] == true || t == 'assistant';
  }
}
