import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_host_chat_bridge.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/host_private_chat_overlay.dart';
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
    }
    LiveHostChatBridge.tryOpenOnLiveHost = _tryOpenChatOnHost;
    LiveHostChatBridge.onIncomingChatWhileLive = _onIncomingChatWhileLive;
  }

  @override
  void dispose() {
    if (LiveHostChatBridge.tryOpenOnLiveHost == _tryOpenChatOnHost) {
      LiveHostChatBridge.tryOpenOnLiveHost = null;
    }
    if (LiveHostChatBridge.onIncomingChatWhileLive == _onIncomingChatWhileLive) {
      LiveHostChatBridge.onIncomingChatWhileLive = null;
    }
    if (Get.isRegistered<LiveController>()) {
      Get.find<LiveController>().setHostScreenActive(false);
    }
    super.dispose();
  }

  bool _tryOpenChatOnHost(Map<String, dynamic> data) {
    if (!Get.isRegistered<LiveController>()) return false;
    final ctrl = Get.find<LiveController>();
    if (!ctrl.isHostingLive) return false;
    ctrl.openPrivateChatFromPayload(data);
    return true;
  }

  void _onIncomingChatWhileLive(Map<String, dynamic> data) {
    if (!Get.isRegistered<LiveController>()) return;
    Get.find<LiveController>().setPendingChatRequest(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<LiveController>(
        builder: (ctrl) {
          final chatPanelHeight = ctrl.privateChatPanelOpen && !ctrl.privateChatMinimized
              ? MediaQuery.of(context).size.height * 0.48
              : 0.0;

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
                bottom: 140 + chatPanelHeight,
                child: _SideActions(ctrl: ctrl),
              ),

              Positioned(
                left: 12,
                right: 80,
                bottom: 90 + chatPanelHeight,
                child: _CommentsList(ctrl: ctrl),
              ),

              if (ctrl.pendingChatRequest != null)
                _PendingChatBanner(ctrl: ctrl),

              if (ctrl.activePrivateChatId != null &&
                  ctrl.privateChatPanelOpen &&
                  !ctrl.privateChatMinimized)
                HostPrivateChatOverlay(
                  chatId: ctrl.activePrivateChatId!,
                  userName: ctrl.activePrivateChatUserName ?? 'User',
                  onMinimize: ctrl.minimizePrivateChat,
                  onClose: ctrl.closePrivateChat,
                ),

              if (ctrl.activePrivateChatId != null && ctrl.privateChatMinimized)
                _MinimizedPrivateChatChip(ctrl: ctrl),

              Positioned(
                left: 0,
                right: 0,
                bottom: chatPanelHeight,
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
            onPressed: () async {
              await ctrl.endLive();
              Get.back();
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
    if (list.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        reverse: true,
        itemCount: list.length > 8 ? 8 : list.length,
        itemBuilder: (_, i) {
          final c = list[i];
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
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

class _PendingChatBanner extends StatelessWidget {
  const _PendingChatBanner({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    final data = ctrl.pendingChatRequest ?? {};
    final name = data['caller_name']?.toString() ??
        data['user_name']?.toString() ??
        'User';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 150,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: AppColors.goldLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$name wants to chat on live',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctrl.rejectPendingChat,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: ctrl.acceptPendingChat,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Accept & reply'),
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

class _MinimizedPrivateChatChip extends StatelessWidget {
  const _MinimizedPrivateChatChip({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 150,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        color: AppColors.primary,
        child: InkWell(
          onTap: ctrl.restorePrivateChat,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  ctrl.activePrivateChatUserName ?? 'Private chat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
