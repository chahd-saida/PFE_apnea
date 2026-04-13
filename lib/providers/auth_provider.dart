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

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get role => _role;
  bool get isDoctor => _role == 'doctor';
  bool get isLoadingRole => _isLoadingRole;

  void clearSession() {
    _user = null;
    _role = null;
    _isLoadingRole = false;
    notifyListeners();
  }

  Future<void> fetchRole(String uid) async {
    if (_role == 'doctor' || _role == 'patient') {
      return;
    }
    _isLoadingRole = true;
    notifyListeners();

    try {
      final String? fetchedRole = await _firebaseService.getUserRole(uid);
      if (fetchedRole == 'doctor' || fetchedRole == 'patient') {
        _role = fetchedRole;
      } else {
        _role = null;
      }
    } catch (_) {
      _role = null;
    } finally {
      _isLoadingRole = false;
      notifyListeners();
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
