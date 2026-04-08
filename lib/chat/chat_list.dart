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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_list_controller.dart';

class ChatList extends StatelessWidget {
  ChatList({super.key});

  final ChatListController controller = Get.put(ChatListController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatListController>(
      builder: (controller) {
        if (controller.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Chats')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.sessions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('Chats')),
            body: Center(child: Text('No chats found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('Chats')),
          body: ListView.builder(
            itemCount: controller.sessions.length,
            itemBuilder: (context, index) {
              final session = controller.sessions[index];

              return ListTile(
                title: Text(session['userName'] ?? 'No Name'),
                subtitle: Text(session['lastMessage'] ?? 'No message'),

                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: session['status'] == 'active' ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(10)),
                  child: Text(session['status'] ?? 'inactive', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),

                onTap: () {
                  print("Open chat: ${session['id']}");
                  // Navigate to chat screen
                },
              );
            },
          ),
        );
      },
    );
  }
}
