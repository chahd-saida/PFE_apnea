import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // ⚠️ Remplace par ton IP PC
  static const String ipServeur = '192.168.1.18';
  static const int port = 8000;

  WebSocketChannel? _canal;
  Function(Map<String, dynamic>)? onDonnees;
  bool _actif = false;

  void connecter(String patientId) {
    _actif = true;
    final uri = Uri.parse('ws://$ipServeur:$port/ws/$patientId');
    _canal = WebSocketChannel.connect(uri);

    _canal!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          onDonnees?.call(data);
        } catch (e) {
          debugPrint('Erreur parse WebSocket: $e');
        }
      },
      onError: (err) {
        debugPrint('WebSocket erreur: $err');
        if (_actif) {
          Future.delayed(Duration(seconds: 3), () => connecter(patientId));
        }
      },
      onDone: () {
        if (_actif) {
          Future.delayed(Duration(seconds: 3), () => connecter(patientId));
        }
      },
    );
    debugPrint('WebSocket connecté à ws://$ipServeur:$port/ws/$patientId');
  }

  void deconnecter() {
    _actif = false;
    _canal?.sink.close();
    _canal = null;
  }
}
