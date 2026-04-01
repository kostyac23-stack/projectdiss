import '../../domain/models/availability.dart';
import '../database/database_helper.dart';

/// Repository for managing specialist availability
class AvailabilityRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get availability schedule for a specialist
  Future<List<Availability>> getAvailabilityBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAvailability,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'day_of_week ASC',
    );
    return maps.map((map) => Availability.fromMap(map)).toList();
  }

  /// Save availability schedule (replaces existing)
  Future<void> saveAvailability(int specialistId, List<Availability> availability) async {
    final db = await DatabaseHelper.database;
    
    // Delete existing availability
    await db.delete(
      DatabaseHelper.tableAvailability,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
    );

    // Insert new availability
    for (final item in availability) {
      await db.insert(
        DatabaseHelper.tableAvailability,
        item.toMap(),
      );
    }
  }

  /// Delete all availability for a specialist
  Future<int> deleteAvailability(int specialistId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableAvailability,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
    );
  }
}

