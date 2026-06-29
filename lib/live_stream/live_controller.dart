import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_vendor/authentication/auth_controller.dart';
import 'package:astrosarthi_vendor/live_stream/host_screen.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:astrosarthi_vendor/utils/call_session_api.dart';
import 'package:astrosarthi_vendor/utils/session_request_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicess/api_service.dart';
import '../chat/chat_controller.dart';

class LiveController extends GetxController {
  static const _prefsKey = 'live_draft_session_v1';
  static const _pendingEndKey = 'live_pending_end_v1';

  RtcEngine? engine;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _liveChatSub;
  String agoraAppId = '';
  String? agoraChannel;
  String? agoraToken;

  /// Must match the UID encoded in [agoraToken] (Laravel sends logged-in user id for host).
  int? agoraUid;

  bool isJoined = false;
  bool isLoading = false;
  bool isLive = false;
  bool localUserJoined = false;
  int? remoteUid;
  int viewerCount = 0;
  int likeCount = 0;
  int? currentLiveId;
  String? currentTitle;

  bool get needsRecovery => isLive && engine == null;

  final List<Map<String, String>> comments = [];
  final TextEditingController commentCtrl = TextEditingController();

  bool hostScreenActive = false;
  Map<String, dynamic>? pendingChatRequest;
  String? activePrivateChatId;
  String? activePrivateChatUserName;
  bool privateChatPanelOpen = false;
  bool privateChatMinimized = false;

  Map<String, dynamic>? pendingVideoCallRequest;
  Map<String, dynamic>? activeVideoCallData;
  bool videoCallPanelOpen = false;
  bool videoCallMinimized = false;
  bool _liveSuspendedForOverlay = false;

  // In-live video call on second channel (same engine via joinChannelEx).
  bool callJoining = false;
  bool callJoined = false;
  String callJoinError = '';
  String _callChannelId = '';
  int? _callSessionId;
  RtcConnection? _callConnection;
  VoidCallback? _onCallOverlayEnded;
  Timer? _callTimer;
  int _callSeconds = 0;
  int? callRemoteUid;
  bool callRemoteJoined = false;
  bool callRemoteVideoReady = false;
  int? _expectedCallRemoteUid;

  int? get expectedCallRemoteUid => _expectedCallRemoteUid;
  String get callChannelId => _callChannelId;
  RtcConnection? get callRtcConnection => _callConnection;

  String get callFormattedTime {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  RtcEngineEx? get _engineEx {
    final e = engine;
    if (e == null) return null;
    return e as RtcEngineEx;
  }

  bool get isHostingLive => isLive && hostScreenActive && engine != null;

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
    _flushPendingEnd();
    _restoreDraft();
  }

  @override
  void onClose() {
    _persistDraft();
    _stopLiveChat();
    _releaseEngine();
    commentCtrl.dispose();
    super.onClose();
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final parts = raw.split('|');
      if (parts.length < 5) return;

      currentLiveId = _parsePositiveInt(parts[0]);
      agoraAppId = parts[1];
      agoraChannel = parts[2].isEmpty ? null : parts[2];
      agoraToken = parts[3].isEmpty ? null : parts[3];
      agoraUid = _parsePositiveInt(parts[4]);
      currentTitle = parts.length >= 6 && parts[5].isNotEmpty ? parts[5] : null;

      // Draft indicates "user started live". Engine is not restored here.
      if (currentLiveId != null && agoraUid != null && agoraChannel != null) {
        isLive = true;
        _startLiveChat();
      }
      update();
    } catch (_) {}
  }

  Future<void> _flushPendingEnd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = _parsePositiveInt(prefs.getString(_pendingEndKey));
      if (id == null) return;
      await prefs.remove(_pendingEndKey);
      unawaited(_endOnServer(id));
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>>? get _liveMessagesRef {
    final id = currentLiveId;
    if (id == null) return null;
    return _firestore.collection('live_chats').doc(id.toString()).collection('messages');
  }

  void _stopLiveChat() {
    _liveChatSub?.cancel();
    _liveChatSub = null;
  }

  void _startLiveChat() {
    _stopLiveChat();
    final ref = _liveMessagesRef;
    if (ref == null) return;
    _liveChatSub = ref.orderBy('createdAt', descending: false).snapshots().listen(
      (snap) {
        comments
          ..clear()
          ..addAll(
            snap.docs.map((d) {
              final m = d.data();
              final name = (m['senderName'] ?? m['sender'] ?? 'User').toString();
              final text = (m['text'] ?? '').toString();
              return {'user': name, 'msg': text};
            }),
      );
        update();
      },
      onError: (_) {},
      );
  }

  Future<void> _persistDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!isLive || currentLiveId == null || agoraUid == null) {
        await prefs.remove(_prefsKey);
        return;
      }
      final raw =
          '${currentLiveId ?? ''}|$agoraAppId|${agoraChannel ?? ''}|${agoraToken ?? ''}|${agoraUid ?? ''}|${currentTitle ?? ''}';
      await prefs.setString(_prefsKey, raw);
    } catch (_) {}
  }

  Future<bool> ensurePermissions() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    final ok = cam.isGranted && mic.isGranted;
    if (!ok) {
      AppSnackbar.show(
        'Permissions required',
        'Camera and microphone permission are required to go live.',
      );
    }
    return ok;
  }

  Future<void> _releaseEngine() async {
    await leaveCallOverlay(endOnServer: false);
    try {
      await engine?.stopPreview();
      await engine?.leaveChannel();
      await engine?.release();
    } catch (e) {
      debugPrint('engine release error $e');
    }
    engine = null;
    isJoined = false;
  }

  bool _isLiveConnection(RtcConnection connection) {
    final id = connection.channelId?.trim() ?? '';
    if (id.isEmpty || id == agoraChannel) return true;
    return false;
  }

  bool _isCallConnection(RtcConnection connection) {
    final id = connection.channelId?.trim() ?? '';
    return id.isNotEmpty && id == _callChannelId;
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callSeconds++;
      update();
    });
  }

  Future<void> _unmuteCallRemote(int uid) async {
    final ex = _engineEx;
    final conn = _callConnection;
    if (ex == null || conn == null || uid <= 0) return;
    try {
      await ex.muteRemoteAudioStreamEx(
        uid: uid,
        mute: false,
        connection: conn,
      );
      await ex.muteRemoteVideoStreamEx(
        uid: uid,
        mute: false,
        connection: conn,
      );
    } catch (e) {
      debugPrint('unmute call remote uid=$uid error: $e');
    }
  }

  Future<void> _onCallChannelJoined() async {
    final ex = _engineEx;
    final conn = _callConnection;
    if (ex == null || conn == null) return;
    try {
      await ex.muteAllRemoteAudioStreamsEx(connection: conn, mute: false);
      await ex.muteAllRemoteVideoStreamsEx(connection: conn, mute: false);
    } catch (e) {
      debugPrint('muteAllRemote call streams error: $e');
    }
    final expected = _expectedCallRemoteUid;
    if (expected != null && expected > 0) {
      await _unmuteCallRemote(expected);
    }
  }

  void _onCallRemoteJoined(int uid) {
    if (uid <= 0 || uid == agoraUid) return;
    callRemoteUid = uid;
    callRemoteJoined = true;
    callRemoteVideoReady = true;
    _startCallTimer();
    unawaited(_unmuteCallRemote(uid));
    update();
  }

  /// Join 1:1 call channel while keeping the live broadcast (receive user video).
  Future<void> joinCallOverlay({
    required Map<String, dynamic> callData,
    VoidCallback? onEnded,
  }) async {
    if (callJoined || callJoining) return;
    if (engine == null || !localUserJoined || agoraUid == null) {
      callJoinError = 'Live stream not ready. Please wait.';
      update();
      return;
    }

    final ex = _engineEx;
    if (ex == null) {
      callJoinError = 'Video engine not available.';
      update();
      return;
    }

    final token = (callData['agora_token'] ?? callData['token'] ?? '')
        .toString()
        .trim();
    final channel =
        (callData['agora_channel'] ?? callData['channel'] ?? '').toString().trim();
    final sessionId = parseCallSessionId(callData);

    if (token.isEmpty || channel.isEmpty) {
      callJoinError = 'Call credentials missing.';
      update();
      return;
    }

    callJoining = true;
    callJoinError = '';
    _onCallOverlayEnded = onEnded;
    _callChannelId = channel;
    _callSessionId = sessionId;
    _expectedCallRemoteUid = int.tryParse(
      (callData['caller_uid'] ?? callData['callerUid'] ?? '').toString(),
    );
    _callConnection = RtcConnection(
      channelId: _callChannelId,
      localUid: agoraUid,
    );
    update();

    try {
      await ex.joinChannelEx(
        token: token,
        connection: _callConnection!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      callJoining = false;
      callJoinError = 'Could not join video call ($e).';
      _callConnection = null;
      _callChannelId = '';
      update();
    }
  }

  Future<void> leaveCallOverlay({
    bool endOnServer = true,
    bool notifyEnded = true,
  }) async {
    if (!callJoined && !callJoining) return;

    _callTimer?.cancel();
    _callTimer = null;

    final ex = _engineEx;
    final conn = _callConnection;
    try {
      if (ex != null && conn != null) {
        await ex.leaveChannelEx(connection: conn);
      }
    } catch (_) {}

    final sessionId = _callSessionId;
    callJoining = false;
    callJoined = false;
    callRemoteUid = null;
    callRemoteJoined = false;
    callRemoteVideoReady = false;
    _callChannelId = '';
    _callConnection = null;
    _callSessionId = null;
    _expectedCallRemoteUid = null;
    _callSeconds = 0;

    if (endOnServer && sessionId != null && sessionId > 0) {
      await endCallSession(sessionId);
    }

    final ended = _onCallOverlayEnded;
    _onCallOverlayEnded = null;
    update();
    if (notifyEnded) {
      ended?.call();
    }
  }

  Future<void> initAgora(bool isHost) async {
    if (isHost && agoraUid == null) {
      AppSnackbar.show(
        'Live',
        'agora_uid missing — update backend or API response.',
      );
      return;
    }

    await _releaseEngine();
    if (!await ensurePermissions()) return;

    engine = createAgoraRtcEngine();
    await engine!.initialize(
      RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
      );
    await engine!.enableVideo();
    await engine!.enableAudio();

    if (isHost) {
      await engine!.enableLocalVideo(true);
      await engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 15,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
    }

    engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (_isCallConnection(connection)) {
            callJoining = false;
            callJoined = true;
            _startCallTimer();
            unawaited(_onCallChannelJoined());
            update();
            return;
          }
          if (_isLiveConnection(connection)) {
            localUserJoined = true;
            update();
          }
        },
        onLeaveChannel: (connection, stats) {
          if (_isCallConnection(connection)) {
            callJoining = false;
            callJoined = false;
            _callTimer?.cancel();
            update();
          }
        },
        onUserJoined: (connection, uid, elapsed) {
          if (_isCallConnection(connection)) {
            debugPrint('CALL remote joined uid=$uid channel=${connection.channelId}');
            _onCallRemoteJoined(uid);
            return;
          }
          if (_isLiveConnection(connection)) {
            remoteUid = uid;
            viewerCount++;
            update();
          }
        },
        onUserOffline: (connection, uid, reason) {
          if (_isCallConnection(connection)) {
            if (uid == callRemoteUid || uid == _expectedCallRemoteUid) {
              callRemoteUid = null;
              callRemoteVideoReady = false;
              update();
              Future.delayed(const Duration(seconds: 8), () {
                if (!callRemoteVideoReady && callJoined) {
                  leaveCallOverlay(endOnServer: true);
                }
              });
            }
            return;
          }
          if (_isLiveConnection(connection)) {
            remoteUid = null;
            if (viewerCount > 0) viewerCount--;
            update();
          }
        },
        onRemoteVideoStateChanged:
            (connection, uid, state, reason, elapsed) {
          if (!_isCallConnection(connection)) return;
          if (uid <= 0 || uid == agoraUid) return;
          debugPrint('CALL remote video uid=$uid state=$state');
          if (state == RemoteVideoState.remoteVideoStateStarting ||
              state == RemoteVideoState.remoteVideoStateDecoding) {
            callRemoteUid = uid;
            callRemoteJoined = true;
            callRemoteVideoReady = true;
            unawaited(_unmuteCallRemote(uid));
            update();
          } else if (state == RemoteVideoState.remoteVideoStateFailed) {
            if (callRemoteUid == uid) {
              callRemoteVideoReady = false;
              update();
            }
          }
        },
        onFirstRemoteVideoFrame:
            (connection, uid, width, height, elapsed) {
          if (!_isCallConnection(connection)) return;
          if (uid > 0 && uid != agoraUid) {
            callRemoteUid = uid;
            callRemoteJoined = true;
            callRemoteVideoReady = true;
            update();
          }
        },
        onError: (err, msg) {
          debugPrint('agora error => $err');
          debugPrint('agora msg => $msg');
          if (callJoining) {
            callJoining = false;
            callJoinError = msg;
            update();
            return;
          }
          AppSnackbar.show(
            'Agora Error',
            msg,
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
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
    debugPrint(
      'agora token/channel/uid => $agoraToken | $agoraChannel | $joinUid',
      );

    update();
  }

  Future<void> startLive({String title = 'Live Astrology Session'}) async {
    if (isLoading) return;
    if (!await ensurePermissions()) return;
    isLoading = true;
    update();
    try {
      final res = await ApiService.post('/live-streams/start', {
        'title': title,
      });
      debugPrint('live stream session $res');

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
      currentTitle = title;

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
      update();

      await _persistDraft();
      _startLiveChat();
      await initAgora(true);
      isJoined = true;
      Get.to(() => const HostScreen());
    } catch (e, stack) {
      debugPrint('ERROR => $e');
      debugPrint('STACK => $stack');
      isLoading = false;
      isLive = false;
      currentLiveId = null;
      agoraUid = null;
      agoraToken = null;
      agoraChannel = null;
      currentTitle = null;
      _stopLiveChat();
      await _persistDraft();
      update();
      AppSnackbar.show('Error', '$e');
    }
  }

  Future<void> endLive({bool leaveHostScreen = true}) async {
    if (isLoading) return;
    final wasOnHost = hostScreenActive;
    isLoading = true;
    update();

    final endId = currentLiveId;

    // Make UI fast: stop locally first.
    _stopLiveChat();
    await _releaseEngine();

    isJoined = false;
    isLive = false;
    viewerCount = 0;
    likeCount = 0;
    currentLiveId = null;
    agoraUid = null;
    agoraToken = null;
    agoraChannel = null;
    currentTitle = null;
    localUserJoined = false;
    remoteUid = null;
    comments.clear();
    clearPrivateChatState();
    clearVideoCallState();
    _liveSuspendedForOverlay = false;
    isLoading = false;
    await _persistDraft();
    update();

    // Best-effort server end in background.
    if (endId != null) {
      unawaited(_endOnServer(endId));
    }

    if (leaveHostScreen && wasOnHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _leaveHostScreen();
      });
    }
  }

  void _leaveHostScreen() {
    setHostScreenActive(false);
    while (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  Future<void> _endOnServer(int liveId) async {
    try {
      await ApiService.post('/live-streams/$liveId/end', {})
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pendingEndKey, liveId.toString());
      } catch (_) {}
    }
  }

  void addLike() {
    likeCount++;
    update();
  }

  Future<void> sendComment(String username) async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    if (privateChatPanelOpen && activePrivateChatId != null) {
      final tag = 'host_private_$activePrivateChatId';
      if (Get.isRegistered<ChatController>(tag: tag)) {
        commentCtrl.clear();
        final chatCtrl = Get.find<ChatController>(tag: tag);
        chatCtrl.msgController.text = text;
        await chatCtrl.sendMessage();
        return;
      }
    }

    commentCtrl.clear();

    final ref = _liveMessagesRef;
    if (ref == null) return;

    await ref.add({
      'text': text,
      'sender': 'astrologer',
      'senderName': username,
      'senderId': Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().user?.id
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void setHostScreenActive(bool active) {
    hostScreenActive = active;
  }

  void setPendingChatRequest(Map<String, dynamic>? data) {
    pendingChatRequest = data;
    update();
  }

  String? resolveFirebaseChatId(Map<String, dynamic> data) {
    final fromPayload =
        (data['firebase_chat_id'] ?? data['firebaseChatId'])?.toString().trim();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;

    final userId = int.tryParse(
      '${data['user_id'] ?? data['caller_uid'] ?? data['customer_id']}',
      );
    final astroId = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().user?.id
        : null;
    if (userId == null ||
        astroId == null ||
        userId <= 0 ||
        astroId <= 0) {
      return null;
    }
    return userId < astroId ? '${userId}_$astroId' : '${astroId}_$userId';
  }

  void ensureHostPrivateChatController() {
    final chatId = activePrivateChatId;
    if (chatId == null) return;
    final tag = 'host_private_$chatId';
    if (Get.isRegistered<ChatController>(tag: tag)) return;
    Get.put(
      ChatController(
        initialChatId: chatId,
        initialUserName: activePrivateChatUserName ?? 'User',
      ),
      tag: tag,
      );
  }

  void openPrivateChatFromPayload(Map<String, dynamic> data) {
    final chatId = resolveFirebaseChatId(data);
    if (chatId == null) return;

    final userName = data['caller_name']?.toString() ??
        data['user_name']?.toString() ??
        'User';

    activePrivateChatId = chatId;
    activePrivateChatUserName = userName;
    privateChatPanelOpen = true;
    privateChatMinimized = false;
    pendingChatRequest = null;
    ensureHostPrivateChatController();
    update();
  }

  Future<void> acceptPendingChat() async {
    final data = pendingChatRequest;
    if (data == null) return;

    final sessionId = SessionRequestApi.parseSessionId(data) ??
        parseCallSessionId(data);
    if (sessionId != null) {
      await acceptChatSession(sessionId);
    }
    openPrivateChatFromPayload(data);
  }

  Future<void> rejectPendingChat() async {
    final data = pendingChatRequest;
    if (data == null) return;

    final sessionId = SessionRequestApi.parseSessionId(data) ??
        parseCallSessionId(data);
    if (sessionId != null) {
      await rejectChatSession(sessionId);
    }
    pendingChatRequest = null;
    update();
  }

  void minimizePrivateChat() {
    privateChatMinimized = true;
    update();
  }

  void restorePrivateChat() {
    privateChatMinimized = false;
    update();
  }

  void closePrivateChat() {
    final chatId = activePrivateChatId;
    if (chatId != null) {
      final tag = 'host_private_$chatId';
      if (Get.isRegistered<ChatController>(tag: tag)) {
        Get.delete<ChatController>(tag: tag, force: true);
      }
    }
    activePrivateChatId = null;
    activePrivateChatUserName = null;
    privateChatPanelOpen = false;
    privateChatMinimized = false;
    update();
  }

  void clearPrivateChatState() {
    pendingChatRequest = null;
    closePrivateChat();
  }

  bool _isVideoCallPayload(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final callType =
        (data['callType'] ?? data['call_type'] ?? '').toString().toLowerCase();
    return callType.contains('video') ||
        type.contains('video') ||
        type == 'incoming_video_call';
  }

  void setPendingVideoCallRequest(Map<String, dynamic>? data) {
    pendingVideoCallRequest = data;
    update();
  }

  void openVideoCallFromPayload(Map<String, dynamic> data) {
    if (!_isVideoCallPayload(data)) return;

    final channel =
        (data['agora_channel'] ?? data['channel'] ?? '').toString().trim();
    if (videoCallPanelOpen && activeVideoCallData != null && channel.isNotEmpty) {
      final existing = (activeVideoCallData!['agora_channel'] ??
              activeVideoCallData!['channel'] ??
              '')
          .toString()
          .trim();
      if (existing == channel) {
        activeVideoCallData = {
          ...Map<String, dynamic>.from(activeVideoCallData!),
          ...Map<String, dynamic>.from(data),
        };
        pendingVideoCallRequest = null;
        update();
        return;
      }
    }

    activeVideoCallData = Map<String, dynamic>.from(data);
    videoCallPanelOpen = true;
    videoCallMinimized = false;
    pendingVideoCallRequest = null;
    update();
  }

  Future<void> acceptPendingVideoCall() async {
    final data = pendingVideoCallRequest;
    if (data == null) return;

    final sessionId = SessionRequestApi.parseSessionId(data) ??
        parseCallSessionId(data);

    var merged = Map<String, dynamic>.from(data);
    if (sessionId != null) {
      try {
        final res = await ApiService.post('/$sessionId/accept', {});
        if (res['success'] == true && res['data'] is Map) {
          merged = {
            ...merged,
            ...Map<String, dynamic>.from(res['data'] as Map),
          };
        }
      } catch (_) {
        await acceptCallSession(sessionId);
      }
    }

    openVideoCallFromPayload(merged);
  }

  Future<void> rejectPendingVideoCall() async {
    final data = pendingVideoCallRequest;
    if (data == null) return;

    final sessionId = SessionRequestApi.parseSessionId(data) ??
        parseCallSessionId(data);
    if (sessionId != null) {
      await rejectCallSession(sessionId);
    }
    pendingVideoCallRequest = null;
    update();
  }

  void minimizeVideoCall() {
    videoCallMinimized = true;
    update();
  }

  void restoreVideoCall() {
    videoCallMinimized = false;
    update();
  }

  void closeVideoCall() {
    unawaited(leaveCallOverlay(endOnServer: false, notifyEnded: false));
    activeVideoCallData = null;
    videoCallPanelOpen = false;
    videoCallMinimized = false;
    update();
  }

  void clearVideoCallState() {
    pendingVideoCallRequest = null;
    closeVideoCall();
  }

  Future<void> suspendLiveForOverlaySession() async {
    if (_liveSuspendedForOverlay) return;
    _liveSuspendedForOverlay = true;
    try {
      await engine?.stopPreview();
      await engine?.leaveChannel();
      await engine?.release();
    } catch (_) {}
    engine = null;
    localUserJoined = false;
    update();
    // Let Android release the camera before the call engine opens it.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> resumeLiveAfterOverlaySession() async {
    if (!_liveSuspendedForOverlay) return;
    _liveSuspendedForOverlay = false;
    if (agoraChannel != null &&
        agoraToken != null &&
        agoraUid != null &&
        agoraAppId.isNotEmpty) {
      await initAgora(true);
    }
    update();
  }

}
