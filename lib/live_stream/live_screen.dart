import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LiveController>(
      builder: (ctrl) => Scaffold(
        appBar: AppBar(
          title: const Text('Go Live'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: 72,
                  color: AppColors.primary.withOpacity(0.85),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Start your live session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Users on the customer app can join your live. Other astrologers cannot see who else is live.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.65),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: ctrl.isLoading ? null : ctrl.startLive,
                    icon: ctrl.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.videocam_rounded),
                    label: Text(
                      ctrl.isLoading ? 'Starting…' : 'Go Live',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
