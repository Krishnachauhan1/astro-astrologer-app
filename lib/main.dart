import 'dart:io';

import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/login_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/calling/agora_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_list.dart';
import 'package:astrosarthi_konnect_astrologer_app/home/home_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/notification/notification_service.dart';
import 'package:astrosarthi_konnect_astrologer_app/profile/profile_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

class NavController extends GetxController {
  int currentIndex = 0;

  void changePage(int i) {
    currentIndex = i;
    update();
  }
}
Future<void> printDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    print("📱 Device: ${androidInfo.model}");
    print("📱 Brand: ${androidInfo.brand}");
    print("📱 Android Version: ${androidInfo.version.release}");
    print("📱 Device ID: ${androidInfo.id}");
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    print("📱 Device: ${iosInfo.utsname.machine}");
    print("📱 iOS Version: ${iosInfo.systemVersion}");
    print("📱 Device ID: ${iosInfo.identifierForVendor}");
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ApiService.loadToken();
  // Get.find<AgoraController>()._initiateCall(); // Call initiation moved here for testing
  String? token = await FirebaseMessaging.instance.getToken();
  print("🔥 FCM Token: $token");
  await printDeviceInfo();

print("🔥 FCM Token: $token");
  await NotificationService().initialize();

  runApp(const AstrologyApp());
}

class AstrologyApp extends StatelessWidget {
  const AstrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Astrosarthi Konnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(NavController());
        // Get.put(ChatController());
        Get.put(VastuController());
        Get.put(LiveController());
        Get.put(VastuController());
      }),
      home: GetBuilder<AuthController>(builder: (auth) => auth.isLoggedIn ? const MainShell() : const LoginScreen()),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static final _pages = [const HomeScreen(), ChatList(), const LiveScreen(), const VastuScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavController>(
      builder: (nav) => Scaffold(
        body: IndexedStack(index: nav.currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          onTap: nav.changePage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv_rounded), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Vastu'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}