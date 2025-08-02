import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _accessibilityKey = 'accessibility_settings';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLargeText = false;
  bool _isHighContrast = false;
  bool _isVoiceEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLargeText => _isLargeText;
  bool get isHighContrast => _isHighContrast;
  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    final accessibilitySettings = prefs.getStringList(_accessibilityKey) ?? [];
    _isLargeText = accessibilitySettings.contains('large_text');
    _isHighContrast = accessibilitySettings.contains('high_contrast');
    _isVoiceEnabled = accessibilitySettings.contains('voice_enabled');

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setLargeText(bool value) async {
    _isLargeText = value;
    await _saveAccessibilitySettings();
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _isHighContrast = value;
    await _saveAccessibilitySettings();
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    _isVoiceEnabled = value;
    await _saveAccessibilitySettings();
    notifyListeners();
  }

  Future<void> _saveAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = <String>[];

    if (_isLargeText) settings.add('large_text');
    if (_isHighContrast) settings.add('high_contrast');
    if (_isVoiceEnabled) settings.add('voice_enabled');

    await prefs.setStringList(_accessibilityKey, settings);
  }

  double get textScaleFactor {
    if (_isLargeText) return 1.3;
    return 1.0;
  }

  ColorScheme get effectiveColorScheme {
    if (_isHighContrast) {
      return _themeMode == ThemeMode.dark
          ? const ColorScheme.dark(
              primary: Colors.white,
              secondary: Colors.white,
              surface: Colors.black,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: Colors.white,
              error: Colors.red,
              onError: Colors.white,
            )
          : const ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.black,
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.black,
              error: Colors.red,
              onError: Colors.white,
            );
    }
    return _themeMode == ThemeMode.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light();
  }
}
