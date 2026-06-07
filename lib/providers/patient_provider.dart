// Imports de base Flutter
import 'package:flutter/foundation.dart';

// Modele de donnees Patient
import 'package:apnea_project/models/patient.dart';
// Service de gestion des utilisateurs et patients dans Firestore
import 'package:apnea_project/services/user_service.dart';
// Service de gestion des notes medicales et diagnostics
import 'package:apnea_project/services/note_service.dart';

// Provider de gestion des patients
// Gere l'ajout de patients, la creation de comptes, l'assignation a des medecins, et l'enregistrement des diagnostics
class PatientProvider extends ChangeNotifier {
  // Constructeur avec injection de dependances pour les services (utile pour les tests)
  PatientProvider({UserService? userService, NoteService? noteService})
    : _userService = userService ?? UserService(),
      _noteService = noteService ?? NoteService();

  // Services pour acceder aux donnees et effectuer des operations
  // Service de gestion des utilisateurs et patients Firestore
  final UserService _userService;
  // Service de gestion des notes medicales et diagnostics
  final NoteService _noteService;

  // Indicateur d'une operation de sauvegarde en cours
  bool _isSaving = false;
  // Message d'erreur de la derniere operation (null si pas d'erreur)
  String? _error;

  // Verifie si une operation de sauvegarde est actuellement en cours
  bool get isSaving => _isSaving;
  // Retourne le dernier message d'erreur (null si aucune erreur)
  String? get error => _error;

  // Ajoute un patient simple (fiche sans compte Firebase Auth)
  // Utile pour creer des fiches patients manuellement sans authentification
  Future<bool> addPatient(Patient patient) async {
    // Active l'indicateur de sauvegarde et reinitialise l'erreur
    _isSaving = true;
    _error = null;
    notifyListeners(); // Notifie les ecoutants du changement d'etat
    try {
      // Appelle le service pour ajouter le patient a Firestore
      await _userService.addPatient(patient);
      return true; // Succes
    } catch (e) {
      // Capture et mappe l'erreur
      _error = _mapError(e);
      return false; // Echec
    } finally {
      // Desactive l'indicateur de sauvegarde peu importe le resultat
      _isSaving = false;
      notifyListeners();
    }
  }

  // Cree un patient avec un compte Firebase Auth (avec email/password)
  // Le patient peut se connecter avec ses identifiants et sera assigne au medecin
  Future<String?> createPatientAccount({
    required String email, // Email du patient (login)
    required String password, // Mot de passe pour l'authentification Firebase
    required String doctorUid, // UID du medecin qui gere ce patient
    required Patient patient, // Donnees du patient
  }) async {
    // Active l'indicateur de sauvegarde
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      // Prepare les donnees du patient pour Firestore
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
      // Appelle le service pour creer le compte Firebase et Firestore
      // Retourne l'ID du patient cree ou null en cas d'erreur
      return await _userService.createPatientAccount(
        email: email,
        password: password,
        doctorUid: doctorUid,
        patientData: patientData,
      );
    } catch (e) {
      // Mappe et stocke le message d'erreur
      _error = _mapError(e);
      return null;
    } finally {
      // Desactive l'indicateur de sauvegarde
      _isSaving = false;
      notifyListeners();
    }
  }

  // Assigne un patient existant a un medecin en utilisant son email
  // Utile pour lier un patient deja inscrit a un nouveau medecin
  Future<String?> assignPatientByEmail({
    required String email, // Email du patient a assigner
    required String
    doctorUid, // UID du medecin qui prendra en charge ce patient
  }) async {
    // Active l'indicateur de sauvegarde
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      // Appelle le service pour assigner le patient au medecin
      // Retourne l'ID du patient assigne
      return await _userService.assignPatientByEmail(
        email: email,
        doctorUid: doctorUid,
      );
    } catch (e) {
      // Mappe et stocke le message d'erreur
      _error = _mapError(e);
      return _error;
    } finally {
      // Desactive l'indicateur de sauvegarde
      _isSaving = false;
      notifyListeners();
    }
  }

  // Sauvegarde un diagnostic ou une note medicale du medecin pour un patient
  // Enregistre la note, le diagnostic et la mesure associee
  Future<bool> saveDiagnosis({
    required String patientId, // ID du patient
    required String doctorUid, // UID du medecin auteur du diagnostic
    required String doctorName, // Nom du medecin (pour la trace)
    required String note, // Note medicale detaillee
    String? diagnosis, // Diagnostic identifie (optionnel)
    String? measurementId, // ID de la mesure associee (optionnel)
  }) async {
    try {
      // Appelle le service pour enregistrer la note medicale
      await _noteService.saveDoctorNote(
        patientId: patientId,
        doctorUid: doctorUid,
        doctorName: doctorName,
        note: note,
        diagnosis: diagnosis,
        measurementId: measurementId,
      );
      return true; // Succes
    } catch (e) {
      // Mappe et stocke le message d'erreur
      _error = _mapError(e);
      return false; // Echec
    }
  }

  // Genere un nouvel ID de document pour une collection Firestore
  // Delegue au service d'utilisateur pour creer un ID unique
  String newDocumentId(String collection) =>
      _userService.newDocumentId(collection);

  // Mappe les exceptions en messages d'erreur francais lisibles pour l'utilisateur
  // Traduit les codes d'erreur Firebase et Firestore
  String _mapError(Object e) {
    final msg = e.toString();
    // Erreur de permission Firestore
    if (msg.contains('permission-denied'))
      return 'Permission refusee. Verifiez votre session.';
    // Document ou collection deja existant
    if (msg.contains('already-exists'))
      return 'Un patient avec cet identifiant existe deja.';
    // Email deja utilise pour un compte
    if (msg.contains('email-already-in-use'))
      return 'Cet email est deja utilise par un autre compte.';
    // Mot de passe qui ne respecte pas les criteres de securite
    if (msg.contains('weak-password'))
      return 'Mot de passe trop faible (6 caracteres minimum).';
    // Erreur de connexion reseau
    if (msg.contains('network-request-failed'))
      return 'Erreur reseau. Verifiez votre connexion.';
    // Erreur generique
    return 'Erreur : $msg';
  }
}
