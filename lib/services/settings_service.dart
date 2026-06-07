import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé pour gérer les préférences utilisateur persistantes
/// Utilise SharedPreferences pour stocker les paramètres localement sur l'appareil
/// Responsabilités:
/// - Mode sombre (thème)
/// - État des notifications push
/// - État des rappels
/// - Langue de l'application
///
/// Les données sont persistantes: elles survivent au redémarrage de l'app
/// Toutes les méthodes sont asynchrones car elles accèdent au système de fichiers
class SettingsService {
  // ────────────────────────────────────────────────────────────────────────
  // Clés de stockage — doivent être cohérentes dans toute l'application
  // ────────────────────────────────────────────────────────────────────────

  /// Clé pour stocker le paramètre du mode sombre (true/false)
  /// Valeur par défaut: false (mode clair activé)
  static const _darkModeKey = 'settings.darkMode';

  /// Clé pour stocker l'état des notifications push (true/false)
  /// Valeur par défaut: true (notifications activées)
  static const _notificationsEnabledKey = 'settings.notificationsEnabled';

  /// Clé pour stocker l'état des rappels (true/false)
  /// Valeur par défaut: true (rappels activés)
  static const _remindersEnabledKey = 'settings.remindersEnabled';

  /// Clé pour stocker la langue (code: 'fr', 'en', etc.)
  /// Valeur par défaut: 'fr' (français)
  static const _languageKey = 'settings.language';

  // ────────────────────────────────────────────────────────────────────────
  // Mode Sombre (Thème)
  // ────────────────────────────────────────────────────────────────────────

  /// Récupère le paramètre du mode sombre
  /// Retourne: true si le mode sombre est activé, false sinon
  /// Valeur par défaut: false
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  /// Active ou désactive le mode sombre
  /// Paramètre: value = true pour activer le mode sombre, false pour désactiver
  /// Les changements sont appliqués immédiatement et persistant
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // ────────────────────────────────────────────────────────────────────────
  // Notifications Push
  // ────────────────────────────────────────────────────────────────────────

  /// Récupère l'état des notifications push
  /// Retourne: true si les notifications sont activées, false sinon
  /// Valeur par défaut: true
  /// Utilisé pour déterminer si les notifications FCM doivent être affichées
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Active ou désactive les notifications push
  /// Paramètre: value = true pour activer, false pour désactiver
  /// Les notifications push existantes ne sont pas affectées immédiatement
  /// Le changement s'applique aux futures notifications
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  // ────────────────────────────────────────────────────────────────────────
  // Rappels
  // ────────────────────────────────────────────────────────────────────────

  /// Récupère l'état des rappels
  /// Retourne: true si les rappels sont activés, false sinon
  /// Valeur par défaut: true
  /// Utilisé pour déterminer si les rappels (ex: mesures) doivent être affichés
  Future<bool> getRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? true;
  }

  /// Active ou désactive les rappels
  /// Paramètre: value = true pour activer, false pour désactiver
  /// Les rappels actifs sont annulés s'ils sont désactivés
  Future<void> setRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, value);
  }

  // ────────────────────────────────────────────────────────────────────────
  // Langue de l'Application
  // ────────────────────────────────────────────────────────────────────────

  /// Récupère la langue actuelle de l'application
  /// Retourne: code de langue ISO 639-1 (ex: 'fr', 'en', 'ar', etc.)
  /// Valeur par défaut: 'fr' (français)
  /// La valeur est utilisée par le système de localisation (l10n)
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'fr';
  }

  /// Définit la langue de l'application
  /// Paramètre: code = code de langue ISO 639-1 ('fr', 'en', 'ar', etc.)
  /// Les changements s'appliquent au prochain redémarrage de l'interface utilisateur
  /// L'app doit être notifiée du changement pour reconstruire avec la nouvelle langue
  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }
}
