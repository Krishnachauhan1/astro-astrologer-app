import 'package:get/get.dart';

import 'assistant_chat_list_controller.dart';
import 'chat_list_controller.dart';

/// Keeps chat lists scoped to the current astrologer across login/logout.
class ChatSessionBindings {
  static void bindForLoggedInAstrologer() {
    if (!Get.isRegistered<ChatListController>()) {
      Get.put(ChatListController(), permanent: true);
    } else {
      Get.find<ChatListController>().ensureListening();
    }

    if (!Get.isRegistered<AssistantChatListController>()) {
      Get.put(AssistantChatListController(), permanent: true);
    } else {
      Get.find<AssistantChatListController>().ensureListening();
    }
  }

  static void clearOnLogout() {
    if (Get.isRegistered<ChatListController>()) {
      Get.find<ChatListController>().reset();
      Get.delete<ChatListController>(force: true);
    }
    if (Get.isRegistered<AssistantChatListController>()) {
      Get.find<AssistantChatListController>().reset();
      Get.delete<AssistantChatListController>(force: true);
    }
  }
}
