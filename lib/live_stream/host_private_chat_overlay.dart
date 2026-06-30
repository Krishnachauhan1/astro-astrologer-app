import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Private 1:1 chat panel on the astrologer live host screen.
class HostPrivateChatOverlay extends StatefulWidget {
  final String chatId;
  final String userName;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const HostPrivateChatOverlay({
    super.key,
    required this.chatId,
    required this.userName,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  State<HostPrivateChatOverlay> createState() => _HostPrivateChatOverlayState();
}

class _HostPrivateChatOverlayState extends State<HostPrivateChatOverlay> {
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'host_private_${widget.chatId}';
    Get.put(
      ChatController(
        initialChatId: widget.chatId,
        initialUserName: widget.userName,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ChatController>(tag: _tag)) {
      Get.delete<ChatController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.48;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: Material(
        elevation: 14,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: const Color(0xFF121212),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: GetBuilder<ChatController>(
                tag: _tag,
                builder: (ctrl) {
                  if (ctrl.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Reply to the user here — you stay on live.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ctrl.messages.length,
                    itemBuilder: (_, i) => _MessageBubble(ctrl.messages[i]),
                  );
                },
              ),
            ),
            GetBuilder<ChatController>(
              tag: _tag,
              builder: (ctrl) => _InputBar(
                controller: ctrl.msgController,
                onSend: ctrl.sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Private chat on live',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Close chat',
          ),
          IconButton(
            onPressed: widget.onMinimize,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
            ),
            tooltip: 'Minimize',
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Reply to ${'user'}…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onSend,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
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
    final isUser = msg['isUser'] == true;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.white12 : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          msg['message']?.toString() ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
