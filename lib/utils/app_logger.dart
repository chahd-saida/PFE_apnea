/// Utilitaire de journalisation (logging) pour l'application.
/// Fournit une interface unifiée pour enregistrer les messages avec différents niveaux.
/// La journalisation s'adapte au mode de compilation (debug vs release).
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Filtre de logs personnalisé qui adapte le niveau de journalisation selon le mode (debug/release).
/// En mode release: uniquement les warnings et erreurs sont journalisés.
/// En mode debug: tous les niveaux de logs sont affichés.
class _ReleaseFilter extends LogFilter {
  /// Détermine si un événement de log doit être journalisé.
  /// En mode debug (kReleaseMode = false): tous les logs sont affichés.
  /// En mode release (kReleaseMode = true): uniquement les warnings et erreurs sont affichés.
  @override
  bool shouldLog(LogEvent event) {
    // Mode debug: afficher tous les logs
    if (!kReleaseMode) {
      return true;
    }
    // Mode release: afficher uniquement les warnings (index >= warning.index)
    return event.level.index >= Level.warning.index;
  }
}

/// Service de journalisation centralisé pour l'application.
/// Fournit des méthodes de log avec des niveaux différents (debug, info, warning, error).
/// Utilise la bibliothèque 'logger' pour un formatage amélioré et s'adapte au mode de compilation.
class AppLogger {
  /// Initialise le logger avec un filtre personnalisé et un formatteur PrettyPrinter.
  /// Configuration adaptée au mode debug/release:
  ///   - Mode debug: affiche les couleurs, emojis, et timestamps détaillés
  ///   - Mode release: formatage minimal pour meilleures performances
  AppLogger()
    : _logger = Logger(
        // Utiliser le filtre personnalisé pour adapter les logs au mode
        filter: _ReleaseFilter(),
        // PrettyPrinter pour un formatage lisible des messages de log
        printer: PrettyPrinter(
          methodCount:
              0, // Nombre de méthodes à afficher dans la stack (0 = aucune)
          errorMethodCount: 5, // Nombre de méthodes en cas d'erreur
          lineLength: 80, // Largeur maximale des lignes de log
          colors: !kReleaseMode, // Couleurs activées en debug uniquement
          printEmojis: !kReleaseMode, // Emojis affichés en debug uniquement
          dateTimeFormat: !kReleaseMode
              ? DateTimeFormat
                    .onlyTimeAndSinceStart // Format détaillé en debug
              : DateTimeFormat.none, // Pas de date en release
        ),
      );

  /// Instance interne du logger de la bibliothèque 'logger'.
  /// Instance interne du logger de la bibliothèque 'logger'.
  final Logger _logger;

  /// Enregistre un message de niveau DEBUG.
  /// Utilisé pour les informations détaillées utiles au débogage.
  /// Paramètres:
  ///   - message: Le message à enregistrer
  ///   - error: Objet erreur optionnel
  ///   - stackTrace: Trace de pile optionnelle
  void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Enregistre un message de niveau INFO.
  /// Utilisé pour les informations générales sur le flux d'exécution.
  /// Paramètres:
  ///   - message: Le message à enregistrer
  ///   - error: Objet erreur optionnel
  ///   - stackTrace: Trace de pile optionnelle
  void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Enregistre un message de niveau WARNING.
  /// Utilisé pour les situations inhabituelles ou potentiellement problématiques.
  /// Les warnings sont affichés aussi en mode release.
  /// Paramètres:
  ///   - message: Le message à enregistrer
  ///   - error: Objet erreur optionnel
  ///   - stackTrace: Trace de pile optionnelle
  void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Enregistre un message de niveau ERROR.
  /// Utilisé pour les erreurs rencontrées lors de l'exécution.
  /// Les erreurs sont affichées aussi en mode release.
  /// Paramètres:
  ///   - message: Le message à enregistrer
  ///   - error: Objet erreur optionnel
  ///   - stackTrace: Trace de pile optionnelle
  void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

/// Instance globale du logger de l'application.
/// À utiliser partout dans l'application via: appLogger.d(), appLogger.i(), etc.
final AppLogger appLogger = AppLogger();
