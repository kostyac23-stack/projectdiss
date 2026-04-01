import 'package:sqflite/sqflite.dart';
import '../../domain/models/favorite.dart';
import '../database/database_helper.dart';
import 'specialist_repository_impl.dart';

/// Repository for managing favorites
class FavoriteRepositoryImpl {
  final SpecialistRepositoryImpl _specialistRepository;

  FavoriteRepositoryImpl({SpecialistRepositoryImpl? specialistRepository})
      : _specialistRepository = specialistRepository ?? SpecialistRepositoryImpl();

  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get all favorites with specialist data
  Future<List<Favorite>> getAllFavorites() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableFavorites,
      orderBy: 'created_at DESC',
    );
    
    final favorites = <Favorite>[];
    
    // Populate specialist data
    for (final map in maps) {
      final favorite = Favorite.fromMap(map);
      final specialist = await _specialistRepository.getSpecialistById(favorite.specialistId);
      favorites.add(favorite.copyWith(specialist: specialist));
    }
    
    return favorites;
  }

  /// Check if a specialist is favorited
  Future<bool> isFavorite(int specialistId) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      DatabaseHelper.tableFavorites,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Add a specialist to favorites
  Future<int> addFavorite(int specialistId) async {
    final db = await DatabaseHelper.database;
    try {
      return await db.insert(
        DatabaseHelper.tableFavorites,
        {
          'specialist_id': specialistId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Already favorited, return existing ID
      final existing = await db.query(
        DatabaseHelper.tableFavorites,
        where: 'specialist_id = ?',
        whereArgs: [specialistId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }
      rethrow;
    }
  }

  /// Remove a specialist from favorites
  Future<int> removeFavorite(int specialistId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableFavorites,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
    );
  }

  /// Get favorite count
  Future<int> getFavoriteCount() async {
    final db = await DatabaseHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableFavorites}'),
    );
    return result ?? 0;
  }
}

