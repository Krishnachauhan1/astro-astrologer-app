import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class VastuController extends GetxController {
  bool isLoading = false;
  List<String> selectedProblems = [];
  List vastuRequests=[];
  final problems = [
    '💰 Arthik Tangi (Finance)',
    '😴 Neend ki Samasya',
    '⚡ Ghar mein Kalesh',
    '🏥 Swasthya Samasya',
    '💔 Vaivahik Samasya',
    '📚 Shiksha mein Rukawat',
  ];
  void loading(){
    isLoading=!isLoading;
    update();
  }
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    loading();
    getVastuRequest();
    loading();

  }
  void toggleProblem(String p) {
    if (selectedProblems.contains(p)) {
      selectedProblems.remove(p);
    } else {
      selectedProblems.add(p);
    }
    update();
  }

  Future<void> getVastuRequest() async {
    try {
      final res = await ApiService.get('/vastu');
      if (res['success'] == true && res['data'] is List) {
        vastuRequests = List.from(res['data'] as List);
      }
    } catch (e) {
      debugPrint('getVastuRequest error: $e');
    } finally {
      update();
    }
  }
}
