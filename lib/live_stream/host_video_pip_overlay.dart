import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/live_stream/live_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// User video PiP during live. Uses [joinChannelEx] on the live engine.
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
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    if (!Get.isRegistered<LiveController>()) return;

    final lc = Get.find<LiveController>();

    for (var i = 0; i < 40 && !lc.localUserJoined; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
    }

    await lc.joinCallOverlay(
      callData: widget.callData,
      onEnded: widget.onClose,
    );
  }

  Future<void> _endCall() async {
    if (Get.isRegistered<LiveController>()) {
      await Get.find<LiveController>().leaveCallOverlay(endOnServer: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 72;

    return Positioned(
      top: top,
      right: 12,
      width: 140,
      height: 200,
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
    if (!Get.isRegistered<LiveController>()) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return GetBuilder<LiveController>(
      builder: (lc) {
        if (lc.callJoining) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        if (lc.callJoinError.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                lc.callJoinError,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final remoteUid = lc.callRemoteUid ?? lc.expectedCallRemoteUid;
        final callConn = lc.callRtcConnection;
        final showRemote =
            lc.engine != null &&
            lc.callJoined &&
            callConn != null &&
            remoteUid != null &&
            remoteUid > 0 &&
            (lc.callRemoteJoined || lc.callRemoteVideoReady);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (showRemote)
              AgoraVideoView(
                key: ValueKey('host_pip_${callConn.channelId}_$remoteUid'),
                controller: VideoViewController.remote(
                  rtcEngine: lc.engine!,
                  canvas: VideoCanvas(
                    uid: remoteUid,
                    renderMode: RenderModeType.renderModeHidden,
                  ),
                  connection: callConn,
                  useAndroidSurfaceView:
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.android,
                  useFlutterTexture:
                      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
                ),
              )
            else
              Center(
                child: Text(
                  lc.callJoined ? 'Waiting for video…' : 'Connecting…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        lc.callFormattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
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
