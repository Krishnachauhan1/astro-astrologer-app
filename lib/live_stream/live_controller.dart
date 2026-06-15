import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/host_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/utils/call_session_api.dart';
import 'package:astrosarthi_konnect_astrologer_app/utils/session_request_api.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicess/api_service.dart';

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
      Get.snackbar(
        'Permissions required',
        'Camera and microphone permission are required to go live.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return ok;
  }

  Future<void> _releaseEngine() async {
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
    if (!await ensurePermissions()) return;

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
          debugPrint('agora error => $err');
          debugPrint('agora msg => $msg');
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
      Get.snackbar('Error', '$e');
    }
  }

  Future<void> endLive() async {
    if (isLoading) return;
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
    isLoading = false;
    await _persistDraft();
    update();

    // Best-effort server end in background.
    if (endId != null) {
      unawaited(_endOnServer(endId));
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
    update();
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

}
