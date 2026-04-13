import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ========== AUTHENTIFICATION ==========

  /// Enregistrer un nouvel utilisateur
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

  /// Connexion utilisateur
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

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtenir l'utilisateur actuel
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Enregistrer un utilisateur avec un profil plus complet.
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? profileImageUrl,
    String? specialization,
    String? medicalLicenseNumber,
    String? yearsOfExperience,
    String? clinicName,
  }) async {
    final credential = await signUp(
      email: email.trim(),
      password: password,
      userRole: role,
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
    } catch (_) {
      // Ignore profile update errors to avoid breaking registration flow.
    }

    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'email': email.trim(),
          'fullName': fullName.trim(),
          'role': role,
          'dateOfBirth': dateOfBirth?.trim(),
          'phone': phone?.trim(),
          'gender': gender,
          'specialization': specialization?.trim(),
          'medicalLicenseNumber': medicalLicenseNumber?.trim(),
          'yearsOfExperience': yearsOfExperience?.trim(),
          'clinicName': clinicName?.trim(),
          'profileImageUrl':
              (trimmedProfileImageUrl != null &&
                  trimmedProfileImageUrl.isNotEmpty)
              ? trimmedProfileImageUrl
              : null,
          'createdAt': DateTime.now(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        // Keep Auth and Firestore consistent: rollback Auth user if profile write fails.
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
    if (data == null) {
      return null;
    }

    final candidates = <dynamic>[
      data['role'],
      data['userRole'],
      data['accountType'],
      data['type'],
    ];

    for (final candidate in candidates) {
      if (candidate is String) {
        final normalized = candidate.trim().toLowerCase();
        if (normalized == 'doctor' || normalized == 'patient') {
          return normalized;
        }
      }
    }

    return null;
  }

  // ========== FIRESTORE ==========

  /// Récupérer le profil utilisateur
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Erreur récupération profil: $e');
      return null;
    }
  }

  /// Mettre à jour le profil utilisateur
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

  /// Récupérer les alertes des patients
  Future<List<Map<String, dynamic>>> getPatientAlerts(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Erreur récupération alertes: $e');
      return [];
    }
  }

  /// Créer une nouvelle alerte
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
        'timestamp': DateTime.now(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Erreur création alerte: $e');
      rethrow;
    }
  }

  /// Stream real-time des alertes
  Stream<QuerySnapshot> getAlertsStream(String patientId) {
    return _firestore
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
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
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();
          items.sort((a, b) {
            final at = _extractDateTime(a['timestamp']);
            final bt = _extractDateTime(b['timestamp']);
            if (at == null && bt == null) {
              return 0;
            }
            if (at == null) {
              return 1;
            }
            if (bt == null) {
              return -1;
            }
            return bt.compareTo(at);
          });
          if (items.length > limit) {
            return items.sublist(0, limit);
          }
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
        if (at == null && bt == null) {
          return 0;
        }
        if (at == null) {
          return 1;
        }
        if (bt == null) {
          return -1;
        }
        return bt.compareTo(at);
      });

      if (items.length > limit) {
        return items.sublist(0, limit);
      }

      return items;
    } catch (e) {
      debugPrint('Erreur récupération mesures: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveMonitoringSession({
    required String uid,
    required DateTime startTime,
    required DateTime endTime,
    required double averageHeartRate,
    required double averageSpo2,
  }) async {
    final durationMinutes = endTime.difference(startTime).inMinutes;
    await _firestore.collection('measurements').add({
      'uid': uid,
      'timestamp': endTime,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'avgHeartRate': averageHeartRate,
      'avgSpo2': averageSpo2,
      'heartRate': averageHeartRate.round(),
      'spo2': averageSpo2.round(),
      'score': _computeSleepScore(
        averageSpo2: averageSpo2,
        averageHeartRate: averageHeartRate,
      ),
      'apneas': 0,
    });
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

      if (patients.isNotEmpty) {
        return patients;
      }

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

      if (snapshot.docs.isEmpty) {
        return null;
      }

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

  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
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
