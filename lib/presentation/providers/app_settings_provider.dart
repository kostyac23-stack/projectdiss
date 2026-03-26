import 'package:flutter/material.dart';
import '../../data/services/settings_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  bool _isDarkMode = false;
  String _language = 'English';
  double _fontSizeMultiplier = 1.0;

  AppSettingsProvider(this._settingsService) {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Locale get locale {
    switch (_language) {
      case 'Русский':
        return const Locale('ru');
      case 'O\'zbekcha':
        return const Locale('uz');
      case 'English':
      default:
        return const Locale('en');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await _settingsService.getUserPreferences();
    _isDarkMode = prefs['is_dark_mode'] ?? false;
    _language = prefs['language'] ?? 'English';
    _fontSizeMultiplier = prefs['font_size_multiplier'] ?? 1.0;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFontSizeMultiplier(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await _settingsService.getUserPreferences();
    prefs['is_dark_mode'] = _isDarkMode;
    prefs['language'] = _language;
    prefs['font_size_multiplier'] = _fontSizeMultiplier;
    await _settingsService.saveUserPreferences(prefs);
  }
}
