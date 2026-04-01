import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/matching_weights.dart';

/// Service for managing app settings (weights, preferences)
class SettingsService {
  static const String _keyWeights = 'matching_weights';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPreferences = 'user_preferences';
  static const String _keyDevMode = 'dev_mode';

  /// Get matching weights from storage
  Future<MatchingWeights> getWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final weightsJson = prefs.getString(_keyWeights);
    if (weightsJson == null) {
      return MatchingWeights.defaultWeights;
    }
    try {
      final map = jsonDecode(weightsJson) as Map<String, dynamic>;
      return MatchingWeights.fromMap(map);
    } catch (e) {
      return MatchingWeights.defaultWeights;
    }
  }

  /// Save matching weights to storage
  Future<void> saveWeights(MatchingWeights weights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWeights, jsonEncode(weights.toMap()));
  }

  /// Check if this is the first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Save user name
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_keyUserPreferences);
    if (prefsJson == null) return {};
    try {
      return jsonDecode(prefsJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPreferences, jsonEncode(preferences));
  }

  /// Check if dev mode is enabled
  Future<bool> isDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDevMode) ?? false;
  }

  /// Toggle dev mode
  Future<void> setDevMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDevMode, enabled);
  }
}

