import 'specialist.dart';

/// Domain model for a favorite specialist
class Favorite {
  final int? id;
  final int specialistId;
  final DateTime? createdAt;
  final Specialist? specialist; // Populated when needed

  Favorite({
    this.id,
    required this.specialistId,
    this.createdAt,
    this.specialist,
  });

  /// Create from database map
  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
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
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Favorite copyWith({
    int? id,
    int? specialistId,
    DateTime? createdAt,
    Specialist? specialist,
  }) {
    return Favorite(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      createdAt: createdAt ?? this.createdAt,
      specialist: specialist ?? this.specialist,
    );
  }
}

