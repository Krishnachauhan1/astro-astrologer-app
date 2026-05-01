import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
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

  Future<void> getVastuRequest()async{
    final res= await ApiService.get('/vastu');
    if(res['success']){
      vastuRequests=res['data'];
      update();
    }

  }
}
