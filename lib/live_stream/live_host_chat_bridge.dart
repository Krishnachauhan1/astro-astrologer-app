/// Hooks so chat requests open on [HostScreen] instead of [ChatScreen].
class LiveHostChatBridge {
  static bool Function(Map<String, dynamic> data)? tryOpenOnLiveHost;
  static void Function(Map<String, dynamic> data)? onIncomingChatWhileLive;

  static void clear() {
    tryOpenOnLiveHost = null;
    onIncomingChatWhileLive = null;
  }
}
