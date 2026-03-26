import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/specialist.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/models/matching_score.dart';
import '../../domain/models/matching_weights.dart';
import '../../domain/repositories/specialist_repository.dart';
import '../database/database_helper.dart';
import '../../domain/services/mcda_service.dart';
import '../../domain/services/location_service.dart';

/// SQLite implementation of SpecialistRepository
class SpecialistRepositoryImpl implements SpecialistRepository {
  final MCDAService _mcdaService;
  final LocationService _locationService;

  SpecialistRepositoryImpl({
    MCDAService? mcdaService,
    LocationService? locationService,
  })  : _mcdaService = mcdaService ?? MCDAService(),
        _locationService = locationService ?? LocationService();

  @override
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  @override
  Future<List<Specialist>> getAllSpecialists() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(DatabaseHelper.tableSpecialists);
    return maps.map((map) => Specialist.fromMap(map)).toList();
  }

  @override
  Future<Specialist?> getSpecialistById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpecialists,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Specialist.fromMap(maps.first);
  }

  /// Get specialist ID by user ID mapping
  Future<int?> getSpecialistIdByUserId(int userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpecialistProfiles,
      columns: ['specialist_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['specialist_id'] as int?;
  }

  @override
  Future<List<Specialist>> searchSpecialists(SearchFilters filters) async {
    final db = await DatabaseHelper.database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    // Keyword search (name, skills, tags)
    if (filters.keyword != null && filters.keyword!.isNotEmpty) {
      final words = filters.keyword!.split(' ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      for (final word in words) {
        where.add('(name LIKE ? OR skills LIKE ? OR tags LIKE ? OR category LIKE ?)');
        final keywordPattern = '%$word%';
        whereArgs.addAll([keywordPattern, keywordPattern, keywordPattern, keywordPattern]);
      }
    }

    // Category filter
    if (filters.category != null) {
      where.add('category = ?');
      whereArgs.add(filters.category);
    }

    // Price range
    if (filters.minPrice != null) {
      where.add('price >= ?');
      whereArgs.add(filters.minPrice);
    }
    if (filters.maxPrice != null) {
      where.add('price <= ?');
      whereArgs.add(filters.maxPrice);
    }

    // Rating threshold
    if (filters.minRating != null) {
      where.add('rating >= ?');
      whereArgs.add(filters.minRating);
    }

    // Experience
    if (filters.minExperience != null) {
      where.add('experience_years >= ?');
      whereArgs.add(filters.minExperience);
    }

    // Distance filter (requires location)
    if (filters.maxDistanceKm != null &&
        filters.userLatitude != null &&
        filters.userLongitude != null) {
      // Get all specialists first, then filter by distance
      // This is less efficient but necessary for Haversine calculation
      final allSpecialists = await getAllSpecialists();
      return allSpecialists.where((specialist) {
        if (specialist.latitude == null || specialist.longitude == null) {
          return false;
        }
        final distance = _locationService.calculateDistance(
          filters.userLatitude!,
          filters.userLongitude!,
          specialist.latitude!,
          specialist.longitude!,
        );
        return distance <= filters.maxDistanceKm!;
      }).toList();
    }

    // Required skills filter
    if (filters.requiredSkills != null && filters.requiredSkills!.isNotEmpty) {
      // Filter in memory after query
      final results = await db.query(
        DatabaseHelper.tableSpecialists,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );
      final specialists = results.map((map) => Specialist.fromMap(map)).toList();
      return specialists.where((specialist) {
        return filters.requiredSkills!.every(
          (skill) => specialist.skills.any((s) => s.toLowerCase().contains(skill.toLowerCase())),
        );
      }).toList();
    }

    final results = await db.query(
      DatabaseHelper.tableSpecialists,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return results.map((map) => Specialist.fromMap(map)).toList();
  }

  @override
  Future<List<MatchingScore>> getRankedSpecialists({
    required MatchingWeights weights,
    SearchFilters? filters,
    double? userLatitude,
    double? userLongitude,
    List<String>? requiredSkills,
  }) async {
    final searchFilters = filters ?? const SearchFilters();
    final effectiveFilters = searchFilters.copyWith(
      userLatitude: userLatitude ?? searchFilters.userLatitude,
      userLongitude: userLongitude ?? searchFilters.userLongitude,
      requiredSkills: requiredSkills ?? searchFilters.requiredSkills,
    );

    // For a true MCDA algorithm, we evaluate preferences as soft bounds rather than strict SQL exclusions.
    // We fetch specialists (optionally filtered by hard category constraint) and run them through MCDA.
    final db = await DatabaseHelper.database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (effectiveFilters.category != null) {
      where.add('category = ?');
      whereArgs.add(effectiveFilters.category);
    }

    final results = await db.query(
      DatabaseHelper.tableSpecialists,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    final specialists = results.map((map) => Specialist.fromMap(map)).toList();

    if (specialists.isEmpty) return [];

    // Calculate matching scores
    final scores = <MatchingScore>[];
    for (final specialist in specialists) {
      final score = _mcdaService.calculateScore(
        specialist: specialist,
        weights: weights,
        filters: effectiveFilters,
      );
      
      // If a search keyword is provided, but the specialist has 0 skills match, exclude them
      if (effectiveFilters.keyword != null && 
          effectiveFilters.keyword!.trim().isNotEmpty && 
          score.skillsScore == 0) {
        continue;
      }
      
      scores.add(score);
    }

    // Sort by total score (descending)
    scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scores;
  }

  @override
  Future<int> insertSpecialist(Specialist specialist) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      DatabaseHelper.tableSpecialists,
      specialist.toMap(),
    );
  }

  @override
  Future<int> updateSpecialist(Specialist specialist) async {
    if (specialist.id == null) {
      throw ArgumentError('Specialist ID is required for update');
    }
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableSpecialists,
      specialist.toMap(),
      where: 'id = ?',
      whereArgs: [specialist.id],
    );
  }

  @override
  Future<int> deleteSpecialist(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableSpecialists,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> insertSpecialists(List<Specialist> specialists) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final specialist in specialists) {
      batch.insert(DatabaseHelper.tableSpecialists, specialist.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> clearAll() async {
    await DatabaseHelper.clearAll();
  }

  @override
  Future<String> exportToJson() async {
    final specialists = await getAllSpecialists();
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'count': specialists.length,
      'specialists': specialists.map((s) => s.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  @override
  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final specialistsList = data['specialists'] as List<dynamic>;
    final specialists = specialistsList
        .map((map) => Specialist.fromMap(Map<String, dynamic>.from(map)))
        .toList();
    await insertSpecialists(specialists);
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await DatabaseHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableSpecialists}'),
    ) ?? 0;

    final priceStats = await db.rawQuery('''
      SELECT 
        MIN(price) as min_price,
        MAX(price) as max_price,
        AVG(price) as avg_price
      FROM ${DatabaseHelper.tableSpecialists}
    ''');

    final ratingStats = await db.rawQuery('''
      SELECT 
        MIN(rating) as min_rating,
        MAX(rating) as max_rating,
        AVG(rating) as avg_rating
      FROM ${DatabaseHelper.tableSpecialists}
    ''');

    final categoryCounts = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM ${DatabaseHelper.tableSpecialists}
      GROUP BY category
      ORDER BY count DESC
    ''');

    return {
      'total_specialists': count,
      'price': priceStats.isNotEmpty ? priceStats.first : {},
      'rating': ratingStats.isNotEmpty ? ratingStats.first : {},
      'categories': categoryCounts.map((row) => {
            'category': row['category'],
            'count': row['count'],
          }).toList(),
    };
  }
}

