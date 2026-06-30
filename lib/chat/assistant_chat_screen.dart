import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'assistant_chat_controller.dart';

class AssistantChatScreen extends StatelessWidget {
  final String sessionId;
  final bool readOnly;
  const AssistantChatScreen({
    super.key,
    required this.sessionId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<AssistantChatController>()) {
      final existing = Get.find<AssistantChatController>();
      if (existing.sessionId != sessionId) {
        Get.delete<AssistantChatController>(force: true);
      }
    }
    if (!Get.isRegistered<AssistantChatController>()) {
      Get.put(AssistantChatController(sessionId: sessionId));
    }

    return GetBuilder<AssistantChatController>(
      builder: (ctrl) {
        final list = ctrl.messages;
        final allowAssistantReply = readOnly; // view-only opens reply-as-assistant
        return Scaffold(
          appBar: AppBar(
            title: const Text('Assistant Chat'),
            actions: [
              if (readOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text(
                        'View only',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              _QuotaBar(ctrl: ctrl),
              Expanded(
                child: ctrl.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : list.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                            itemCount: list.length + (ctrl.isTyping ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (ctrl.isTyping && i == list.length) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _TypingBubble(),
                                  ),
      );
                              }
                              return _MessageBubble(list[i]);
                            },
                          ),
              ),
              if (!readOnly)
                _InputBar(
                  controller: ctrl.msgController,
                  onSend: ctrl.sendMessage,
                  hintText: ctrl.canSend
                      ? 'Ask assistant to draft a reply...'
                      : 'Limit reached (user app purchase required)',
                  sendColor: AppColors.primary,
                ),
              if (allowAssistantReply)
                _AssistantReplyBar(
                  onSend: ctrl.sendAssistantMessage,
                ),
            ],
          ),
      );
      },
      );
  }
}

class _QuotaBar extends StatelessWidget {
  final AssistantChatController ctrl;
  const _QuotaBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bg = ctrl.isPaid ? AppColors.online : AppColors.away;
    final title = ctrl.isPaid
        ? 'Assistant active'
        : 'Free: ${ctrl.freeRemaining}/${AssistantChatController.freeMessageLimit}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ctrl.isPaid ? Icons.verified_rounded : Icons.auto_awesome_rounded,
              size: 18,
              color: bg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ctrl.isPaid
                      ? 'Customers can continue based on purchase.'
                      : 'After 5, user must purchase in User app.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!ctrl.canSend && !ctrl.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.busy.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Limit reached',
                style: TextStyle(
                  color: AppColors.busy,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final String hintText;
  final Color sendColor;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.hintText,
    required this.sendColor,
  });

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
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
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
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: sendColor,
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
    final time = _formatTime(msg['createdAt']);

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.grey.shade200 : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 4 : 18),
            bottomRight: Radius.circular(isUser ? 18 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.black87 : Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: (isUser ? Colors.black54 : Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
      );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate().toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(),
          const SizedBox(width: 6),
          _dot(),
          const SizedBox(width: 6),
          _dot(),
        ],
      ),
      );
  }

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(999),
        ),
      );
}

class _AssistantReplyBar extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  const _AssistantReplyBar({required this.onSend});

  @override
  State<_AssistantReplyBar> createState() => _AssistantReplyBarState();
}

class _AssistantReplyBarState extends State<_AssistantReplyBar> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await widget.onSend(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Reply as Assistant...',
                filled: true,
                fillColor: AppColors.primarySurface,
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
            onTap: _sending ? null : _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
      );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No assistant messages yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Once users talk to the assistant, their messages will appear here in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      );
  }
}

