import 'package:astrosarthi_konnect_astrologer_app/authentication/user_model.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  bool isLoggedIn = false;
  bool isLoading = false;
  UserModel? user;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (ApiService.isLoggedIn) {
        await ApiService.post('/user/update-fcm-token', {
          "fcm_token": newToken,
        });
      }
    });
  }

  Future<void> _checkAuth() async {
    await ApiService.loadToken();
    if (ApiService.isLoggedIn) {
      isLoggedIn = true;
      update();
      await fetchProfile();
      await updateFcmToken();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    update();
    final res = await ApiService.post('/login', {
      'email': email,
      'password': password,
    });
    isLoading = false;
    if (res['data'] != null && res['data']['token'] != null) {
      await ApiService.saveToken(res['data']['token']);
      if (res['data']['user'] != null) {
        user = UserModel.fromJson(res['data']['user']);
      }
      isLoggedIn = true;
      update();
      await updateFcmToken();
      return true;
    }
    update();
    return false;
  }

  String? _lastSentToken;
  Future<void> updateFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        await Future.delayed(const Duration(seconds: 2));
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token != null && token != _lastSentToken) {
        final res = await ApiService.post('/user/update-fcm-token', {
          "fcm_token": token,
        });
        _lastSentToken = token;
        print("FCM token updated: $res");
      }
    } catch (e) {
      print("FCM update error: $e");
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool isAstrologer = false,
  }) async {
    isLoading = true;
    update();

    try {
      final endpoint = isAstrologer ? '/register-astrologer' : '/register';

      // ✅ IMPORTANT: dynamic use karo
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'bio': 'New astrologer',
        'specializations': ['Vedic', 'Tarot'], // ✅ array
        'chat_rate': 10, // ✅ int
        'call_rate': 20,
        'video_rate': 30,
        'experience_years': 1,
      };

      final res = await ApiService.post(endpoint, body);
      print(res);
      isLoading = false;

      // ✅ Success check

      if (res['data'] != null && res['data']['token'] != null) {
        // Save token
        await ApiService.saveToken(res['data']['token']);

        // Save user
        if (res['data']['user'] != null) {
          user = UserModel.fromJson(res['data']['user']);
        }

        isLoggedIn = true;
        update();
        await updateFcmToken();
        return true;
      }

      update();
      return false;
    } catch (e) {
      isLoading = false;
      update();
      print("Register Error: $e");
      return false;
    }
  }

  Future<void> fetchProfile() async {
    final res = await ApiService.get('/profile');
    if (res['data'] != null) {
      user = UserModel.fromJson(res['data']);
      update();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/user/update-fcm-token', {"fcm_token": ""});
    } catch (_) {}
    await ApiService.post('/logout', {});
    await ApiService.clearToken();
    isLoggedIn = false;
    user = null;
    update();
  }
}
