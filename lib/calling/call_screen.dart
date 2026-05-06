import 'dart:async';
import 'package:astrosarthi_konnect_astrologer_app/calling/agora_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart' show Inst;
import 'package:get/get_navigation/src/extension_navigation.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const CallScreen({super.key, required this.data});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;

  int seconds = 0;
  Timer? timer;
  late AgoraController agora;

  @override
  void initState() {
    super.initState();
    print("📞 Starting call with data: ${widget.data}");
    agora = Get.put(
      AgoraController(
        // astrologerId: int.parse(widget.data['astrologer_id'].toString()),
        isVideoCall: widget.data['type'] == 'video',
        astrologerName: widget.data['caller_name'] ?? '',
        callData: widget.data,
      ),
    );

    /// 🔥 CALL START
    // agora.initiateCall();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  String formatTime(int sec) {
    final minutes = (sec ~/ 60).toString().padLeft(2, '0');
    final seconds = (sec % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void endCall() {
    timer?.cancel();
    Get.back(); // close screen
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.data['caller_name'] ?? "User";
    final callerImage =
        widget.data['caller_image'] ?? "https://via.placeholder.com/150";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// 👤 Caller Image
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(callerImage),
            ),

            const SizedBox(height: 20),

            /// 📛 Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// ⏱ Timer
            Text(
              formatTime(seconds),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const Spacer(),

            /// 🎛 Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// 🔇 Mute
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: isMuted
                            ? Colors.white
                            : Colors.grey.shade800,
                        child: Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          color: isMuted ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Mute", style: TextStyle(color: Colors.white)),
                  ],
                ),

                /// 🔊 Speaker
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isSpeakerOn = !isSpeakerOn;
                        });
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: isSpeakerOn
                            ? Colors.white
                            : Colors.grey.shade800,
                        child: Icon(
                          Icons.volume_up,
                          color: isSpeakerOn ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Speaker",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                /// ❌ End Call
                Column(
                  children: [
                    GestureDetector(
                      onTap: endCall,
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.call_end, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("End", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
