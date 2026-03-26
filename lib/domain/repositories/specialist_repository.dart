import '../models/specialist.dart';
import '../models/search_filters.dart';
import '../models/matching_score.dart';
import '../models/matching_weights.dart';

/// Repository interface for specialist data operations
abstract class SpecialistRepository {
  /// Initialize database and tables
  Future<void> initialize();

  /// Get all specialists
  Future<List<Specialist>> getAllSpecialists();

  /// Get specialist by ID
  Future<Specialist?> getSpecialistById(int id);

  /// Search specialists with filters
  Future<List<Specialist>> searchSpecialists(SearchFilters filters);

  /// Get ranked specialists with matching scores
  Future<List<MatchingScore>> getRankedSpecialists({
    required MatchingWeights weights,
    SearchFilters? filters,
    double? userLatitude,
    double? userLongitude,
    List<String>? requiredSkills,
  });

  /// Insert a specialist
  Future<int> insertSpecialist(Specialist specialist);

  /// Update a specialist
  Future<int> updateSpecialist(Specialist specialist);

  /// Delete a specialist
  Future<int> deleteSpecialist(int id);

  /// Bulk insert specialists (for seeding)
  Future<void> insertSpecialists(List<Specialist> specialists);

  /// Clear all specialists
  Future<void> clearAll();

  /// Export data to JSON
  Future<String> exportToJson();

  /// Import data from JSON
  Future<void> importFromJson(String json);

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics();
}

