import '../../domain/models/user.dart';
import '../database/database_helper.dart';

/// Repository for authentication and user management
class AuthRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Register a new user
  Future<User> registerUser({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    String? phone,
  }) async {
    final db = await DatabaseHelper.database;
    
    // Check if email already exists
    final existing = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Email already registered');
    }
    
    // Simple password hash (in production, use proper hashing like bcrypt)
    final passwordHash = _simpleHash(password);
    
    final user = User(
      email: email.toLowerCase(),
      passwordHash: passwordHash,
      role: role,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    
    final userId = await db.insert(
      DatabaseHelper.tableUsers,
      user.toMap(),
    );
    
    return user.copyWith(id: userId);
  }

  /// Login user
  Future<User?> login(String email, String password) async {
    final db = await DatabaseHelper.database;
    
    final passwordHash = _simpleHash(password);
    
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), passwordHash],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final user = User.fromMap(maps.first);
    
    // Update last login
    await db.update(
      DatabaseHelper.tableUsers,
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    
    return user.copyWith(lastLoginAt: DateTime.now());
  }

  /// Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Update user
  Future<int> updateUser(User user) async {
    if (user.id == null) {
      throw ArgumentError('User ID is required for update');
    }
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Toggle Two-Factor Authentication
  Future<int> updateTwoFactorSetting(int userId, bool isEnabled) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableUsers,
      {'is_two_factor_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Simple hash function (for demo - use proper hashing in production)
  String _simpleHash(String password) {
    // This is a simple hash for demo purposes only
    // In production, use bcrypt or similar
    return password.hashCode.toString();
  }
}

