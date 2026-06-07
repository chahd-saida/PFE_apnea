// Imports de base Flutter
import 'package:flutter/material.dart';

// Service de gestion des preferences utilisateur (stockage local)
import 'package:apnea_project/services/settings_service.dart';

// Provider de gestion de la langue et localisation de l'application
// Gere la langue actuelle (FR/EN/AR) et sa persistence dans les preferences
class LocaleProvider extends ChangeNotifier {
  // Constructeur qui initialise le provider avec le service de parametres
  LocaleProvider(this._settingsService);

  // Service pour lire/ecrire les preferences utilisateur dans le stockage local
  final SettingsService _settingsService;
  // Locale actuelle de l'application (par defaut : francais)
  Locale _locale = const Locale('fr');

  // ════════════════════════════════════════════════════════════════
  // GETTERS PUBLICS
  // ════════════════════════════════════════════════════════════════

  // Retourne la Locale actuelle (objet contenant la langue et region)
  Locale get locale => _locale;
  // Retourne le code de la langue actuelle (ex: 'fr', 'en', 'ar')
  String get languageCode => _locale.languageCode;

  // ════════════════════════════════════════════════════════════════
  // METHODES PUBLIQUES
  // ════════════════════════════════════════════════════════════════

  // Charge la langue sauvegardee de l'utilisateur au demarrage de l'app
  // Lit le code de langue depuis le stockage local et met a jour la Locale
  Future<void> loadLocale() async {
    // Recupere le code de langue depuis les preferences (ex: 'fr', 'en', 'ar')
    final code = await _settingsService.getLanguage();
    // Convertit le code en objet Locale et met a jour l'etat local
    _locale = _localeFromCode(code);
    // Notifie les ecoutants (widgets) que la langue a change
    notifyListeners();
  }

  // Modifie la langue actuelle et la sauvegarde dans les preferences
  // Prend un code de langue (ex: 'fr', 'en', 'ar')
  Future<void> setLocaleCode(String code) async {
    // Convertit le code en objet Locale et met a jour l'etat
    _locale = _localeFromCode(code);
    // Sauvegarde le choix de langue dans le stockage local pour la prochaine session
    await _settingsService.setLanguage(code);
    // Notifie les ecoutants que la langue a change (provoque rebuild des widgets)
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  // METHODES PRIVEES
  // ════════════════════════════════════════════════════════════════

  // Convertit un code de langue (String) en objet Locale utilisable par Flutter
  // Supporte : 'en' (anglais), 'ar' (arabe), 'fr' (francais par defaut)
  Locale _localeFromCode(String code) {
    // Mappe le code de langue a l'objet Locale correspondant
    switch (code) {
      case 'en':
        // Anglais
        return const Locale('en');
      case 'ar':
        // Arabe
        return const Locale('ar');
      case 'fr':
      default:
        // Francais (langue par defaut)
        return const Locale('fr');
    }
  }
}
