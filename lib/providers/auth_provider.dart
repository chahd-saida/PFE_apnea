import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:apnea_project/services/auth_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    UserService? userService,
    FirebaseAuth? auth,
    bool listenToAuthChanges = true,
    User? initialUser,
    String? initialRole,
  }) : _authService = authService ?? AuthService(),
       _userService = userService ?? UserService(),
       _auth = listenToAuthChanges ? (auth ?? FirebaseAuth.instance) : null,
       _user = initialUser,
       _role = initialRole {
    if (listenToAuthChanges) {
      _user = _auth?.currentUser;
      if (_user != null && (_role != 'doctor' && _role != 'patient')) {
        _isLoadingRole = true;
        unawaited(fetchRole(_user!.uid));
      }
      _authSubscription = _auth?.authStateChanges().listen((User? user) {
        _user = user;
        if (user == null) {
          _role          = null;
          _isLoadingRole = false;
        } else {
          _role          = null;
          _isLoadingRole = true;
          unawaited(fetchRole(user.uid));
        }
        notifyListeners();
      });
    } else {
      _isLoadingRole = false;
    }
  }

  final AuthService   _authService;
  final UserService   _userService;
  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;

  User?   _user;
  String? _role;
  bool    _isLoadingRole = false;
  String? _loginError;

  User?   get user          => _user;
  bool    get isLoggedIn    => _user != null;
  String? get role          => _role;
  bool    get isDoctor      => _role == 'doctor';
  bool    get isLoadingRole => _isLoadingRole;
  String? get loginError    => _loginError;

  void clearSession() {
    _user          = null;
    _role          = null;
    _isLoadingRole = false;
    _loginError    = null;
    notifyListeners();
  }

  Future<void> fetchRole(String uid) async {
    if (_role == 'doctor' || _role == 'patient') return;
    _isLoadingRole = true;
    notifyListeners();
    try {
      final String? fetchedRole = await _userService.getUserRole(uid);
      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole;
        debugPrint('✅ Role fetched: $_role for uid: $uid');
      } else {
        _role = null;
        debugPrint('⚠️ No valid role for uid: $uid (fetched: $fetchedRole)');
      }
    } catch (e) {
      _role = null;
      debugPrint('❌ Error fetching role for uid: $uid — $e');
    } finally {
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
    String? selectedRole,
  }) async {
    _loginError    = null;
    _isLoadingRole = true;
    notifyListeners();
    try {
      final cred           = await _authService.signIn(
                               email: email, password: password);
      final User? firebaseUser = cred.user;
      if (firebaseUser == null) {
        _loginError = 'Erreur de connexion inattendue.';
        return _loginError;
      }
      _user = firebaseUser;

      final String? fetchedRole =
          await _userService.getUserRole(firebaseUser.uid);

      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole;
      } else {
        _role = null;
      }

      if (_role == null) return 'fixProfile';

      if (selectedRole != null && selectedRole != _role) {
        await _authService.signOut();
        _user = null;
        _role = null;
        final roleLabel = fetchedRole == 'doctor' ? 'Médecin' : 'Patient';
        _loginError =
            'Le rôle sélectionné ne correspond pas à ce compte ($roleLabel).';
        return 'roleMismatch:${fetchedRole ?? ''}';
      }

      // CORRECTION 1 : await au lieu de unawaited
      // → garantit que le nom est envoyé avant de continuer
      if (_role == 'patient') {
        await _enregistrerPatientFastAPI(firebaseUser);
        unawaited(_envoyerUidEsp32(firebaseUser.uid));
      }

      debugPrint('✅ Login successful for role: $_role');
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

  Future<String?> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String dateOfBirth,
    required String phone,
    String? gender,
    String? profileImageUrl,
  }) async {
    _loginError    = null;
    _isLoadingRole = true;
    notifyListeners();
    try {
      await _authService.registerUser(
        email:           email,
        password:        password,
        role:            role,
        fullName:        fullName,
        dateOfBirth:     dateOfBirth,
        phone:           phone,
        gender:          gender,
        profileImageUrl: profileImageUrl,
      );

      final loginCred      = await _authService.signIn(
                               email: email, password: password);
      final User? firebaseUser = loginCred.user;
      if (firebaseUser == null) {
        _loginError = 'Inscription réussie mais connexion échouée.';
        return _loginError;
      }
      _user = firebaseUser;

      String? fetchedRole;
      for (int i = 0; i < 5; i++) {
        fetchedRole = await _userService.getUserRole(firebaseUser.uid);
        if (fetchedRole == 'doctor' || fetchedRole == 'patient') break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
      _role = (fetchedRole == 'doctor' || fetchedRole == 'patient')
          ? fetchedRole
          : null;

      // CORRECTION 2 : await au lieu de unawaited pour register aussi
      // → fullName est disponible directement ici, pas besoin de Firestore
      if (_role == 'patient') {
        await _enregistrerPatientFastAPI(
          firebaseUser,
          fullName:    fullName,    // ← disponible directement
          dateOfBirth: dateOfBirth,
          phone:       phone,
        );
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

  // ── Enregistrement SQLite FastAPI ─────────────────────────────
  Future<void> _enregistrerPatientFastAPI(
    User firebaseUser, {
    String? fullName,
    String? dateOfBirth,
    String? phone,
  }) async {
    try {
      String nom    = '';
      String prenom = '';
      String dob    = dateOfBirth ?? '';
      String tel    = phone       ?? '';

      // Étape 1 : fullName fourni directement (cas register)
      String displayName = fullName?.trim() ?? '';

      // Étape 2 : displayName Firebase (cas login)
      if (displayName.isEmpty) {
        displayName = firebaseUser.displayName?.trim() ?? '';
      }

      // Étape 3 : lire Firestore si toujours vide
      if (displayName.isEmpty) {
        try {
          final userData =
              await _userService.getUserProfile(firebaseUser.uid);
          if (userData != null) {
            // Essayer fullName d'abord
            final fn = (userData['fullName'] as String?)?.trim() ?? '';
            if (fn.isNotEmpty) {
              displayName = fn;
            } else {
              // Essayer firstName + lastName
              final firstName =
                  (userData['firstName'] as String?)?.trim() ?? '';
              final lastName  =
                  (userData['lastName']  as String?)?.trim() ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                displayName = '$firstName $lastName'.trim();
              }
            }
            dob = (userData['dateOfBirth'] as String?)?.trim() ?? dob;
            tel = (userData['phone']       as String?)?.trim() ?? tel;
          }
        } catch (e) {
          debugPrint('⚠️ getUserProfile failed: $e');
        }
      }

      // Étape 4 : fallback email si tout est vide
      if (displayName.isEmpty) {
        final email = firebaseUser.email ?? '';
        if (email.isNotEmpty) {
          displayName = email.split('@').first
              .replaceAll('.', ' ')
              .replaceAll('_', ' ');
          debugPrint('⚠️ Fallback email utilisé : $displayName');
        }
      }

      // Étape 5 : parser en prénom / nom
      if (displayName.isNotEmpty) {
        final parts = displayName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          prenom = parts.first;
          nom    = parts.sublist(1).join(' ');
        } else {
          prenom = displayName;
          nom    = '';
        }
      }

      debugPrint('=== enregistrerPatientFastAPI ===');
      debugPrint('UID    : ${firebaseUser.uid}');
      debugPrint('Prénom : $prenom');
      debugPrint('Nom    : $nom');
      debugPrint('DOB    : $dob');

      // Étape 6 : envoyer à FastAPI
      final ok = await ApiService().enregistrerPatient(
        patientId:     firebaseUser.uid,
        nom:           nom,
        prenom:        prenom,
        dateNaissance: dob,
        telephone:     tel,
      );

      debugPrint(ok
        ? '✅ Patient enregistré FastAPI : $prenom $nom (${firebaseUser.uid})'
        : '⚠️ Enregistrement FastAPI échoué pour ${firebaseUser.uid}');

    } catch (e) {
      debugPrint('⚠️ _enregistrerPatientFastAPI (non bloquant) : $e');
    }
  }

  // ── Envoi UID à l'ESP32 via MQTT ──────────────────────────────
  Future<void> _envoyerUidEsp32(String uid) async {
    try {
      final ok = await ApiService().envoyerUidEsp32(uid);
      debugPrint(ok
        ? '✅ UID envoyé à l\'ESP32 : $uid'
        : '⚠️ Envoi UID ESP32 échoué (non bloquant)');
    } catch (e) {
      debugPrint('⚠️ _envoyerUidEsp32 (non bloquant) : $e');
    }
  }

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

  @visibleForTesting
  void setSessionForTest({User? user, String? role}) {
    _user = user;
    _role = role;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}