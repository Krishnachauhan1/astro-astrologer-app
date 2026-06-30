import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    String title,
    String message, {
    AppSnackbarType? type,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration? duration,
    EdgeInsets? margin,
    TextButton? mainButton,
  }) {
    final kind = type ?? _inferType(title, message);
    final bg = _background(kind);

    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: bg,
      colorText: Colors.white,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 3),
      icon: Icon(_icon(kind), color: Colors.white, size: 22),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      mainButton: mainButton,
    );
  }

  static void success(String title, String message) =>
      show(title, message, type: AppSnackbarType.success);

  static void error(String title, String message) =>
      show(title, message, type: AppSnackbarType.error);

  static void warning(String title, String message) =>
      show(title, message, type: AppSnackbarType.warning);

  static void info(String title, String message) =>
      show(title, message, type: AppSnackbarType.info);

  static Color _background(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.primary;
      case AppSnackbarType.error:
        return AppColors.busy;
      case AppSnackbarType.warning:
        return AppColors.away;
      case AppSnackbarType.info:
        return AppColors.primaryDark;
    }
  }

  static IconData _icon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_outline_rounded;
      case AppSnackbarType.error:
        return Icons.error_outline_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackbarType.info:
        return Icons.info_outline_rounded;
    }
  }

  static AppSnackbarType _inferType(String title, String message) {
    final text = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (text.contains('success') ||
        text.contains('saved') ||
        text.contains('thank you') ||
        text.contains('copied') ||
        text.contains('registered successfully')) {
      return AppSnackbarType.success;
    }
    if (text.contains('cancel')) {
      return AppSnackbarType.warning;
    }
    if (text.contains('error') ||
        text.contains('fail') ||
        text.contains('invalid') ||
        text.contains('could not') ||
        text.contains('required') ||
        text.contains('wrong') ||
        text.contains('upload failed')) {
      return AppSnackbarType.error;
    }
    return AppSnackbarType.info;
  }
}
