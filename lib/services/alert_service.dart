// lib/services/alert_service.dart
//
// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE ALERTES — AlertService
// ═══════════════════════════════════════════════════════════════════════════════
//
// Rôle : Création, lecture, suppression et streaming des alertes médicales.
//
// CORRECTIONS APPORTÉES :
//   1. createAlert()          → doctorUid récupéré automatiquement depuis Firestore
//                               si non fourni en paramètre. Le champ est TOUJOURS
//                               présent dans le document (jamais null/absent).
//   2. checkAndCreateAlerts() → syntaxe '?assignedDoctorId' corrigée en
//                               'assignedDoctorId ?? '''. Firestore refuse les
//                               valeurs null dans un Map lors de l'ajout.
//   3. streamDoctorAlerts()   → suppression de .orderBy() pour éviter l'index
//                               composite Firestore. Le tri est fait côté client.
//   4. createAlertWithData()  → ajout d'une normalisation des champs avant écriture
//                               pour garantir que doctorUid est toujours une String.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─── Sévérité des alertes ─────────────────────────────────────────────────────
enum AlertSeverity { info, warning, critical }

// ─── Seuils de déclenchement des alertes ─────────────────────────────────────
class AlertThresholds {
  static const double spo2Critical = 90.0; // SpO₂ critique
  static const double spo2Warning = 94.0; // SpO₂ faible
  static const double heartRateLow = 45.0; // Bradycardie
  static const double heartRateHigh = 100.0; // Tachycardie
  static const double tempHigh = 38.0; // Fièvre
  static const int apneaEventsCritical = 5; // Apnées critiques
  static const int apneaEventsWarning = 3; // Apnées avertissement
}

// ─── Service principal ────────────────────────────────────────────────────────
class AlertService {
  AlertService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — Création d'alertes
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crée une alerte simple pour un patient.
  ///
  /// CORRECTION : Le champ [doctorUid] est maintenant automatiquement récupéré
  /// depuis le profil Firestore du patient si non fourni. Cela garantit que le
  /// médecin assigné verra toujours l'alerte dans son dashboard.
  ///
  /// Paramètres :
  ///   - [patientId]  : UID du patient concerné
  ///   - [severity]   : 'critical', 'warning' ou 'info'
  ///   - [message]    : texte descriptif de l'alerte
  ///   - [type]       : type d'alerte (ex: 'spo2', 'heartRate', 'apnea', 'temperature')
  ///   - [doctorUid]  : UID du médecin (optionnel — récupéré automatiquement si absent)
  Future<void> createAlert({
    required String patientId,
    required String severity,
    required String message,
    String type = 'general',
    String? doctorUid,
  }) async {
    try {
      // ── FIX 1 : Récupérer le doctorUid depuis le profil patient si non fourni ──
      // Sans ce bloc, les alertes créées sans doctorUid explicite sont
      // invisibles dans le dashboard médecin (filtre .where('doctorUid', ...) vide).
      String resolvedDoctorUid = doctorUid ?? '';

      if (resolvedDoctorUid.isEmpty) {
        final userDoc = await _firestore
            .collection('users')
            .doc(patientId)
            .get();

        final data = userDoc.data();
        resolvedDoctorUid =
            (data?['assignedDoctorId'] as String?)?.trim() ??
            (data?['doctorUid'] as String?)?.trim() ??
            '';

        debugPrint(
          '[AlertService] doctorUid résolu depuis profil patient: '
          '"$resolvedDoctorUid"',
        );
      }

      // ── Écriture dans Firestore ──────────────────────────────────────────
      await _firestore.collection('alerts').add({
        'patientId': patientId,
        'severity': severity,
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        // FIX : toujours une String (jamais null) pour que le filtre
        // .where('doctorUid', isEqualTo: uid) fonctionne côté médecin.
        'doctorUid': resolvedDoctorUid,
        'assignedDoctorId': resolvedDoctorUid,
      });

      debugPrint(
        '[AlertService] Alerte créée — patient: $patientId | '
        'sévérité: $severity | doctorUid: $resolvedDoctorUid',
      );
    } catch (e) {
      debugPrint('[AlertService] ❌ Erreur création alerte: $e');
      rethrow;
    }
  }

  /// Crée une alerte à partir d'un Map déjà construit.
  ///
  /// CORRECTION : Normalise le champ 'doctorUid' avant l'écriture pour s'assurer
  /// qu'il n'est jamais null (Firestore accepte null mais la requête .where() ne
  /// le retrouvera pas).
  Future<void> createAlertWithData(Map<String, dynamic> alertData) async {
    try {
      // ── FIX 2 : Normaliser doctorUid — null → '' ─────────────────────────
      // La syntaxe '?assignedDoctorId' utilisée dans l'ancienne version était
      // invalide en Dart. Elle écrivait null dans Firestore, ce qui rendait
      // l'alerte introuvable via .where('doctorUid', isEqualTo: uid).
      final normalized = Map<String, dynamic>.from(alertData);

      normalized['doctorUid'] =
          (normalized['doctorUid'] as String?)?.trim() ??
          (normalized['assignedDoctorId'] as String?)?.trim() ??
          '';

      normalized['assignedDoctorId'] = normalized['doctorUid'];

      await _firestore.collection('alerts').add(normalized);

      debugPrint(
        '[AlertService] Alerte enrichie créée — '
        'doctorUid: ${normalized['doctorUid']}',
      );
    } catch (e) {
      debugPrint('[AlertService] ❌ Erreur création alerte enrichie: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — Analyse et génération automatique d'alertes
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyse les métriques d'une session de sommeil et crée les alertes
  /// correspondantes si les seuils sont dépassés.
  ///
  /// CORRECTION : La syntaxe '?assignedDoctorId' (invalide en Dart) a été
  /// remplacée par 'assignedDoctorId ?? ""'. Toutes les alertes générées
  /// contiennent maintenant un 'doctorUid' valide.
  ///
  /// Paramètres :
  ///   - [patientId]        : UID du patient
  ///   - [avgSpo2]          : saturation moyenne en oxygène (%)
  ///   - [avgHeartRate]     : fréquence cardiaque moyenne (BPM)
  ///   - [apneaEvents]      : nombre d'événements d'apnée détectés
  ///   - [assignedDoctorId] : UID du médecin assigné au patient
  Future<void> checkAndCreateAlerts({
    required String patientId,
    required double avgSpo2,
    required double avgHeartRate,
    required int apneaEvents,
    String? assignedDoctorId,
  }) async {
    // ── FIX 3 : Résoudre le doctorUid en amont ────────────────────────────
    // Si assignedDoctorId est null ici, on tente de le récupérer depuis le
    // profil Firestore du patient. Évite d'écrire '' systématiquement si le
    // patient a bien un médecin enregistré en base.
    String resolvedDoctor = assignedDoctorId?.trim() ?? '';

    if (resolvedDoctor.isEmpty) {
      try {
        final doc = await _firestore.collection('users').doc(patientId).get();
        final d = doc.data();
        resolvedDoctor =
            (d?['assignedDoctorId'] as String?)?.trim() ??
            (d?['doctorUid'] as String?)?.trim() ??
            '';
      } catch (_) {
        // Échec silencieux — l'alerte sera créée sans médecin assigné
      }
    }

    final alerts = <Map<String, dynamic>>[];

    // ── SpO₂ ─────────────────────────────────────────────────────────────
    if (avgSpo2 < AlertThresholds.spo2Critical) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'spo2',
        'message':
            'SpO₂ critique : ${avgSpo2.toStringAsFixed(1)}% '
            '(seuil : ${AlertThresholds.spo2Critical}%)',
        'value': avgSpo2,
        'threshold': AlertThresholds.spo2Critical,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        // FIX : '' au lieu de null (l'ancienne syntaxe ?assignedDoctorId
        // produisait null → alerte jamais visible chez le médecin)
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    } else if (avgSpo2 < AlertThresholds.spo2Warning) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'spo2',
        'message':
            'SpO₂ faible : ${avgSpo2.toStringAsFixed(1)}% '
            '(seuil : ${AlertThresholds.spo2Warning}%)',
        'value': avgSpo2,
        'threshold': AlertThresholds.spo2Warning,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    }

    // ── Fréquence cardiaque ───────────────────────────────────────────────
    if (avgHeartRate < AlertThresholds.heartRateLow) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'heartRate',
        'message':
            'Bradycardie : ${avgHeartRate.toStringAsFixed(0)} BPM '
            '(seuil : ${AlertThresholds.heartRateLow} BPM)',
        'value': avgHeartRate,
        'threshold': AlertThresholds.heartRateLow,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    } else if (avgHeartRate > AlertThresholds.heartRateHigh) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'heartRate',
        'message':
            'Tachycardie : ${avgHeartRate.toStringAsFixed(0)} BPM '
            '(seuil : ${AlertThresholds.heartRateHigh} BPM)',
        'value': avgHeartRate,
        'threshold': AlertThresholds.heartRateHigh,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    }

    // ── Apnées ────────────────────────────────────────────────────────────
    if (apneaEvents >= AlertThresholds.apneaEventsCritical) {
      alerts.add({
        'patientId': patientId,
        'severity': 'critical',
        'type': 'apnea',
        'message':
            'Apnées multiples : $apneaEvents événements '
            '(seuil : ${AlertThresholds.apneaEventsCritical})',
        'value': apneaEvents.toDouble(),
        'threshold': AlertThresholds.apneaEventsCritical.toDouble(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    } else if (apneaEvents >= AlertThresholds.apneaEventsWarning) {
      alerts.add({
        'patientId': patientId,
        'severity': 'warning',
        'type': 'apnea',
        'message':
            'Événements apnée : $apneaEvents '
            '(seuil : ${AlertThresholds.apneaEventsWarning})',
        'value': apneaEvents.toDouble(),
        'threshold': AlertThresholds.apneaEventsWarning.toDouble(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'doctorUid': resolvedDoctor,
        'assignedDoctorId': resolvedDoctor,
      });
    }

    // ── Écriture dans Firestore ───────────────────────────────────────────
    for (final alert in alerts) {
      try {
        await createAlertWithData(alert);
      } catch (e) {
        debugPrint('[AlertService] ❌ Erreur création alerte batch: $e');
      }
    }

    debugPrint(
      '[AlertService] checkAndCreateAlerts → ${alerts.length} alerte(s) créée(s) '
      '| doctorUid: $resolvedDoctor',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — Lecture et streaming des alertes
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream temps réel des alertes destinées à un médecin spécifique.
  ///
  /// CORRECTION : Suppression de .orderBy('createdAt', descending: true) qui
  /// nécessitait un index composite Firestore (doctorUid + createdAt) et
  /// causait une erreur 'failed-precondition' si l'index n'existait pas.
  /// Le tri est maintenant effectué côté client.
  Stream<List<Map<String, dynamic>>> streamDoctorAlerts(String doctorUid) {
    return _firestore
        .collection('alerts')
        .where('doctorUid', isEqualTo: doctorUid)
        // ── FIX 4 : PAS de .orderBy ici pour éviter l'index composite ────
        // L'index composite (doctorUid ASC + createdAt DESC) doit être créé
        // manuellement dans Firebase Console si vous voulez le remettre.
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();

          // Tri décroissant côté client (plus récent en premier)
          list.sort((a, b) {
            final at = _toDateTime(a['createdAt']);
            final bt = _toDateTime(b['createdAt']);
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          return list;
        });
  }

  /// Stream temps réel des alertes d'un patient spécifique.
  /// Utilisé côté patient pour afficher ses propres alertes.
  Stream<List<Map<String, dynamic>>> streamPatientAlerts(String patientId) {
    return _firestore
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        // Pas de .orderBy → pas d'index composite nécessaire
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();

          // Tri décroissant côté client
          list.sort((a, b) {
            final at = _toDateTime(a['createdAt']);
            final bt = _toDateTime(b['createdAt']);
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          return list;
        });
  }

  /// Ancienne méthode — retourne un QuerySnapshot brut.
  /// Préférer [streamPatientAlerts] pour un Stream typé.
  Stream<QuerySnapshot> getAlertsStream(String patientId) {
    return _firestore
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        .snapshots();
  }

  /// Récupère les alertes d'un patient (lecture unique, pas de stream).
  Future<List<Map<String, dynamic>>> getPatientAlerts(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .get();

      final list = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

      list.sort((a, b) {
        final at = _toDateTime(a['createdAt']);
        final bt = _toDateTime(b['createdAt']);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      return list;
    } catch (e) {
      debugPrint('[AlertService] ❌ Erreur récupération alertes patient: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — Mise à jour et suppression
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marque une alerte comme lue.
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({'read': true});
    } catch (e) {
      debugPrint('[AlertService] ❌ Erreur marquage alerte lue: $e');
    }
  }

  /// Marque toutes les alertes non lues d'un patient comme lues.
  /// Utilise un batch pour optimiser les writes Firestore.
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
      debugPrint('[AlertService] ❌ Erreur marquage toutes alertes lues: $e');
    }
  }

  /// Supprime une alerte par son ID.
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
    } catch (e) {
      debugPrint('[AlertService] ❌ Erreur suppression alerte: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5 — Utilitaires (labels et conversion de dates)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convertit un label de sévérité en texte lisible.
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

  /// Convertit un type d'alerte en label lisible.
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

  /// Convertit différents formats de date en [DateTime].
  /// Gère : Timestamp Firestore, DateTime natif, String ISO 8601.
  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
