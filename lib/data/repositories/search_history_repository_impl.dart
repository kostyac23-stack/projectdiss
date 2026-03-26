import '../../domain/models/search_history.dart';
import '../database/database_helper.dart';

/// Repository for managing search history
class SearchHistoryRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get recent search history (last N items)
  Future<List<SearchHistory>> getRecentSearches({int limit = 10}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSearchHistory,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => SearchHistory.fromMap(map)).toList();
  }

  /// Add a search query to history
  Future<int> addSearch(String query) async {
    if (query.trim().isEmpty) return 0;
    
    final db = await DatabaseHelper.database;
    
    // Check if this exact query was searched recently (within last hour)
    final recent = await db.query(
      DatabaseHelper.tableSearchHistory,
      where: 'query = ? AND created_at > datetime("now", "-1 hour")',
      whereArgs: [query.trim()],
      limit: 1,
    );
    
    if (recent.isNotEmpty) {
      // Update existing entry timestamp
      return await db.update(
        DatabaseHelper.tableSearchHistory,
        {'created_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [recent.first['id']],
      );
    }
    
    // Insert new search
    final history = SearchHistory(
      query: query.trim(),
      createdAt: DateTime.now(),
    );
    return await db.insert(
      DatabaseHelper.tableSearchHistory,
      history.toMap(),
    );
  }

  /// Clear all search history
  Future<int> clearHistory() async {
    final db = await DatabaseHelper.database;
    return await db.delete(DatabaseHelper.tableSearchHistory);
  }

  /// Delete a specific search history item
  Future<int> deleteSearch(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableSearchHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

