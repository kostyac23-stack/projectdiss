/// Domain model for a review
class Review {
  final int? id;
  final int specialistId;
  final String clientName;
  final int rating; // 1-5
  final String? comment;
  final String? specialistResponse; // Response from specialist
  final DateTime? createdAt;

  Review({
    this.id,
    required this.specialistId,
    required this.clientName,
    required this.rating,
    this.comment,
    this.specialistResponse,
    this.createdAt,
  });

  /// Create from database map
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      clientName: map['client_name'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      specialistResponse: map['specialist_response'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      'client_name': clientName,
      'rating': rating,
      'comment': comment,
      'specialist_response': specialistResponse,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Review copyWith({
    int? id,
    int? specialistId,
    String? clientName,
    int? rating,
    String? comment,
    String? specialistResponse,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      clientName: clientName ?? this.clientName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      specialistResponse: specialistResponse ?? this.specialistResponse,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

