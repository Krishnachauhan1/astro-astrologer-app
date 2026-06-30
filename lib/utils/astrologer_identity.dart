import 'package:astrosarthi_vendor/authentication/auth_controller.dart';
import 'package:astrosarthi_vendor/authentication/user_model.dart';
import 'package:astrosarthi_vendor/chat/chat_session_filter.dart';
import 'package:get/get.dart';

/// Resolves which id(s) represent the logged-in astrologer in Firestore chat docs.
class AstrologerIdentity {
  static UserModel? get _user {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>().user;
  }

  /// Laravel user id — most chat sessions store this as `astrologerId`.
  static int? get userId => ChatSessionFilter.parseId(_user?.id);

  /// Optional `astrologers` table id from profile/register payload.
  static int? get recordId => ChatSessionFilter.parseId(_user?.astrologerRecordId);

  static bool matchesField(dynamic value) {
    final id = ChatSessionFilter.parseId(value);
    if (id == null) return false;
    if (userId != null && id == userId) return true;
    if (recordId != null && id == recordId) return true;
    return false;
  }

  static bool sessionBelongsToLoggedInAstrologer(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    return ChatSessionFilter.belongsToLoggedInAstrologer(
      data,
      userId: userId,
      recordId: recordId,
      docId: docId,
    );
  }
}
