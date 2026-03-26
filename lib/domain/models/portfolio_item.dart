/// Domain model for a portfolio item (photo/work sample)
class PortfolioItem {
  final int? id;
  final int specialistId;
  final String imagePath;
  final String? description;
  final DateTime? createdAt;

  PortfolioItem({
    this.id,
    required this.specialistId,
    required this.imagePath,
    this.description,
    this.createdAt,
  });

  /// Create from database map
  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      imagePath: map['image_path'] as String,
      description: map['description'] as String?,
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
      'image_path': imagePath,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  PortfolioItem copyWith({
    int? id,
    int? specialistId,
    String? imagePath,
    String? description,
    DateTime? createdAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

