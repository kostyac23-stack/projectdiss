import '../../domain/models/portfolio_item.dart';
import '../database/database_helper.dart';

/// Repository for managing portfolio items
class PortfolioRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get all portfolio items for a specialist
  Future<List<PortfolioItem>> getPortfolioBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePortfolio,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => PortfolioItem.fromMap(map)).toList();
  }

  /// Get portfolio item by ID
  Future<PortfolioItem?> getPortfolioItemById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePortfolio,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PortfolioItem.fromMap(maps.first);
  }

  /// Add a portfolio item
  Future<int> insertPortfolioItem(PortfolioItem item) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      DatabaseHelper.tablePortfolio,
      item.toMap(),
    );
  }

  /// Update a portfolio item
  Future<int> updatePortfolioItem(PortfolioItem item) async {
    if (item.id == null) {
      throw ArgumentError('Portfolio item ID is required for update');
    }
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tablePortfolio,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a portfolio item
  Future<int> deletePortfolioItem(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tablePortfolio,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all portfolio items for a specialist
  Future<int> deletePortfolioBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tablePortfolio,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
    );
  }
}

