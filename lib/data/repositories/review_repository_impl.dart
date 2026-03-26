import 'package:sqflite/sqflite.dart';
import '../../domain/models/review.dart';
import '../database/database_helper.dart';

/// Repository for managing reviews
class ReviewRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get all reviews for a specialist
  Future<List<Review>> getReviewsBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReviews,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Review.fromMap(map)).toList();
  }

  /// Get review by ID
  Future<Review?> getReviewById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReviews,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Review.fromMap(maps.first);
  }

  /// Add a new review
  Future<int> insertReview(Review review) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      DatabaseHelper.tableReviews,
      review.toMap(),
    );
  }

  /// Update a review
  Future<int> updateReview(Review review) async {
    if (review.id == null) {
      throw ArgumentError('Review ID is required for update');
    }
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableReviews,
      review.toMap(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  /// Delete a review
  Future<int> deleteReview(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableReviews,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get average rating for a specialist
  Future<double?> getAverageRating(int specialistId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avg_rating
      FROM ${DatabaseHelper.tableReviews}
      WHERE specialist_id = ?
    ''', [specialistId]);
    
    if (result.isEmpty || result.first['avg_rating'] == null) {
      return null;
    }
    return (result.first['avg_rating'] as num).toDouble();
  }

  /// Get review count for a specialist
  Future<int> getReviewCount(int specialistId) async {
    final db = await DatabaseHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableReviews} WHERE specialist_id = ?',
        [specialistId],
      ),
    );
    return result ?? 0;
  }
}

