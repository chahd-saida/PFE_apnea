import 'package:flutter/material.dart';

import 'package:apnea_project/services/settings_service.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._settingsService);

  final SettingsService _settingsService;
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> loadLocale() async {
    final code = await _settingsService.getLanguage();
    _locale = _localeFromCode(code);
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    _locale = _localeFromCode(code);
    await _settingsService.setLanguage(code);
    notifyListeners();
  }

  Locale _localeFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en');
      case 'ar':
        return const Locale('ar');
      case 'fr':
      default:
        return const Locale('fr');
    }
  }
}
