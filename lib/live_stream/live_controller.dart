import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_stream_model.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:get/get.dart';

class LiveController extends GetxController {
  List<LiveStreamModel> streams = [];
  bool isLoading = false;

  @override
  void onInit() {
    super.onInit();
    fetchStreams();
  }

  Future<void> fetchStreams() async {
    isLoading = true;
    update();

    final res = await ApiService.get('/live-streams');
    print('live data ${res['data']['data']}');

    isLoading = false;

    final data = res['data']['data'];

    if (data.isEmpty) {
      streams = _mock();
    } else {
      streams = (data as List)
          .map((e) => LiveStreamModel.fromJson(e))
          .toList();
    }

    update();
  }
  List<LiveStreamModel> _mock() => [
    LiveStreamModel(id: 1, title: 'Shani Sade Sati — Upay', astrologerName: 'Pt. Suresh Sharma', viewers: 342),
    LiveStreamModel(id: 2, title: 'Tarot Card Reading Live', astrologerName: 'Dr. Priya Joshi', viewers: 215),
    LiveStreamModel(id: 3, title: 'Kundali Milan Special', astrologerName: 'Acharya Ram Das', viewers: 589),
  ];
}
