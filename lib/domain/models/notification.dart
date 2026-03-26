/// Notification types
enum NotificationType {
  order,
  message,
  review,
  system,
}

/// Domain model for notifications
class Notification {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final int? relatedId; // ID of related order, message, review, etc.
  final DateTime? createdAt;

  Notification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  /// Create from database map
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'] as String,
        orElse: () => NotificationType.system,
      ),
      isRead: (map['is_read'] as int? ?? 0) == 1,
      relatedId: map['related_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'is_read': isRead ? 1 : 0,
      'related_id': relatedId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    int? relatedId,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

