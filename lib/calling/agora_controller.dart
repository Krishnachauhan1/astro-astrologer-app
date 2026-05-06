import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraController extends GetxController {
  RtcEngine? engine;
  bool isLoading = true;
  bool isInitialized = false;
  String errorMessage = '';
  bool isMuted = false;
  bool isVideoOn = true;
  bool isSpeakerOn = true;
  bool isFrontCamera = true;
  int? remoteUid;
  bool remoteJoined = false;
  String? _agoraAppId;
  String? _agoraChannel;
  String? _agoraToken;
  int? _callSessionId;
  int? _ratePerMin;
  bool _callEnded = false;
  final int astrologerId;
  final bool isVideoCall;
  final String astrologerName;
  String get rateText => _ratePerMin != null ? '₹$_ratePerMin/min' : '';
  String get channelName => _agoraChannel ?? '';
  // String get channelName => '123';
  AgoraController({
    required this.astrologerId,
    required this.isVideoCall,
    required this.astrologerName,
  });

  @override
  void onInit() {
    super.onInit();
    _initiateCall();
  }

  Future<void> _initiateCall() async {
    final response = await ApiService.post('/initiate', {
      'astrologer_id': astrologerId,
      'type': isVideoCall ? 'video' : 'audio',
    });

    print('astrologer id is ====$astrologerId');
    print('Call initiate response: $response');

    final data = response['data'];

    _agoraAppId = "YOUR_AGORA_APP_ID"; // or from backend
    _agoraChannel = data['agora_channel'];
    _agoraToken = data['agora_token'];
    _callSessionId = data['id'];
    _ratePerMin = data['rate_per_min'];

    print(' AppId: $_agoraAppId');
    print('Channel: $_agoraChannel');
    print('Session: $_callSessionId');
    print('Rate: $_ratePerMin/min');
    _startPolling();
  }

  bool _isValidAgoraToken(String token) {
    return token.isNotEmpty && token.startsWith('007');
  }

  Future<void> _requestPermissionsAndInit() async {
    final permissions = [Permission.microphone];
    if (isVideoCall) permissions.add(Permission.camera);
    final statuses = await permissions.request();
    print('Permissions: $statuses');

    // Permission check
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      errorMessage = 'Microphone permission denied';
      isLoading = false;
      update();
      return;
    }
    await _initAgora();
  }

  void _startPolling() {
    Timer.periodic(Duration(seconds: 2), (timer) async {
      final res = await ApiService.get('/call/$_callSessionId/status');

      print("STATUS: ${res['status']}");

      if (res['status'] == 'active') {
        await _requestPermissionsAndInit();
      }

      if (res['status'] == 'rejected') {
        timer.cancel();
        Get.back();
      }
    });
  }

  Future<void> _initAgora() async {
    if (_agoraAppId == null || _agoraAppId!.isEmpty) {
      errorMessage = 'Agora App ID nahi mila.';
      isLoading = false;
      update();
      return;
    }

    final cleanAppId = _agoraAppId!
        .trim()
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(RegExp(r'\s+'), '');

    if (cleanAppId.length != 32) {
      errorMessage = 'App ID invalid (length: ${cleanAppId.length})';
      isLoading = false;
      update();
      return;
    }

    try {
      engine = createAgoraRtcEngine();
      await engine!.initialize(
        RtcEngineContext(
          appId: cleanAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      print('Agora engine initialized!');
      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            print(' Joined............... ${connection.channelId}');
            isInitialized = true;
            isLoading = false;
            engine?.setEnableSpeakerphone(isSpeakerOn).catchError((e) {
              print('Speaker set error: $e');
            });
            update();
          },
          onUserJoined: (connection, uid, elapsed) {
            print('Remote joined=======$uid');
            remoteUid = uid;
            remoteJoined = true;
            update();
          },
          onUserOffline: (connection, uid, reason) {
            remoteUid = null;
            remoteJoined = false;
            update();
          },
          onError: (err, msg) {
            print('Agora error=========== $err : $msg');
            errorMessage = 'Error ($err): $msg';
            isLoading = false;
            update();
          },
        ),
      );

      if (isVideoCall) {
        await engine!.enableVideo();
        await engine!.enableAudio();
        await engine!.startPreview();
      } else {
        await engine!.enableAudio();
        await engine!.disableVideo();
      }

      // final cleanChannel = _agoraChannel!.trim().replaceAll(RegExp(r'\s+'), '');
      final finalToken = _agoraToken ?? '';
      // print('Channel============ "$cleanChannel"');
      print('Token================$finalToken');

      await engine!.joinChannel(
        // token: finalToken,
        token: _agoraToken!,
        channelId: _agoraChannel!,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoCall,
        ),
      );
      print("FINAL CHANNEL: $_agoraChannel");
      print("FINAL TOKEN: $_agoraToken");
      print(' joinChannel called!');
    } catch (e) {
      print('Agora init error: $e');
      errorMessage = 'Connection fail: $e';
      isLoading = false;
      update();
    }
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    try {
      await engine?.setEnableSpeakerphone(isSpeakerOn);
    } catch (e) {
      print('Speaker toggle error======== $e');
    }
    update();
  }

  Future<void> toggleMute() async {
    isMuted = !isMuted;
    await engine?.muteLocalAudioStream(isMuted);
    update();
  }

  Future<void> toggleVideo() async {
    isVideoOn = !isVideoOn;
    await engine?.muteLocalVideoStream(!isVideoOn);
    update();
  }

  Future<void> switchCamera() async {
    isFrontCamera = !isFrontCamera;
    await engine?.switchCamera();
    update();
  }

  Future<void> endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    try {
      await engine?.leaveChannel();
      await engine?.release();
      engine = null;
    } catch (e) {
      print('Engine release error========== $e');
    }

    // API call end
    if (_callSessionId != null) {
      try {
        final response = await ApiService.post('/call/$_callSessionId/end', {});
        print('Call end response ======= $response');
      } catch (e) {
        print('Call end error ======= $e');
      }
    }

    Get.back();
  }

  @override
  void onClose() {
    if (!_callEnded) {
      engine?.leaveChannel();
      engine?.release();
    }
    super.onClose();
  }
}
