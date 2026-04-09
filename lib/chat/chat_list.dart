// import 'package:astrosarthi_konnect_astrologer_app/chat/chat_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:astrosarthi_konnect_astrologer_app/chat/chat_list_controller.dart';

// class ChatList extends StatelessWidget {
//   const ChatList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ChatListController>(
//       init: ChatListController(),
//       builder: (controller) {

//         print("BUILD: ${controller.sessions.length}");

//         if (controller.isLoading) {
//           return Scaffold(
//             appBar: AppBar(title: Text('Chat List')),
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (controller.sessions.isEmpty) {
//           return Scaffold(
//             appBar: AppBar(title: Text('Chat List')),
//             body: Center(child: Text('No active chats yet')),
//           );
//         }

//         return Scaffold(
//           appBar: AppBar(title: Text('Chat List')),
//           body: ListView.builder(
//             itemCount: controller.sessions.length,
//             itemBuilder: (context, index) {
//               final session = controller.sessions[index];
//               final user = session['user'] ?? {};
//               final messages = session['messages'] ?? [];

//               return ListTile(
//                 onTap: (){
//                   Get.to(()=>ChatScreen());
//                 },
//                 title: Text(user['name'] ?? 'No name'),
//                 subtitle: Text(
//                   messages.isNotEmpty
//                       ? messages.last['message']
//                       : 'No message',
//                 ),

//                 trailing: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: session['status'] == 'active'
//                         ? Colors.green
//                         : Colors.grey,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     session['status'] == 'active' ? 'Active' : 'Inactive',
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:astrosarthi_konnect_astrologer_app/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_list_controller.dart';
import 'chat_screen.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatListController>(
      init: ChatListController(),
      tag: Get.arguments?['chatId'],
      builder: (controller) {
        if (controller.isLoading) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.sessions.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No chats yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(),
          body: ListView.separated(
            itemCount: controller.sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final session = controller.sessions[index];
              final userName = session['userName'] ?? 'User';
              final lastMessage = session['lastMessage'] ?? 'No message';
              final status = session['status'] ?? 'inactive';
              final updatedAt = session['updatedAt'];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: _getAvatarColor(userName),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
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
                        lastMessage,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? Colors.green
                            : Colors.grey.shade400,
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
                  print("Tapped: ${session['id']} — ${session['userName']}");
                  Get.delete<ChatController>(force: true);
                  Get.put(
                    ChatController(
                      initialChatId: session['id'] ?? 'demo_chat',
                      initialUserName: session['userName'] ?? 'User',
                    ),
                  );

                  Get.to(() => const ChatScreen());
                },
              );
            },
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
      elevation: 1,
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [Colors.teal];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
