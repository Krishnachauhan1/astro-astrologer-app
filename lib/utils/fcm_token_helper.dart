import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Resolves FCM token without crashing on iOS simulator (no APNS).
Future<String?> resolveFcmToken() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb && Platform.isIOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return await FirebaseMessaging.instance.getToken();
  } catch (e) {
    debugPrint('FCM token unavailable: $e');
    return null;
  }
}
