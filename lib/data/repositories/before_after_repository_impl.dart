import 'package:sqflite/sqflite.dart';
import '../../domain/models/before_after_project.dart';
import '../database/database_helper.dart';

/// Repository for managing before/after project showcases
class BeforeAfterRepositoryImpl {
  static const String tableProjects = 'before_after_projects';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final db = await DatabaseHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        before_description TEXT,
        after_description TEXT,
        category TEXT NOT NULL,
        before_image_path TEXT,
        after_image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    _initialized = true;
  }

  Future<List<BeforeAfterProject>> getProjects(int specialistId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      tableProjects,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => BeforeAfterProject.fromMap(m)).toList();
  }

  Future<int> addProject(BeforeAfterProject project) async {
    final db = await DatabaseHelper.database;
    return await db.insert(tableProjects, project.toMap());
  }

  Future<void> deleteProject(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete(tableProjects, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedDemoProjects(int specialistId, String category) async {
    final existing = await getProjects(specialistId);
    if (existing.isNotEmpty) return;
    
    final projects = [
      BeforeAfterProject(
        specialistId: specialistId, title: 'Complete Renovation',
        category: category, beforeDescription: 'Old and worn-out, needed full restoration',
        afterDescription: 'Modern, clean, and professionally finished',
        description: 'Full service from start to finish',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      BeforeAfterProject(
        specialistId: specialistId, title: 'Quick Fix Project',
        category: category, beforeDescription: 'Minor issues that needed attention',
        afterDescription: 'Everything working perfectly',
        description: 'Fast turnaround on a smaller project',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];
    for (final p in projects) await addProject(p);
  }
}
