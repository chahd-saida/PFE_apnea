import 'package:flutter/foundation.dart';

import 'package:apnea_project/models/patient.dart';
import 'package:apnea_project/services/firebase_service.dart';

class PatientProvider extends ChangeNotifier {
  PatientProvider({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  // ── Ajouter patient (fiche simple, sans compte Auth) ──────────────────────
  Future<bool> addPatient(Patient patient) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _firebaseService.addPatient(patient);
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Créer patient + compte Auth (Cas 2) ───────────────────────────────────
  Future<String?> createPatientAccount({
    required String email,
    required String password,
    required String doctorUid,
    required Patient patient,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final patientData = {
        'firstName': patient.prenom,
        'lastName': patient.nom,
        'fullName': patient.fullName,
        'age': patient.age,
        'dateOfBirth': patient.dateNaissance?.toIso8601String(),
        'gender': patient.sexe,
        'phone': patient.telephone,
        'medicalNotes': patient.notesMedicales,
      };
      // doctorUid passé séparément → sera forcé dans FirebaseService
      return await _firebaseService.createPatientAccount(
        email: email,
        password: password,
        doctorUid: doctorUid,
        patientData: patientData,
      );
    } catch (e) {
      _error = _mapError(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Sauvegarder diagnostic médecin ────────────────────────────────────────
  Future<bool> saveDiagnosis({
    required String patientId,
    required String doctorUid,
    required String doctorName,
    required String note,
    String? diagnosis,
    String? measurementId,
  }) async {
    try {
      await _firebaseService.saveDoctorNote(
        patientId: patientId,
        doctorUid: doctorUid,
        doctorName: doctorName,
        note: note,
        diagnosis: diagnosis,
        measurementId: measurementId,
      );
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    }
  }

  String newDocumentId(String collection) =>
      _firebaseService.newDocumentId(collection);

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied'))
      return 'Permission refusée. Vérifiez votre session.';
    if (msg.contains('already-exists'))
      return 'Un patient avec cet identifiant existe déjà.';
    if (msg.contains('email-already-in-use'))
      return 'Cet email est déjà utilisé par un autre compte.';
    if (msg.contains('weak-password'))
      return 'Mot de passe trop faible (6 caractères minimum).';
    if (msg.contains('network-request-failed'))
      return 'Erreur réseau. Vérifiez votre connexion.';
    return 'Erreur : $msg';
  }
}
