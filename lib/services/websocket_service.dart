import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String ipServeur = '192.168.1.18';
  static const int port = 8000;
  static const int _maxRetries = 5;

  WebSocketChannel? _canal;
  Function(Map<String, dynamic>)? onDonnees;
  Function(bool)? onConnectionChanged;

  bool _actif = false;
  int _retryCount = 0;
  String? _patientId; // AJOUT : mémoriser pour reconnecter après reset

  void connecter(String patientId) {
    _actif = true;
    _patientId = patientId;
    _canal?.sink.close();

    final uri = Uri.parse('ws://$ipServeur:$port/ws/$patientId');
    debugPrint('🔌 WebSocket tentative #$_retryCount → $uri');

    try {
      _canal = WebSocketChannel.connect(uri);
      _canal!.stream.listen(
        (message) {
          _retryCount = 0;
          onConnectionChanged?.call(true);
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            onDonnees?.call(data);
          } catch (e) {
            debugPrint('❌ Erreur parse WebSocket: $e');
          }
        },
        onError: (err) {
          debugPrint('⚠️ WebSocket erreur: $err');
          onConnectionChanged?.call(false);
          _scheduleReconnect(patientId);
        },
        onDone: () {
          debugPrint('🔌 WebSocket fermé');
          onConnectionChanged?.call(false);
          _scheduleReconnect(patientId);
        },
      );
    } catch (e) {
      debugPrint('❌ WebSocket connect failed: $e');
      _scheduleReconnect(patientId);
    }
  }

  void _scheduleReconnect(String patientId) {
    if (!_actif) return;
    if (_retryCount >= _maxRetries) {
      debugPrint('🛑 WebSocket: max retries atteint.');
      onConnectionChanged?.call(false);
      // AJOUT : ne pas bloquer définitivement — permet reconnexion manuelle
      // via reinitialiser() depuis l'UI
      return;
    }
    // Exponential backoff : 3s, 6s, 12s, 24s, 48s
    final delay = Duration(seconds: 3 * (1 << _retryCount));
    _retryCount++;
    debugPrint(
      '🔄 Reconnexion dans ${delay.inSeconds}s '
      '($_retryCount/$_maxRetries)...',
    );
    Future.delayed(delay, () {
      if (_actif) connecter(patientId);
    });
  }

  // AJOUT : réinitialiser le compteur et reconnecter manuellement
  // Appelé depuis l'UI quand l'utilisateur appuie sur "Reconnecter"
  void reinitialiser() {
    if (_patientId == null) return;
    debugPrint('🔄 WebSocket : réinitialisation manuelle');
    _retryCount = 0;
    connecter(_patientId!);
  }

  void deconnecter() {
    _actif = false;
    _retryCount = 0;
    _canal?.sink.close();
    _canal = null;
    onConnectionChanged?.call(false);
  }

  // AJOUT : état de connexion lisible depuis l'UI
  bool get estConnecte => _canal != null && _actif;
  bool get retryEpuise => _retryCount >= _maxRetries;
}
