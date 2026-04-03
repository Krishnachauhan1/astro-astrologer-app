class ChatMessage {
  final int id;
  final String message;
  final String senderType; // 'user' or 'astrologer'
  final int senderId;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderType,
    required this.senderId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? 0,
    message: json['message'] ?? '',
    senderType: json['sender_type'] ?? 'user',
    senderId: json['sender_id'] ?? 0,
    createdAt: json['created_at'] ?? '',
  );

  bool get isUser => senderType == 'user';
}