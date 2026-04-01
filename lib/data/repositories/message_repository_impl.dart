import 'package:sqflite/sqflite.dart';
import '../../domain/models/message.dart';
import '../database/database_helper.dart';

/// Repository for managing chat messages
class MessageRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get messages for a specific conversation (specialist + user)
  Future<List<Message>> getMessages({required int specialistId, required int userId}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableMessages,
      where: 'specialist_id = ? AND user_id = ?',
      whereArgs: [specialistId, userId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  /// Legacy: Get all messages for a specialist (no user scoping)
  Future<List<Message>> getMessagesBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableMessages,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  /// Get unread message count for a specialist (legacy)
  Future<int> getUnreadCount(int specialistId) async {
    final db = await DatabaseHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableMessages} WHERE specialist_id = ? AND is_from_client = 0 AND is_read = 0',
        [specialistId],
      ),
    );
    return result ?? 0;
  }

  /// Add a new message
  Future<int> insertMessage(Message message) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      DatabaseHelper.tableMessages,
      message.toMap(),
    );
  }

  /// Mark messages as read for a specific conversation
  Future<int> markAsRead({
    required int specialistId,
    required int userId,
    required bool isReadingByClient,
  }) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableMessages,
      {'is_read': 1},
      where: 'specialist_id = ? AND user_id = ? AND is_from_client = ?',
      // If client is reading, mark specialist's messages (is_from_client=0) as read
      // If specialist is reading, mark client's messages (is_from_client=1) as read
      whereArgs: [specialistId, userId, isReadingByClient ? 0 : 1],
    );
  }

  /// Delete all messages for a specialist
  Future<int> deleteMessagesBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableMessages,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
    );
  }

  /// Delete a specific conversation strand between a specialist and a client
  Future<int> deleteConversation({required int specialistId, required int userId}) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableMessages,
      where: 'specialist_id = ? AND user_id = ?',
      whereArgs: [specialistId, userId],
    );
  }

  /// Get all conversations for a specific Client user
  Future<List<Map<String, dynamic>>> getConversationsForUser(int userId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        specialist_id,
        MAX(created_at) as last_message_time,
        COUNT(*) as message_count,
        SUM(CASE WHEN is_from_client = 0 AND is_read = 0 THEN 1 ELSE 0 END) as unread_count
      FROM ${DatabaseHelper.tableMessages}
      WHERE user_id = ?
      GROUP BY specialist_id
      ORDER BY last_message_time DESC
    ''', [userId]);
    return result;
  }

  /// Get all conversations for a specific Specialist
  Future<List<Map<String, dynamic>>> getConversationsForSpecialist(int specialistId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        user_id,
        MAX(created_at) as last_message_time,
        COUNT(*) as message_count,
        SUM(CASE WHEN is_from_client = 1 AND is_read = 0 THEN 1 ELSE 0 END) as unread_count
      FROM ${DatabaseHelper.tableMessages}
      WHERE specialist_id = ? AND user_id IS NOT NULL
      GROUP BY user_id
      ORDER BY last_message_time DESC
    ''', [specialistId]);
    return result;
  }

  /// Get all conversations (legacy, no user scoping)
  Future<List<Map<String, dynamic>>> getAllConversations() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        specialist_id,
        MAX(created_at) as last_message_time,
        COUNT(*) as message_count,
        SUM(CASE WHEN is_from_client = 0 AND is_read = 0 THEN 1 ELSE 0 END) as unread_count
      FROM ${DatabaseHelper.tableMessages}
      GROUP BY specialist_id
      ORDER BY last_message_time DESC
    ''');
    return result;
  }
}
