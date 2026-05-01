import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  //  String get channelName => _agoraChannel ?? '';
  String get channelName => '123';
  AgoraController({
    required this.astrologerId,
    required this.isVideoCall,
    required this.astrologerName,
  });

  @override
  void onInit() {
    super.onInit();
    _updateFcmToken() ; 
    _listenFcmRefresh();
    _initiateCall();
  }

void _listenFcmRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      print('FCM Token Refreshed: $newToken');

      await ApiService.post(
        '/user/update-fcm-token',
        {
          "fcm_token": newToken,
        },
      );
    } catch (e) {
      print('FCM refresh error: $e');
    }
  });
}


Future<void> _updateFcmToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null && token.isNotEmpty) {
      print('FCM Token: $token');

      await ApiService.post(
        '/user/update-fcm-token',
        {
          "fcm_token": token,
        },
      );

      print('FCM token updated successfully');
    }
  } catch (e) {
    print('FCM update error: $e');
  }
}







  Future<void> _initiateCall() async {
    isLoading = true;
    errorMessage = '';
    update();




    try {
      final response = await ApiService.post( '/call/initiate', {
        'astrologer_id': astrologerId,
        'type': isVideoCall ? 'video' : 'audio',
      });
      print('Call initiate response: $response');
      if (response['success'] != true) {
        final message = response['message'] ?? 'Call shuru nahi ho saka';
        final errors = response['errors']?.toString() ?? '';
        errorMessage = '$message\n$errors';
        isLoading = false;
        update();
        return;
      }
      final data = response['data'];
      if (data == null) {
        errorMessage = 'Server se data nahi aaya';
        isLoading = false;
        update();
        return;
      }
      _agoraAppId = data['agora_app_id']?.toString().trim();
      // _agoraChannel = data['agora_channel']?.toString().trim();
      _agoraChannel = '123';
      final rawToken = data['agora_token']?.toString().trim() ?? '';
      _agoraToken = _isValidAgoraToken(rawToken) ? rawToken : '';
      final session = data['session'];
      _callSessionId = session?['id'];
      _ratePerMin = session?['rate_per_min'];
      print(' AppId: $_agoraAppId');
      print('Channel: $_agoraChannel');
      print('Session: $_callSessionId');
      print('Rate: $_ratePerMin/min');
      await _requestPermissionsAndInit();
    } catch (e) {
      print('Call initiate error: $e');
      errorMessage = 'Call shuru nahi ho saka: $e';
      isLoading = false;
      update();
    }
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
        token: '',
        // channelId: cleanChannel,
        channelId: "123",
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
