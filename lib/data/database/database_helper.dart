import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static const String _databaseName = 'specialist_finder.db';
  static const int _databaseVersion = 9; // Bumped to 9 for User Profile Images

  // Table names
  static const String tableSpecialists = 'specialists';
  static const String tableSettings = 'settings';
  static const String tableLogs = 'logs';
  static const String tableReviews = 'reviews';
  static const String tableFavorites = 'favorites';
  static const String tableOrders = 'orders';
  static const String tablePortfolio = 'portfolio';
  static const String tableMessages = 'messages';
  static const String tableSearchHistory = 'search_history';
  static const String tableUsers = 'users';
  static const String tableSpecialistProfiles = 'specialist_profiles';
  static const String tableClientProfiles = 'client_profiles';
  static const String tableNotifications = 'notifications';
  static const String tableAvailability = 'availability';

  // Singleton instance
  static Database? _database;

  /// Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Specialists table
    await db.execute('''
      CREATE TABLE $tableSpecialists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        skills TEXT,
        price REAL NOT NULL,
        rating REAL NOT NULL,
        experience_years INTEGER NOT NULL,
        lat REAL,
        lon REAL,
        address TEXT,
        bio TEXT,
        image_path TEXT,
        tags TEXT,
        availability_notes TEXT,
        is_verified INTEGER DEFAULT 0,
        response_time_hours REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE $tableSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Logs table (for dev mode)
    await db.execute('''
      CREATE TABLE $tableLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE $tableReviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
        comment TEXT,
        specialist_response TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE $tableFavorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE $tableOrders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        service_description TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        price REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Seed mock orders so order history is not empty for testing
    // Assigning to a generic 'John Doe' client name or generic user
    final now = DateTime.now().toIso8601String();
    final past = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
    final older = DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
    
    await db.execute('''
      INSERT INTO $tableOrders (specialist_id, client_name, service_description, status, price, created_at, updated_at)
      VALUES 
      (1, 'Client User', 'Full apartment deep cleaning', 'completed', 150.0, '$older', '$older'),
      (2, 'Client User', 'Fix leaking kitchen sink', 'accepted', 85.0, '$past', '$past'),
      (3, 'Client User', 'Math tutoring for high schooler', 'pending', 45.0, '$now', '$now')
    ''');

    // Portfolio table
    await db.execute('''
      CREATE TABLE $tablePortfolio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE $tableMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        user_id INTEGER,
        sender_name TEXT NOT NULL,
        is_from_client INTEGER NOT NULL DEFAULT 1,
        content TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE $tableSearchHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT,
        last_login_at TEXT,
        is_two_factor_enabled INTEGER DEFAULT 0,
        profile_image_path TEXT
      )
    ''');

    // Specialist profiles table
    await db.execute('''
      CREATE TABLE $tableSpecialistProfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        specialist_id INTEGER,
        category TEXT NOT NULL,
        skills TEXT,
        price REAL NOT NULL,
        bio TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        tags TEXT,
        availability_notes TEXT,
        response_time_hours REAL,
        is_verified INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE SET NULL
      )
    ''');

    // Client profiles table
    await db.execute('''
      CREATE TABLE $tableClientProfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        address TEXT,
        latitude REAL,
        longitude REAL,
        preferences TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_specialists_category ON $tableSpecialists(category)');
    await db.execute('CREATE INDEX idx_specialists_rating ON $tableSpecialists(rating)');
    await db.execute('CREATE INDEX idx_specialists_price ON $tableSpecialists(price)');
    await db.execute('CREATE INDEX idx_reviews_specialist ON $tableReviews(specialist_id)');
    await db.execute('CREATE INDEX idx_favorites_specialist ON $tableFavorites(specialist_id)');
    await db.execute('CREATE INDEX idx_orders_specialist ON $tableOrders(specialist_id)');
    await db.execute('CREATE INDEX idx_orders_status ON $tableOrders(status)');
    await db.execute('CREATE INDEX idx_portfolio_specialist ON $tablePortfolio(specialist_id)');
    await db.execute('CREATE INDEX idx_messages_specialist ON $tableMessages(specialist_id)');
    await db.execute('CREATE INDEX idx_messages_created ON $tableMessages(created_at)');
    await db.execute('CREATE INDEX idx_search_history_created ON $tableSearchHistory(created_at)');
    await db.execute('CREATE INDEX idx_users_email ON $tableUsers(email)');
    await db.execute('CREATE INDEX idx_users_role ON $tableUsers(role)');
    await db.execute('CREATE INDEX idx_specialist_profiles_user ON $tableSpecialistProfiles(user_id)');
    await db.execute('CREATE INDEX idx_client_profiles_user ON $tableClientProfiles(user_id)');

    // Notifications table
    await db.execute('''
      CREATE TABLE $tableNotifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        related_id INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    // Availability table
    await db.execute('''
      CREATE TABLE $tableAvailability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL CHECK(day_of_week >= 0 AND day_of_week <= 6),
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_notifications_user ON $tableNotifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_read ON $tableNotifications(is_read)');
    await db.execute('CREATE INDEX idx_availability_specialist ON $tableAvailability(specialist_id)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to specialists table
      try {
        await db.execute('ALTER TABLE $tableSpecialists ADD COLUMN is_verified INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE $tableSpecialists ADD COLUMN response_time_hours REAL');
      } catch (e) {
        // Column might already exist
      }

      // Create new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableReviews (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL,
          client_name TEXT NOT NULL,
          rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
          comment TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableFavorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL UNIQUE,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableOrders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL,
          client_name TEXT NOT NULL,
          service_description TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          price REAL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tablePortfolio (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          description TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reviews_specialist ON $tableReviews(specialist_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_specialist ON $tableFavorites(specialist_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_specialist ON $tableOrders(specialist_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_status ON $tableOrders(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_portfolio_specialist ON $tablePortfolio(specialist_id)');
    }
    
    if (oldVersion < 3) {
      // Add messages table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableMessages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL,
          user_id INTEGER,
          sender_name TEXT NOT NULL,
          is_from_client INTEGER NOT NULL DEFAULT 1,
          content TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      // Add search history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSearchHistory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_specialist ON $tableMessages(specialist_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_created ON $tableMessages(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_search_history_created ON $tableSearchHistory(created_at)');
    }
    
    if (oldVersion < 4) {
      // Add users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          last_login_at DATETIME
        )
      ''');

      // Add specialist profiles table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSpecialistProfiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          specialist_id INTEGER,
          category TEXT NOT NULL,
          skills TEXT,
          price REAL NOT NULL,
          bio TEXT,
          address TEXT,
          latitude REAL,
          longitude REAL,
          tags TEXT,
          availability_notes TEXT,
          response_time_hours REAL,
          is_verified INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE SET NULL
        )
      ''');

      // Add client profiles table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableClientProfiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          address TEXT,
          latitude REAL,
          longitude REAL,
          preferences TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON $tableUsers(email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_role ON $tableUsers(role)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_specialist_profiles_user ON $tableSpecialistProfiles(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_client_profiles_user ON $tableClientProfiles(user_id)');
    }
    
    if (oldVersion < 5) {
      // Add specialist_response to reviews table
      try {
        await db.execute('ALTER TABLE $tableReviews ADD COLUMN specialist_response TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Add notifications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableNotifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          related_id INTEGER,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');

      // Add availability table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableAvailability (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specialist_id INTEGER NOT NULL,
          day_of_week INTEGER NOT NULL CHECK(day_of_week >= 0 AND day_of_week <= 6),
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          is_available INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (specialist_id) REFERENCES $tableSpecialists(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_user ON $tableNotifications(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON $tableNotifications(is_read)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_availability_specialist ON $tableAvailability(specialist_id)');
    }

    if (oldVersion < 6) {
      // Add user_id column to messages for per-user conversation scoping
      try {
        await db.execute('ALTER TABLE $tableMessages ADD COLUMN user_id INTEGER');
      } catch (_) {
        // Column may already exist
      }
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_user ON $tableMessages(user_id)');
    }

    if (oldVersion < 7) {
      // Add two-factor authentication flag to users table
      try {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN is_two_factor_enabled INTEGER DEFAULT 0');
      } catch (_) {
        // Column may already exist
      }
    }

    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE before_after_projects ADD COLUMN before_image_path TEXT');
        await db.execute('ALTER TABLE before_after_projects ADD COLUMN after_image_path TEXT');
      } catch (_) {
        // Column may already exist
      }
    }

    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN profile_image_path TEXT');
      } catch (_) {
        // Column may already exist
      }
    }
  }

  /// Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing/reset)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableSpecialists);
    await db.delete(tableSettings);
    await db.delete(tableLogs);
    await db.delete(tableReviews);
    await db.delete(tableFavorites);
    await db.delete(tableOrders);
    await db.delete(tablePortfolio);
    await db.delete(tableMessages);
    await db.delete(tableSearchHistory);
    await db.delete(tableUsers);
    await db.delete(tableSpecialistProfiles);
    await db.delete(tableClientProfiles);
    await db.delete(tableNotifications);
    await db.delete(tableAvailability);
  }
}

