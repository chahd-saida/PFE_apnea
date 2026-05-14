import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AlertSeverity { info, warning, critical }

class AlertThresholds {
  static const double spo2Critical = 90.0;
  static const double spo2Warning = 94.0;
  static const double heartRateLow = 45.0;
  static const double heartRateHigh = 100.0;
  static const double tempHigh = 38.0;
  static const int apneaEventsCritical = 5;
  static const int apneaEventsWarning = 3;
}

class AlertService {
  AlertService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> checkAndCreateAlerts({
    required String patientId,
    required double avgSpo2,
    required double avgHeartRate,
    required int apneaEvents,
    String? assignedDoctorId,
  }) async {
    final alerts = <Map<String, dynamic>>[];

    if (avgSpo2 < AlertThresholds.spo2Critical) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'spo2',
        'message':
            'SpO₂ critique: ${avgSpo2.toStringAsFixed(1)}% (seuil: ${AlertThresholds.spo2Critical}%)',
        'value': avgSpo2,
        'threshold': AlertThresholds.spo2Critical,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    } else if (avgSpo2 < AlertThresholds.spo2Warning) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'spo2',
        'message':
            'SpO₂ faible: ${avgSpo2.toStringAsFixed(1)}% (seuil: ${AlertThresholds.spo2Warning}%)',
        'value': avgSpo2,
        'threshold': AlertThresholds.spo2Warning,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    }

    if (avgHeartRate < AlertThresholds.heartRateLow) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'heartRate',
        'message':
            'Bradycardie: ${avgHeartRate.toStringAsFixed(0)} BPM (seuil: ${AlertThresholds.heartRateLow} BPM)',
        'value': avgHeartRate,
        'threshold': AlertThresholds.heartRateLow,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    } else if (avgHeartRate > AlertThresholds.heartRateHigh) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'heartRate',
        'message':
            'Tachycardie: ${avgHeartRate.toStringAsFixed(0)} BPM (seuil: ${AlertThresholds.heartRateHigh} BPM)',
        'value': avgHeartRate,
        'threshold': AlertThresholds.heartRateHigh,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    }

    if (apneaEvents >= AlertThresholds.apneaEventsCritical) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'apnea',
        'message':
            'Apnées multiples: $apneaEvents événements (seuil: ${AlertThresholds.apneaEventsCritical})',
        'value': apneaEvents.toDouble(),
        'threshold': AlertThresholds.apneaEventsCritical.toDouble(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    } else if (apneaEvents >= AlertThresholds.apneaEventsWarning) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'apnea',
        'message':
            'Événements apnée: $apneaEvents (seuil: ${AlertThresholds.apneaEventsWarning})',
        'value': apneaEvents.toDouble(),
        'threshold': AlertThresholds.apneaEventsWarning.toDouble(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': ?assignedDoctorId,
        'assignedDoctorId': ?assignedDoctorId,
      });
    }

    for (final alert in alerts) {
      try {
        await createAlertWithData(alert);
      } catch (e) {
        debugPrint('Erreur création alerte: $e');
      }
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({'read': true});
    } catch (e) {
      debugPrint('Erreur marquage alerte lue: $e');
    }
  }

  Future<void> markAllAlertsAsRead(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Erreur marquage toutes alertes lues: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
    } catch (e) {
      debugPrint('Erreur suppression alerte: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamPatientAlerts(String patientId) {
    return _firestore
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getPatientAlerts(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('Erreur récupération alertes: $e');
      return [];
    }
  }

  Future<void> createAlert({
    required String patientId,
    required String severity,
    required String message,
  }) async {
    try {
      await _firestore.collection('alerts').add({
        'patientId': patientId,
        'severity': severity,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Erreur création alerte: $e');
      rethrow;
    }
  }

  Future<void> createAlertWithData(Map<String, dynamic> alertData) async {
    try {
      await _firestore.collection('alerts').add(alertData);
    } catch (e) {
      debugPrint('Erreur création alerte: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAlertsStream(String patientId) {
    return _firestore
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> streamDoctorAlerts(String doctorUid) {
    final query = _firestore
        .collection('alerts')
        .where('doctorUid', isEqualTo: doctorUid)
        .orderBy('createdAt', descending: true)
        .limit(100);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList(),
    );
  }

  String getSeverityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'Critique';
      case 'warning':
        return 'Avertissement';
      default:
        return 'Information';
    }
  }

  String getAlertTypeLabel(String type) {
    switch (type) {
      case 'spo2':
        return 'SpO₂';
      case 'heartRate':
        return 'Fréquence cardiaque';
      case 'apnea':
        return 'Apnée';
      case 'temperature':
        return 'Température';
      default:
        return 'Autre';
    }
  }
}
