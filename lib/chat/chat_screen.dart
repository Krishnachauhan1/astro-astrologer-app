import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      init: ChatController(),
      builder: (ctrl) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    ctrl.userName.isNotEmpty
                        ? ctrl.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(ctrl.userName, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ctrl.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Reply to the user 🙏',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ctrl.messages.length,
                        itemBuilder: (_, i) => _MessageBubble(ctrl.messages[i]),
                      ),
              ),
              _InputBar(ctrl: ctrl),
            ],
          ),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final ChatController ctrl;
  const _InputBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl.msgController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your response...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: ctrl.sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _MessageBubble(this.msg);

  @override
  Widget build(BuildContext context) {
    final bool isUser = msg['isUser'] ?? false;

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.grey.shade200 : Colors.deepPurple,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 4 : 18),
            bottomRight: Radius.circular(isUser ? 18 : 4),
          ),
        ),
        child: Text(
          msg['message'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.black87 : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
