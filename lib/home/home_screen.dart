import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/authentication/auth_controller.dart';
import 'package:astrosarthi_vendor/home/astrologer_status_controller.dart';
import 'package:astrosarthi_vendor/main.dart';
import 'package:astrosarthi_vendor/notification/astrologer_notification_screen.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:astrosarthi_vendor/utils/profile_photo_url.dart';
import 'package:astrosarthi_vendor/utils/safe_bottom.dart';
import 'package:astrosarthi_vendor/vastu/vastu_screen.dart';
import 'package:astrosarthi_vendor/widgets/profile_avatar.dart';
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
            pinned: true,            flexibleSpace: FlexibleSpaceBar(
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
                              ProfileAvatar(
                                photoUrl: resolveProfilePhotoUrl(
                                  profilePhoto: auth.user?.profilePhoto,
                                  profilePhotoUrl: auth.user?.profilePhotoUrl,
                                ),
                                name: auth.user?.name,
                                size: 48,
                                borderWidth: 2,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Namaste, ${auth.user?.name.split(' ').first ?? 'User'}!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (auth.user?.name.isNotEmpty == true)
                                      Text(
                                        auth.user!.name,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
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
              'Astrosarathi Konnect',
              style: TextStyle(
                color: Colors.white,
                // fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Get.to(() => const AstrologerNotificationScreen()),
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GetBuilder<AstrologerStatusController>(
                    builder: (statusCtrl) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Availability',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Go online to receive chat, audio and video calls.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                _statusChip(
                                  'Online',
                                  'online',
                                  Colors.green,
                                  statusCtrl,
                                ),
                                _statusChip(
                                  'Busy',
                                  'busy',
                                  Colors.orange,
                                  statusCtrl,
                                ),
                                _statusChip(
                                  'Offline',
                                  'offline',
                                  Colors.grey,
                                  statusCtrl,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  SafeBottom.tabSpacer(),
                ],
              ),
            ),
          ),
        ],
      ),
      );
  }

  Widget _statusChip(
    String label,
    String value,
    Color color,
    AstrologerStatusController ctrl,
  ) {
    final selected = ctrl.status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: ctrl.isUpdating ? null : (_) => ctrl.setStatus(value),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
      AppSnackbar.show(
        '$channel',
        'Stay online on home screen. Incoming $channel from users will ring here.',
        snackPosition: SnackPosition.BOTTOM,
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
