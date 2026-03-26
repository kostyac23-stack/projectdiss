import '../models/specialist.dart';
import '../models/matching_score.dart';
import '../models/matching_weights.dart';
import '../models/search_filters.dart';
import 'location_service.dart';

/// Service for Multi-Criteria Decision Analysis (MCDA) scoring
class MCDAService {
  final LocationService _locationService;

  MCDAService({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  /// Calculate matching score for a specialist
  MatchingScore calculateScore({
    required Specialist specialist,
    required MatchingWeights weights,
    required SearchFilters filters,
  }) {
    // Determine skills to match against (either requiredSkills or search keyword)
    List<String> skillsToMatch = [];
    if (filters.requiredSkills != null && filters.requiredSkills!.isNotEmpty) {
      skillsToMatch = filters.requiredSkills!;
    } else if (filters.keyword != null && filters.keyword!.trim().isNotEmpty) {
      skillsToMatch = filters.keyword!.split(' ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    // Calculate subscores for each criterion
    final skillsScore = _calculateSkillsScore(specialist, skillsToMatch);
    final priceScore = _calculatePriceScore(specialist, filters.maxPrice);
    final locationScore = _calculateLocationScore(
      specialist,
      filters.userLatitude,
      filters.userLongitude,
      filters.maxDistanceKm,
    );
    final ratingScore = _calculateRatingScore(specialist, filters.minRating);
    final experienceScore = _calculateExperienceScore(specialist, filters.minExperience);

    // Calculate distance if location available
    double? distanceKm;
    if (filters.userLatitude != null &&
        filters.userLongitude != null &&
        specialist.latitude != null &&
        specialist.longitude != null) {
      distanceKm = _locationService.calculateDistance(
        filters.userLatitude!,
        filters.userLongitude!,
        specialist.latitude!,
        specialist.longitude!,
      );
    }

    // Calculate weighted total score
    double totalScore = (weights.skills * skillsScore) +
        (weights.price * priceScore) +
        (weights.location * locationScore) +
        (weights.rating * ratingScore) +
        (weights.experience * experienceScore);

    // Apply Verification Boost (Trust Mechanism)
    // Verified specialists get a 10% boost to their final score
    if (specialist.isVerified) {
      totalScore = totalScore * 1.10; 
    }

    // Apply MCDA Veto Penalty for extreme deviations
    // If they egregiously fail any core user filter, veto their overall score 
    double vetoPenalty = 1.0;
    
    // Price Veto
    if (filters.maxPrice != null && filters.maxPrice! > 0) {
      final excessRatio = specialist.price / filters.maxPrice!;
      if (excessRatio > 2.0) {
        vetoPenalty *= 0.1; // 90% penalty if over double the budget
      } else if (excessRatio > 1.3) {
        vetoPenalty *= 0.4; // 60% penalty if 30% over budget
      }
    }

    // Rating Veto
    if (filters.minRating != null && filters.minRating! > 0) {
      final ratingDeficit = filters.minRating! - specialist.rating;
      if (ratingDeficit >= 2.0) {
        vetoPenalty *= 0.1; // 90% penalty if severely under-rated
      } else if (ratingDeficit >= 1.0) {
        vetoPenalty *= 0.4; // 60% penalty if a whole star under-rated
      }
    }

    // Experience Veto
    if (filters.minExperience != null && filters.minExperience! > 0) {
      final expRatio = specialist.experienceYears / filters.minExperience!;
      if (expRatio < 0.25) {
        vetoPenalty *= 0.1; // 90% penalty if they have barely a quarter of requested experience
      } else if (expRatio < 0.5) {
        vetoPenalty *= 0.4; // 60% penalty if they have less than half the requested experience
      }
    }

    totalScore *= vetoPenalty;

    return MatchingScore(
      specialist: specialist,
      totalScore: totalScore.clamp(0.0, 1.0),
      skillsScore: skillsScore,
      priceScore: priceScore,
      locationScore: locationScore,
      ratingScore: ratingScore,
      experienceScore: experienceScore,
      distanceKm: distanceKm,
    );
  }

  /// Calculate skills matching score (0-1)
  /// Based on overlap between required skills and specialist skills
  double _calculateSkillsScore(Specialist specialist, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) {
      // If no skills required, give neutral score (0.5)
      return 0.5;
    }

    // Normalize skill names for comparison
    final specialistDataWords = [
      ...specialist.skills,
      specialist.name,
      specialist.category,
      ...specialist.tags ?? [],
    ].map((s) => s.toLowerCase().trim()).toSet();
    
    final requiredSkillsLower = requiredSkills.map((s) => s.toLowerCase().trim()).toSet();

    // Count matches
    int matches = 0;
    for (final requiredSkill in requiredSkillsLower) {
      // Check for exact match or partial match
      bool matched = false;
      for (final dataWord in specialistDataWords) {
        if (dataWord.contains(requiredSkill) || requiredSkill.contains(dataWord)) {
          matched = true;
          break;
        }
        // Simple prefix match for word roots (e.g. "plumb"er vs "plumb"ing)
        if (requiredSkill.length >= 4 && dataWord.length >= 4) {
          if (requiredSkill.substring(0, 4) == dataWord.substring(0, 4)) {
            matched = true;
            break;
          }
        }
      }
      if (matched) matches++;
    }

    // Score = matched skills / required skills
    return (matches / requiredSkills.length).clamp(0.0, 1.0);
  }

  /// Calculate price score (0-1)
  /// Evaluates price against the user's budget preference (maxPriceFilter)
  double _calculatePriceScore(Specialist specialist, double? maxPriceFilter) {
    if (maxPriceFilter != null && maxPriceFilter > 0) {
      if (specialist.price <= maxPriceFilter) {
        // Within budget: Score 0.8 to 1.0 based on how cheap it is relative to budget
        return 1.0 - (specialist.price / maxPriceFilter) * 0.2;
      } else {
        // Exceeds budget: Soft penalty decay
        final excessRatio = specialist.price / maxPriceFilter;
        if (excessRatio >= 2.0) return 0.0; // Over twice the budget is not a match
        return (2.0 - excessRatio) * 0.4; // Max 0.4 score if slightly over budget
      }
    }
    // No budget specified: normalize against a realistic market cap
    return (1.0 - (specialist.price / 300.0)).clamp(0.0, 1.0);
  }

  /// Calculate location score (0-1)
  /// Evaluates proximity against user's max distance preference
  double _calculateLocationScore(
    Specialist specialist,
    double? userLatitude,
    double? userLongitude,
    double? maxDistanceFilter,
  ) {
    // If no user location, return neutral score
    if (userLatitude == null || userLongitude == null) return 0.5;
    // If specialist has no location, return low score
    if (specialist.latitude == null || specialist.longitude == null) return 0.2;

    // Calculate distance
    final distance = _locationService.calculateDistance(
      userLatitude,
      userLongitude,
      specialist.latitude!,
      specialist.longitude!,
    );

    if (maxDistanceFilter != null && maxDistanceFilter > 0) {
      if (distance <= maxDistanceFilter) {
        // Within preferred distance: Score 0.8 to 1.0
        return 1.0 - (distance / maxDistanceFilter) * 0.2;
      } else {
        // Too far: Soft penalty decay
        final excessRatio = distance / maxDistanceFilter;
        if (excessRatio >= 3.0) return 0.0; // Over 3x as far is not a match
        return (3.0 - excessRatio) * 0.2; // Max 0.4 score if slightly too far
      }
    }

    // Default normalization
    return (1.0 - (distance / 50.0)).clamp(0.0, 1.0);
  }

  /// Calculate rating score (0-1)
  /// Evaluates rating against user's minimum rating preference
  double _calculateRatingScore(Specialist specialist, double? minRatingFilter) {
    if (minRatingFilter != null && minRatingFilter > 0) {
      if (specialist.rating >= minRatingFilter) {
        // Meets or exceeds minimum: Score 0.8 to 1.0
        return 0.8 + 0.2 * ((specialist.rating - minRatingFilter) / (5.0 - minRatingFilter + 0.001));
      } else {
        // Below minimum: Penalized heavily based on how far below
        return 0.5 * (specialist.rating / minRatingFilter);
      }
    }
    return (specialist.rating / 5.0).clamp(0.0, 1.0);
  }

  /// Calculate experience score (0-1)
  /// Evaluates experience against user's minimum experience preference
  double _calculateExperienceScore(Specialist specialist, int? minExperienceFilter) {
    if (minExperienceFilter != null && minExperienceFilter > 0) {
      if (specialist.experienceYears >= minExperienceFilter) {
        // Meets preference
        return 1.0;
      } else {
        // Below preference: Partial score
        return specialist.experienceYears / minExperienceFilter;
      }
    }
    // Cap experience at 20 years for normalization
    const cap = 20.0;
    final cappedExperience = specialist.experienceYears > cap ? cap : specialist.experienceYears.toDouble();
    return (cappedExperience / cap).clamp(0.0, 1.0);
  }
}

