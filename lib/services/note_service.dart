import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des notes médicales et diagnostics
/// Permet aux médecins de sauvegarder des notes et diagnostics liés aux mesures d'un patient
/// Fournit des méthodes pour consulter l'historique des notes d'un patient
class NoteService {
  /// Constructeur avec injection optionnelle de Firestore (utile pour les tests)
  NoteService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instance de Firestore pour accéder à la base de données
  final FirebaseFirestore _firestore;

  // ========== NOTES / DIAGNOSIS ==========

  /// Sauvegarde une note médicale écrite par un médecin pour un patient
  /// La note peut être optionnellement liée à une mesure spécifique et contenir un diagnostic
  /// Paramètres:
  ///   - patientId: identifiant du patient concerné
  ///   - doctorUid: identifiant unique du médecin auteur de la note
  ///   - doctorName: nom du médecin (pour affichage)
  ///   - note: contenu textuel de la note
  ///   - measurementId: (optionnel) identifiant d'une mesure associée
  ///   - diagnosis: (optionnel) diagnostic associé à la note
  Future<void> saveDoctorNote({
    required String patientId,
    required String doctorUid,
    required String doctorName,
    required String note,
    String? measurementId,
    String? diagnosis,
  }) async {
    // Ajouter la note à Firestore avec tous les métadonnées
    await _firestore.collection('notes').add({
      'patientId': patientId,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'note': note.trim(), // Supprimer les espaces inutiles
      'diagnosis': diagnosis?.trim(), // Diagnostic optionnel
      'measurementId': measurementId, // Lien vers une mesure (si applicable)
      'createdAt': FieldValue.serverTimestamp(), // Timestamp serveur Firestore
    });
  }

  /// Stream en temps réel des notes d'un patient
  /// Retourne les notes triées par date décroissante (les plus récentes en premier)
  /// Paramètre:
  ///   - patientId: identifiant unique du patient
  Stream<List<Map<String, dynamic>>> streamPatientNotes(String patientId) {
    return _firestore
        .collection('notes')
        .where('patientId', isEqualTo: patientId) // Filtrer par patient
        .orderBy('createdAt', descending: true) // Trier par date décroissante
        .snapshots() // Obtenir le stream en temps réel
        .map(
          // Convertir les documents en maps avec l'ID du document
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Récupère les notes d'un patient de manière asynchrone (une seule fois)
  /// Retourne les notes triées par date décroissante
  /// Retourne une liste vide en cas d'erreur pour éviter les crashes
  /// Paramètre:
  ///   - patientId: identifiant unique du patient
  Future<List<Map<String, dynamic>>> getPatientNotes(String patientId) async {
    try {
      // Récupérer tous les documents notes du patient
      final snapshot = await _firestore
          .collection('notes')
          .where('patientId', isEqualTo: patientId) // Filtrer par patient
          .orderBy('createdAt', descending: true) // Trier par date décroissante
          .get();

      // Convertir les documents en maps avec l'ID du document
      return snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      // En cas d'erreur, afficher le message et retourner une liste vide
      debugPrint('Erreur récupération notes: $e');
      return [];
    }
  }
}
