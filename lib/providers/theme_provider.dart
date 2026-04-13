import 'package:flutter/material.dart';

import 'package:apnea_project/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final bool isDarkMode = await _settingsService.getDarkMode();
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _settingsService.setDarkMode(value);
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
