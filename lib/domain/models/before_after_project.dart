/// Model for before/after project showcase
class BeforeAfterProject {
  final int? id;
  final int specialistId;
  final String title;
  final String? description;
  final String? beforeDescription;
  final String? afterDescription;
  final String category;
  final String? beforeImagePath;
  final String? afterImagePath;
  final DateTime createdAt;

  BeforeAfterProject({
    this.id,
    required this.specialistId,
    required this.title,
    this.description,
    this.beforeDescription,
    this.afterDescription,
    required this.category,
    this.beforeImagePath,
    this.afterImagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BeforeAfterProject.fromMap(Map<String, dynamic> map) {
    return BeforeAfterProject(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      beforeDescription: map['before_description'] as String?,
      afterDescription: map['after_description'] as String?,
      category: map['category'] as String,
      beforeImagePath: map['before_image_path'] as String?,
      afterImagePath: map['after_image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      'title': title,
      'description': description,
      'before_description': beforeDescription,
      'after_description': afterDescription,
      'category': category,
      'before_image_path': beforeImagePath,
      'after_image_path': afterImagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
