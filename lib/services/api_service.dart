// lib/services/api_service.dart
// Client HTTP vers FastAPI backend (192.168.1.18:8000)
// Complémente WebSocketService (temps réel) et FirebaseService (cloud)
// Utilisé pour : historique SQLite, résultats IA, alertes locales, santé serveur

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://192.168.1.18:8000';
  static const Duration _timeout = Duration(seconds: 10);

  // ── Singleton ────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Headers communs ───────────────────────────────────────────────────────
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── GET /health — vérifier que le serveur est en ligne ───────────────────
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: _headers)
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ ApiService.checkHealth: $e');
      return false;
    }
  }

  // ── GET /api/historique/{patient_id} — mesures SQLite ────────────────────
  Future<List<Map<String, dynamic>>> getHistoriqueMesures({
    required String patientId,
    int limite = 100,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/historique/$patientId?limite=$limite',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('⚠️ historique: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getHistoriqueMesures: $e');
      return [];
    }
  }

  // ── GET /api/resultats_ia/{patient_id} — résultats MoteurIA v4 ───────────
  Future<List<Map<String, dynamic>>> getResultatsIA({
    required String patientId,
    int limite = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/resultats_ia/$patientId?limite=$limite',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('⚠️ resultats_ia: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getResultatsIA: $e');
      return [];
    }
  }

  // ── GET /api/alarmes/{patient_id} — alarmes SQLite ────────────────────────
  Future<List<Map<String, dynamic>>> getAlarmes({
    required String patientId,
    int limite = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/alarmes/$patientId?limite=$limite',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('⚠️ alarmes: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getAlarmes: $e');
      return [];
    }
  }

  // ── POST /chatbot/chat — chatbot IA via FastAPI ───────────────────────────
  Future<String?> sendChatMessage({
    required String message,
    required String role,
    required List<Map<String, String>> historique,
    String? patientId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chatbot/chat'),
            headers: _headers,
            body: jsonEncode({
              'message':    message,
              'role':       role,
              'historique': historique,
              'patient_id': patientId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reponse'] as String?;
      }
      debugPrint('⚠️ chatbot: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.sendChatMessage: $e');
      return null;
    }
  }

  // ── GET /api/statistiques/{patient_id} — stats globales ──────────────────
  Future<Map<String, dynamic>?> getStatistiques(String patientId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/statistiques/$patientId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.getStatistiques: $e');
      return null;
    }
  }
}