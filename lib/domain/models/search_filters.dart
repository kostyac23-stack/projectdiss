/// Filters for searching specialists
class SearchFilters {
  final String? keyword; // Search in name, skills, tags
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final int? minExperience;
  final double? maxDistanceKm; // Maximum distance in kilometers
  final double? userLatitude; // User's location for distance calculation
  final double? userLongitude;
  final List<String>? requiredSkills; // Skills that must match
  final bool? verifiedOnly; // Show only verified specialists

  const SearchFilters({
    this.keyword,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.minExperience,
    this.maxDistanceKm,
    this.userLatitude,
    this.userLongitude,
    this.requiredSkills,
    this.verifiedOnly,
  });

  SearchFilters copyWith({
    String? keyword,
    bool clearKeyword = false,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? minExperience,
    double? maxDistanceKm,
    double? userLatitude,
    double? userLongitude,
    List<String>? requiredSkills,
    bool? verifiedOnly,
  }) {
    return SearchFilters(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      minExperience: minExperience ?? this.minExperience,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  /// Check if filters are empty (no filtering applied)
  bool get isEmpty {
    return keyword == null &&
        category == null &&
        minPrice == null &&
        maxPrice == null &&
        minRating == null &&
        minExperience == null &&
        maxDistanceKm == null &&
        verifiedOnly == null &&
        (requiredSkills == null || requiredSkills!.isEmpty);
  }
}

