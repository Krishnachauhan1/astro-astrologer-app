import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_host_chat_bridge.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/host_video_pip_overlay.dart';
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
    LiveHostChatBridge.tryOpenChatOnLiveHost = _tryOpenChatOnHost;
    LiveHostChatBridge.onIncomingChatWhileLive = _onIncomingChatWhileLive;
    LiveHostChatBridge.tryOpenVideoOnLiveHost = _tryOpenVideoOnHost;
    LiveHostChatBridge.onIncomingVideoWhileLive = _onIncomingVideoWhileLive;
  }

  @override
  void dispose() {
    if (LiveHostChatBridge.tryOpenChatOnLiveHost == _tryOpenChatOnHost) {
      LiveHostChatBridge.tryOpenChatOnLiveHost = null;
    }
    if (LiveHostChatBridge.onIncomingChatWhileLive == _onIncomingChatWhileLive) {
      LiveHostChatBridge.onIncomingChatWhileLive = null;
    }
    if (LiveHostChatBridge.tryOpenVideoOnLiveHost == _tryOpenVideoOnHost) {
      LiveHostChatBridge.tryOpenVideoOnLiveHost = null;
    }
    if (LiveHostChatBridge.onIncomingVideoWhileLive == _onIncomingVideoWhileLive) {
      LiveHostChatBridge.onIncomingVideoWhileLive = null;
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

  bool _tryOpenVideoOnHost(Map<String, dynamic> data) {
    if (!Get.isRegistered<LiveController>()) return false;
    final ctrl = Get.find<LiveController>();
    if (!ctrl.isHostingLive) return false;
    ctrl.openVideoCallFromPayload(data);
    return true;
  }

  void _onIncomingVideoWhileLive(Map<String, dynamic> data) {
    if (!Get.isRegistered<LiveController>()) return;
    Get.find<LiveController>().setPendingVideoCallRequest(data);
  }

  void _confirmEnd(BuildContext ctx) {
    if (!Get.isRegistered<LiveController>()) return;
    final ctrl = Get.find<LiveController>();
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
              Navigator.of(ctx).pop();
              await ctrl.endLive();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _confirmEnd(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GetBuilder<LiveController>(
          builder: (ctrl) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _LocalVideo(ctrl: ctrl),

                _GradientOverlay(),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: _TopBar(
                    ctrl: ctrl,
                    onEnd: () => _confirmEnd(context),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: 140,
                child: _SideActions(ctrl: ctrl),
              ),

              Positioned(
                left: 12,
                right: 80,
                bottom: 90,
                child: _CommentsList(ctrl: ctrl),
              ),

              if (ctrl.pendingChatRequest != null)
                _PendingChatBanner(ctrl: ctrl),

              if (ctrl.pendingVideoCallRequest != null)
                _PendingVideoBanner(ctrl: ctrl),

              if (ctrl.activeVideoCallData != null &&
                  ctrl.videoCallPanelOpen)
                HostVideoPipOverlay(
                  callData: ctrl.activeVideoCallData!,
                  onClose: ctrl.closeVideoCall,
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
  const _TopBar({required this.ctrl, required this.onEnd});
  final LiveController ctrl;
  final VoidCallback onEnd;

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

        if (ctrl.privateChatPanelOpen && ctrl.activePrivateChatId != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 11),
                const SizedBox(width: 4),
                Text(
                  ctrl.activePrivateChatUserName ?? 'Private',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // End Live button
        GestureDetector(
          onTap: onEnd,
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
    final inPrivate =
        ctrl.privateChatPanelOpen && ctrl.activePrivateChatId != null;

    if (inPrivate) {
      final tag = 'host_private_${ctrl.activePrivateChatId}';
      return GetBuilder<ChatController>(
        tag: tag,
        builder: (chatCtrl) {
          final msgs = chatCtrl.messages;
          if (msgs.isEmpty) {
            return Text(
              'Private chat with ${ctrl.activePrivateChatUserName ?? 'user'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
      );
          }
          return SizedBox(
            height: 200,
            child: ListView.builder(
              reverse: true,
              itemCount: msgs.length > 8 ? 8 : msgs.length,
              itemBuilder: (_, i) {
                final idx = msgs.length - 1 - i;
                final m = msgs[idx];
                final isUser = m['isUser'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isUser ? Icons.lock_outline : Icons.reply,
                        color: AppColors.goldLight,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.black45
                                : AppColors.primary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: isUser
                                      ? '${ctrl.activePrivateChatUserName ?? 'User'}  '
                                      : 'You  ',
                                  style: const TextStyle(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: m['message']?.toString() ?? '',
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
        },
      );
    }

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
                decoration: InputDecoration(
                  hintText: ctrl.privateChatPanelOpen &&
                          ctrl.activePrivateChatId != null
                      ? 'Private reply to ${ctrl.activePrivateChatUserName ?? 'user'}…'
                      : 'Say something...',
                  hintStyle: const TextStyle(color: Colors.white38),
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

class _PendingVideoBanner extends StatelessWidget {
  const _PendingVideoBanner({required this.ctrl});
  final LiveController ctrl;

  @override
  Widget build(BuildContext context) {
    final data = ctrl.pendingVideoCallRequest ?? {};
    final name = data['caller_name']?.toString() ?? 'User';

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
                  const Icon(Icons.videocam_outlined,
                      color: AppColors.goldLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$name wants video on live',
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
                      onPressed: ctrl.rejectPendingVideoCall,
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
                      onPressed: ctrl.acceptPendingVideoCall,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Accept video'),
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
