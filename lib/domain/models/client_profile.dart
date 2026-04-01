/// Client profile model
class ClientProfile {
  final int? id;
  final int userId; // Links to users table
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? preferences; // JSON string for preferences
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientProfile({
    this.id,
    required this.userId,
    this.address,
    this.latitude,
    this.longitude,
    this.preferences,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from database map
  factory ClientProfile.fromMap(Map<String, dynamic> map) {
    return ClientProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      preferences: map['preferences'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'preferences': preferences,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ClientProfile copyWith({
    int? id,
    int? userId,
    String? address,
    double? latitude,
    double? longitude,
    String? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

