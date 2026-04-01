import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/models/task_request.dart';
import '../../domain/models/bid.dart';

/// Repository for task requests and bids (Profi.ru style)
class TaskRequestRepositoryImpl {
  Database? _database;

  Future<void> initialize() async {
    if (_database != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'specialist_finder.db');
    _database = await openDatabase(path, version: 1);
    await _createTables();
  }

  Future<void> _createTables() async {
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS task_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        budget_min REAL,
        budget_max REAL,
        preferred_date TEXT,
        location TEXT,
        urgency TEXT NOT NULL DEFAULT 'flexible',
        status TEXT NOT NULL DEFAULT 'open',
        created_at TEXT NOT NULL
      )
    ''');
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS bids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_request_id INTEGER NOT NULL,
        specialist_id INTEGER NOT NULL,
        specialist_name TEXT NOT NULL,
        proposed_price REAL NOT NULL,
        message TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_request_id) REFERENCES task_requests(id)
      )
    ''');
  }

  // --- Task Requests ---

  Future<int> createTaskRequest(TaskRequest request) async {
    await initialize();
    return await _database!.insert('task_requests', request.toMap());
  }

  Future<List<TaskRequest>> getAllOpenRequests() async {
    await initialize();
    final maps = await _database!.query(
      'task_requests',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => TaskRequest.fromMap(m)).toList();
  }

  Future<List<TaskRequest>> getRequestsByCategory(String category) async {
    await initialize();
    final maps = await _database!.query(
      'task_requests',
      where: 'status = ? AND category = ?',
      whereArgs: ['open', category],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => TaskRequest.fromMap(m)).toList();
  }

  Future<List<TaskRequest>> getRequestsByClientId(int clientId) async {
    await initialize();
    final maps = await _database!.query(
      'task_requests',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => TaskRequest.fromMap(m)).toList();
  }

  Future<TaskRequest?> getRequestById(int id) async {
    await initialize();
    final maps = await _database!.query(
      'task_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TaskRequest.fromMap(maps.first);
  }

  Future<void> updateRequestStatus(int id, TaskRequestStatus status) async {
    await initialize();
    await _database!.update(
      'task_requests',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Bids ---

  Future<int> createBid(Bid bid) async {
    await initialize();
    return await _database!.insert('bids', bid.toMap());
  }

  Future<List<Bid>> getBidsForRequest(int taskRequestId) async {
    await initialize();
    final maps = await _database!.query(
      'bids',
      where: 'task_request_id = ?',
      whereArgs: [taskRequestId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Bid.fromMap(m)).toList();
  }

  Future<List<Bid>> getBidsBySpecialist(int specialistId) async {
    await initialize();
    final maps = await _database!.query(
      'bids',
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Bid.fromMap(m)).toList();
  }

  Future<void> updateBidStatus(int bidId, BidStatus status) async {
    await initialize();
    await _database!.update(
      'bids',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [bidId],
    );
  }

  Future<int> getBidCountForRequest(int taskRequestId) async {
    await initialize();
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM bids WHERE task_request_id = ?',
      [taskRequestId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<bool> hasSpecialistBid(int taskRequestId, int specialistId) async {
    await initialize();
    final result = await _database!.query(
      'bids',
      where: 'task_request_id = ? AND specialist_id = ?',
      whereArgs: [taskRequestId, specialistId],
    );
    return result.isNotEmpty;
  }

  /// Seed some demo task requests for testing
  Future<void> seedDemoRequests() async {
    await initialize();
    final existing = await _database!.query('task_requests');
    if (existing.isNotEmpty) return;

    final demoRequests = [
      TaskRequest(
        clientId: 1,
        clientName: 'Anna Petrova',
        category: 'Plumbing',
        description: 'Need to fix a leaking kitchen faucet. The faucet drips constantly and the handle is loose. Prefer morning appointments.',
        budgetMin: 30,
        budgetMax: 80,
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        location: 'Downtown, Apt 15B',
        urgency: TaskUrgency.withinWeek,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TaskRequest(
        clientId: 2,
        clientName: 'Dmitry Volkov',
        category: 'Electrical',
        description: 'Install a new chandelier in the living room. I have the chandelier already, just need a professional to mount it safely.',
        budgetMin: 40,
        budgetMax: 100,
        preferredDate: DateTime.now().add(const Duration(days: 5)),
        location: 'Suburb Area, House 42',
        urgency: TaskUrgency.flexible,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      TaskRequest(
        clientId: 1,
        clientName: 'Anna Petrova',
        category: 'Cleaning',
        description: 'Deep cleaning for a 2-bedroom apartment before moving in. Around 75 sq.m. Need windows, floors, bathroom, and kitchen thoroughly cleaned.',
        budgetMin: 60,
        budgetMax: 150,
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        location: 'City Center, Block 7',
        urgency: TaskUrgency.asap,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      TaskRequest(
        clientId: 3,
        clientName: 'Maria Sokolova',
        category: 'Tutoring',
        description: 'Looking for a math tutor for my 10th grader. Preparing for university entrance exams. Need 2 sessions per week.',
        budgetMin: 20,
        budgetMax: 50,
        location: 'Remote / Online',
        urgency: TaskUrgency.flexible,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TaskRequest(
        clientId: 2,
        clientName: 'Dmitry Volkov',
        category: 'Beauty',
        description: 'Professional haircut and styling for a wedding event. Need someone who can do both cut and formal styling.',
        budgetMin: 40,
        budgetMax: 120,
        preferredDate: DateTime.now().add(const Duration(days: 10)),
        location: 'Any salon or home visit',
        urgency: TaskUrgency.withinWeek,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];

    for (final req in demoRequests) {
      await _database!.insert('task_requests', req.toMap());
    }
  }
}
