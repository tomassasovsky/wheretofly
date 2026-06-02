/// A chat thread summary for the inbox list.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.isGroup,
    this.name,
    this.lastMessageBody,
    this.lastMessageAt,
    this.otherHandle,
    this.otherDisplayName,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      name: json['name'] as String?,
      lastMessageBody: json['lastMessageBody'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      otherHandle: json['otherHandle'] as String?,
      otherDisplayName: json['otherDisplayName'] as String?,
    );
  }

  final String id;
  final bool isGroup;
  final String? name;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final String? otherHandle;
  final String? otherDisplayName;

  String displayTitle() {
    if (isGroup && name != null && name!.isNotEmpty) return name!;
    if (otherDisplayName != null && otherDisplayName!.isNotEmpty) {
      return otherDisplayName!;
    }
    if (otherHandle != null && otherHandle!.isNotEmpty) {
      return '@$otherHandle';
    }
    return 'Chat';
  }
}
