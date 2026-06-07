// Import de Material Design pour ThemeMode et ChangeNotifier
import 'package:flutter/material.dart';

// Service de stockage des preferences utilisateur (theme, langue, etc.)
import 'package:apnea_project/services/settings_service.dart';

// Provider de gestion du theme (mode clair/sombre) de l'application
// Gere la persistence du choix et notifie les ecoutants lors de changements
class ThemeProvider extends ChangeNotifier {
  // Constructeur avec injection optionnelle du service (utile pour les tests)
  ThemeProvider({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  // Service de persistence pour sauvegarder les preferences utilisateur
  final SettingsService _settingsService;
  // Mode de theme actuel (par defaut: mode clair)
  ThemeMode _themeMode = ThemeMode.light;

  // Retourne le mode de theme actuel (ThemeMode.light ou ThemeMode.dark)
  ThemeMode get themeMode => _themeMode;
  // Retourne true si le mode sombre est actif, false sinon
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Charge le theme sauvegarde lors du demarrage de l'application
  // Lit la preference depuis le stockage local (SharedPreferences)
  Future<void> loadTheme() async {
    // Recupere la preference de mode sombre sauvegardee
    final bool isDarkMode = await _settingsService.getDarkMode();
    // Convertit le booleen en ThemeMode
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    // Notifie tous les ecoutants du changement
    notifyListeners();
  }

  // Change le theme et sauvegarde la preference utilisateur
  // Parametre value: true pour activer le mode sombre, false pour le mode clair
  Future<void> setDarkMode(bool value) async {
    // Persiste le choix de l'utilisateur dans le stockage local
    await _settingsService.setDarkMode(value);
    // Convertit le booleen en ThemeMode et met a jour l'etat
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    // Notifie tous les ecoutants pour rafraichir l'interface
    notifyListeners();
  }
}
