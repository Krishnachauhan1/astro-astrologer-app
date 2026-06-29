import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/assistant_chat_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'assistant_chat_screen.dart';

class AssistantChatListScreen extends StatelessWidget {
  const AssistantChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (auth) {
        if (auth.user?.id == null || auth.user!.id <= 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (Get.isRegistered<AssistantChatListController>()) {
          Get.find<AssistantChatListController>().ensureListening();
        }

        return GetBuilder<AssistantChatListController>(
          init: AssistantChatListController(),
          builder: (controller) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

        if (controller.sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No assistant chats yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
      );
        }

        return ListView.separated(
          itemCount: controller.sessions.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final session = controller.sessions[index];
            final name = (session['userName'] ?? 'Assistant').toString();
            final last = (session['lastMessage'] ?? 'No message').toString();
            final status = (session['status'] ?? 'inactive').toString();
            final updatedAt = session['updatedAt'];
            final id = (session['id'] ?? '').toString();

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (updatedAt != null)
                    Text(
                      controller.formatTime(updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'active'
                            ? Colors.deepPurple
                            : Colors.grey,
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          status == 'active' ? Colors.green : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status == 'active' ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (id.isEmpty) return;
                Get.to(() => AssistantChatScreen(sessionId: id, readOnly: true));
              },
      );
          },
      );
          },
      );
      },
      );
  }
}

