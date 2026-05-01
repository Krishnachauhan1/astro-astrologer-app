import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'agora_controller.dart';

class AudioCallScreen extends StatelessWidget {
  const AudioCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    Get.put(
      AgoraController(
        astrologerId: args['astrologerId'] ?? 1,
        isVideoCall: false,
        astrologerName: args['astrologerName'] ?? '',
      ),
    );

    return Scaffold(
      body: GetBuilder<AgoraController>(
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    Color(0xFF00B4B4),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.call_end_rounded,
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
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  Color(0xFF00B4B4),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: ctrl.endCall,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Astrologer Avatar
                  _AstrologerAvatar(
                    photo: args['astrologerPhoto'],
                    name: args['astrologerName'] ?? '',
                  ),
                  const SizedBox(height: 24),
                  // Astrologer name
                  Text(
                    args['astrologerName'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Connection status
                  Text(
                    ctrl.remoteJoined ? 'Connected' : 'Connecting...',
                    style: TextStyle(
                      color: ctrl.remoteJoined
                          ? AppColors.online
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Timer + Rate
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const _CallTimer(),
                        if (ctrl.rateText.isNotEmpty)
                          Text(
                            '  •  ${ctrl.rateText}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Waveform
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        20,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 4,
                          height: (i % 5 + 1) * 8.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              ctrl.isMuted ? 0.2 : 0.6,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute
                        _AudioControl(
                          icon: ctrl.isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: ctrl.isMuted ? 'Unmute' : 'Mute',
                          isActive: ctrl.isMuted,
                          onTap: ctrl.toggleMute,
                        ),
                        //End call
                        GestureDetector(
                          onTap: ctrl.endCall,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),

                        // Speaker
                        _AudioControl(
                          icon: ctrl.isSpeakerOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          label: ctrl.isSpeakerOn ? 'Speaker' : 'Earpiece',
                          isActive: false,
                          onTap: ctrl.toggleSpeaker,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30),
        ],
      ),
      child: ClipOval(
        child: photo != null && photo!.isNotEmpty
            ? Image.network(
                photo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final letters = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '--';
    return Center(
      child: Text(
        letters,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
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
    style: const TextStyle(color: Colors.white, fontSize: 13),
  );
}

class _AudioControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _AudioControl({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.red.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
