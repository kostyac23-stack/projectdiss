import 'specialist.dart';

/// Specialist profile model linked to a user account
class SpecialistProfile {
  final int? id;
  final int userId; // Links to users table
  final int? specialistId; // Links to specialists table (if already exists)
  final String category;
  final List<String> skills;
  final double price;
  final String? bio;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final String? availabilityNotes;
  final double? responseTimeHours;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SpecialistProfile({
    this.id,
    required this.userId,
    this.specialistId,
    required this.category,
    required this.skills,
    required this.price,
    this.bio,
    this.address,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.availabilityNotes,
    this.responseTimeHours,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from database map
  factory SpecialistProfile.fromMap(Map<String, dynamic> map) {
    return SpecialistProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      specialistId: map['specialist_id'] as int?,
      category: map['category'] as String,
      skills: _parseList(map['skills'] as String?),
      price: (map['price'] as num).toDouble(),
      bio: map['bio'] as String?,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      tags: _parseList(map['tags'] as String?),
      availabilityNotes: map['availability_notes'] as String?,
      responseTimeHours: map['response_time_hours'] as double?,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
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
      if (specialistId != null) 'specialist_id': specialistId,
      'category': category,
      'skills': skills.join(','),
      'price': price,
      'bio': bio,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags.join(','),
      'availability_notes': availabilityNotes,
      'response_time_hours': responseTimeHours,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Parse comma-separated string to list
  static List<String> _parseList(String? str) {
    if (str == null || str.isEmpty) return [];
    return str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// Convert to Specialist model
  Specialist toSpecialist({required String name, double rating = 0.0, int experienceYears = 0}) {
    return Specialist(
      id: specialistId,
      name: name,
      category: category,
      skills: skills,
      price: price,
      rating: rating,
      experienceYears: experienceYears,
      latitude: latitude,
      longitude: longitude,
      address: address,
      bio: bio,
      tags: tags,
      availabilityNotes: availabilityNotes,
      isVerified: isVerified,
      responseTimeHours: responseTimeHours,
      createdAt: createdAt,
    );
  }

  SpecialistProfile copyWith({
    int? id,
    int? userId,
    int? specialistId,
    String? category,
    List<String>? skills,
    double? price,
    String? bio,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? tags,
    String? availabilityNotes,
    double? responseTimeHours,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpecialistProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      price: price ?? this.price,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      availabilityNotes: availabilityNotes ?? this.availabilityNotes,
      responseTimeHours: responseTimeHours ?? this.responseTimeHours,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

