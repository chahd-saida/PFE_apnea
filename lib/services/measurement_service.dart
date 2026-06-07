import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service responsable de la gestion des mesures de santé (fréquence cardiaque, SpO2, etc.)
/// Permet de récupérer, sauvegarder et streamer les données de mesures depuis Firebase Firestore
class MeasurementService {
  /// Constructeur avec injection optionnelle de Firestore (utile pour les tests)
  MeasurementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instance de Firestore pour accéder à la base de données
  final FirebaseFirestore _firestore;

  // ========== MEASUREMENTS ==========

  /// Stream en temps réel des mesures d'un patient
  /// Retourne les mesures triées par date décroissante (plus récentes d'abord)
  /// Paramètres:
  ///   - uid: identifiant unique du patient
  ///   - limit: nombre maximum de mesures à retourner (par défaut 50)
  Stream<List<Map<String, dynamic>>> streamMeasurementRecords({
    required String uid,
    int limit = 50,
  }) {
    return _firestore
        .collection('measurements')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          // Convertir les documents Firestore en maps et ajouter l'ID du document
          final items = snapshot.docs
              .map(
                (doc) => <String, dynamic>{...doc.data(), 'id': doc.id},
              ) // ← 'id' ajouté
              .toList();
          // Trier les mesures par date décroissante (plus récentes en premier)
          items.sort((a, b) {
            final at = _extractDateTime(a['timestamp']);
            final bt = _extractDateTime(b['timestamp']);
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });
          if (items.length > limit) return items.sublist(0, limit);
          return items;
        });
  }

  /// Récupère les mesures d'un patient de manière asynchrone (une seule fois)
  /// Retourne les mesures triées par date décroissante
  /// Paramètres:
  ///   - uid: identifiant unique du patient
  ///   - limit: nombre maximum de mesures à retourner (par défaut 50)
  Future<List<Map<String, dynamic>>> getMeasurementRecords({
    required String uid,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('measurements')
          .where('uid', isEqualTo: uid)
          .get();

      // Convertir les documents en maps avec l'ID du document
      final items = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

      // Trier les mesures par date décroissante
      items.sort((a, b) {
        final at = _extractDateTime(a['timestamp']);
        final bt = _extractDateTime(b['timestamp']);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      // Limiter le nombre de résultats retournés
      if (items.length > limit) return items.sublist(0, limit);
      return items;
    } catch (e) {
      // En cas d'erreur, afficher le message d'erreur et retourner une liste vide
      debugPrint('Erreur récupération mesures: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Récupère une mesure spécifique par son ID
  /// Retourne null si la mesure n'existe pas
  /// Paramètre:
  ///   - measurementId: identifiant unique de la mesure
  Future<Map<String, dynamic>?> getMeasurementById(String measurementId) async {
    try {
      final doc = await _firestore
          .collection('measurements')
          .doc(measurementId)
          .get();
      // Afficher un message de debug pour suivre la récupération
      debugPrint('📄 getMeasurementById($measurementId) exists=${doc.exists}');
      if (!doc.exists) return null;
      // Retourner les données du document avec son ID
      return <String, dynamic>{...?doc.data(), 'id': doc.id};
    } catch (e) {
      // Afficher l'erreur et la remonter pour que le FutureBuilder l'affiche
      debugPrint('❌ getMeasurementById error: $e');
      rethrow; // ← remonte l'erreur → FutureBuilder.hasError → message d'erreur affiché
    }
  }

  /// Sauvegarde une session de monitoring (mesure) dans la base de données
  /// Calcule automatiquement le score de sommeil basé sur les paramètres de santé
  /// Retourne l'ID du document créé
  /// Paramètres:
  ///   - uid: identifiant du patient
  ///   - startTime: heure de début de la mesure
  ///   - endTime: heure de fin de la mesure
  ///   - averageHeartRate: fréquence cardiaque moyenne
  ///   - averageSpo2: saturation en oxygène moyenne
  ///   - apneas: nombre d'apnées détectées
  Future<String> saveMonitoringSession({
    required String uid,
    required DateTime startTime,
    required DateTime endTime,
    required double averageHeartRate,
    required double averageSpo2,
    int apneas = 0,
  }) async {
    // Calculer la durée de la session en minutes
    final durationMinutes = endTime.difference(startTime).inMinutes;
    // Calculer le score de qualité de sommeil
    final score = _computeSleepScore(
      averageSpo2: averageSpo2,
      averageHeartRate: averageHeartRate,
      apneas: apneas,
    );
    // Ajouter la mesure à Firestore avec tous les paramètres de santé
    final ref = await _firestore.collection('measurements').add({
      'uid': uid,
      'timestamp': Timestamp.fromDate(endTime),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'avgHeartRate': averageHeartRate,
      'avgSpo2': averageSpo2,
      'heartRate': averageHeartRate.round(),
      'spo2': averageSpo2.round(),
      'score': score,
      'apneas': apneas,
    });
    return ref.id; // ← retourner l'ID
  }


Future<void> updateApneaCount(String measurementId, int apneas) async {
  await _firestore
      .collection('measurements')
      .doc(measurementId)
      .update({'apneas': apneas});
}

  /// Récupère la date/heure de la dernière mesure d'un patient
  /// Utile pour déterminer quand le patient a effectué sa dernière mesure
  /// Paramètre:
  ///   - patientUid: identifiant unique du patient
  Future<DateTime?> getPatientLastMeasurementTimestamp(
    String patientUid,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('measurements')
          .where('uid', isEqualTo: patientUid)
          .get();

      // Retourner null si aucune mesure trouvée
      if (snapshot.docs.isEmpty) return null;

      // Chercher la date la plus récente parmi les mesures
      DateTime? latest;
      for (final doc in snapshot.docs) {
        final current = _extractDateTime(doc.data()['timestamp']);
        if (current != null && (latest == null || current.isAfter(latest))) {
          latest = current;
        }
      }

      return latest;
    } catch (e) {
      // En cas d'erreur, afficher le message et retourner null
      debugPrint('Erreur dernière mesure patient: $e');
      return null;
    }
  }

  // ========== HELPERS ==========

  /// Convertit divers formats de date/heure en objet DateTime
  /// Accepte: Timestamp Firestore, DateTime, String au format ISO 8601
  /// Retourne null si la conversion échoue
  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Calcule un score de qualité de sommeil (0-100) basé sur les paramètres de santé
  /// Formule:
  ///   - Score de base: 100
  ///   - Pénalités pour SpO2: -25 si < 92%, -10 si < 95%
  ///   - Pénalités pour fréquence cardiaque: -15 si hors intervalle [45, 100]
  ///   - Pénalités pour apnées: dégressives selon le nombre d'apnées détectées
  int _computeSleepScore({
    required double averageSpo2,
    required double averageHeartRate,
    int apneas = 0,
  }) {
    // Initialiser le score de base
    var score = 100;

    // Évaluer la saturation en oxygène (SpO2)
    if (averageSpo2 < 92) {
      score -= 25; // Critique: SpO2 très basse
    } else if (averageSpo2 < 95) {
      score -= 10; // Alerte: SpO2 légèrement basse
    }

    // Évaluer la fréquence cardiaque
    if (averageHeartRate < 45 || averageHeartRate > 100) {
      score -= 15; // Anormale: fréquence cardiaque hors intervalle normal
    }

    // Évaluer le nombre d'apnées détectées (pénalités dégressives)
    if (apneas >= 10)
      score -= 30; // Critique: beaucoup d'apnées
    else if (apneas >= 5)
      score -= 20; // Grave: plusieurs apnées
    else if (apneas >= 3)
      score -= 10; // Modéré: quelques apnées
    else if (apneas >= 1)
      score -= 5; // Léger: une ou deux apnées

    // Retourner le score en s'assurant qu'il reste entre 0 et 100
    return score.clamp(0, 100).toInt();
  }
}
