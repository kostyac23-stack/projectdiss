import '../../domain/models/client_profile.dart';
import '../database/database_helper.dart';

/// Repository for managing client profiles
class ClientProfileRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get client profile by user ID
  Future<ClientProfile?> getProfileByUserId(int userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableClientProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ClientProfile.fromMap(maps.first);
  }

  /// Create or update client profile
  Future<int> saveProfile(ClientProfile profile) async {
    final db = await DatabaseHelper.database;
    
    if (profile.id == null) {
      // Insert new profile
      final profileToSave = profile.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return await db.insert(
        DatabaseHelper.tableClientProfiles,
        profileToSave.toMap(),
      );
    } else {
      // Update existing profile
      final profileToSave = profile.copyWith(
        updatedAt: DateTime.now(),
      );
      return await db.update(
        DatabaseHelper.tableClientProfiles,
        profileToSave.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    }
  }

  /// Delete client profile
  Future<int> deleteProfile(int userId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableClientProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

