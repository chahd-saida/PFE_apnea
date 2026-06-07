// lib/services/api_service.dart
// Import pour la gestion des operations asynchrones
import 'dart:async';
// Import pour l'encodage/decodage JSON
import 'dart:convert';
// Import Flutter foundation pour debugPrint
import 'package:flutter/foundation.dart';
// Import HTTP pour les requetes reseau vers le backend FastAPI
import 'package:http/http.dart' as http;

// Service API pour communiquer avec le backend FastAPI
// Implemente le pattern Singleton pour une instance unique
class ApiService {
  // URL de base du serveur FastAPI (backend)
  static const String _baseUrl = 'http://192.168.1.18:8000';
  //static const String _baseUrl = 'http://localhost:8000';
  // Timeout standard pour les requetes courtes (10 secondes)
  static const Duration _timeout = Duration(seconds: 10);
  // Timeout pour le chatbot (requetes plus longues, 30 secondes)
  static const Duration _timeoutChatbot = Duration(seconds: 30);
  // Timeout pour les analyses de nuit (requetes tres longues, 60 secondes)
  static const Duration _timeoutNuit = Duration(seconds: 60);

  // Instance singleton du service
  static final ApiService _instance = ApiService._internal();
  // Factory pour retourner l'instance unique
  factory ApiService() => _instance;
  // Constructeur prive pour le singleton
  ApiService._internal();

  // En-tetes HTTP standard pour toutes les requetes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ═══════════════════════════════════════════════════════════════
  // SANTÉ SERVEUR
  // ═══════════════════════════════════════════════════════════════

  // Verifie si le serveur FastAPI est accessible et en bonne sante
  // Effectue un GET vers l'endpoint /health
  // Retourne: true si le serveur repond avec le code 200, false sinon
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

  // Enregistre un nouveau patient dans le backend
  // Envoie les informations du patient a l'endpoint POST /api/patients
  // Parametre patientId: UID Firebase du patient
  // Parametre nom: Nom de famille du patient
  // Parametre prenom: Prenom du patient
  // Parametre dateNaissance: Date de naissance (format ISO, optionnel)
  // Parametre telephone: Numero de telephone (optionnel)
  // Parametre medecinId: UID du medecin assigné (optionnel)
  // Retourne: true si enregistrement reussi, false sinon
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

  // Recupere les informations d'un patient depuis le backend
  // Effectue un GET vers /api/patients/{patientId}
  // Parametre patientId: UID Firebase du patient
  // Retourne: Map contenant les donnees du patient, ou null en cas d'erreur
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

  // Recupere la liste de tous les patients enregistres
  // Effectue un GET vers /api/patients
  // Retourne: Liste des patients (vide si aucun ou erreur)
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

  // POST /api/config/patient_id
  // Envoie l'UID Firebase au serveur pour que l'ESP32 soit configure
  // Le serveur publie l'UID sur MQTT → l'ESP32 met a jour son patientId dynamiquement
  // Parametre uid: UID Firebase du patient
  // Retourne: true si UID envoye avec succes, false sinon
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

  // Recupere l'historique des mesures d'un patient depuis la base de donnees SQLite
  // Effectue un GET vers /api/historique/{patientId}
  // Parametre patientId: UID du patient
  // Parametre limite: Nombre maximum de mesures a retourner (par defaut 100)
  // Retourne: Liste des mesures triees (vide si aucune ou erreur)
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

  // Recupere les resultats d'analyse IA pour un patient
  // Les resultats incluent les diagnostics et predictions du modele IA
  // Effectue un GET vers /api/resultats_ia/{patientId}
  // Parametre patientId: UID du patient
  // Parametre limite: Nombre maximum de resultats a retourner (par defaut 50)
  // Retourne: Liste des resultats IA (vide si aucun ou erreur)
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

  // Recupere les alarmes declenchees pour un patient
  // Les alarmes representent des depassements de seuils detectes
  // Effectue un GET vers /api/alarmes/{patientId}
  // Parametre patientId: UID du patient
  // Parametre limite: Nombre maximum d'alarmes a retourner (par defaut 50)
  // Retourne: Liste des alarmes (vide si aucune ou erreur)
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

  // Recupere les statistiques aggregees pour un patient
  // Les statistiques incluent moyennes, medians, valeurs min/max, etc.
  // Effectue un GET vers /api/statistiques/{patientId}
  // Parametre patientId: UID du patient
  // Retourne: Map contenant les donnees statistiques, ou null en cas d'erreur
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

  // Envoie un message au chatbot IA et recoit une reponse
  // Le chatbot genere des reponses intelligentes basees sur le contexte medical
  // Effectue un POST vers /chatbot/chat avec timeout prolonge
  // Parametre message: Message de l'utilisateur
  // Parametre role: Role de l'utilisateur (doctor, patient)
  // Parametre historique: Historique de la conversation precedente
  // Parametre patientId: UID du patient (contexte, optionnel)
  // Retourne: Reponse du chatbot, ou null en cas d'erreur
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

  // Genere un resume IA des donnees de la nuit (resume_nuit)
  // Analyse les mesures de la nuit et produit un rapport structure
  // Effectue un POST vers /chatbot/resume_nuit avec timeout prolonge
  // Parametre donneesNuit: Dictionnaire contenant les donnees de la nuit
  // Parametre role: Role utilisateur pour contextualiser le resume (doctor par defaut)
  // Retourne: Map contenant le resume genere, ou null en cas d'erreur
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

  // Analyse les dernieres alarmes declenchees
  // Effectue un GET vers /chatbot/analyse_alarme
  // Retourne: Map contenant l'analyse des alarmes, ou null en cas d'erreur
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

  // Recupere le statut actuel du chatbot
  // Indique si le chatbot est disponible et ses capacites
  // Effectue un GET vers /chatbot/statut
  // Retourne: Map contenant les informations de statut, ou null en cas d'erreur
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

  // Recupere les cas critiques identifies par le chatbot IA
  // Les cas critiques sont des situations medicales qui demandent une attention immediate
  // Effectue un GET vers /chatbot/cas_critiques avec timeout prolonge
  // Retourne: Map contenant les cas critiques identifies, ou null en cas d'erreur
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

  // Effectue une analyse detaillee de la nuit d'un patient
  // Genere un rapport complet avec tendances, anomalies et recommandations
  // Effectue un GET vers /chatbot/analyse_nuit/{patientId} avec timeout tres prolonge
  // Parametre patientId: UID du patient a analyser
  // Retourne: Map contenant l'analyse complete de la nuit, ou null en cas d'erreur
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
