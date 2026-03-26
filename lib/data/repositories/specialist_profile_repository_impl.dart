import '../../domain/models/specialist_profile.dart';
import '../database/database_helper.dart';

/// Repository for managing specialist profiles
class SpecialistProfileRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get specialist profile by user ID
  Future<SpecialistProfile?> getProfileByUserId(int userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpecialistProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SpecialistProfile.fromMap(maps.first);
  }

  /// Get specialist profile by specialist ID
  Future<SpecialistProfile?> getProfileBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpecialistProfiles,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SpecialistProfile.fromMap(maps.first);
  }

  /// Create or update specialist profile
  Future<int> saveProfile(SpecialistProfile profile) async {
    final db = await DatabaseHelper.database;
    
    if (profile.id == null) {
      // Insert new profile
      final profileToSave = profile.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return await db.insert(
        DatabaseHelper.tableSpecialistProfiles,
        profileToSave.toMap(),
      );
    } else {
      // Update existing profile
      final profileToSave = profile.copyWith(
        updatedAt: DateTime.now(),
      );
      return await db.update(
        DatabaseHelper.tableSpecialistProfiles,
        profileToSave.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    }
  }

  /// Delete specialist profile
  Future<int> deleteProfile(int userId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableSpecialistProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

