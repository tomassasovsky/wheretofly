/// A single chat message in a thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.mediaKey,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      senderId: json['senderId'] as String,
      body: json['body'] as String? ?? '',
      mediaKey: json['mediaKey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final String? mediaKey;
  final DateTime createdAt;
}
