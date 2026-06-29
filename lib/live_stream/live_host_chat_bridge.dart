/// Hooks so chat/video from live viewers stay on [HostScreen].
class LiveHostChatBridge {
  static bool Function(Map<String, dynamic> data)? tryOpenChatOnLiveHost;
  static void Function(Map<String, dynamic> data)? onIncomingChatWhileLive;

  static bool Function(Map<String, dynamic> data)? tryOpenVideoOnLiveHost;
  static void Function(Map<String, dynamic> data)? onIncomingVideoWhileLive;

  /// Back-compat alias used by chat routing.
  static set tryOpenOnLiveHost(bool Function(Map<String, dynamic> data)? fn) {
    tryOpenChatOnLiveHost = fn;
  }

  static set onLiveChatAccepted(void Function(Map<String, dynamic> data)? fn) {
    onIncomingChatWhileLive = fn;
  }

  static void clear() {
    tryOpenChatOnLiveHost = null;
    onIncomingChatWhileLive = null;
    tryOpenVideoOnLiveHost = null;
    onIncomingVideoWhileLive = null;
  }
}
