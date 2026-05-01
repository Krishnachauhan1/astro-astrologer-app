import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'agora_controller.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    Get.put(
      AgoraController(
        astrologerId: args['astrologerId'] ?? 1,
        isVideoCall: true,
        astrologerName: args['astrologerName'] ?? '',
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0A2020),
      body: GetBuilder<AgoraController>(
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A2020), Color(0xFF003535)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      args['astrologerName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Call is Starting...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }
          if (ctrl.errorMessage.isNotEmpty) {
            return Container(
              color: const Color(0xFF0A2020),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ctrl.errorMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Stack(
            children: [
              // Remote video
              ctrl.remoteJoined && ctrl.engine != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: ctrl.engine!,
                        canvas: VideoCanvas(uid: ctrl.remoteUid),
                        connection: RtcConnection(channelId: ctrl.channelName),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A2020), Color(0xFF003535)],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Astrologer photo
                            _AstrologerAvatar(
                              photo: args['astrologerPhoto'],
                              name: args['astrologerName'] ?? '',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              args['astrologerName'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Connecting with Astrologer...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  width: 90,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ctrl.isVideoOn && ctrl.engine != null
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: ctrl.engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white54,
                                size: 28,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: ctrl.endCall,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              args['astrologerName'] ?? 'Video Call',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const _CallTimer(),
                          ],
                        ),
                      ),
                      if (ctrl.rateText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on_outlined,
                                color: AppColors.gold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ctrl.rateText,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControl(
                        icon: ctrl.isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: ctrl.isMuted ? 'Unmute' : 'Mute',
                        active: ctrl.isMuted,
                        onTap: ctrl.toggleMute,
                      ),
                      _CallControl(
                        icon: ctrl.isVideoOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        label: ctrl.isVideoOn ? 'Video' : 'Video Off',
                        active: !ctrl.isVideoOn,
                        onTap: ctrl.toggleVideo,
                      ),
                      // End Call button
                      GestureDetector(
                        onTap: ctrl.endCall,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'End',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CallControl(
                        icon: ctrl.isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: 'Speaker',
                        active: ctrl.isSpeakerOn,
                        onTap: ctrl.toggleSpeaker,
                      ),
                      _CallControl(
                        icon: Icons.flip_camera_ios_rounded,
                        label: ctrl.isFrontCamera ? 'Front' : 'Back',
                        active: false,
                        onTap: ctrl.switchCamera,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AstrologerAvatar extends StatelessWidget {
  final String? photo;
  final String name;
  const _AstrologerAvatar({this.photo, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
      ),
      child: ClipOval(
        child: photo != null && photo!.isNotEmpty
            ? Image.network(
                photo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(name),
              )
            : _initials(name),
      ),
    );
  }

  Widget _initials(String name) {
    final letters = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return Center(
      child: Text(
        letters,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CallTimer extends StatefulWidget {
  const _CallTimer();
  @override
  State<_CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<_CallTimer> {
  int _seconds = 0;
  late final _sub = Stream.periodic(const Duration(seconds: 1), (i) => i + 1)
      .listen((s) {
        if (mounted) setState(() => _seconds = s);
      });

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) => Text(
    _formatted,
    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
  );
}

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CallControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? Colors.red.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? Colors.red.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.red : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
