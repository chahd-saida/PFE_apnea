/// Importe le service d'authentification Firebase pour gérer les comptes utilisateur
import 'package:firebase_auth/firebase_auth.dart';

/// Importe Firestore pour la persistence des données utilisateur
import 'package:cloud_firestore/cloud_firestore.dart';

/// Importe Foundation pour accéder à debugPrint (logging en développement)
import 'package:flutter/foundation.dart';

/// Service d'authentification centralisé
/// Gère toutes les opérations d'authentification Firebase :
/// - Inscription d'utilisateurs
/// - Connexion et déconnexion
/// - Gestion des mots de passe
/// - Stockage des profils utilisateur dans Firestore
class AuthService {
  /// Constructeur avec injection de dépendances (permet le test unitaire)
  ///
  /// Paramètres:
  /// - [auth]: Instance Firebase Auth (défaut: FirebaseAuth.instance)
  /// - [firestore]: Instance Firestore (défaut: FirebaseFirestore.instance)
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instance Firebase Authentication - utilisée pour créer et gérer les comptes
  final FirebaseAuth _auth;

  /// Instance Firestore - utilisée pour stocker les profils utilisateur complets
  final FirebaseFirestore _firestore;

  // ========== AUTHENTIFICATION ==========

  /// Crée un compte utilisateur dans Firebase Authentication
  ///
  /// Cette méthode effectue UNIQUEMENT la création dans Firebase Auth.
  /// Pour une inscription complète, utilisez [registerUser] qui crée aussi le profil Firestore.
  ///
  /// Paramètres:
  /// - [email]: Adresse email unique de l'utilisateur
  /// - [password]: Mot de passe (au moins 6 caractères)
  /// - [userRole]: Rôle de l'utilisateur ('doctor' ou 'patient') - non utilisé ici, stocké dans Firestore
  ///
  /// Retour: [UserCredential] contenant l'UID et les informations de l'utilisateur créé
  ///
  /// Lève [FirebaseAuthException] si l'email existe déjà ou le mot de passe est faible
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String userRole,
  }) async {
    try {
      // Crée le compte dans Firebase Authentication
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Log l'erreur pour le développement
      debugPrint('Erreur inscription: ${e.message}');
      // Re-lève l'exception pour que l'appelant la gère
      rethrow;
    }
  }

  /// Authentifie un utilisateur existant avec email et mot de passe
  ///
  /// Paramètres:
  /// - [email]: Adresse email du compte
  /// - [password]: Mot de passe du compte
  ///
  /// Retour: [UserCredential] contenant l'UID et les informations de l'utilisateur authentifié
  ///
  /// Lève [FirebaseAuthException] si les identifiants sont invalides ou le compte n'existe pas
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Authentifie l'utilisateur avec Firebase
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Log l'erreur pour le développement
      debugPrint('Erreur connexion: ${e.message}');
      // Re-lève l'exception pour que l'appelant la gère
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur actuellement authentifié
  ///
  /// Supprime la session Firebase locale. L'utilisateur devra se reconnecter
  /// pour utiliser l'application.
  Future<void> signOut() async {
    // Supprime la session Firebase de l'appareil
    await _auth.signOut();
  }

  /// Récupère l'utilisateur actuellement authentifié
  ///
  /// Retour: [User] du Firebase Auth (null si aucun utilisateur n'est connecté)
  User? getCurrentUser() {
    // Retourne l'utilisateur actuel de Firebase Auth
    return _auth.currentUser;
  }

  /// Inscription complète : crée un compte Firebase + profil Firestore
  ///
  /// Effectue l'enregistrement complet d'un nouvel utilisateur :
  /// 1. Valide le rôle (doit être 'doctor' ou 'patient')
  /// 2. Crée le compte Firebase Auth
  /// 3. Définit le nom et la photo de profil Firebase
  /// 4. Crée le document profil complet dans Firestore
  ///
  /// Paramètres:
  /// - [email]: Adresse email unique
  /// - [password]: Mot de passe (au moins 6 caractères)
  /// - [role]: 'doctor' ou 'patient' (validé strictement)
  /// - [fullName]: Nom complet de l'utilisateur
  /// - [dateOfBirth]: Date de naissance (optionnel)
  /// - [phone]: Numéro de téléphone (optionnel)
  /// - [gender]: Genre (optionnel)
  /// - [profileImageUrl]: URL de la photo de profil (optionnel)
  ///
  /// Retour: [UserCredential] du compte créé
  ///
  /// Lève [FirebaseException] si :
  /// - Le rôle n'est pas valide
  /// - L'email existe déjà
  /// - La création Firestore échoue (le compte Firebase est supprimé)
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
    // Valide et normalise le rôle en minuscules pour assurer la cohérence
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'doctor' && normalizedRole != 'patient') {
      // Lance une exception si le rôle est invalide
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Le rôle doit être "doctor" ou "patient".',
      );
    }

    // Étape 1 : Crée le compte Firebase Authentication
    final credential = await signUp(
      email: email.trim(),
      password: password,
      userRole: normalizedRole,
    );

    // Récupère l'utilisateur créé et son UID unique
    final user = credential.user;
    final uid = user?.uid;
    // Prépare l'URL de la photo de profil en supprimant les espaces inutiles
    final trimmedProfileImageUrl = profileImageUrl?.trim();

    // Étape 2 : Met à jour les informations de profil Firebase (displayName et photoURL)
    try {
      if (user != null) {
        // Définit le nom complet dans Firebase Auth
        await user.updateDisplayName(fullName.trim());
        // Définit la photo de profil si elle est fournie et valide
        if (trimmedProfileImageUrl != null &&
            trimmedProfileImageUrl.isNotEmpty) {
          await user.updatePhotoURL(trimmedProfileImageUrl);
        }
      }
    } catch (_) {
      // Ignore les erreurs de mise à jour (non critique)
    }

    // Étape 3 : Crée le profil utilisateur complet dans Firestore
    if (uid != null) {
      try {
        // Crée/met à jour le document utilisateur avec tous les champs
        await _firestore.collection('users').doc(uid).set({
          // Données d'authentification
          'email': email.trim(),
          // Données de profil
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
          // Métadonnée de création (horodatage côté serveur)
          'createdAt': DateTime.now(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        // Si la création Firestore échoue, supprime le compte Firebase créé
        // pour éviter un compte orphelin sans profil
        try {
          await user?.delete();
        } catch (_) {
          // Ignore les erreurs de suppression
        }
        // Re-lève l'exception d'origine
        rethrow;
      }
    }

    // Retourne le UserCredential contenant l'UID et les infos du nouvel utilisateur
    return credential;
  }

  /// Change le mot de passe de l'utilisateur actuellement connecté
  ///
  /// Nécessite une réauthentification avec le mot de passe actuel pour
  /// vérifier l'identité avant de changer le mot de passe (mesure de sécurité).
  ///
  /// Paramètres:
  /// - [currentPassword]: Mot de passe actuel (pour la réauthentification)
  /// - [newPassword]: Nouveau mot de passe (au moins 6 caractères)
  ///
  /// Lève [FirebaseAuthException] si :
  /// - Aucun utilisateur n'est connecté
  /// - Le mot de passe actuel est incorrect
  /// - L'email du compte n'est pas disponible
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Récupère l'utilisateur actuellement authentifié
    final user = _auth.currentUser;
    if (user == null) {
      // Lance une exception si aucun utilisateur n'est connecté
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Aucun utilisateur connecté.',
      );
    }

    // Récupère l'email de l'utilisateur (nécessaire pour la réauthentification)
    final email = user.email;
    if (email == null || email.isEmpty) {
      // Lance une exception si l'email n'est pas disponible
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Email utilisateur indisponible.',
      );
    }

    // Crée les credentials d'authentification avec email et mot de passe actuel
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    // Réauthentifie l'utilisateur (vérification de sécurité)
    // Cela valide que le mot de passe actuel est correct
    await user.reauthenticateWithCredential(credential);
    // Change le mot de passe vers le nouveau mot de passe
    await user.updatePassword(newPassword);
  }
}
