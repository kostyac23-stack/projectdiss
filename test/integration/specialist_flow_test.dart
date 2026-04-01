import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:specialist_finder/domain/models/specialist.dart';
import 'package:specialist_finder/domain/models/matching_weights.dart';
import 'package:specialist_finder/domain/models/search_filters.dart';
import 'package:specialist_finder/data/repositories/specialist_repository_impl.dart';
import 'package:specialist_finder/domain/repositories/specialist_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel(
    'plugins.flutter.io/path_provider',
  ).setMockMethodCallHandler((methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      final dir = Directory.systemTemp.createTempSync(
        'specialist_finder_test_',
      );
      return dir.path;
    }
    return null;
  });

  group('Specialist Flow Integration Tests', () {
    late SpecialistRepository repository;

    setUp(() async {
      repository = SpecialistRepositoryImpl();
      await repository.initialize();
      await repository.clearAll();
    });

    test('insert, search, and rank specialists', () async {
      // Insert test specialists
      final specialist1 = Specialist(
        name: 'John Developer',
        category: 'Developer',
        skills: ['Flutter', 'Dart'],
        price: 100.0,
        rating: 4.5,
        experienceYears: 5,
        latitude: 51.5074,
        longitude: -0.1278,
      );

      final specialist2 = Specialist(
        name: 'Jane Designer',
        category: 'Designer',
        skills: ['UI/UX', 'Figma'],
        price: 150.0,
        rating: 4.0,
        experienceYears: 3,
        latitude: 51.5084,
        longitude: -0.1288,
      );

      await repository.insertSpecialist(specialist1);
      await repository.insertSpecialist(specialist2);

      // Search by keyword
      final results = await repository.searchSpecialists(
        const SearchFilters(keyword: 'Developer'),
      );

      expect(results.length, 1);
      expect(results.first.name, 'John Developer');

      // Get ranked specialists
      final ranked = await repository.getRankedSpecialists(
        weights: MatchingWeights.defaultWeights,
        requiredSkills: ['Flutter'],
        userLatitude: 51.5074,
        userLongitude: -0.1278,
      );

      expect(ranked.length, greaterThanOrEqualTo(1));
      expect(ranked.first.specialist.name, 'John Developer');
    });

    test('filter by category and price range', () async {
      final specialist1 = Specialist(
        name: 'Cheap Developer',
        category: 'Developer',
        skills: ['Flutter'],
        price: 50.0,
        rating: 4.0,
        experienceYears: 2,
      );

      final specialist2 = Specialist(
        name: 'Expensive Developer',
        category: 'Developer',
        skills: ['Flutter'],
        price: 500.0,
        rating: 4.0,
        experienceYears: 10,
      );

      final specialist3 = Specialist(
        name: 'Designer',
        category: 'Designer',
        skills: ['UI/UX'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 5,
      );

      await repository.insertSpecialists([
        specialist1,
        specialist2,
        specialist3,
      ]);

      // Filter by category
      var results = await repository.searchSpecialists(
        const SearchFilters(category: 'Developer'),
      );
      expect(results.length, 2);

      // Filter by price range
      results = await repository.searchSpecialists(
        const SearchFilters(minPrice: 0.0, maxPrice: 100.0),
      );
      expect(results.length, 2); // Cheap Developer and Designer

      // Combined filters
      results = await repository.searchSpecialists(
        const SearchFilters(
          category: 'Developer',
          minPrice: 0.0,
          maxPrice: 100.0,
        ),
      );
      expect(results.length, 1);
      expect(results.first.name, 'Cheap Developer');
    });

    test('export and import data', () async {
      final specialist = Specialist(
        name: 'Test Specialist',
        category: 'Developer',
        skills: ['Flutter'],
        price: 100.0,
        rating: 4.0,
        experienceYears: 3,
      );

      await repository.insertSpecialist(specialist);

      // Export
      final json = await repository.exportToJson();
      expect(json, isNotEmpty);
      expect(json, contains('Test Specialist'));

      // Clear and import
      await repository.clearAll();
      await repository.importFromJson(json);

      final all = await repository.getAllSpecialists();
      expect(all.length, 1);
      expect(all.first.name, 'Test Specialist');
    });

    test('get statistics', () async {
      await repository.insertSpecialists([
        Specialist(
          name: 'Specialist 1',
          category: 'Developer',
          skills: ['Flutter'],
          price: 100.0,
          rating: 4.0,
          experienceYears: 3,
        ),
        Specialist(
          name: 'Specialist 2',
          category: 'Designer',
          skills: ['UI/UX'],
          price: 200.0,
          rating: 5.0,
          experienceYears: 5,
        ),
      ]);

      final stats = await repository.getStatistics();
      expect(stats['total_specialists'], 2);
      expect(stats['categories'], isA<List>());
    });

    test(
      'keyword search does not change MCDA percentage for the same specialist',
      () async {
        final specialist = Specialist(
          name: 'John Flutter Expert',
          category: 'Developer',
          skills: ['Flutter', 'Dart'],
          tags: ['mobile'],
          price: 100.0,
          rating: 4.5,
          experienceYears: 5,
        );

        await repository.insertSpecialist(specialist);

        final baseline = await repository.getRankedSpecialists(
          weights: MatchingWeights.defaultWeights,
        );
        final withKeyword = await repository.getRankedSpecialists(
          weights: MatchingWeights.defaultWeights,
          filters: const SearchFilters(keyword: 'Flutter'),
        );

        expect(baseline, isNotEmpty);
        expect(withKeyword, isNotEmpty);
        expect(
          withKeyword.first.specialist.name,
          baseline.first.specialist.name,
        );
        expect(withKeyword.first.totalScore, baseline.first.totalScore);
      },
    );
  });
}
