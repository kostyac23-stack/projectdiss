import '../../domain/models/notification.dart';
import '../database/database_helper.dart';

/// Repository for managing notifications
class NotificationRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get all notifications for a user
  Future<List<Notification>> getNotificationsByUserId(int userId, {bool unreadOnly = false}) async {
    final db = await DatabaseHelper.database;
    final where = unreadOnly ? 'user_id = ? AND is_read = 0' : 'user_id = ?';
    final maps = await db.query(
      DatabaseHelper.tableNotifications,
      where: where,
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Notification.fromMap(map)).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount(int userId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotifications} WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Create a notification
  Future<int> createNotification(Notification notification) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      DatabaseHelper.tableNotifications,
      notification.toMap(),
    );
  }

  /// Mark notification as read
  Future<int> markAsRead(int notificationId) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableNotifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Mark all notifications as read for a user
  Future<int> markAllAsRead(int userId) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableNotifications,
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete a notification
  Future<int> deleteNotification(int notificationId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableNotifications,
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Delete all notifications for a user
  Future<int> deleteAllNotifications(int userId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableNotifications,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

