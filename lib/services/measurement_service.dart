import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MeasurementService {
  MeasurementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ========== MEASUREMENTS ==========

  Stream<List<Map<String, dynamic>>> streamMeasurementRecords({
    required String uid,
    int limit = 50,
  }) {
    return _firestore
        .collection('measurements')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(
                (doc) => <String, dynamic>{...doc.data(), 'id': doc.id},
              ) // ← 'id' ajouté
              .toList();
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

  Future<List<Map<String, dynamic>>> getMeasurementRecords({
    required String uid,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('measurements')
          .where('uid', isEqualTo: uid)
          .get();

      final items = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

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
    } catch (e) {
      debugPrint('Erreur récupération mesures: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>?> getMeasurementById(String measurementId) async {
    try {
      final doc = await _firestore
          .collection('measurements')
          .doc(measurementId)
          .get();
      debugPrint('📄 getMeasurementById($measurementId) exists=${doc.exists}');
      if (!doc.exists) return null;
      return <String, dynamic>{...?doc.data(), 'id': doc.id};
    } catch (e) {
      debugPrint('❌ getMeasurementById error: $e');
      rethrow; // ← remonte l'erreur → FutureBuilder.hasError → message d'erreur affiché
    }
  }

  Future<String> saveMonitoringSession({
    required String uid,
    required DateTime startTime,
    required DateTime endTime,
    required double averageHeartRate,
    required double averageSpo2,
  }) async {
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final score = _computeSleepScore(
      averageSpo2: averageSpo2,
      averageHeartRate: averageHeartRate,
    );
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
      'apneas': 0,
    });
    return ref.id; // ← retourner l'ID
  }

  Future<DateTime?> getPatientLastMeasurementTimestamp(
    String patientUid,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('measurements')
          .where('uid', isEqualTo: patientUid)
          .get();

      if (snapshot.docs.isEmpty) return null;

      DateTime? latest;
      for (final doc in snapshot.docs) {
        final current = _extractDateTime(doc.data()['timestamp']);
        if (current != null && (latest == null || current.isAfter(latest))) {
          latest = current;
        }
      }

      return latest;
    } catch (e) {
      debugPrint('Erreur dernière mesure patient: $e');
      return null;
    }
  }

  // ========== HELPERS ==========

  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int _computeSleepScore({
    required double averageSpo2,
    required double averageHeartRate,
  }) {
    var score = 100;
    if (averageSpo2 < 92) {
      score -= 25;
    } else if (averageSpo2 < 95) {
      score -= 10;
    }

    if (averageHeartRate < 45 || averageHeartRate > 100) {
      score -= 15;
    }

    return score.clamp(0, 100).toInt();
  }
}
