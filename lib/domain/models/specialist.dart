/// Domain model for a specialist/service provider
class Specialist {
  final int? id;
  final String name;
  final String category;
  final List<String> skills;
  final double price;
  final double rating; // 0-5
  final int experienceYears;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? bio;
  final String? imagePath;
  final List<String> tags;
  final String? availabilityNotes;
  final bool isVerified;
  final double? responseTimeHours; // Average response time in hours
  final DateTime? createdAt;

  Specialist({
    this.id,
    required this.name,
    required this.category,
    required this.skills,
    required this.price,
    required this.rating,
    required this.experienceYears,
    this.latitude,
    this.longitude,
    this.address,
    this.bio,
    this.imagePath,
    this.tags = const [],
    this.availabilityNotes,
    this.isVerified = false,
    this.responseTimeHours,
    this.createdAt,
  });

  /// Create from database map
  factory Specialist.fromMap(Map<String, dynamic> map) {
    return Specialist(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      skills: _parseList(map['skills'] as String?),
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      experienceYears: map['experience_years'] as int,
      latitude: map['lat'] as double?,
      longitude: map['lon'] as double?,
      address: map['address'] as String?,
      bio: map['bio'] as String?,
      imagePath: map['image_path'] as String?,
      tags: _parseList(map['tags'] as String?),
      availabilityNotes: map['availability_notes'] as String?,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
      responseTimeHours: map['response_time_hours'] as double?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'skills': skills.join(','),
      'price': price,
      'rating': rating,
      'experience_years': experienceYears,
      'lat': latitude,
      'lon': longitude,
      'address': address,
      'bio': bio,
      'image_path': imagePath,
      'tags': tags.join(','),
      'availability_notes': availabilityNotes,
      'is_verified': isVerified ? 1 : 0,
      'response_time_hours': responseTimeHours,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Parse comma-separated string to list
  static List<String> _parseList(String? str) {
    if (str == null || str.isEmpty) return [];
    return str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Specialist copyWith({
    int? id,
    String? name,
    String? category,
    List<String>? skills,
    double? price,
    double? rating,
    int? experienceYears,
    double? latitude,
    double? longitude,
    String? address,
    String? bio,
    String? imagePath,
    List<String>? tags,
    String? availabilityNotes,
    bool? isVerified,
    double? responseTimeHours,
    DateTime? createdAt,
  }) {
    return Specialist(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      availabilityNotes: availabilityNotes ?? this.availabilityNotes,
      isVerified: isVerified ?? this.isVerified,
      responseTimeHours: responseTimeHours ?? this.responseTimeHours,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

