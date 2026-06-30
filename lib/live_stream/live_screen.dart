import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/live_stream/host_screen.dart';
import 'package:astrosarthi_vendor/live_stream/live_controller.dart';
import 'package:astrosarthi_vendor/utils/safe_bottom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Future<void> _confirmEnd(BuildContext context, LiveController ctrl) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End live session?'),
        content: const Text('This will end your live for all viewers.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('End'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (ok == true) {
      await ctrl.endLive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LiveController>(
      builder: (ctrl) => Scaffold(
        appBar: AppBar(
          title: const Text('Live Studio'),
          actions: [
            if (ctrl.isLive)
              TextButton(
                onPressed: ctrl.isLoading
                    ? null
                    : () async {
                        await _confirmEnd(context, ctrl);
                      },
                child: const Text(
                  'End',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (ctrl.needsRecovery) ...[
                const _WarningCard(
                  title: 'Live needs recovery',
                  message:
                      'Your live session was started earlier, but the app restarted. Tap “Resume” to reopen the studio. If it fails, end the live and start again.',
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003F3F), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.live_tv_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctrl.isLive ? 'You are live' : 'Ready to go live',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ctrl.isLive
                                ? 'Keep your camera steady and audio clear.'
                                : 'Only customers can discover and join your live session.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GoLiveCard(ctrl: ctrl),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'Tips',
                bullets: [
                  'Use good lighting and a stable internet connection',
                  'Start with a clear topic title so users know what to expect',
                  'End the live when you are done to avoid background streaming',
                ],
              ),
              SafeBottom.tabSpacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoLiveCard extends StatelessWidget {
  final LiveController ctrl;
  const _GoLiveCard({required this.ctrl});

  Future<void> _confirmEnd(BuildContext context) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End live session?'),
        content: const Text('This will end your live for all viewers.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('End'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (ok == true) {
      await ctrl.endLive();
    }
  }

  Future<void> _startFlow() async {
    final titleCtrl = TextEditingController(text: 'Live Astrology Session');
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Live title'),
        content: TextField(
          controller: titleCtrl,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'e.g. Career guidance Q&A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: titleCtrl.text.trim()),
            child: const Text('Start'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    final title = (result ?? '').trim();
    if (title.isEmpty) return;
    await ctrl.startLive(title: title);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (ctrl.isLive ? AppColors.busy : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ctrl.isLive ? '● LIVE' : '● OFFLINE',
                    style: TextStyle(
                      color: ctrl.isLive ? AppColors.busy : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (ctrl.isLive)
                  Text(
                    '${ctrl.viewerCount} watching',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.isLive ? 'Session is running' : 'Start a live session',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ctrl.isLive
                  ? (ctrl.currentTitle?.isNotEmpty == true
                      ? 'Topic: ${ctrl.currentTitle}\nTap Resume to open your live studio screen.'
                      : 'Tap Resume to open your live studio screen.')
                  : 'Choose a title and go live. Other astrologers will not see this list.',
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ctrl.isLoading
                        ? null
                        : ctrl.isLive
                            ? () => Get.to(() => const HostScreen())
                            : _startFlow,
                    icon: ctrl.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            ctrl.isLive
                                ? Icons.open_in_new_rounded
                                : Icons.videocam_rounded,
                          ),
                    label: Text(
                      ctrl.isLoading
                          ? 'Please wait…'
                          : (ctrl.isLive ? 'Resume' : 'Go Live'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (ctrl.isLive) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctrl.isLoading
                          ? null
                          : () async {
                              await _confirmEnd(context);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: AppColors.busy.withValues(alpha: 0.7),
                        ),
                        foregroundColor: AppColors.busy,
                      ),
                      child: const Text(
                        'End Live',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  const _InfoCard({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.70),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String message;
  const _WarningCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.70),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
