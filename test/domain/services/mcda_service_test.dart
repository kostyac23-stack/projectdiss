import 'package:flutter_test/flutter_test.dart';
import 'package:specialist_finder/domain/services/mcda_service.dart';
import 'package:specialist_finder/domain/models/specialist.dart';
import 'package:specialist_finder/domain/models/matching_weights.dart';
import 'package:specialist_finder/domain/models/search_filters.dart';

void main() {
  group('MCDAService', () {
    late MCDAService service;
    late MatchingWeights defaultWeights;

    setUp(() {
      service = MCDAService();
      defaultWeights = MatchingWeights.defaultWeights;
    });

    test('calculates score for specialist with all criteria', () {
      final specialist = Specialist(
        name: 'Test Specialist',
        category: 'Developer',
        skills: ['Flutter', 'Dart', 'Mobile'],
        price: 100.0,
        rating: 4.5,
        experienceYears: 5,
        latitude: 51.5074,
        longitude: -0.1278,
      );

      final allSpecialists = [specialist];
      final score = service.calculateScore(
        specialist: specialist,
        weights: defaultWeights,
        filters: const SearchFilters(
          userLatitude: 51.5074,
          userLongitude: -0.1278,
          requiredSkills: ['Flutter', 'Dart'],
        ),
      );

      expect(score.totalScore, greaterThanOrEqualTo(0.0));
      expect(score.totalScore, lessThanOrEqualTo(1.0));
      expect(score.skillsScore, greaterThan(0.0));
      expect(score.priceScore, greaterThanOrEqualTo(0.0));
      expect(score.locationScore, greaterThanOrEqualTo(0.0));
      expect(score.ratingScore, closeTo(0.9, 0.1)); // 4.5/5 = 0.9
      expect(score.experienceScore, greaterThanOrEqualTo(0.0));
    });

    test('handles missing location gracefully', () {
      final specialist = Specialist(
        name: 'Test Specialist',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
      );

      final allSpecialists = [specialist];
      final score = service.calculateScore(
        specialist: specialist,
        weights: defaultWeights,
        filters: const SearchFilters(
          requiredSkills: ['Flutter'],
        ),
      );

      expect(score.locationScore, closeTo(0.5, 0.1)); // Neutral score
      expect(score.distanceKm, isNull);
    });

    test('calculates skills score correctly', () {
      final specialist = Specialist(
        name: 'Test',
        category: 'Developer',
        skills: ['Flutter', 'Dart', 'Mobile'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
      );

      final allSpecialists = [specialist];
      
      // Perfect match
      var score = service.calculateScore(
        specialist: specialist,
        weights: defaultWeights,
        filters: const SearchFilters(
          requiredSkills: ['Flutter', 'Dart'],
        ),
      );
      expect(score.skillsScore, closeTo(1.0, 0.1));

      // Partial match
      score = service.calculateScore(
        specialist: specialist,
        weights: defaultWeights,
        filters: const SearchFilters(
          requiredSkills: ['Flutter', 'Python'],
        ),
      );
      expect(score.skillsScore, closeTo(0.5, 0.1));

      // No match
      score = service.calculateScore(
        specialist: specialist,
        weights: defaultWeights,
        filters: const SearchFilters(
          requiredSkills: ['Java', 'Python'],
        ),
      );
      expect(score.skillsScore, lessThan(0.5));
    });

    test('normalizes price score (lower is better)', () {
      final cheap = Specialist(
        name: 'Cheap',
        category: 'Developer',
        skills: ['Flutter'],
        price: 50.0,
        rating: 4.0,
        experienceYears: 3,
      );

      final expensive = Specialist(
        name: 'Expensive',
        category: 'Developer',
        skills: ['Flutter'],
        price: 500.0,
        rating: 4.0,
        experienceYears: 3,
      );

      final allSpecialists = [cheap, expensive];

      final cheapScore = service.calculateScore(
        specialist: cheap,
        weights: defaultWeights,
        filters: const SearchFilters(),
      );

      final expensiveScore = service.calculateScore(
        specialist: expensive,
        weights: defaultWeights,
        filters: const SearchFilters(),
      );

      expect(cheapScore.priceScore, greaterThan(expensiveScore.priceScore));
    });

    test('normalizes rating score correctly', () {
      final specialist5 = Specialist(
        name: '5 Star',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 5.0,
        experienceYears: 3,
      );

      final specialist3 = Specialist(
        name: '3 Star',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 3.0,
        experienceYears: 3,
      );

      final allSpecialists = [specialist5, specialist3];

      final score5 = service.calculateScore(
        specialist: specialist5,
        weights: defaultWeights,
        filters: const SearchFilters(),
      );

      final score3 = service.calculateScore(
        specialist: specialist3,
        weights: defaultWeights,
        filters: const SearchFilters(),
      );

      expect(score5.ratingScore, closeTo(1.0, 0.1)); // 5/5 = 1.0
      expect(score3.ratingScore, closeTo(0.6, 0.1)); // 3/5 = 0.6
    });

    test('calculates location score based on distance', () {
      // London coordinates
      final userLat = 51.5074;
      final userLon = -0.1278;

      // Close specialist
      final close = Specialist(
        name: 'Close',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
        latitude: 51.5084, // ~1km away
        longitude: -0.1288,
      );

      // Far specialist
      final far = Specialist(
        name: 'Far',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
        latitude: 51.6074, // ~11km away
        longitude: -0.1278,
      );

      final allSpecialists = [close, far];

      final closeScore = service.calculateScore(
        specialist: close,
        weights: defaultWeights,
        filters: SearchFilters(
          userLatitude: userLat,
          userLongitude: userLon,
        ),
      );

      final farScore = service.calculateScore(
        specialist: far,
        weights: defaultWeights,
        filters: SearchFilters(
          userLatitude: userLat,
          userLongitude: userLon,
        ),
      );

      expect(closeScore.locationScore, greaterThan(farScore.locationScore));
      expect(closeScore.distanceKm, lessThan(farScore.distanceKm!));
    });
  });
}

