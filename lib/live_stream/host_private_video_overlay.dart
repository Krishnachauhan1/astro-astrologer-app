import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/calling/agora_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 1:1 video call panel on the astrologer live host screen.
class HostPrivateVideoOverlay extends StatefulWidget {
  final Map<String, dynamic> callData;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const HostPrivateVideoOverlay({
    super.key,
    required this.callData,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  State<HostPrivateVideoOverlay> createState() => _HostPrivateVideoOverlayState();
}

class _HostPrivateVideoOverlayState extends State<HostPrivateVideoOverlay> {
  late final String _tag;
  bool _liveSuspended = false;

  @override
  void initState() {
    super.initState();
    final sessionId =
        int.tryParse('${widget.callData['session_id'] ?? widget.callData['sessionId']}') ??
            0;
    _tag = 'host_video_$sessionId';
    _startCall();
  }

  Future<void> _startCall() async {
    if (Get.isRegistered<LiveController>()) {
      await Get.find<LiveController>().suspendLiveForOverlaySession();
    }
    _liveSuspended = true;

    final name = widget.callData['caller_name']?.toString() ??
        widget.callData['callerName']?.toString() ??
        'User';

    Get.put(
      AgoraController(
        callData: widget.callData,
        isVideoCall: true,
        astrologerName: name,
        embeddedOnLive: true,
        onEmbeddedEnded: _handleEnded,
      ),
      tag: _tag,
      );

    if (mounted) setState(() {});
  }

  Future<void> _handleEnded() async {
    if (_liveSuspended && Get.isRegistered<LiveController>()) {
      await Get.find<LiveController>().resumeLiveAfterOverlaySession();
    }
    _liveSuspended = false;
    widget.onClose();
  }

  Future<void> _endCall() async {
    if (Get.isRegistered<AgoraController>(tag: _tag)) {
      await Get.find<AgoraController>(tag: _tag).endCall();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AgoraController>(tag: _tag)) {
      Get.delete<AgoraController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.52;
    final callerName = widget.callData['caller_name']?.toString() ?? 'User';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: Material(
        elevation: 14,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: Colors.black,
        child: GetBuilder<AgoraController>(
          tag: _tag,
          builder: (ctrl) {
            if (ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
      );
            }
            if (ctrl.errorMessage.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ctrl.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
      );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                if (ctrl.remoteJoined &&
                    ctrl.engine != null &&
                    ctrl.remoteUid != null &&
                    ctrl.remoteUid! > 0)
                  AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: ctrl.engine!,
                      canvas: VideoCanvas(uid: ctrl.remoteUid),
                      connection: RtcConnection(channelId: ctrl.channelName),
                      useAndroidSurfaceView: !kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.android,
                      useFlutterTexture: !kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.iOS,
                    ),
                  )
                else
                  Center(
                    child: Text(
                      'Connecting with $callerName…',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(ctrl, callerName),
                      const Spacer(),
                      _buildControls(ctrl),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
      );
          },
        ),
      ),
      );
  }

  Widget _buildHeader(AgoraController ctrl, String callerName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  ctrl.remoteJoined ? 'Video on live' : 'Joining…',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ctrl.formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onMinimize,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white),
          ),
        ],
      ),
      );
  }

  Widget _buildControls(AgoraController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundBtn(
            icon: ctrl.isMuted ? Icons.mic_off : Icons.mic,
            onTap: ctrl.toggleMute,
          ),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white),
            ),
          ),
          _RoundBtn(
            icon: ctrl.isVideoOn ? Icons.videocam : Icons.videocam_off,
            onTap: ctrl.toggleVideo,
          ),
        ],
      ),
      );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
      );
  }
}
