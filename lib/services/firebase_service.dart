import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apnea_project/models/patient.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ========== AUTHENTIFICATION ==========

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String userRole,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur inscription: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur connexion: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? profileImageUrl,
  }) async {
    // Normalize role to lowercase to ensure consistency
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'doctor' && normalizedRole != 'patient') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Le rôle doit être "doctor" ou "patient".',
      );
    }

    final credential = await signUp(
      email: email.trim(),
      password: password,
      userRole: normalizedRole,
    );

    final user = credential.user;
    final uid = user?.uid;
    final trimmedProfileImageUrl = profileImageUrl?.trim();

    try {
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        if (trimmedProfileImageUrl != null &&
            trimmedProfileImageUrl.isNotEmpty) {
          await user.updatePhotoURL(trimmedProfileImageUrl);
        }
      }
    } catch (_) {}

    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'email': email.trim(),
          'fullName': fullName.trim(),
          'role': normalizedRole,
          'dateOfBirth': dateOfBirth?.trim(),
          'phone': phone?.trim(),
          'gender': gender,
          'profileImageUrl':
              (trimmedProfileImageUrl != null &&
                  trimmedProfileImageUrl.isNotEmpty)
              ? trimmedProfileImageUrl
              : null,
          'createdAt': DateTime.now(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        try {
          await user?.delete();
        } catch (_) {}
        rethrow;
      }
    }

    return credential;
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final resolved = _resolveRoleFromProfile(data);
      if (resolved != null) {
        return resolved;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur récupération rôle: $e');
      return null;
    }
  }

  String? _resolveRoleFromProfile(Map<String, dynamic>? data) {
    if (data == null) return null;

    final candidates = <dynamic>[
      data['role'],
      data['userRole'],
      data['accountType'],
      data['type'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        final normalized = candidate.trim().toLowerCase();
        if (normalized == 'doctor' || normalized == 'patient') {
          return normalized;
        }
      }
    }

    return null;
  }

  // ========== FIRESTORE ==========

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Erreur récupération profil: $e');
      return null;
    }
  }

  String newDocumentId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  Future<void> addPatient(Patient patient) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Utilisateur non authentifié.',
        );
      }

      if (patient.doctorUid == null || patient.doctorUid!.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'doctorUid manquant pour le patient.',
        );
      }

      if (patient.doctorUid != currentUser.uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Le patient doit être rattaché au médecin connecté.',
        );
      }

      final ref = _firestore.collection('users').doc(patient.id);
      final existing = await ref.get();
      if (existing.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'Un utilisateur avec cet identifiant existe déjà.',
        );
      }

      await ref.set(patient.toFirestore());
    } catch (e) {
      debugPrint('Erreur ajout patient: $e');
      rethrow;
    }
  }

  Future<String> createPatientAccount({
    required String email,
    required String password,
    required String doctorUid,
    required Map<String, dynamic> patientData,
  }) async {
    final currentDoctor = _auth.currentUser;
    if (currentDoctor == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Médecin non authentifié.',
      );
    }

    // ── Récupérer le nom du médecin AVANT de créer l'app secondaire ──
    String doctorName = 'Médecin';
    try {
      final doctorDoc = await _firestore
          .collection('users')
          .doc(doctorUid)
          .get();
      final name = (doctorDoc.data()?['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        doctorName = name;
      }
    } catch (e) {
      debugPrint('⚠️ Impossible de récupérer le nom du médecin: $e');
    }

    debugPrint(
      '🔵 Création patient → doctorUid=$doctorUid, doctorName=$doctorName',
    );

    final secondaryApp = await Firebase.initializeApp(
      name: 'patient_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final patientUid = cred.user!.uid;

      // ── Écrire Firestore avec doctorUid ET doctorName garantis ──
      await _firestore.collection('users').doc(patientUid).set({
        // Données du patient
        'uid': patientUid,
        'email': email.trim(),
        'role': 'patient', // Always lowercase
        'fullName': patientData['fullName'] ?? '',
        'firstName': patientData['firstName'] ?? '',
        'lastName': patientData['lastName'] ?? '',
        'age': patientData['age'],
        'dateOfBirth': patientData['dateOfBirth'],
        'gender': patientData['gender'],
        'phone': patientData['phone'],
        'medicalNotes': patientData['medicalNotes'],
        // ── Assignation médecin — toujours présents et non nuls ──
        'doctorUid': doctorUid, // ← pour streamDoctorPatients()
        'doctorName': doctorName, // ← pour l'affichage dans les profils
        // ── Métadonnées ──
        'createdByDoctor': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '✅ Patient $patientUid créé → doctorUid=$doctorUid, doctorName=$doctorName',
      );
      await secondaryAuth.signOut();
      return patientUid;
    } catch (e) {
      debugPrint('❌ Erreur createPatientAccount: $e');
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Erreur mise à jour profil: $e');
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Aucun utilisateur connecté.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Email utilisateur indisponible.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<List<Map<String, dynamic>>> getDoctors({String? search}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      final doctors = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'uid': doc.id})
          .toList();

      if (search == null || search.trim().isEmpty) {
        return doctors;
      }

      final query = search.trim().toLowerCase();
      return doctors.where((doctor) {
        final name = doctor['fullName'];
        if (name is String) {
          return name.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    } catch (e) {
      debugPrint('Erreur récupération médecins: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // ========== ALERTS ==========

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

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return <String, dynamic>{...data, 'uid': doc.id};
    });
  }

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

  Stream<List<Map<String, dynamic>>> streamDoctorPatients(String doctorUid) {
    final primaryQuery = _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .where('doctorUid', isEqualTo: doctorUid);

    return primaryQuery.snapshots().map((snapshot) {
      final patients = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'uid': doc.id})
          .toList();

      if (patients.isNotEmpty) return patients;
      return <Map<String, dynamic>>[];
    });
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

  // ========== MESSAGING ==========

  Stream<List<Map<String, dynamic>>> streamConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<String> getOrCreateConversation({
    required String doctorUid,
    required String patientUid,
  }) async {
    final query = await _firestore
        .collection('conversations')
        .where('doctorUid', isEqualTo: doctorUid)
        .where('patientUid', isEqualTo: patientUid)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final doctorDoc = await _firestore.collection('users').doc(doctorUid).get();
    final patientDoc = await _firestore
        .collection('users')
        .doc(patientUid)
        .get();

    final doctorName =
        (doctorDoc.data()?['fullName'] as String?)?.trim() ?? 'Médecin';
    final patientName =
        (patientDoc.data()?['fullName'] as String?)?.trim() ?? 'Patient';

    final ref = await _firestore.collection('conversations').add({
      'doctorUid': doctorUid,
      'patientUid': patientUid,
      'participants': [doctorUid, patientUid],
      'doctorName': doctorName,
      'patientName': patientName,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final convRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': text.trim().length > 60
          ? '${text.trim().substring(0, 60)}...'
          : text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ========== NOTES / DIAGNOSIS ==========

  Future<void> saveDoctorNote({
    required String patientId,
    required String doctorUid,
    required String doctorName,
    required String note,
    String? measurementId,
    String? diagnosis,
  }) async {
    await _firestore.collection('notes').add({
      'patientId': patientId,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'note': note.trim(),
      'diagnosis': diagnosis?.trim(),
      'measurementId': measurementId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamPatientNotes(String patientId) {
    return _firestore
        .collection('notes')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getPatientNotes(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('Erreur récupération notes: $e');
      return [];
    }
  }

  // ========== STATISTICS ==========

  Future<Map<String, dynamic>> getPatientStats(String uid) async {
    final records = await getMeasurementRecords(uid: uid, limit: 30);
    if (records.isEmpty) {
      return {
        'totalSessions': 0,
        'avgScore': 0,
        'avgSpo2': 0,
        'avgHeartRate': 0,
        'totalApneas': 0,
        'lastSession': null,
      };
    }

    double totalScore = 0;
    double totalSpo2 = 0;
    double totalHR = 0;
    int totalApneas = 0;

    for (final r in records) {
      totalScore += (r['score'] as num?)?.toDouble() ?? 0;
      totalSpo2 += (r['avgSpo2'] ?? r['spo2'] as num?)?.toDouble() ?? 0;
      totalHR += (r['avgHeartRate'] ?? r['heartRate'] as num?)?.toDouble() ?? 0;
      totalApneas += (r['apneas'] as num?)?.toInt() ?? 0;
    }

    final count = records.length;
    return {
      'totalSessions': count,
      'avgScore': (totalScore / count).round(),
      'avgSpo2': (totalSpo2 / count).toStringAsFixed(1),
      'avgHeartRate': (totalHR / count).round(),
      'totalApneas': totalApneas,
      'lastSession': records.first['timestamp'],
    };
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
