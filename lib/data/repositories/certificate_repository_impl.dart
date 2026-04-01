import 'package:sqflite/sqflite.dart';
import '../../domain/models/certificate.dart';
import '../database/database_helper.dart';

/// Repository for managing specialist certificates
class CertificateRepositoryImpl {
  static const String tableCertificates = 'certificates';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final db = await DatabaseHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCertificates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specialist_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        issued_by TEXT,
        issued_date TEXT,
        expiry_date TEXT,
        description TEXT,
        image_path TEXT,
        type TEXT NOT NULL DEFAULT 'certificate'
      )
    ''');
    _initialized = true;
  }

  Future<List<Certificate>> getCertificates(int specialistId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      tableCertificates,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'issued_date DESC',
    );
    return results.map((m) => Certificate.fromMap(m)).toList();
  }

  Future<int> addCertificate(Certificate cert) async {
    final db = await DatabaseHelper.database;
    return await db.insert(tableCertificates, cert.toMap());
  }

  Future<void> deleteCertificate(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete(tableCertificates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedDemoCertificates(int specialistId) async {
    final existing = await getCertificates(specialistId);
    if (existing.isNotEmpty) return;
    
    final certs = [
      Certificate(specialistId: specialistId, title: 'Professional Certification', issuedBy: 'Industry Board', 
        issuedDate: DateTime(2023, 3, 15), type: CertificateType.certificate,
        description: 'Certified professional in the field'),
      Certificate(specialistId: specialistId, title: 'Advanced Training Course', issuedBy: 'Training Academy',
        issuedDate: DateTime(2024, 6, 1), type: CertificateType.training,
        description: 'Completed 120-hour advanced training program'),
    ];
    for (final c in certs) {
      await addCertificate(c);
    }
  }
}
