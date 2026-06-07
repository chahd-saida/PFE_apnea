import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apnea_project/models/patient.dart';

/// Service de gestion des utilisateurs (patients et médecins).
/// Responsable de l'authentification, la création de comptes patients,
/// l'assignation de patients aux médecins, et la récupération des profils utilisateur.
/// Utilise Firebase Authentication et Firestore pour les opérations de persistance.
class UserService {
  /// Constructeur du service utilisateur.
  /// Accepte des instances optionnelles de FirebaseAuth et Firestore pour faciliter les tests.
  /// Utilise les singletons par défaut si aucune instance n'est fournie.
  UserService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instance Firebase Authentication pour la gestion de l'authentification des utilisateurs.
  final FirebaseAuth _auth;

  /// Instance Cloud Firestore pour les opérations de base de données (lecture/écriture).
  final FirebaseFirestore _firestore;

  // ========== OPÉRATIONS FIRESTORE ==========

  /// Récupère le rôle d'un utilisateur (patient ou médecin) à partir de son UID.
  /// Cherche d'abord dans les données Firestore, puis résout le rôle avec flexibilité
  /// sur les noms de champs pour supporter différentes structures de documents.
  /// Retourne: Le rôle ('patient' ou 'doctor') ou null si non trouvé ou erreur.
  Future<String?> getUserRole(String uid) async {
    try {
      // Récupérer le document utilisateur de Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      // Résoudre le rôle avec flexibilité sur le nom du champ
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

  /// Résout le rôle utilisateur en cherchant dans plusieurs champs possibles.
  /// Supporte les variations de noms de champs (role, userRole, accountType, type)
  /// pour maximiser la compatibilité avec différentes structures de données.
  /// Normalise la valeur en minuscules et valide qu'elle est 'patient' ou 'doctor'.
  String? _resolveRoleFromProfile(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Liste de champs alternatifs pour le rôle (flexibilité sur la structure)
    final candidates = <dynamic>[
      data['role'],
      data['userRole'],
      data['accountType'],
      data['type'],
    ];

    // Parcourir les candidats et retourner le premier rôle valide trouvé
    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        // Normaliser en minuscules pour comparaison insensible à la casse
        final normalized = candidate.trim().toLowerCase();
        if (normalized == 'doctor' || normalized == 'patient') {
          return normalized;
        }
      }
    }

    return null;
  }

  /// Récupère le profil complet d'un utilisateur depuis Firestore.
  /// Retourne: Un dictionnaire contenant toutes les données de profil, ou null en cas d'erreur.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      // Récupérer le document utilisateur de la collection 'users'
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Erreur récupération profil: $e');
      return null;
    }
  }

  /// Génère un nouvel ID de document unique pour une collection Firestore.
  /// Utilisé pour préallouer des IDs avant de créer les documents.
  /// Paramètre: collectionPath - Le chemin de la collection (ex: 'users', 'measurements')
  /// Retourne: Une chaîne ID unique générée par Firestore.
  String newDocumentId(String collectionPath) {
    // Générer un ID en créant un document de référence (sans persister)
    return _firestore.collection(collectionPath).doc().id;
  }

  /// Ajoute un nouveau patient à Firestore avec validation des permissions.
  /// Vérifie que: 1) Un médecin est connecté, 2) Le patient a un doctorUid,
  /// 3) Le patient est assigné au médecin actuellement connecté, 4) Le patient n'existe pas déjà.
  /// Paramètre: patient - L'objet Patient à ajouter (doit avoir doctorUid défini).
  /// Lève: FirebaseAuthException si médecin non authentifié, ou FirebaseException pour autres erreurs.
  Future<void> addPatient(Patient patient) async {
    try {
      // Vérifier qu'un médecin est connecté
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Utilisateur non authentifié.',
        );
      }

      // Vérifier que le patient a un doctorUid défini
      if (patient.doctorUid == null || patient.doctorUid!.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'doctorUid manquant pour le patient.',
        );
      }

      // Vérifier que le patient est assigné au médecin connecté (sécurité)
      if (patient.doctorUid != currentUser.uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Le patient doit être rattaché au médecin connecté.',
        );
      }

      // Vérifier que le patient n'existe pas déjà
      final ref = _firestore.collection('users').doc(patient.id);
      final existing = await ref.get();
      if (existing.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'Un utilisateur avec cet identifiant existe déjà.',
        );
      }

      // Ajouter le patient à Firestore
      await ref.set(patient.toFirestore());
    } catch (e) {
      debugPrint('Erreur ajout patient: $e');
      rethrow;
    }
  }

  /// Crée un nouveau compte patient avec authentification Firebase séparée.
  /// Utilise une app Firebase secondaire pour créer l'utilisateur sans déconnecter le médecin.
  /// Paramètres:
  ///   - email: Adresse email du patient
  ///   - password: Mot de passe du compte patient
  ///   - doctorUid: UID du médecin assigné au patient
  ///   - patientData: Dictionnaire contenant les données du profil patient
  /// Retourne: L'UID du patient créé (utilisé pour la connexion ultérieure).
  /// Lève: FirebaseAuthException si le médecin n'est pas authentifié.
  Future<String> createPatientAccount({
    required String email,
    required String password,
    required String doctorUid,
    required Map<String, dynamic> patientData,
  }) async {
    // Vérifier que le médecin est authentifié
    final currentDoctor = _auth.currentUser;
    if (currentDoctor == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Médecin non authentifié.',
      );
    }

    // ── Récupérer le nom du médecin AVANT de créer l'app secondaire ──
    // Cela ensures que doctorName est disponible même si l'app secondaire est créée ensuite
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

    // Créer une app Firebase secondaire pour l'authentification du patient
    // Évite de déconnecter le médecin actuellement connecté
    final secondaryApp = await Firebase.initializeApp(
      name: 'patient_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      // Obtenir une instance Auth séparée pour cette app secondaire
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Créer le compte utilisateur patient dans Firebase Auth
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final patientUid = cred.user!.uid;

      // Écrire les données du patient dans Firestore avec doctorUid et doctorName garantis
      await _firestore.collection('users').doc(patientUid).set({
        // Données de base du patient
        'uid': patientUid,
        'email': email.trim(),
        'role': 'patient', // Toujours en minuscules pour cohérence
        'fullName': patientData['fullName'] ?? '',
        'firstName': patientData['firstName'] ?? '',
        'lastName': patientData['lastName'] ?? '',
        'age': patientData['age'],
        'dateOfBirth': patientData['dateOfBirth'],
        'gender': patientData['gender'],
        'phone': patientData['phone'],
        'medicalNotes': patientData['medicalNotes'],
        // Assignation médecin - toujours présents et non nuls
        'doctorUid':
            doctorUid, // Utilisé par streamDoctorPatients() pour filtrer
        'doctorName': doctorName, // Utilisé pour l'affichage dans les profils
        // Métadonnées de création
        'createdByDoctor': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '✅ Patient $patientUid créé → doctorUid=$doctorUid, doctorName=$doctorName',
      );
      // Déconnecter l'authentification secondaire
      await secondaryAuth.signOut();
      return patientUid;
    } catch (e) {
      debugPrint('❌ Erreur createPatientAccount: $e');
      rethrow;
    } finally {
      // Nettoyer l'app secondaire (obligatoire)
      await secondaryApp.delete();
    }
  }

  /// Assigne un patient existant (par email) à un médecin.
  /// Cherche le patient par email, vérifie qu'il n'est pas déjà assigné à un autre médecin,
  /// puis met à jour son doctorUid et doctorName.
  /// Paramètres:
  ///   - email: L'adresse email du patient à assigner
  ///   - doctorUid: L'UID du médecin qui doit être assigné au patient
  /// Retourne: null si succès, ou une chaîne de message d'erreur en cas d'échec.
  Future<String?> assignPatientByEmail({
    required String email,
    required String doctorUid,
  }) async {
    try {
      // Chercher le patient par email
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('role', isEqualTo: 'patient')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Aucun patient trouvé avec cet email.';
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Vérifier que le patient n'est pas déjà assigné à un AUTRE médecin
      final existingDoctorUid = data['doctorUid'] as String?;
      if (existingDoctorUid != null &&
          existingDoctorUid.isNotEmpty &&
          existingDoctorUid != doctorUid) {
        return 'Ce patient est déjà assigné à un autre médecin.';
      }

      // Récupérer le nom du médecin pour mise à jour dans le profil patient
      String doctorName = 'Médecin';
      try {
        final doctorDoc = await _firestore
            .collection('users')
            .doc(doctorUid)
            .get();
        final name = (doctorDoc.data()?['fullName'] as String?)?.trim();
        if (name != null && name.isNotEmpty) doctorName = name;
      } catch (_) {}

      // Mettre à jour le document patient avec l'assignation du médecin
      await _firestore.collection('users').doc(doc.id).update({
        'doctorUid': doctorUid,
        'doctorName': doctorName,
      });

      // Retourner null pour indiquer le succès
      return null;
    } catch (e) {
      debugPrint('Erreur assignPatientByEmail: $e');
      return 'Erreur : $e';
    }
  }

  /// Met à jour le profil d'un utilisateur dans Firestore.
  /// Paramètres:
  ///   - uid: L'UID de l'utilisateur dont le profil doit être mis à jour
  ///   - data: Dictionnaire contenant les champs à mettre à jour
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      // Mettre à jour (fusion) les champs fournis dans le document utilisateur
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Erreur mise à jour profil: $e');
      rethrow;
    }
  }

  /// Récupère la liste des médecins disponibles, optionnellement filtrée par recherche.
  /// Paramètre: search - Chaîne de recherche optionnelle pour filtrer par nom complet du médecin.
  /// Retourne: Liste de dictionnaires contenant les profils des médecins trouvés.
  Future<List<Map<String, dynamic>>> getDoctors({String? search}) async {
    try {
      // Récupérer tous les documents des utilisateurs avec le rôle 'doctor'
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      // Transformer les documents en dictionnaires avec l'UID inclus
      final doctors = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'uid': doc.id})
          .toList();

      // Si aucune recherche n'est spécifiée, retourner tous les médecins
      if (search == null || search.trim().isEmpty) {
        return doctors;
      }

      // Filtrer les médecins par nom (recherche insensible à la casse)
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

  /// Diffuse en temps réel les mises à jour du profil d'un utilisateur.
  /// Paramètre: uid - L'UID de l'utilisateur à surveiller.
  /// Retourne: Un stream qui émet des dictionnaires contenant les données mises à jour, ou null si l'utilisateur n'existe pas.
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    // Retourner le stream Firestore en transformant les documents
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      // Inclure l'UID dans le dictionnaire pour complétude
      return <String, dynamic>{...data, 'uid': doc.id};
    });
  }

  /// Diffuse en temps réel la liste des patients assignés à un médecin.
  /// Écoute les changements Firestore et met à jour la liste automatiquement.
  /// Paramètre: doctorUid - L'UID du médecin dont on veut les patients.
  /// Retourne: Un stream qui émet une liste des patients du médecin, mise à jour en temps réel.
  Stream<List<Map<String, dynamic>>> streamDoctorPatients(String doctorUid) {
    // Construire la requête pour récupérer les patients d'un médecin spécifique
    final primaryQuery = _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .where('doctorUid', isEqualTo: doctorUid);

    // Transformer les snapshots Firestore en listes de dictionnaires
    return primaryQuery.snapshots().map((snapshot) {
      // Transformer chaque document en dictionnaire avec son UID
      final patients = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'uid': doc.id})
          .toList();

      // Retourner la liste (vide si aucun patient trouvé)
      if (patients.isNotEmpty) return patients;
      return <Map<String, dynamic>>[];
    });
  }
}
