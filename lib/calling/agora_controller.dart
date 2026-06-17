import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/utils/call_session_api.dart';
import 'package:flutter/foundation.dart';
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
  bool remoteVideoReady = false;

  String? _agoraAppId;
  String? _agoraChannel;
  String? _agoraToken;
  int? _callSessionId;
  int? _ratePerMin;
  int? _joinUid;
  int? _expectedRemoteUid;

  final bool isVideoCall;
  final String astrologerName;

  int _seconds = 0;
  Timer? _timer;
  Timer? _offlineGraceTimer;
  bool _callEnded = false;

  String get rateText => _ratePerMin != null ? '₹$_ratePerMin/min' : '';
  String get channelName => _agoraChannel ?? '';
  int? get remoteVideoUid => remoteUid ?? _expectedRemoteUid;

  final Map<String, dynamic> callData;

  final bool embeddedOnLive;
  final VoidCallback? onEmbeddedEnded;

  AgoraController({
    required this.callData,
    required this.isVideoCall,
    required this.astrologerName,
    this.embeddedOnLive = false,
    this.onEmbeddedEnded,
  });

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      update();
    });
  }

  String get formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void onInit() {
    super.onInit();
    print("FULL CALL DATA => $callData");

    _agoraAppId = (callData['agora_app_id'] ?? callData['appId'] ?? '')
        ?.toString()
        .trim();
    _agoraChannel = (callData['channel'] ?? callData['agora_channel'] ?? '')
        ?.toString()
        .trim();
    _agoraToken = (callData['agora_token'] ?? callData['token'] ?? '')
        ?.toString()
        .trim();

    // IMPORTANT: The backend generates the FCM-delivered token bound to the
    // ASTROLOGER's own user id ($astrologer->id on the server). So this side
    // must join Agora with the logged-in astrologer's id, NOT with the
    // `uid`/`caller_uid` field from the FCM payload (those refer to the
    // customer / are informational only).
    final loggedInAstrologerId = _resolveLoggedInAstrologerId();
    _joinUid = loggedInAstrologerId;

    // The remote peer (customer) joins with their own user_id, which the
    // backend sends as `caller_uid` in the FCM payload. Use it to recognize
    // the remote when they appear.
    _expectedRemoteUid = int.tryParse(
      (callData['caller_uid'] ?? callData['callerUid'] ?? '').toString(),
      );

    _callSessionId = int.tryParse(
      (callData['session_id'] ?? callData['sessionId'] ?? '').toString(),
      );
    _ratePerMin = int.tryParse(
      (callData['rate_per_min'] ?? callData['ratePerMin'] ?? '').toString(),
      );

    print("APP ID = $_agoraAppId");
    print("CHANNEL = $_agoraChannel");
    print("TOKEN = $_agoraToken");
    print("JOIN UID (astrologer) = $_joinUid");
    print("EXPECTED REMOTE UID (caller) = $_expectedRemoteUid");

    _requestPermissionsAndInit();
  }

  int? _resolveLoggedInAstrologerId() {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final id = auth.user?.id;
        if (id != null && id > 0) return id;
      }
    } catch (e) {
      print('resolveLoggedInAstrologerId error: $e');
    }
    return null;
  }

  Future<void> _requestPermissionsAndInit() async {
    final permissions = [Permission.microphone];
    if (isVideoCall) permissions.add(Permission.camera);

    final status = await permissions.request();

    if (status[Permission.microphone] != PermissionStatus.granted) {
      errorMessage = 'Microphone permission denied';
      isLoading = false;
      update();
      return;
    }

    if (isVideoCall && status[Permission.camera] != PermissionStatus.granted) {
      errorMessage = 'Camera permission denied';
      isLoading = false;
      update();
      return;
    }

    await _initAgora();
  }

  Future<void> _initAgora() async {
    if (_agoraAppId == null || _agoraAppId!.isEmpty) {
      errorMessage = 'Agora App ID missing';
      isLoading = false;
      update();
      return;
    }
    if (_agoraChannel == null || _agoraChannel!.isEmpty) {
      errorMessage = 'Agora channel missing';
      isLoading = false;
      update();
      return;
    }

    try {
      engine = createAgoraRtcEngine();

      await engine!.initialize(
        RtcEngineContext(
          appId: _agoraAppId!,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await engine!.enableAudio();
      await engine!.enableLocalAudio(true);

      if (isVideoCall) {
        await engine!.enableVideo();
        if (embeddedOnLive) {
          // Receive user's camera only — live host already uses the camera.
          await engine!.enableLocalVideo(false);
        } else {
          await engine!.enableLocalVideo(true);
          await engine!.startPreview();
        }
      } else {
        await engine!.disableVideo();
      }

      // setEnableSpeakerphone before joinChannel can fail with -3 (ERR_NOT_READY)
      // on some devices. Use setDefaultAudioRouteToSpeakerphone here, and apply
      // setEnableSpeakerphone after the channel is joined.
      try {
        await engine!.setDefaultAudioRouteToSpeakerphone(isSpeakerOn);
      } catch (e) {
        print('setDefaultAudioRouteToSpeakerphone error: $e');
      }

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            print(
              "ASTRO JOINED CHANNEL => ${connection.channelId} localUid=${connection.localUid} elapsed=$elapsed",
      );
            isInitialized = true;
            isLoading = false;
            try {
              engine?.muteAllRemoteAudioStreams(false);
              engine?.muteAllRemoteVideoStreams(false);
            } catch (e) {
              print('muteAllRemoteStreams error: $e');
            }
            try {
              engine?.setEnableSpeakerphone(isSpeakerOn);
            } catch (e) {
              print('setEnableSpeakerphone (post-join) error: $e');
            }
            update();
          },
          onRejoinChannelSuccess: (connection, elapsed) {
            print(
              "ASTRO REJOINED CHANNEL => ${connection.channelId} localUid=${connection.localUid} elapsed=$elapsed",
      );
          },
          onLeaveChannel: (connection, stats) {
            print("ASTRO LEFT CHANNEL => ${connection.channelId}");
          },
          onUserJoined: (connection, uid, elapsed) {
            print("USER REMOTE JOINED => $uid elapsed=$elapsed");
            _offlineGraceTimer?.cancel();
            if (uid > 0 && uid != _joinUid) {
              remoteUid = uid;
              remoteJoined = true;
              _startTimer();
            }
            try {
              engine?.muteRemoteAudioStream(uid: uid, mute: false);
              engine?.muteRemoteVideoStream(uid: uid, mute: false);
            } catch (e) {
              print('unmute remote error: $e');
            }
            update();
          },
          onUserOffline: (connection, uid, reason) {
            print("REMOTE USER OFFLINE => $uid reason=$reason");
            if (uid != remoteUid && uid != _expectedRemoteUid) return;
            remoteUid = null;
            remoteJoined = false;
            remoteVideoReady = false;
            _timer?.cancel();
            update();
            if (embeddedOnLive) {
              _offlineGraceTimer?.cancel();
              _offlineGraceTimer = Timer(const Duration(seconds: 8), () {
                if (!_callEnded && !remoteJoined) {
                  endCall();
                }
              });
            } else {
              endCall();
            }
          },
          onConnectionStateChanged: (connection, state, reason) {
            print("CONNECTION STATE => $state reason=$reason");
            // Common signature of UID collision (both peers joining with the
            // same uid): rapid Interrupted <-> RejoinSuccess loop. Log it so
            // backend can fix the uid assignment per peer.
            if (reason ==
                ConnectionChangedReasonType.connectionChangedBannedByServer) {
              errorMessage =
                  'Disconnected by server (possible duplicate uid). Please retry.';
              isLoading = false;
              update();
            }
          },
          onConnectionLost: (connection) {
            print("CONNECTION LOST => ${connection.channelId}");
          },
          onTokenPrivilegeWillExpire: (connection, token) {
            print("TOKEN WILL EXPIRE for ${connection.channelId}");
          },
          onRequestToken: (connection) {
            print("AGORA REQUEST TOKEN for ${connection.channelId}");
          },
          onRemoteAudioStateChanged:
              (connection, remoteUid, state, reason, elapsed) {
                print(
                  "REMOTE AUDIO STATE => uid=$remoteUid state=$state reason=$reason",
      );
              },
          onRemoteVideoStateChanged:
              (connection, remoteUid, state, reason, elapsed) {
                print("REMOTE VIDEO STATE => uid=$remoteUid state=$state");
                if (remoteUid <= 0 || remoteUid == _joinUid) return;
                if (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding) {
                  this.remoteUid = remoteUid;
                  remoteJoined = true;
                  remoteVideoReady = true;
                  update();
                } else if (state ==
                        RemoteVideoState.remoteVideoStateStopped ||
                    state == RemoteVideoState.remoteVideoStateFailed) {
                  if (this.remoteUid == remoteUid) {
                    remoteVideoReady = false;
                    update();
                  }
                }
              },
          onFirstRemoteVideoFrame:
              (connection, remoteUid, width, height, elapsed) {
            print("FIRST REMOTE VIDEO => uid=$remoteUid");
            if (remoteUid > 0 && remoteUid != _joinUid) {
              this.remoteUid = remoteUid;
              remoteJoined = true;
              remoteVideoReady = true;
              update();
            }
          },
          onError: (err, msg) {
            print("AGORA ERROR => code=$err msg=$msg");
            // Non-fatal errors during the call should not blow up the UI.
            // Surface only fatal codes (e.g. invalid token / banned).
            if (err == ErrorCodeType.errInvalidToken ||
                err == ErrorCodeType.errTokenExpired ||
                err == ErrorCodeType.errInvalidAppId ||
                err == ErrorCodeType.errInvalidChannelName) {
              errorMessage = 'Call connection failed ($err). $msg';
              isLoading = false;
              update();
            }
          },
        ),
      );

      // joinChannel: the backend (CallController@sendIncomingCallNotification)
      // generates the FCM-delivered token bound to the astrologer's user id.
      // So we MUST join with that same id, or Agora will return
      // errInvalidToken. Reading from AuthController guarantees the join uid
      // and the token's signed uid match.
      final joinUid = _joinUid;
      if (joinUid == null || joinUid <= 0) {
        errorMessage =
            'Cannot start call: astrologer not logged in. Please re-login.';
        isLoading = false;
        update();
        return;
      }
      print(
        "ASTRO joinChannel => channel=$_agoraChannel uid=$joinUid tokenLen=${_agoraToken?.length ?? 0}",
      );
      await engine!.joinChannel(
        token: _agoraToken ?? '',
        channelId: _agoraChannel!,
        uid: joinUid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideoCall && !embeddedOnLive,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoCall,
        ),
      );

      print("ASTRO joinChannel called!");
    } catch (e) {
      print("ASTRO INIT ERROR => $e");
      errorMessage = 'Connection failed: $e';
      isLoading = false;
      update();
    }
  }

  void toggleMute() async {
    isMuted = !isMuted;
    try {
      await engine?.muteLocalAudioStream(isMuted);
    } catch (e) {
      print('Mute error: $e');
    }
    update();
  }

  void toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    try {
      await engine?.setEnableSpeakerphone(isSpeakerOn);
    } catch (e) {
      print('Speaker error: $e');
    }
    update();
  }

  void toggleVideo() async {
    isVideoOn = !isVideoOn;
    try {
      await engine?.muteLocalVideoStream(!isVideoOn);
      await engine?.enableLocalVideo(isVideoOn);
    } catch (e) {
      print('Video toggle error: $e');
    }
    update();
  }

  void switchCamera() async {
    isFrontCamera = !isFrontCamera;
    try {
      await engine?.switchCamera();
    } catch (e) {
      print('Switch camera error: $e');
    }
    update();
  }

  Future<void> endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    _timer?.cancel();
    _timer = null;
    _offlineGraceTimer?.cancel();
    _offlineGraceTimer = null;

    final sessionId = _callSessionId;
    final localEngine = engine;
    engine = null;

    try {
      if (!embeddedOnLive && (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }
    } catch (e) {
      print('Get.back error: $e');
    }

    Future.microtask(() async {
      try {
        await localEngine?.leaveChannel();
      } catch (e) {
        print('leaveChannel error: $e');
      }
      try {
        await localEngine?.release();
      } catch (e) {
        print('engine release error: $e');
      }
      if (sessionId != null) {
        await endCallSession(sessionId);
      }
      final deleteTag = _tagForDelete();
      try {
        if (Get.isRegistered<AgoraController>(tag: deleteTag)) {
          Get.delete<AgoraController>(tag: deleteTag, force: true);
        } else if (!embeddedOnLive && Get.isRegistered<AgoraController>()) {
          Get.delete<AgoraController>(force: true);
        }
      } catch (_) {}
      if (embeddedOnLive) {
        onEmbeddedEnded?.call();
      }
    });
  }

  String _tagForDelete() {
    final channel =
        (_agoraChannel ?? callData['agora_channel'] ?? callData['channel'] ?? '')
            .toString()
            .trim();
    if (channel.isNotEmpty) return 'host_pip_$channel';
    final sessionId = callData['session_id'] ?? callData['sessionId'] ?? '0';
    return 'host_pip_$sessionId';
  }

  @override
  void onClose() {
    _timer?.cancel();
    _timer = null;
    if (!_callEnded) {
      final localEngine = engine;
      engine = null;
      Future.microtask(() async {
        try {
          await localEngine?.leaveChannel();
        } catch (_) {}
        try {
          await localEngine?.release();
        } catch (_) {}
      });
    }
    super.onClose();
  }
}
