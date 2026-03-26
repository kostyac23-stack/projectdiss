import 'specialist.dart';

/// Detailed matching score breakdown for a specialist
class MatchingScore {
  final Specialist specialist;
  final double totalScore;
  final double skillsScore;
  final double priceScore;
  final double locationScore;
  final double ratingScore;
  final double experienceScore;
  final double? distanceKm; // Distance in kilometers if location available

  MatchingScore({
    required this.specialist,
    required this.totalScore,
    required this.skillsScore,
    required this.priceScore,
    required this.locationScore,
    required this.ratingScore,
    required this.experienceScore,
    this.distanceKm,
  });

  /// Get textual explanation of the score
  String getExplanation() {
    final parts = <String>[];
    
    if (skillsScore > 0.8) {
      parts.add('Excellent skill match');
    } else if (skillsScore > 0.5) {
      parts.add('Good skill match');
    } else if (skillsScore > 0) {
      parts.add('Partial skill match');
    } else {
      parts.add('No skill match');
    }

    if (priceScore > 0.8) {
      parts.add('very affordable');
    } else if (priceScore > 0.5) {
      parts.add('moderately priced');
    } else {
      parts.add('higher priced');
    }

    if (distanceKm != null) {
      if (distanceKm! < 5) {
        parts.add('very close');
      } else if (distanceKm! < 20) {
        parts.add('nearby');
      } else {
        parts.add('further away');
      }
    }

    if (ratingScore > 0.8) {
      parts.add('highly rated');
    } else if (ratingScore > 0.5) {
      parts.add('well rated');
    }

    if (experienceScore > 0.8) {
      parts.add('very experienced');
    } else if (experienceScore > 0.5) {
      parts.add('experienced');
    }

    return parts.join(', ');
  }
}

