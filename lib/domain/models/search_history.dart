/// Domain model for search history
class SearchHistory {
  final int? id;
  final String query;
  final DateTime? createdAt;

  SearchHistory({
    this.id,
    required this.query,
    this.createdAt,
  });

  /// Create from database map
  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'] as int?,
      query: map['query'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'query': query,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  SearchHistory copyWith({
    int? id,
    String? query,
    DateTime? createdAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

