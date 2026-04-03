import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';

import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_stream_model.dart';
import 'package:astrosarthi_konnect_astrologer_app/main.dart';
import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GetBuilder<AuthController>(
                      builder: (auth) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Text('Namaste, ${auth.user?.name.split(' ').first ?? 'User'}!',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('What does the stars say today?', style: TextStyle(color: AppColors.primarySurface, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('Astrosarthi konnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _sectionTitle('Quick Consult'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickAction(context, Icons.chat_bubble_rounded, 'Chat', AppColors.primary),
                      const SizedBox(width: 12),
                      _quickAction(context, Icons.call_rounded, 'Call', AppColors.gold),
                      const SizedBox(width: 12),
                      _quickAction(context, Icons.videocam_rounded, 'Video', AppColors.primaryLight),
                      const SizedBox(width: 12),
                      _quickAction(context, Icons.home_work_rounded, 'Vastu', AppColors.away),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Horoscope banner
                  _horoscopeBanner(),
                  const SizedBox(height: 24),
                  // Top Astrologers

                  const SizedBox(height: 24),
                  // Live Now
                  _sectionTitle('Live Now 🔴'),
                  const SizedBox(height: 12),
                  GetBuilder<LiveController>(
                    builder: (ctrl) => SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ctrl.streams.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _LiveCard(ctrl.streams[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary));

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color) {
    final actions = {
      'Chat': () => Get.find<NavController>().changePage(1),
      'Vastu': () => Get.to(() => const VastuScreen()),
    };
    return Expanded(
      child: GestureDetector(
        onTap: actions[label] ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horoscopeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF005F5F), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Today\'s Horoscope', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Stars align for new beginnings. Mercury in your 5th house brings creativity and joy.', style: TextStyle(color: AppColors.primarySurface, fontSize: 12), maxLines: 3),
                SizedBox(height: 12),
                Text('Read More →', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 60),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final LiveStreamModel s;
  const _LiveCard(this.s);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF003F3F), AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.busy, borderRadius: BorderRadius.circular(8)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              Text('${s.viewers}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(s.astrologerName, style: const TextStyle(color: AppColors.goldLight, fontSize: 11)),
        ],
      ),
    );
  }
}