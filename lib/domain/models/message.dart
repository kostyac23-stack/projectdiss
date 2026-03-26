/// Domain model for a chat message
class Message {
  final int? id;
  final int specialistId;
  final int? userId; // Links to the user who owns this conversation
  final String senderName;
  final bool isFromClient;
  final String content;
  final DateTime? createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.specialistId,
    this.userId,
    required this.senderName,
    required this.isFromClient,
    required this.content,
    this.createdAt,
    this.isRead = false,
  });

  /// Create from database map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      userId: map['user_id'] as int?,
      senderName: map['sender_name'] as String,
      isFromClient: (map['is_from_client'] as int? ?? 0) == 1,
      content: map['content'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      if (userId != null) 'user_id': userId,
      'sender_name': senderName,
      'is_from_client': isFromClient ? 1 : 0,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  Message copyWith({
    int? id,
    int? specialistId,
    int? userId,
    String? senderName,
    bool? isFromClient,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      userId: userId ?? this.userId,
      senderName: senderName ?? this.senderName,
      isFromClient: isFromClient ?? this.isFromClient,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
