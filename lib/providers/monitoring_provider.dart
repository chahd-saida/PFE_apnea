// lib/providers/monitoring_provider.dart
// Provider de suivi en temps reel des donnees du patient
// Gere la connexion WebSocket, la reception des donnees en direct et les apnees detectees

import 'package:flutter/foundation.dart';
// Service WebSocket pour communiquer avec le serveur en temps reel
import 'package:apnea_project/services/websocket_service.dart';
// Service de suivi pour acceder aux donnees de surveillance du patient
import 'package:apnea_project/services/monitoring_service.dart';

// Provider de gestion du suivi en temps reel (WebSocket + donnees)
// Coordonne la connexion au serveur et la reception des donnees live du patient
class MonitoringProvider extends ChangeNotifier {
  // Service WebSocket pour la communication bidirectionnelle en temps reel
  final WebSocketService _wsService = WebSocketService();
  // Service de suivi pour gerer les donnees de surveillance
  final MonitoringService _monService = MonitoringService();

  // Etat du provider
  // Indicateur de connexion au serveur WebSocket
  bool _isConnected = false;
  // Indicateur du suivi actif (monitoring en cours)
  bool _isMonitoring = false;
  // Donnees en direct reçues du serveur (capteurs, parametres)
  Map<String, dynamic> _liveData = {};
  // Resultats de l'analyse IA (detection d'apnees, etc.)
  Map<String, dynamic> _iaResult = {};

  // ════════════════════════════════════════════════════════════════
  // GETTERS PUBLICS
  // ════════════════════════════════════════════════════════════════

  // Verifie si la connexion WebSocket est active
  bool get isConnected => _isConnected;
  // Verifie si le suivi du patient est en cours
  bool get isMonitoring => _isMonitoring;
  // Retourne les donnees en direct du patient (parametres, capteurs)
  Map<String, dynamic> get liveData => _liveData;
  // Retourne les resultats d'analyse IA (apnees detectees, etc.)
  Map<String, dynamic> get iaResult => _iaResult;

  // ════════════════════════════════════════════════════════════════
  // SETTERS DE CALLBACKS — le screen branche ses propres callbacks
  // ════════════════════════════════════════════════════════════════

  // Attache un callback pour etre notifie lors de changements de connexion
  // Le setter ecrase toujours le callback precedent (= au lieu de ??=)
  set onConnectionChanged(Function(bool)? cb) =>
      _wsService.onConnectionChanged = cb;

  // Attache un callback pour etre notifie a la reception de nouvelles donnees
  set onDonnees(Function(Map<String, dynamic>)? cb) =>
      _wsService.onDonnees = cb;

  // ════════════════════════════════════════════════════════════════
  // DEMARRAGE DU SUIVI
  // ════════════════════════════════════════════════════════════════

  // Demarrage du suivi en temps reel d'un patient
  // Se connecte au serveur WebSocket et configure les callbacks par defaut
  void startMonitoring(String patientId) {
    // Valide que l'ID du patient est valide
    if (patientId.isEmpty || patientId == 'patient_unknown') {
      debugPrint('❌ MonitoringProvider: patientId invalide → $patientId');
      return; // Annule si ID invalide
    }

    // Active le mode suivi
    // Active le mode suivi
    _isMonitoring = true;

    // Configure les callbacks par defaut du provider
    // Ces callbacks seront remplaces par le screen APRES via attachScreenCallbacks()
    // Callback de reception des donnees en direct du serveur
    _wsService.onDonnees = (data) {
      // Extrait les donnees live et les resultats IA du message recu
      _liveData = (data['donnees'] as Map<String, dynamic>?) ?? {};
      _iaResult = (data['ia'] as Map<String, dynamic>?) ?? {};
      // Marque comme connecte
      _isConnected = true;
      // Notifie les ecoutants de la mise a jour
      notifyListeners();
    };

    // Callback lors de changements d'etat de connexion
    _wsService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
    };

    // Initie la connexion au serveur WebSocket pour ce patient
    _wsService.connecter(patientId);
    // Notifie les ecoutants du changement d'etat
    notifyListeners();
  }

  // ── Appelé par le screen APRÈS avoir branché ses callbacks ────
  // pour remplacer les callbacks par défaut par ceux du screen
  void attachScreenCallbacks({
    required Function(bool) onConnectionChanged,
    required Function(Map<String, dynamic>) onDonnees,
  }) {
    _wsService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
      onConnectionChanged(connected);
    };

    _wsService.onDonnees = (data) {
      _liveData = (data['donnees'] as Map<String, dynamic>?) ?? {};
      _iaResult = (data['ia'] as Map<String, dynamic>?) ?? {};
      _isConnected = true;
      notifyListeners();
      onDonnees(data);
    };
  }

  // ════════════════════════════════════════════════════════════════
  // ARRET DU SUIVI
  // ════════════════════════════════════════════════════════════════

  // Arrete le suivi du patient et deconnecte le WebSocket
  void stopMonitoring() {
    // Desactive le mode suivi
    _isMonitoring = false;
    // Ferme la connexion WebSocket au serveur
    _wsService.deconnecter();
    // Marque comme deconnecte
    _isConnected = false;
    // Notifie les ecoutants du changement d'etat
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  // RECONNEXION MANUELLE
  // ════════════════════════════════════════════════════════════════

  // Reconnexion manuelle sur action de l'utilisateur (bouton "Reconnecter")
  // Reinitialise le service WebSocket pour relancer la connexion
  void reconnecter() {
    _wsService.reinitialiser();
  }

  // ════════════════════════════════════════════════════════════════
  // REINITIALISATION DES CALLBACKS
  // ════════════════════════════════════════════════════════════════

  // Reinitialise les callbacks du provider avec leurs versions par defaut
  // Annule les callbacks personnalises du screen et restaure ceux du provider
  void resetCallbacks() {
    // Restaure le callback par defaut pour la reception des donnees
    _wsService.onDonnees = (data) {
      _liveData = (data['donnees'] as Map<String, dynamic>?) ?? {};
      _iaResult = (data['ia'] as Map<String, dynamic>?) ?? {};
      _isConnected = true;
      notifyListeners();
    };
    // Restaure le callback par defaut pour les changements de connexion
    _wsService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
    };
  }

  // ════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════

  // Nettoie les ressources lors de la destruction du provider
  // Deconnecte le WebSocket et libere les ressources du service de suivi
  @override
  void dispose() {
    // Ferme la connexion WebSocket
    _wsService.deconnecter();
    // Libere les ressources du service de suivi
    _monService.dispose();
    super.dispose();
  }
}
