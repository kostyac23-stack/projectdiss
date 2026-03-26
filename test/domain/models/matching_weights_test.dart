import 'package:flutter_test/flutter_test.dart';
import 'package:specialist_finder/domain/models/matching_weights.dart';

void main() {
  group('MatchingWeights', () {
    test('default weights sum to 1.0', () {
      const weights = MatchingWeights.defaultWeights;
      final total = weights.skills +
          weights.price +
          weights.location +
          weights.rating +
          weights.experience;
      expect(total, closeTo(1.0, 0.01));
    });

    test('normalizes weights correctly', () {
      final weights = MatchingWeights(
        skills: 0.5,
        price: 0.5,
        location: 0.5,
        rating: 0.5,
        experience: 0.5,
      );

      final normalized = weights.normalize();
      final total = normalized.skills +
          normalized.price +
          normalized.location +
          normalized.rating +
          normalized.experience;

      expect(total, closeTo(1.0, 0.01));
    });

    test('fromMap creates correct weights', () {
      final map = {
        'skills': 0.4,
        'price': 0.3,
        'location': 0.1,
        'rating': 0.1,
        'experience': 0.1,
      };

      final weights = MatchingWeights.fromMap(map);
      expect(weights.skills, 0.4);
      expect(weights.price, 0.3);
      expect(weights.location, 0.1);
      expect(weights.rating, 0.1);
      expect(weights.experience, 0.1);
    });

    test('toMap converts correctly', () {
      const weights = MatchingWeights.defaultWeights;
      final map = weights.toMap();

      expect(map['skills'], weights.skills);
      expect(map['price'], weights.price);
      expect(map['location'], weights.location);
      expect(map['rating'], weights.rating);
      expect(map['experience'], weights.experience);
    });

    test('copyWith normalizes automatically', () {
      const weights = MatchingWeights.defaultWeights;
      final newWeights = weights.copyWith(skills: 0.5);

      final total = newWeights.skills +
          newWeights.price +
          newWeights.location +
          newWeights.rating +
          newWeights.experience;

      expect(total, closeTo(1.0, 0.01));
    });
  });
}

