import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:apnea_project/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    FirebaseService? firebaseService,
    FirebaseAuth? auth,
    bool listenToAuthChanges = true,
    User? initialUser,
    String? initialRole,
  }) : _firebaseService = firebaseService ?? FirebaseService(),
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
          _role = null;
          _isLoadingRole = false;
        } else {
          _role = null;
          _isLoadingRole = true;
          unawaited(fetchRole(user.uid));
        }
        notifyListeners();
      });
    } else {
      _isLoadingRole = false;
    }
  }

  final FirebaseService _firebaseService;
  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  String? _role;
  bool _isLoadingRole = false;
  String? _loginError;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get role => _role;
  bool get isDoctor => _role == 'doctor';
  bool get isLoadingRole => _isLoadingRole;
  String? get loginError => _loginError;

  void clearSession() {
    _user = null;
    _role = null;
    _isLoadingRole = false;
    _loginError = null;
    notifyListeners();
  }

  Future<void> fetchRole(String uid) async {
    if (_role == 'doctor' || _role == 'patient') return;
    _isLoadingRole = true;
    notifyListeners();
    try {
      final String? fetchedRole = await _firebaseService.getUserRole(uid);
      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole;
        debugPrint('✅ Role fetched successfully: $_role for uid: $uid');
      } else {
        _role = null;
        debugPrint('⚠️ No valid role found for uid: $uid (fetched: $fetchedRole)');
      }
    } catch (e) {
      _role = null;
      debugPrint('❌ Error fetching role for uid: $uid - Error: $e');
    } finally {
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  /// Retourne null si succès, 'fixProfile', 'roleMismatch:doctor',
  /// 'roleMismatch:patient', ou un message d'erreur lisible.
  Future<String?> login({
    required String email,
    required String password,
    String? selectedRole,
  }) async {
    _loginError = null;
    _isLoadingRole = true;
    notifyListeners();
    try {
      final cred = await _firebaseService.signIn(
        email: email,
        password: password,
      );
      final User? firebaseUser = cred.user;
      if (firebaseUser == null) {
        _loginError = 'Erreur de connexion inattendue.';
        debugPrint('❌ Login failed: Firebase user is null');
        return _loginError;
      }
      _user = firebaseUser;
      debugPrint('🔵 Firebase sign-in successful for: ${firebaseUser.uid}');

      // Récupérer le rôle via Firestore
      final String? fetchedRole =
          await _firebaseService.getUserRole(firebaseUser.uid);
      
      debugPrint(
        '🔍 Role resolution: fetched=$fetchedRole, selectedRole=$selectedRole',
      );
      
      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole;
        debugPrint('✅ Valid role assigned: $_role');
      } else {
        _role = null;
        debugPrint('⚠️ Invalid or missing role from Firestore: $fetchedRole');
      }

      // Rôle inconnu → rediriger vers fixProfile
      if (_role == null) {
        debugPrint(
          '❌ User profile incomplete: role not found in Firestore for uid: ${firebaseUser.uid}',
        );
        return 'fixProfile';
      }

      // Le rôle choisi dans l'UI ne correspond pas au rôle du compte
      if (selectedRole != null && selectedRole != _role) {
        await _firebaseService.signOut();
        _user = null;
        _role = null;
        final roleLabel = fetchedRole == 'doctor' ? 'Médecin' : 'Patient';
        _loginError =
            'Le rôle sélectionné ne correspond pas à ce compte ($roleLabel).';
        debugPrint('❌ Role mismatch: selected=$selectedRole, actual=$fetchedRole');
        return 'roleMismatch:${fetchedRole ?? ''}';
      }

      debugPrint('✅ Login successful for role: $_role');
      return null; // succès
    } on FirebaseAuthException catch (e) {
      _loginError = _mapAuthError(e);
      debugPrint('❌ Firebase auth error: ${e.code} - ${e.message}');
      return _loginError;
    } catch (e) {
      _loginError = 'Erreur inattendue : ${e.toString()}';
      return _loginError;
    } finally {
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  /// Retourne null si succès, ou un message d'erreur lisible.
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
    _loginError = null;
    _isLoadingRole = true;
    notifyListeners();
    try {
      await _firebaseService.registerUser(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        gender: gender,
        profileImageUrl: profileImageUrl,
      );

      // Auto-login après inscription
      final loginCred = await _firebaseService.signIn(
        email: email,
        password: password,
      );
      final User? firebaseUser = loginCred.user;
      if (firebaseUser == null) {
        _loginError = 'Inscription réussie mais connexion échouée.';
        return _loginError;
      }
      _user = firebaseUser;

      // Récupérer le rôle avec retry (propagation Firestore)
      String? fetchedRole;
      for (int i = 0; i < 5; i++) {
        fetchedRole = await _firebaseService.getUserRole(firebaseUser.uid);
        if (fetchedRole == 'doctor' || fetchedRole == 'patient') break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
      _role = (fetchedRole == 'doctor' || fetchedRole == 'patient')
          ? fetchedRole
          : null;

      return null; // succès
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