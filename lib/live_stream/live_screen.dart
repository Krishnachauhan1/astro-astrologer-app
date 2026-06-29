import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/live_stream/live_controller.dart';
import 'package:astrosarthi_vendor/servicess/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LiveController(),
      builder: (ctrl) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Live Sessions'),
              Spacer(),
              GestureDetector(
                onTap: ctrl.startLive,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Go Live',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: GetBuilder<LiveController>(
          builder: (ctrl) => ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ctrl.fetchStreams();
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ctrl.streams.length,
                    itemBuilder: (_, i) => _LiveListCard(ctrl.streams[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _LiveListCard extends StatelessWidget {
  final Map<String, dynamic> s;

  const _LiveListCard(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final astroName = (s['astrologer_name'] ?? '').toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final res = await ApiService.get('/live-streams/${s['id']}/join');
          Get.snackbar(
            'Joining Live',
            'Joining ${s['title']}...',
            backgroundColor: AppColors.primary,
            colorText: Colors.white,
          );
        },
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF003F3F), AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.busy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '● LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${s['viewers']} watching',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                s['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white24,
                    child: Text(
                      astroName.isNotEmpty ? astroName[0] : '',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    astroName,
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
