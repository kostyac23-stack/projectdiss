import 'package:flutter_test/flutter_test.dart';
import 'package:specialist_finder/domain/models/specialist.dart';

void main() {
  group('Specialist', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 1,
        'name': 'Test Specialist',
        'category': 'Developer',
        'skills': 'Flutter,Dart,Mobile',
        'price': 100.0,
        'rating': 4.5,
        'experience_years': 5,
        'lat': 51.5074,
        'lon': -0.1278,
        'address': '123 Main St',
        'bio': 'Test bio',
        'image_path': 'path/to/image',
        'tags': 'Expert,Certified',
        'availability_notes': 'Available weekdays',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final specialist = Specialist.fromMap(map);

      expect(specialist.id, 1);
      expect(specialist.name, 'Test Specialist');
      expect(specialist.category, 'Developer');
      expect(specialist.skills, ['Flutter', 'Dart', 'Mobile']);
      expect(specialist.price, 100.0);
      expect(specialist.rating, 4.5);
      expect(specialist.experienceYears, 5);
      expect(specialist.latitude, 51.5074);
      expect(specialist.longitude, -0.1278);
      expect(specialist.address, '123 Main St');
      expect(specialist.bio, 'Test bio');
      expect(specialist.imagePath, 'path/to/image');
      expect(specialist.tags, ['Expert', 'Certified']);
      expect(specialist.availabilityNotes, 'Available weekdays');
    });

    test('toMap converts correctly', () {
      final specialist = Specialist(
        id: 1,
        name: 'Test',
        category: 'Developer',
        skills: ['Flutter', 'Dart'],
        price: 100.0,
        rating: 4.5,
        experienceYears: 5,
        latitude: 51.5074,
        longitude: -0.1278,
        address: '123 Main St',
        bio: 'Test bio',
        imagePath: 'path/to/image',
        tags: ['Expert'],
        availabilityNotes: 'Available',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = specialist.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test');
      expect(map['skills'], 'Flutter,Dart');
      expect(map['tags'], 'Expert');
    });

    test('parses empty skills and tags', () {
      final map = {
        'name': 'Test',
        'category': 'Developer',
        'skills': '',
        'tags': '',
        'price': 100.0,
        'rating': 4.0,
        'experience_years': 3,
      };

      final specialist = Specialist.fromMap(map);
      expect(specialist.skills, isEmpty);
      expect(specialist.tags, isEmpty);
    });

    test('copyWith creates new instance with changes', () {
      final original = Specialist(
        id: 1,
        name: 'Original',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
      );

      final updated = original.copyWith(name: 'Updated', price: 200.0);

      expect(updated.name, 'Updated');
      expect(updated.price, 200.0);
      expect(updated.id, 1); // Unchanged
      expect(original.name, 'Original'); // Original unchanged
    });
  });
}

