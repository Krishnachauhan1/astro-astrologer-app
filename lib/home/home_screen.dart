import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
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
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.gold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Namaste, ${auth.user?.name.split(' ').first ?? 'User'}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'What does the stars say today?',
                            style: TextStyle(
                              color: AppColors.primarySurface,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: const Text(
              'Astrosarthi konnect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.65,
                    children: [
                      _quickActionTile(
                        context,
                        Icons.chat_bubble_rounded,
                        'Chat',
                        AppColors.primary,
                      ),
                      _quickActionTile(
                        context,
                        Icons.call_rounded,
                        'Audio Call',
                        AppColors.gold,
                      ),
                      _quickActionTile(
                        context,
                        Icons.videocam_rounded,
                        'Video Call',
                        AppColors.primaryLight,
                      ),
                      _quickActionTile(
                        context,
                        Icons.home_work_rounded,
                        'Vastu',
                        AppColors.away,
                      ),
                    ],
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

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );

  Widget _quickActionTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    void showIncomingOnlyInfo(String channel) {
      Get.snackbar(
        '$channel Calls',
        'Incoming $channel calls from users will ring on this screen automatically.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    }

    final actions = {
      'Chat': () => Get.find<NavController>().changePage(1),
      'Audio Call': () => showIncomingOnlyInfo('Audio'),
      'Video Call': () => showIncomingOnlyInfo('Video'),
      'Vastu': () => Get.to(() => const VastuScreen()),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: actions[label] ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textPrimary.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
