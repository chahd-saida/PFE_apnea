// lib/providers/monitoring_provider.dart
import 'package:flutter/foundation.dart';
import 'package:apnea_project/services/websocket_service.dart';
import 'package:apnea_project/services/monitoring_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  final MonitoringService _monService = MonitoringService();

  bool _isConnected = false;
  bool _isMonitoring = false;
  Map<String, dynamic> _liveData = {};
  Map<String, dynamic> _iaResult = {};

  // ── Getters publics ────────────────────────────────────────────────────────
  bool get isConnected => _isConnected;
  bool get isMonitoring => _isMonitoring;
  Map<String, dynamic> get liveData => _liveData;
  Map<String, dynamic> get iaResult => _iaResult;

  // ── Setters publics — permettent à RealtimeMonitoringScreen ───────────────
  // de brancher ses propres callbacks sur le WebSocket
  set onConnectionChanged(Function(bool)? cb) =>
      _wsService.onConnectionChanged = cb;

  set onDonnees(Function(Map<String, dynamic>)? cb) =>
      _wsService.onDonnees = cb;

  // ── startMonitoring ────────────────────────────────────────────────────────
  void startMonitoring(String patientId) {
    _isMonitoring = true;

    // Callbacks internes du provider (mise à jour de l'état partagé)
    // Ces callbacks sont remplacés par ceux du screen via les setters ci-dessus
    // si le screen branche les siens en premier via postFrameCallback
    _wsService.onDonnees ??= (data) {
      _liveData = (data['donnees'] as Map<String, dynamic>?) ?? {};
      _iaResult = (data['ia'] as Map<String, dynamic>?) ?? {};
      _isConnected = true;
      notifyListeners();
    };

    _wsService.onConnectionChanged ??= (connected) {
      _isConnected = connected;
      notifyListeners();
    };

    _wsService.connecter(patientId);
    notifyListeners();
  }

  // ── stopMonitoring ─────────────────────────────────────────────────────────
  void stopMonitoring() {
    _isMonitoring = false;
    _wsService.deconnecter();
    notifyListeners();
  }

  // ── resetCallbacks — remet les callbacks internes du provider ──────────────
  // Appeler si le screen est détruit et qu'un autre Provider prend le relais
  void resetCallbacks() {
    _wsService.onDonnees = (data) {
      _liveData = (data['donnees'] as Map<String, dynamic>?) ?? {};
      _iaResult = (data['ia'] as Map<String, dynamic>?) ?? {};
      _isConnected = true;
      notifyListeners();
    };
    _wsService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
    };
  }

  @override
  void dispose() {
    _wsService.deconnecter();
    _monService.dispose();
    super.dispose();
  }
}
