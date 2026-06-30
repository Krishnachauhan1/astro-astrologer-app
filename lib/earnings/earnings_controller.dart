import 'package:astrosarthi_vendor/servicess/api_service.dart';
import 'package:get/get.dart';

class EarningsController extends GetxController {
  bool isLoading = false;
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> daily = [];
  List<Map<String, dynamic>> monthly = [];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading = true;
    update();
    try {
      final summaryRes = await ApiService.get('/astrologer/earnings/summary');
      if (summaryRes['success'] == true && summaryRes['data'] is Map) {
        summary = Map<String, dynamic>.from(summaryRes['data'] as Map);
      }

      final dailyRes = await ApiService.get('/astrologer/earnings/daily?days=30');
      if (dailyRes['success'] == true && dailyRes['data'] is List) {
        daily = (dailyRes['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      final monthlyRes =
          await ApiService.get('/astrologer/earnings/monthly?year=${DateTime.now().year}');
      if (monthlyRes['success'] == true && monthlyRes['data'] is List) {
        monthly = (monthlyRes['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
    } finally {
      isLoading = false;
      update();
    }
  }

  Map<String, dynamic> bucket(String key) {
    final data = summary[key];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String money(dynamic value) => '₹${(double.tryParse('$value') ?? 0).toStringAsFixed(0)}';
}
