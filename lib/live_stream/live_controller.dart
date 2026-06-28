import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_vendor/live_stream/host_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../servicess/api_service.dart';

class LiveController extends GetxController {
  RtcEngine? engine;
  String agoraAppId = '';
  String? agoraChannel;
  String? agoraToken;

  /// Must match the UID encoded in [agoraToken] (Laravel sends logged-in user id for host).
  int? agoraUid;

  bool isJoined = false;
  List<Map<String, dynamic>> streams = [];
  bool isLoading = false;
  bool isLive = false;
  bool localUserJoined = false;
  int? remoteUid;
  int viewerCount = 0;
  int likeCount = 0;
  int? currentLiveId;

  final List<Map<String, String>> comments = [];
  final TextEditingController commentCtrl = TextEditingController();

  int? _parsePositiveInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : null;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  @override
  void onInit() {
    super.onInit();
    fetchStreams();
  }

  @override
  void onClose() {
    _releaseEngine();
    commentCtrl.dispose();
    super.onClose();
  }

  Future<void> _releaseEngine() async {
    try {
      await engine?.stopPreview();
      await engine?.leaveChannel();
      await engine?.release();
    } catch (e) {
      print('engine release error $e');
    }
    engine = null;
    isJoined = false;
  }

  Future<void> initAgora(bool isHost) async {
    if (isHost && agoraUid == null) {
      Get.snackbar(
        'Live',
        'agora_uid missing — update backend or API response.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await _releaseEngine();
    await [Permission.camera, Permission.microphone].request();
    final mic = await Permission.microphone.status;
    print('MIC STATUS => $mic');

    engine = createAgoraRtcEngine();
    await engine!.initialize(RtcEngineContext(appId: agoraAppId));
    await engine!.enableVideo();
    await engine!.enableAudio();

    engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          localUserJoined = true;
          update();
        },
        onUserJoined: (connection, uid, elapsed) {
          remoteUid = uid;
          viewerCount++;
          update();
        },
        onUserOffline: (connection, uid, reason) {
          remoteUid = null;
          if (viewerCount > 0) viewerCount--;
          update();
        },
        onError: (err, msg) {
          print('the error of agora is $err');
          print('the msg of agora is $msg');
          Get.snackbar(
            'Agora Error',
            msg,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      ),
    );

    await engine!.setClientRole(
      role: isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    if (isHost) await engine!.startPreview();

    final int joinUid = isHost ? agoraUid! : (agoraUid ?? 0);

    await engine!.joinChannel(
      token: agoraToken ?? '',
      channelId: agoraChannel ?? '',
      uid: joinUid,
      options: ChannelMediaOptions(
        clientRoleType: isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: isHost,
        publishMicrophoneTrack: isHost,
      ),
    );
    print('agora token/channel/uid => $agoraToken | $agoraChannel | $joinUid');

    update();
  }

  Future<void> fetchStreams() async {
    isLoading = true;
    update();
    try {
      final res = await ApiService.get('/live-streams');
      print('live stream data $res');
      final List<dynamic> data = res['data']?['data'] ?? [];
      streams = data.isNotEmpty
          ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : _mock();
    } catch (_) {
      streams = _mock();
    }
    isLoading = false;
    update();
  }

  Future<void> startLive({String title = 'Live Astrology Session'}) async {
    isLoading = true;
    update();
    try {
      final res = await ApiService.post('/live-streams/start', {
        'title': title,
      });
      print('live stream session $res');

      if (res['success'] != true) {
        throw Exception(res['message']?.toString() ?? 'Start live failed');
      }

      final d = res['data'] as Map<String, dynamic>?;
      if (d == null) throw Exception('Invalid response: missing data');

      final stream = d['stream'] as Map<String, dynamic>?;
      if (stream == null) throw Exception('Invalid response: missing stream');

      currentLiveId = _parsePositiveInt(stream['id']);
      agoraAppId = '${d['agora_app_id'] ?? ''}';
      agoraChannel = d['agora_channel']?.toString();
      agoraToken = d['agora_token']?.toString();
      agoraUid = _parsePositiveInt(d['agora_uid']);

      if (agoraUid == null) {
        throw Exception(
          'agora_uid missing from API — deploy Laravel LiveController that returns agora_uid.',
        );
      }

      isLive = true;
      viewerCount = 0;
      likeCount = 0;
      localUserJoined = false;
      isLoading = false;
      print('data of response $d');
      update();

      await initAgora(true);
      isJoined = true;
      Get.to(() => const HostScreen());
    } catch (e, stack) {
      print('ERROR => $e');
      print('STACK => $stack');
      isLoading = false;
      isLive = false;
      currentLiveId = null;
      agoraUid = null;
      agoraToken = null;
      agoraChannel = null;
      update();
      Get.snackbar('Error', '$e');
    }
  }

  Future<void> endLive() async {
    try {
      if (currentLiveId != null) {
        await ApiService.post('/live-streams/$currentLiveId/end', {});
      }
    } catch (_) {}
    await _releaseEngine();
    isJoined = false;
    isLive = false;
    viewerCount = 0;
    likeCount = 0;
    currentLiveId = null;
    agoraUid = null;
    agoraToken = null;
    agoraChannel = null;
    localUserJoined = false;
    remoteUid = null;
    comments.clear();
    update();
    Get.back();
  }

  void addLike() {
    likeCount++;
    update();
  }

  void sendComment(String username) {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;
    comments.insert(0, {'user': username, 'msg': text});
    commentCtrl.clear();
    update();
  }

  List<Map<String, dynamic>> _mock() => [
    {
      'id': 1,
      'title': 'Shani Sade Sati — Upay aur Samadhan',
      'astrologer_name': 'Pt Sharma',
      'viewers': 340,
      'agora_channel': '',
      'agora_token': '',
    },
  ];
}
