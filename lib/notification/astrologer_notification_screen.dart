import 'package:astrosarthi_vendor/app_theme.dart';   
import 'package:astrosarthi_vendor/notification/astrologer_notification_controller.dart';
import 'package:astrosarthi_vendor/utils/session_request_api.dart';   
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AstrologerNotificationScreen extends StatelessWidget {
  const AstrologerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AstrologerNotificationController());
    return GetBuilder<AstrologerNotificationController>(
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: c.fetchNotifications,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: c.isLoading
            ? const Center(child: CircularProgressIndicator())
            : c.items.isEmpty
                ? const Center(
                    child: Text(
                      'No pending call or chat requests',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: c.fetchNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: c.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = c.items[i];
                        final payload = item['data'] is Map
                            ? Map<String, dynamic>.from(item['data'] as Map)
                            : item;
                        final isChat = SessionRequestApi.isChatRequest(item);
                        final title = item['title']?.toString() ??
                            payload['title']?.toString() ??
                            (isChat ? 'Chat request' : 'Call request');
                        final body = item['body']?.toString() ??
                            payload['body']?.toString() ??
                            payload['caller_name']?.toString() ??
                            'A user is waiting for you';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isChat
                                          ? Icons.chat_bubble_outline
                                          : Icons.call,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => c.reject(item),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => c.accept(item),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
      );
                      },
                    ),
                  ),
      ),
      );
  }
}
