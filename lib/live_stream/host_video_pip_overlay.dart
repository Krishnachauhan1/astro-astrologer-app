import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/calling/agora_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HostVideoPipOverlay extends StatefulWidget {
  final Map<String, dynamic> callData;
  final VoidCallback onClose;

  const HostVideoPipOverlay({
    super.key,
    required this.callData,
    required this.onClose,
  });

  @override
  State<HostVideoPipOverlay> createState() => _HostVideoPipOverlayState();
}

class _HostVideoPipOverlayState extends State<HostVideoPipOverlay> {
  late final String _tag;
  bool _liveSuspended = false;

  @override
  void initState() {
    super.initState();
    final sessionId =
        int.tryParse('${widget.callData['session_id'] ?? widget.callData['sessionId']}') ??
            0;
    _tag = 'host_pip_$sessionId';
    _start();
  }

  Future<void> _start() async {
    if (Get.isRegistered<LiveController>()) {
      await Get.find<LiveController>().suspendLiveForOverlaySession();
    }
    _liveSuspended = true;

    final name = widget.callData['caller_name']?.toString() ?? 'User';
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
    final top = MediaQuery.of(context).padding.top + 72;

    return Positioned(
      top: top,
      right: 12,
      width: 118,
      height: 168,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        color: Colors.black,
        child: _buildBody(),
      ),
      );
  }

  Widget _buildBody() {
    if (!Get.isRegistered<AgoraController>(tag: _tag)) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return GetBuilder<AgoraController>(
      tag: _tag,
      builder: (ctrl) {
        if (ctrl.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
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
              const Center(
                child: Icon(Icons.videocam, color: Colors.white38),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctrl.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    GestureDetector(
                      onTap: _endCall,
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      );
      },
      );
  }
}
