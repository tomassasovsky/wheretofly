/// Per-category push notification toggles.
class NotificationPreferences {
  const NotificationPreferences({
    required this.follows,
    required this.messages,
    required this.comments,
    required this.weather,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      follows: json['follows'] as bool? ?? true,
      messages: json['messages'] as bool? ?? true,
      comments: json['comments'] as bool? ?? true,
      weather: json['weather'] as bool? ?? true,
    );
  }

  final bool follows;
  final bool messages;
  final bool comments;
  final bool weather;

  NotificationPreferences copyWith({
    bool? follows,
    bool? messages,
    bool? comments,
    bool? weather,
  }) {
    return NotificationPreferences(
      follows: follows ?? this.follows,
      messages: messages ?? this.messages,
      comments: comments ?? this.comments,
      weather: weather ?? this.weather,
    );
  }

  Map<String, dynamic> toJson() => {
        'follows': follows,
        'messages': messages,
        'comments': comments,
        'weather': weather,
      };
}
