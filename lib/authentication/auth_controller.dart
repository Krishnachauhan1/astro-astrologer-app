import 'package:astrosarthi_konnect_astrologer_app/authentication/user_model.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  bool isLoggedIn = false;
  bool isLoading = false;
  UserModel? user;
  String? lastRegisterError;

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

  static String? _messageFromApi(Map<String, dynamic> res) {
    final message = res['message'];
    if (message is String && message.isNotEmpty) return message;

    final errors = res['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v != null) return v.toString();
      }
    }

    final error = res['error'];
    if (error is String && error.isNotEmpty) return error;

    return null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool isAstrologer = true,
    String? bio,
    List<String>? specializations,
    int? chatRate,
    int? callRate,
    int? videoRate,
    int? experienceYears,
  }) async {
    isLoading = true;
    lastRegisterError = null;
    update();

    try {
      const endpoint = '/register';

      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      };

      if (isAstrologer) {
        body['bio'] = bio?.trim().isNotEmpty == true ? bio!.trim() : null;
        body['specializations'] =
            (specializations != null && specializations.isNotEmpty)
            ? specializations
            : null;
        body['chat_rate'] = chatRate;
        body['call_rate'] = callRate;
        body['video_rate'] = videoRate;
        body['experience_years'] = experienceYears;
        body.removeWhere((_, v) => v == null);
      }

      final res = await ApiService.post(endpoint, body);
      if (kDebugMode) {
        debugPrint('Register body: $body');
        debugPrint('Register response: $res');
      }
      isLoading = false;

      final data = res['data'];
      final token = data is Map ? data['token'] : null;

      if (res['success'] == true && token != null) {
        await ApiService.saveToken(token.toString());

        if (data is Map && data['user'] != null) {
          user = UserModel.fromJson(
            Map<String, dynamic>.from(data['user'] as Map),
          );
        }

        isLoggedIn = true;
        update();
        await updateFcmToken();
        return true;
      }

      lastRegisterError =
          _messageFromApi(res) ?? 'Registration failed. Please try again.';
      update();
      return false;
    } catch (e) {
      isLoading = false;
      lastRegisterError = 'Registration failed. Please try again.';
      update();
      debugPrint('Register Error: $e');
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
