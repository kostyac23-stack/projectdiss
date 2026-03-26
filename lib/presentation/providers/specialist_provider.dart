import 'package:flutter/foundation.dart';
import '../../domain/models/specialist.dart';
import '../../domain/models/matching_score.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/models/matching_weights.dart';
import '../../domain/repositories/specialist_repository.dart';
import '../../data/services/settings_service.dart';

/// Provider for managing specialist data and ranking
class SpecialistProvider with ChangeNotifier {
  final SpecialistRepository _repository;
  final SettingsService _settingsService;

  List<MatchingScore> _rankedSpecialists = [];
  MatchingWeights _weights = MatchingWeights.defaultWeights;
  SearchFilters _filters = const SearchFilters();
  bool _isLoading = false;
  String? _error;
  double? _userLatitude;
  double? _userLongitude;
  List<String>? _requiredSkills;

  SpecialistProvider({
    required SpecialistRepository repository,
    required SettingsService settingsService,
  })  : _repository = repository,
        _settingsService = settingsService;

  // Getters
  List<MatchingScore> get rankedSpecialists => _rankedSpecialists;
  MatchingWeights get weights => _weights;
  SearchFilters get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  List<String>? get requiredSkills => _requiredSkills;

  /// Initialize provider (load weights from storage)
  Future<void> initialize() async {
    _weights = await _settingsService.getWeights();
    notifyListeners();
  }

  /// Load and rank specialists
  Future<void> loadRankedSpecialists({bool isQuietRefresh = false}) async {
    if (!isQuietRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _rankedSpecialists = await _repository.getRankedSpecialists(
        weights: _weights,
        filters: _filters.isEmpty ? null : _filters,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        requiredSkills: _requiredSkills,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load specialists: $e';
      if (!isQuietRefresh) {
        _rankedSpecialists = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update search filters
  void updateFilters(SearchFilters filters, {bool isQuietRefresh = false}) {
    _filters = filters;
    loadRankedSpecialists(isQuietRefresh: isQuietRefresh);
  }

  /// Update matching weights
  Future<void> updateWeights(MatchingWeights weights) async {
    _weights = weights;
    await _settingsService.saveWeights(weights);
    await loadRankedSpecialists();
  }

  /// Set user location
  void setUserLocation(double? latitude, double? longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    loadRankedSpecialists();
  }

  /// Set required skills
  void setRequiredSkills(List<String>? skills) {
    _requiredSkills = skills;
    loadRankedSpecialists();
  }

  /// Clear filters
  void clearFilters() {
    _filters = const SearchFilters();
    _requiredSkills = null;
    loadRankedSpecialists();
  }

  /// Get specialist by ID
  Future<Specialist?> getSpecialistById(int id) async {
    try {
      return await _repository.getSpecialistById(id);
    } catch (e) {
      _error = 'Failed to load specialist: $e';
      notifyListeners();
      return null;
    }
  }
}

