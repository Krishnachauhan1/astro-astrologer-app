import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_list_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: Colors.white.withOpacity(0.2), child: Text('astrologer.name[0]', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('astrologer.name', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration( shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('astrologer.status', style: const TextStyle(fontSize: 11, color: AppColors.primarySurface)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: GetBuilder<ChatController>(
        init: ChatController(),
        builder: (ctrl) => Column(
          children: [
            Expanded(
              child: ctrl.messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 48),
                    const SizedBox(height: 12),
                    const Text('Your consultation starts here 🙏', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.messages!.length,
                itemBuilder: (_, i) => _MessageBubble(ctrl.messages[i]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl.msgController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: ctrl.sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final String message = msg['message'] ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}