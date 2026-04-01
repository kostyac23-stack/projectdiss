import '../database/database_helper.dart';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Service for local logging (dev mode)
class LoggingService {
  final bool _enabled;

  LoggingService({bool? enabled}) : _enabled = enabled ?? false;

  /// Log a message
  Future<void> log(LogLevel level, String message) async {
    if (!_enabled) return;

    try {
      final db = await DatabaseHelper.database;
      await db.insert(
        DatabaseHelper.tableLogs,
        {
          'level': level.name,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail if logging fails
      // ignore: avoid_print
      print('Logging error: $e');
    }
  }

  /// Log debug message
  Future<void> debug(String message) => log(LogLevel.debug, message);

  /// Log info message
  Future<void> info(String message) => log(LogLevel.info, message);

  /// Log warning message
  Future<void> warning(String message) => log(LogLevel.warning, message);

  /// Log error message
  Future<void> error(String message, [Object? error]) {
    final errorMessage = error != null ? '$message: $error' : message;
    return log(LogLevel.error, errorMessage);
  }

  /// Get recent logs
  Future<List<Map<String, dynamic>>> getRecentLogs({int limit = 100}) async {
    if (!_enabled) return [];

    try {
      final db = await DatabaseHelper.database;
      return await db.query(
        DatabaseHelper.tableLogs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    if (!_enabled) return;

    try {
      final db = await DatabaseHelper.database;
      await db.delete(DatabaseHelper.tableLogs);
    } catch (e) {
      // Silently fail
    }
  }
}

