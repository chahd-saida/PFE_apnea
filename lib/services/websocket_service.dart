// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Remplace par l'IP du PC serveur sur le réseau Wi-Fi local
  static const String ipServeur = '192.168.1.18';
  static const int    port       = 8000;
  static const int    _maxRetries = 5;

  // ── Callbacks ─────────────────────────────────────────────────
  Function(Map<String, dynamic>)? onDonnees;
  Function(bool)?                 onConnectionChanged;

  // ── État interne ──────────────────────────────────────────────
  WebSocketChannel? _canal;
  bool    _actif      = false;
  int     _retryCount = 0;
  String? _patientId;

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // ═══════════════════════════════════════════════════════════════
  // CONNEXION
  // ═══════════════════════════════════════════════════════════════

  void connecter(String patientId) {
    debugPrint('📡 WebSocketService.connecter() → "$patientId"');

    if (patientId.isEmpty || patientId == 'patient_unknown') {
      debugPrint('❌ WebSocket: patientId vide ou invalide !');
      return;
    }

    _actif     = true;
    _patientId = patientId;

    // Annuler tout timer de reconnexion en attente
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Arrêter le ping de l'ancien canal
    _pingTimer?.cancel();
    _pingTimer = null;

    // Fermer l'ancien canal proprement AVANT d'en créer un nouveau
    // On met _canal = null AVANT de fermer pour que onDone l'ignore
    final oldCanal = _canal;
    _canal = null;
    if (oldCanal != null) {
      debugPrint('🔌 Fermeture ancien canal WebSocket…');
      try { oldCanal.sink.close(); } catch (_) {}
    }

    // Construire l'URL : ws://192.168.1.18:8000/ws/{patientId}
    final uri = Uri.parse('ws://$ipServeur:$port/ws/$patientId');
    debugPrint('🔌 Connexion WebSocket → $uri (tentative #$_retryCount)');

    try {
      final canal = WebSocketChannel.connect(uri);
      _canal = canal;

      // ── Ping toutes les 20s pour maintenir la connexion ──────
      _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_canal != null) {
          try { _canal!.sink.add('ping'); } catch (_) {}
        }
      });

      // ── Écoute du flux de messages ───────────────────────────
      canal.stream.listen(
        (message) {
          // Ignorer si ce canal n'est plus le canal actif
          // (évite les événements résiduels d'un ancien canal)
          if (!identical(canal, _canal)) return;

          // Connexion confirmée au premier message reçu
          _retryCount = 0;
          onConnectionChanged?.call(true);

          final msg = message as String;

          // Heartbeat ping/pong — ne pas parser en JSON
          if (msg == 'pong' || msg == 'ping') {
            debugPrint('💓 WebSocket heartbeat: $msg');
            return;
          }

          // Parser le JSON et transmettre les données
          try {
            final data = jsonDecode(msg) as Map<String, dynamic>;
            onDonnees?.call(data);
          } catch (e) {
            debugPrint('❌ Erreur parse WebSocket: $e (msg: "$msg")');
          }
        },

        onError: (err) {
          // Ignorer si ancien canal
          if (!identical(canal, _canal)) return;
          debugPrint('⚠️ WebSocket erreur: $err');
          onConnectionChanged?.call(false);
          _scheduleReconnect(patientId);
        },

        onDone: () {
          // Ignorer si ancien canal (fermeture intentionnelle)
          if (!identical(canal, _canal)) return;
          debugPrint('🔌 WebSocket fermé par le serveur');
          onConnectionChanged?.call(false);
          _scheduleReconnect(patientId);
        },

        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('❌ WebSocket connect failed: $e');
      _scheduleReconnect(patientId);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RECONNEXION AUTOMATIQUE (exponential backoff)
  // ═══════════════════════════════════════════════════════════════

  void _scheduleReconnect(String patientId) {
    if (!_actif) return;

    if (_retryCount >= _maxRetries) {
      debugPrint('🛑 WebSocket: max retries atteint (${ _maxRetries}).');
      onConnectionChanged?.call(false);
      // Ne pas bloquer définitivement :
      // l'utilisateur peut relancer via reinitialiser()
      return;
    }

    // Exponential backoff : 3s → 6s → 12s → 24s → 48s
    final delay = Duration(seconds: 3 * (1 << _retryCount));
    _retryCount++;

    debugPrint(
      '🔄 Reconnexion dans ${delay.inSeconds}s '
      '($_retryCount/$_maxRetries)…',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_actif) connecter(patientId);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RECONNEXION MANUELLE
  // ═══════════════════════════════════════════════════════════════

  /// Appelé depuis l'UI quand l'utilisateur appuie sur "Reconnecter".
  /// Remet le compteur à zéro et relance immédiatement.
  void reinitialiser() {
    if (_patientId == null) return;
    debugPrint('🔄 WebSocket: réinitialisation manuelle');
    _retryCount = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    connecter(_patientId!);
  }

  // ═══════════════════════════════════════════════════════════════
  // DÉCONNEXION VOLONTAIRE
  // ═══════════════════════════════════════════════════════════════

  void deconnecter() {
    _actif      = false;
    _retryCount = 0;

    _pingTimer?.cancel();
    _pingTimer = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Mettre _canal = null AVANT de fermer pour que onDone l'ignore
    final oldCanal = _canal;
    _canal = null;
    try { oldCanal?.sink.close(); } catch (_) {}

    onConnectionChanged?.call(false);
    debugPrint('🔌 WebSocket déconnecté volontairement');
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// true si un canal est ouvert ET le service est actif
  bool get estConnecte => _canal != null && _actif;

  /// true si toutes les tentatives automatiques sont épuisées
  /// → l'UI peut afficher un bouton "Reconnecter manuellement"
  bool get retryEpuise => _retryCount >= _maxRetries;
}