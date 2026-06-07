import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Services d'authentification et de gestion utilisateur
import 'package:apnea_project/services/auth_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/api_service.dart';
import 'package:apnea_project/services/notification_service.dart';

// Provider de gestion de l'authentification Firebase
// Gere la connexion, l'enregistrement, les roles (doctor/patient) et la session utilisateur
class AuthProvider extends ChangeNotifier {
  // Constructeur avec initialisation des services et optionnellement l'ecoute des changements
  AuthProvider({
    AuthService? authService,
    UserService? userService,
    FirebaseAuth? auth,
    bool listenToAuthChanges = true,
    User? initialUser,
    String? initialRole,
  }) : _authService = authService ?? AuthService(),
       _userService = userService ?? UserService(),
       // Utilise Firebase instance ou null selon listenToAuthChanges
       _auth = listenToAuthChanges ? (auth ?? FirebaseAuth.instance) : null,
       _user = initialUser,
       _role = initialRole {
    if (listenToAuthChanges) {
      // Recupere l'utilisateur courant de Firebase
      _user = _auth?.currentUser;
      // Si utilisateur connecte mais role non valide, le charge depuis Firestore
      if (_user != null && (_role != 'doctor' && _role != 'patient')) {
        _isLoadingRole = true;
        unawaited(fetchRole(_user!.uid));
      }
      // Ecoute les changements d'authentification (connexion/deconnexion)
      _authSubscription = _auth?.authStateChanges().listen((User? user) {
        _user = user;
        if (user == null) {
          // Utilisateur deconnecte : reinitialise l'etat
          _role = null;
          _isLoadingRole = false;
        } else {
          // Nouvel utilisateur connecte : charge son role depuis Firestore
          _role = null;
          _isLoadingRole = true;
          unawaited(fetchRole(user.uid));
        }
        notifyListeners(); // Notifie les widgets ecoutant ce provider
      });
    } else {
      _isLoadingRole = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SERVICES ET DONNEES PRIVEES
  // ════════════════════════════════════════════════════════════════

  // Services pour l'authentification et la gestion des utilisateurs
  final AuthService _authService; // Authentification Firebase
  final UserService _userService; // Acces aux donnees Firestore
  final FirebaseAuth? _auth; // Connexion Firebase (optionnelle)
  StreamSubscription<User?>?
  _authSubscription; // Abonnement aux changements Auth

  // Etat de l'utilisateur et de sa session
  User? _user; // Utilisateur Firebase courant
  String? _role; // Role de l'utilisateur (doctor/patient)
  bool _isLoadingRole = false; // Indique si le role est en cours de chargement
  String? _loginError; // Message d'erreur de connexion

  // ════════════════════════════════════════════════════════════════
  // GETTERS PUBLICS
  // ════════════════════════════════════════════════════════════════

  User? get user => _user; // Utilisateur Firebase courant
  bool get isLoggedIn => _user != null; // Verifie si l'utilisateur est connecte
  String? get role => _role; // Role actuel (doctor/patient)
  bool get isDoctor =>
      _role == 'doctor'; // Verifie si l'utilisateur est medecin
  bool get isLoadingRole =>
      _isLoadingRole; // Verifie si le role est en cours de chargement
  String? get loginError =>
      _loginError; // Message d'erreur de la derniere tentative

  // Reinitialise la session utilisateur (apres deconnexion)
  // Efface toutes les donnees de l'utilisateur et notifie les ecoutants
  void clearSession() {
    _user = null;
    _role = null;
    _isLoadingRole = false;
    _loginError = null;
    notifyListeners(); // Indique aux widgets que l'etat a change
  }

  // Recupere le role de l'utilisateur depuis Firestore
  // Interroge la base de donnees pour savoir si l'utilisateur est medecin ou patient
  Future<void> fetchRole(String uid) async {
    // Evite les chargements multiples si le role est deja connu
    if (_role == 'doctor' || _role == 'patient') return;

    _isLoadingRole = true;
    notifyListeners();

    try {
      // Interroge Firestore pour obtenir le role de l'utilisateur
      final String? fetchedRole = await _userService.getUserRole(uid);

      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole; // Role valide
        debugPrint('✅ Role fetched: $_role for uid: $uid');
      } else {
        _role = null; // Role invalide ou non trouve
        debugPrint('⚠️ No valid role for uid: $uid (fetched: $fetchedRole)');
      }
    } catch (e) {
      // En cas d'erreur, reinitialise le role
      _role = null;
      debugPrint('❌ Error fetching role for uid: $uid — $e');
    } finally {
      _isLoadingRole = false;
      notifyListeners(); // Notifie les ecoutants que le chargement est termine
    }
  }

  // ════════════════════════════════════════════════════════════════
  // AUTHENTIFICATION : Connexion utilisateur
  // ════════════════════════════════════════════════════════════════

  // Connecte l'utilisateur avec email/password et charge son role
  // Retourne null si succes, un message d'erreur sinon
  Future<String?> login({
    required String email, // Email de l'utilisateur
    required String password, // Mot de passe
    String? selectedRole, // Role attendu (doctor/patient) pour validation
  }) async {
    // Reinitialise les variables d'erreur et charge le role
    _loginError = null;
    _isLoadingRole = true;
    notifyListeners();

    try {
      // ETAPE 1 : Authentifier avec Firebase
      final cred = await _authService.signIn(email: email, password: password);
      final User? firebaseUser = cred.user;

      if (firebaseUser == null) {
        _loginError = 'Erreur de connexion inattendue.';
        return _loginError; // Erreur : pas d'utilisateur retourne
      }
      _user = firebaseUser; // Stocke l'utilisateur connecte

      // ETAPE 2 : Charger le role depuis Firestore
      final String? fetchedRole = await _userService.getUserRole(
        firebaseUser.uid,
      );

      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole; // Role valide
      } else {
        _role = null; // Role invalide
      }

      // ETAPE 3 : Verifier que le role est valide
      if (_role == null) return 'fixProfile'; // Signal pour fixer le profil

      // ETAPE 4 : Valider que le role selectionne correspond au compte
      if (selectedRole != null && selectedRole != _role) {
        // Les roles ne correspondent pas : deconnecte l'utilisateur
        await _authService.signOut();
        _user = null;
        _role = null;
        final roleLabel = fetchedRole == 'doctor' ? 'Médecin' : 'Patient';
        _loginError =
            'Le rôle sélectionné ne correspond pas à ce compte ($roleLabel).';
        return 'roleMismatch:${fetchedRole ?? ''}'; // Signal d'erreur
      }

      // ETAPE 5 : Etapes specifiques aux patients
      if (_role == 'patient') {
        // Enregistre le patient dans FastAPI (avec ses donnees)
        // Utilise 'await' pour garantir que les donnees sont envoyees avant de continuer
        await _enregistrerPatientFastAPI(firebaseUser);
        // Envoie le UID a l'ESP32 pour l'appairage du dispositif (non bloquant)
        unawaited(_envoyerUidEsp32(firebaseUser.uid));
      }

      // ETAPE 6 : Initialiser les notifications push
      await NotificationService().init();

      // Connexion reussie
      debugPrint('✅ Login successful for role: $_role');
      return null; // Pas d'erreur
    } on FirebaseAuthException catch (e) {
      // Erreur Firebase (identifiants invalides, compte inexistant, etc.)
      _loginError = _mapAuthError(e);
      return _loginError;
    } catch (e) {
      // Autre erreur inattendue
      _loginError = 'Erreur inattendue : ${e.toString()}';
      return _loginError;
    } finally {
      // Marque le chargement comme termine et notifie les ecoutants
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // AUTHENTIFICATION : Inscription nouvel utilisateur
  // ════════════════════════════════════════════════════════════════

  // Enregistre un nouvel utilisateur avec ses donnees personnelles
  // Retourne null si succes, un message d'erreur sinon
  Future<String?> register({
    required String email, // Email de l'utilisateur
    required String password, // Mot de passe
    required String role, // Role (doctor/patient)
    required String fullName, // Nom complet
    required String dateOfBirth, // Date de naissance
    required String phone, // Telephone
    String? gender, // Genre (optionnel)
    String? profileImageUrl, // URL de la photo de profil (optionnelle)
  }) async {
    // Reinitialise les variables d'erreur et charge le role
    _loginError = null;
    _isLoadingRole = true;
    notifyListeners();

    try {
      // ETAPE 1 : Creer le compte utilisateur dans Firebase et Firestore
      await _authService.registerUser(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        gender: gender,
        profileImageUrl: profileImageUrl,
      );

      // ETAPE 2 : Connecter automatiquement l'utilisateur apres inscription
      final loginCred = await _authService.signIn(
        email: email,
        password: password,
      );
      final User? firebaseUser = loginCred.user;

      if (firebaseUser == null) {
        _loginError = 'Inscription réussie mais connexion échouée.';
        return _loginError; // Erreur : inscript reussie mais connexion echouee
      }
      _user = firebaseUser; // Stocke l'utilisateur connecte

      // ETAPE 3 : Charger le role (avec retry si necessaire)
      // Effectue plusieurs tentatives car Firestore peut etre lent
      String? fetchedRole;
      for (int i = 0; i < 5; i++) {
        fetchedRole = await _userService.getUserRole(firebaseUser.uid);
        if (fetchedRole == 'doctor' || fetchedRole == 'patient')
          break; // Role trouve
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // Attendre avant retry
      }
      _role = (fetchedRole == 'doctor' || fetchedRole == 'patient')
          ? fetchedRole
          : null;

      // ETAPE 4 : Etapes specifiques aux patients
      if (_role == 'patient') {
        // Enregistre le patient dans FastAPI
        // Utilise les donnees passees directement (pas de lecture Firestore)
        await _enregistrerPatientFastAPI(
          firebaseUser,
          fullName: fullName, // Donnees disponibles de l'inscription
          dateOfBirth: dateOfBirth,
          phone: phone,
        );
        // Envoie le UID a l'ESP32 pour l'appairage (non bloquant)
        unawaited(_envoyerUidEsp32(firebaseUser.uid));
      }

      return null;
    } on FirebaseAuthException catch (e) {
      _loginError = _mapAuthError(e);
      return _loginError;
    } catch (e) {
      _loginError = 'Erreur inattendue : ${e.toString()}';
      return _loginError;
    } finally {
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // METHODES PRIVEES : Enregistrement et communications
  // ════════════════════════════════════════════════════════════════

  // Enregistre le patient dans la base FastAPI
  // Extrait le nom/prenom de differentes sources et les envoie a FastAPI
  Future<void> _enregistrerPatientFastAPI(
    User firebaseUser, {
    String? fullName,
    String? dateOfBirth,
    String? phone,
  }) async {
    try {
      // Initialise les variables a envoyer a FastAPI
      String nom = ''; // Nom de famille
      String prenom = ''; // Prenom
      String dob = dateOfBirth ?? ''; // Date de naissance
      String tel = phone ?? ''; // Telephone

      // ─────────────────────────────────────────────────────────
      // ETAPE 1 : Essayer d'obtenir le nom complet (fullName fourni directement)
      // ─────────────────────────────────────────────────────────
      String displayName =
          fullName?.trim() ?? ''; // Cas register : fullName disponible

      // ─────────────────────────────────────────────────────────
      // ETAPE 2 : Fallback Firebase displayName (cas login)
      // ─────────────────────────────────────────────────────────
      if (displayName.isEmpty) {
        displayName =
            firebaseUser.displayName?.trim() ?? ''; // Essai depuis Firebase
      }

      // ─────────────────────────────────────────────────────────
      // ETAPE 3 : Fallback Firestore si toujours vide
      // ─────────────────────────────────────────────────────────
      if (displayName.isEmpty) {
        try {
          // Lit le profil utilisateur depuis Firestore
          final userData = await _userService.getUserProfile(firebaseUser.uid);
          if (userData != null) {
            // Essaye d'abord 'fullName'
            final fn = (userData['fullName'] as String?)?.trim() ?? '';
            if (fn.isNotEmpty) {
              displayName = fn;
            } else {
              // Sinon combine 'firstName' + 'lastName'
              final firstName =
                  (userData['firstName'] as String?)?.trim() ?? '';
              final lastName = (userData['lastName'] as String?)?.trim() ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                displayName = '$firstName $lastName'.trim();
              }
            }
            // Complementer les autres donnees depuis Firestore
            dob = (userData['dateOfBirth'] as String?)?.trim() ?? dob;
            tel = (userData['phone'] as String?)?.trim() ?? tel;
          }
        } catch (e) {
          debugPrint('⚠️ getUserProfile failed: $e');
        }
      }

      // ─────────────────────────────────────────────────────────
      // ETAPE 4 : Fallback email si tout est vide
      // ─────────────────────────────────────────────────────────
      if (displayName.isEmpty) {
        final email = firebaseUser.email ?? '';
        if (email.isNotEmpty) {
          // Extrait la partie avant '@' et remplace '.' et '_' par des espaces
          displayName = email
              .split('@')
              .first
              .replaceAll('.', ' ')
              .replaceAll('_', ' ');
          debugPrint('⚠️ Fallback email utilisé : $displayName');
        }
      }

      // ─────────────────────────────────────────────────────────
      // ETAPE 5 : Parser le nom complet en prenom / nom
      // ─────────────────────────────────────────────────────────
      if (displayName.isNotEmpty) {
        // Divise par espaces et filtre les parties vides
        final parts = displayName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          // Nom compose : premier mot = prenom, reste = nom
          prenom = parts.first;
          nom = parts.sublist(1).join(' ');
        } else {
          // Seul mot : considere comme prenom
          prenom = displayName;
          nom = '';
        }
      }

      // ─────────────────────────────────────────────────────────
      // Affiche les donnees a envoyer (debug)
      // ─────────────────────────────────────────────────────────
      debugPrint('=== enregistrerPatientFastAPI ===');
      debugPrint('UID    : ${firebaseUser.uid}');
      debugPrint('Prénom : $prenom');
      debugPrint('Nom    : $nom');
      debugPrint('DOB    : $dob');

      // ─────────────────────────────────────────────────────────
      // ETAPE 6 : Envoyer les donnees a FastAPI
      // ─────────────────────────────────────────────────────────
      final ok = await ApiService().enregistrerPatient(
        patientId: firebaseUser.uid,
        nom: nom,
        prenom: prenom,
        dateNaissance: dob,
        telephone: tel,
      );

      // Affiche le resultat de l'enregistrement
      debugPrint(
        ok
            ? '✅ Patient enregistré FastAPI : $prenom $nom (${firebaseUser.uid})'
            : '⚠️ Enregistrement FastAPI échoué pour ${firebaseUser.uid}',
      );
    } catch (e) {
      // Erreur non bloquante (l'enregistrement FastAPI n'est pas critique)
      debugPrint('⚠️ _enregistrerPatientFastAPI (non bloquant) : $e');
    }
  }

  // Envoie l'UID de l'utilisateur a l'ESP32 via MQTT
  // Permet l'appairage du dispositif avec l'utilisateur
  Future<void> _envoyerUidEsp32(String uid) async {
    try {
      // Appelle le service API pour envoyer l'UID a l'ESP32
      final ok = await ApiService().envoyerUidEsp32(uid);

      debugPrint(
        ok
            ? '✅ UID envoyé à l\'ESP32 : $uid'
            : '⚠️ Envoi UID ESP32 échoué (non bloquant)', // Non bloquant
      );
    } catch (e) {
      // Erreur non bloquante (l'envoi ESP32 n'est pas critique pour la connexion)
      debugPrint('⚠️ _envoyerUidEsp32 (non bloquant) : $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // GESTION D'ERREURS
  // ════════════════════════════════════════════════════════════════

  // Traduit les erreurs Firebase en messages francais lisibles
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'operation-not-allowed':
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND':
        return 'Authentification Firebase non configurée.';
      default:
        return e.message ?? 'Erreur d\'authentification.';
    }
  }

  // ════════════════════════════════════════════════════════════════
  // DECONNEXION
  // ════════════════════════════════════════════════════════════════

  // Deconnecte l'utilisateur : efface le token de notifications et la session
  Future<void> logout() async {
    try {
      // Efface le token FCM des notifications push
      await NotificationService().clearToken();
    } catch (e) {
      debugPrint('⚠️ Error clearing notification token: $e');
    }
    // Deconnecte de Firebase
    await _authService.signOut();
    // Reinitialise l'etat local
    clearSession();
    debugPrint('✅ Logout successful');
  }

  // ════════════════════════════════════════════════════════════════
  // METHODES DE TEST
  // ════════════════════════════════════════════════════════════════

  // Defini manuellement la session pour les tests unitaires
  @visibleForTesting
  void setSessionForTest({User? user, String? role}) {
    _user = user; // Simule un utilisateur connecte
    _role = role; // Simule un role
    notifyListeners(); // Notifie les ecoutants
  }

  // ════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════

  // Nettoie les ressources au moment de la destruction du provider
  @override
  void dispose() {
    // Arrete l'ecoute des changements Firebase
    _authSubscription?.cancel();
    super.dispose();
  }
}
