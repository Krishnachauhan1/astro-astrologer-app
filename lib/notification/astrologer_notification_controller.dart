import 'package:astrosarthi_vendor/servicess/api_service.dart';
import 'package:astrosarthi_vendor/utils/session_request_api.dart';
import 'package:get/get.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';

class AstrologerNotificationController extends GetxController {
  bool isLoading = false;
  List<Map<String, dynamic>> items = [];

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading = true;
    update();
    try {
      final res = await ApiService.get('/notifications');
      items = SessionRequestApi.parseNotificationList(res)
          .where(SessionRequestApi.isPendingSessionRequest)
          .toList();
    } catch (_) {
      items = [];
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> accept(Map<String, dynamic> item) async {
    final sessionId = SessionRequestApi.parseSessionId(item);
    if (sessionId == null) return;

    final isChat = SessionRequestApi.isChatRequest(item);
    final ok = await SessionRequestApi.acceptSession(sessionId, isChat: isChat);
    if (!ok) {
      AppSnackbar.show(
        'Request',
        'Could not accept. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await SessionRequestApi.openSessionFromNotification(item);
    await fetchNotifications();
  }

  Future<void> reject(Map<String, dynamic> item) async {
    final sessionId = SessionRequestApi.parseSessionId(item);
    if (sessionId == null) return;
    await SessionRequestApi.rejectSession(
      sessionId,
      isChat: SessionRequestApi.isChatRequest(item),
      );
    await fetchNotifications();
  }
}
