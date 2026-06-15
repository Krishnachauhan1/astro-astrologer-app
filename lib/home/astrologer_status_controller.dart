import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:get/get.dart';

class AstrologerStatusController extends GetxController {
  String status = 'offline';
  bool isUpdating = false;

  Future<void> setStatus(String next) async {
    if (isUpdating || status == next) return;
    isUpdating = true;
    update();
    try {
      final res = await ApiService.post('/astrologer/status', {'status': next});
      if (res['success'] == true) {
        status = next;
        Get.snackbar('Status', 'You are now $next');
      }
    } catch (e) {
      Get.snackbar('Status', 'Could not update status');
    } finally {
      isUpdating = false;
      update();
    }
  }
}
