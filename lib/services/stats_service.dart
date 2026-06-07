/// Service de calcul des statistiques de santé pour un patient
/// Aggrège les données des mesures individuelles en statistiques globales
/// Fournit des indicateurs moyens et totaux pour l'affichage et l'analyse
class StatsService {
  /// Constructeur simple (pas d'initialisation complexe nécessaire)
  StatsService();

  // ========== STATISTIQUES ==========

  /// Calcule les statistiques agrégées d'un patient sur ses 30 dernières mesures
  ///
  /// Paramètres:
  ///   - uid: identifiant unique du patient
  ///   - getMeasurementRecords: fonction callback pour récupérer les mesures
  ///       (injection de dépendance pour faciliter les tests)
  ///
  /// Retourne: Map avec les statistiques:
  ///   - totalSessions: nombre de mesures (0-30)
  ///   - avgScore: score de qualité de sommeil moyen (0-100), arrondi
  ///   - avgSpo2: saturation en oxygène moyenne (%), 1 décimale
  ///   - avgHeartRate: fréquence cardiaque moyenne (bpm), arrondie
  ///   - totalApneas: nombre total d'apnées détectées
  ///   - lastSession: date/heure de la dernière mesure
  ///
  /// Cas limites:
  ///   - Si aucune mesure: retourne des zéros et lastSession=null
  ///   - Gère les valeurs manquantes (null) en les traitant comme 0
  ///   - Gère les champs avec noms alternatifs (spo2 vs avgSpo2, etc.)
  Future<Map<String, dynamic>> getPatientStats(
    String uid, {
    required Future<List<Map<String, dynamic>>> Function({
      required String uid,
      int limit,
    })
    getMeasurementRecords,
  }) async {
    // Récupérer les 30 dernières mesures du patient
    final records = await getMeasurementRecords(uid: uid, limit: 30);

    // Cas d'aucune mesure: retourner des statistiques vides
    if (records.isEmpty) {
      return {
        'totalSessions': 0,
        'avgScore': 0, // Score de sommeil par défaut
        'avgSpo2': 0, // SpO2 par défaut
        'avgHeartRate': 0, // FC par défaut
        'totalApneas': 0, // Pas d'apnées
        'lastSession': null, // Pas de mesure
      };
    }

    // Accumulateurs pour calculer les moyennes
    double totalScore = 0; // Somme des scores
    double totalSpo2 = 0; // Somme des SpO2
    double totalHR = 0; // Somme des fréquences cardiaques
    int totalApneas = 0; // Total des apnées

    // Itérer sur toutes les mesures pour accumuler les valeurs
    for (final r in records) {
      // Ajouter le score (0 par défaut si absent)
      totalScore += (r['score'] as num?)?.toDouble() ?? 0;

      // Ajouter SpO2 (accepter 'avgSpo2' ou 'spo2', 0 par défaut)
      totalSpo2 += (r['avgSpo2'] ?? r['spo2'] as num?)?.toDouble() ?? 0;

      // Ajouter FC (accepter 'avgHeartRate' ou 'heartRate', 0 par défaut)
      totalHR += (r['avgHeartRate'] ?? r['heartRate'] as num?)?.toDouble() ?? 0;

      // Ajouter les apnées (0 par défaut si absent)
      totalApneas += (r['apneas'] as num?)?.toInt() ?? 0;
    }

    // Calculer le nombre de mesures
    final count = records.length;

    // Retourner les statistiques calculées
    return {
      'totalSessions': count, // Nombre de mesures
      'avgScore': (totalScore / count).round(), // Score moyen arrondi
      'avgSpo2': (totalSpo2 / count).toStringAsFixed(
        1,
      ), // SpO2 moyenne (1 décimale)
      'avgHeartRate': (totalHR / count).round(), // FC moyenne arrondie
      'totalApneas': totalApneas, // Total des apnées
      'lastSession':
          records.first['timestamp'], // Timestamp de la dernière mesure
    };
  }
}
