// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://192.168.1.18:8000';
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _timeoutChatbot = Duration(seconds: 30);
  static const Duration _timeoutNuit = Duration(seconds: 60);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ═══════════════════════════════════════════════════════════════
  // SANTÉ SERVEUR
  // ═══════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════
  // PATIENTS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> enregistrerPatient({
    required String patientId,
    required String nom,
    required String prenom,
    String dateNaissance = '',
    String telephone = '',
    String medecinId = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/patients'),
            headers: _headers,
            body: jsonEncode({
              'patient_id': patientId,
              'nom': nom,
              'prenom': prenom,
              'date_naissance': dateNaissance,
              'telephone': telephone,
              'medecin_id': medecinId,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        debugPrint('✅ Patient enregistré : $prenom $nom');
        return true;
      }
      debugPrint('⚠️ enregistrerPatient: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('⚠️ ApiService.enregistrerPatient (non bloquant): $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getInfosPatient(String patientId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/patients/$patientId'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.getInfosPatient: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTousPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/patients'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getTousPatients: $e');
      return [];
    }
  }

  // ── POST /api/config/patient_id ───────────────────────────────
  // AJOUT : publie l'UID Firebase sur MQTT → l'ESP32 met à jour
  // son patientId dynamiquement via moniteur/config/patient_id
  Future<bool> envoyerUidEsp32(String uid) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/config/patient_id'),
            headers: _headers,
            body: jsonEncode({'patient_id': uid}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        debugPrint('✅ UID ESP32 envoyé : $uid');
        return true;
      }
      debugPrint('⚠️ envoyerUidEsp32: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('⚠️ ApiService.envoyerUidEsp32 (non bloquant): $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DONNÉES CAPTEURS — HISTORIQUE SQLITE
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getHistoriqueMesures({
    required String patientId,
    int limite = 100,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/historique/$patientId?limite=$limite'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getHistoriqueMesures: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getResultatsIA({
    required String patientId,
    int limite = 50,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/resultats_ia/$patientId?limite=$limite'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getResultatsIA: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAlarmes({
    required String patientId,
    int limite = 50,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/alarmes/$patientId?limite=$limite'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ ApiService.getAlarmes: $e');
      return [];
    }
  }

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

  // ═══════════════════════════════════════════════════════════════
  // CHATBOT
  // ═══════════════════════════════════════════════════════════════

  Future<String?> sendChatMessage({
    required String message,
    required String role,
    required List<Map<String, String>> historique,
    String? patientId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chatbot/chat'),
          headers: _headers,
          body: jsonEncode({
            'message': message,
            'role': role,
            'historique': historique,
            'patient_id': patientId,
          }),
        )
        .timeout(_timeoutChatbot);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['reponse'] as String?;
    }
    debugPrint('⚠️ chatbot: ${response.statusCode} — ${response.body}');
    return null;
  }

  Future<Map<String, dynamic>?> resumeNuit({
    required Map<String, dynamic> donneesNuit,
    String role = 'doctor',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chatbot/resume_nuit?role=$role'),
            headers: _headers,
            body: jsonEncode(donneesNuit),
          )
          .timeout(_timeoutChatbot);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.resumeNuit: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyseAlarme() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/chatbot/analyse_alarme'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.analyseAlarme: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> statutChatbot() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/chatbot/statut'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.statutChatbot: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCasCritiques() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/chatbot/cas_critiques'), headers: _headers)
          .timeout(_timeoutChatbot);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.getCasCritiques: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyseNuit(String patientId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/chatbot/analyse_nuit/$patientId'),
            headers: _headers,
          )
          .timeout(_timeoutNuit);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.analyseNuit: $e');
      return null;
    }
  }
}
