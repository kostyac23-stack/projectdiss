/// Weights for MCDA matching algorithm
/// All weights should sum to 1.0 (100%)
class MatchingWeights {
  final double skills; // 35% default
  final double price; // 25% default
  final double location; // 15% default
  final double rating; // 15% default
  final double experience; // 10% default

  const MatchingWeights({
    this.skills = 0.35,
    this.price = 0.25,
    this.location = 0.15,
    this.rating = 0.15,
    this.experience = 0.10,
  });

  /// Default weights from requirements
  static const MatchingWeights defaultWeights = MatchingWeights();

  /// Create from map (e.g., from JSON or settings)
  factory MatchingWeights.fromMap(Map<String, dynamic> map) {
    return MatchingWeights(
      skills: (map['skills'] as num?)?.toDouble() ?? 0.35,
      price: (map['price'] as num?)?.toDouble() ?? 0.25,
      location: (map['location'] as num?)?.toDouble() ?? 0.15,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.15,
      experience: (map['experience'] as num?)?.toDouble() ?? 0.10,
    );
  }

  /// Convert to map (e.g., for JSON or settings storage)
  Map<String, dynamic> toMap() {
    return {
      'skills': skills,
      'price': price,
      'location': location,
      'rating': rating,
      'experience': experience,
    };
  }

  /// Normalize weights to sum to 1.0
  MatchingWeights normalize() {
    final total = skills + price + location + rating + experience;
    if (total == 0) return MatchingWeights.defaultWeights;
    return MatchingWeights(
      skills: skills / total,
      price: price / total,
      location: location / total,
      rating: rating / total,
      experience: experience / total,
    );
  }

  MatchingWeights copyWith({
    double? skills,
    double? price,
    double? location,
    double? rating,
    double? experience,
  }) {
    return MatchingWeights(
      skills: skills ?? this.skills,
      price: price ?? this.price,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
    ).normalize();
  }
}

