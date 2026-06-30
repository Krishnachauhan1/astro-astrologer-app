import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/live_stream/live_controller.dart';
import 'package:astrosarthi_vendor/utils/safe_bottom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LiveController>()) {
      Get.find<LiveController>().setHostScreenActive(true);
      Get.find<LiveController>().ensureLiveChatListening();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<LiveController>()) {
      Get.find<LiveController>().setHostScreenActive(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Get.find<LiveController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<LiveController>(
        builder: (ctrl) {
          final navBottom = SafeBottom.inset(context);
          const commentBarHeight = 64.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              _LocalVideo(ctrl: ctrl),

              _GradientOverlay(),

              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: _TopBar(ctrl: ctrl),
              ),
              Positioned(
                right: 16,
                bottom: 140 + navBottom,
                child: _SideActions(ctrl: ctrl),
              ),

              Positioned(
                left: 12,
                right: 80,
                bottom: commentBarHeight + navBottom + 16,
                child: _CommentsList(ctrl: ctrl),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CommentBar(ctrl: ctrl),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocalVideo extends StatelessWidget {
  const _LocalVideo({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.engine == null || !ctrl.localUserJoined) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: ctrl.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top scrim
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
        const Spacer(),
        // Bottom scrim
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LIVE badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '● LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Viewer count chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${ctrl.viewerCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),

        const Spacer(),

        // End Live button
        GestureDetector(
          onTap: () => _confirmEnd(context, ctrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'End',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmEnd(BuildContext ctx, LiveController ctrl) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Live?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your live session will end for all viewers.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.endLive();
            },
            child: Text(
              'End Live',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideActions extends StatefulWidget {
  const _SideActions({required this.ctrl});
  final LiveController ctrl;

  @override
  State<_SideActions> createState() => _SideActionsState();
}

class _SideActionsState extends State<_SideActions> {
  bool _muted = false;
  bool _frontCam = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _ActionBtn(
          icon: Icons.favorite,
          color: Colors.pink,
          label: '${widget.ctrl.likeCount}',
          onTap: widget.ctrl.addLike,
        ),
        const SizedBox(height: 18),

        // Flip camera
        _ActionBtn(
          icon: Icons.flip_camera_ios_rounded,
          color: Colors.white,
          onTap: () {
            _frontCam = !_frontCam;
            widget.ctrl.engine?.switchCamera();
            setState(() {});
          },
        ),
        const SizedBox(height: 18),

        // Mute mic
        _ActionBtn(
          icon: _muted ? Icons.mic_off : Icons.mic,
          color: _muted ? Colors.red : Colors.white,
          onTap: () {
            _muted = !_muted;
            widget.ctrl.engine?.muteLocalAudioStream(_muted);
            setState(() {});
          },
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    final list = ctrl.comments;
    if (list.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            'Live chat — viewer messages appear here',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    final visible = list.length > 8 ? list.sublist(list.length - 8) : list;

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final c = visible[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (c['user'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${c['user']}  ',
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: c['msg'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentBar extends StatelessWidget {
  const _CommentBar({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SafeBottom.inputBarPadding(context, top: 8, extra: 12),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: ctrl.commentCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => ctrl.sendComment('You (Host)'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ctrl.sendComment('You (Host)'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
