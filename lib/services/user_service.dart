import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apnea_project/models/patient.dart';

class UserService {
  UserService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ========== FIRESTORE ==========

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

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return <String, dynamic>{...data, 'uid': doc.id};
    });
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
}
