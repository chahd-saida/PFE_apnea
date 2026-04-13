import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';

UserProfileProvider useUser(BuildContext context) {
  return context.watch<UserProfileProvider>();
}

UserProfileProvider? useDoctorProfile(BuildContext context) {
  final profile = context.watch<UserProfileProvider>();
  if (profile.role != 'doctor') {
    return null;
  }
  return profile;
}

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  static const _storageKey = 'session.userProfile';

  final FirebaseService _firebaseService;

  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  String? _activeUid;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _lastError;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  String get fullName => _readString('fullName') ?? 'Utilisateur';
  String get email => _readString('email') ?? 'Non renseigne';
  String get role => _normalizeRole(_user?['role']) ?? 'patient';
  String get phone => _readString('phone') ?? 'Non renseigne';
  String? get doctorUid => _readString('doctorUid');
  String? get doctorName =>
      _readString('doctorName') ?? _readString('assignedDoctorName');
  String get specialization =>
      _readString('specialization') ?? 'Non renseignee';
  String get medicalLicenseNumber =>
      _readString('medicalLicenseNumber') ?? 'Non renseigne';
  String get yearsOfExperience =>
      _readString('yearsOfExperience') ?? 'Non renseigne';
  String get clinicName => _readString('clinicName') ?? 'Non renseigne';
  String? get profileImageUrl =>
      _readString('profileImageUrl') ?? _readString('photoUrl');

  void bindAuth(AuthProvider authProvider) {
    final firebaseUser = authProvider.user;
    if (firebaseUser == null) {
      unawaited(clear());
      return;
    }

    final uid = firebaseUser.uid;

    if (_activeUid == uid) {
      final merged = _composeUserData(
        firebaseUser: firebaseUser,
        role: authProvider.role,
        profile: _user,
      );
      if (!_mapEquals(_user, merged)) {
        _user = merged;
        unawaited(_persist(merged));
        notifyListeners();
      }
      return;
    }

    unawaited(_initializeForUser(firebaseUser, authProvider.role));
  }

  Future<void> _initializeForUser(User firebaseUser, String? role) async {
    _activeUid = firebaseUser.uid;
    _isLoading = true;
    notifyListeners();

    await _profileSubscription?.cancel();

    final cached = await _loadCached();
    if (cached != null && cached['uid'] == firebaseUser.uid) {
      _user = _composeUserData(
        firebaseUser: firebaseUser,
        role: role,
        profile: cached,
      );
      notifyListeners();
    }

    _profileSubscription = _firebaseService
        .streamUserProfile(firebaseUser.uid)
        .listen(
          (profile) {
            final merged = _composeUserData(
              firebaseUser: firebaseUser,
              role: role,
              profile: profile,
            );
            _user = merged;
            _lastError = null;
            _isLoading = false;
            unawaited(_persist(merged));
            notifyListeners();
          },
          onError: (Object error) {
            _lastError = 'Erreur chargement profil: $error';
            _isLoading = false;
            notifyListeners();
          },
        );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final uid = _activeUid;
    if (uid == null) {
      return;
    }

    _user = <String, dynamic>{...(_user ?? <String, dynamic>{}), ...updates};
    notifyListeners();
    await _persist(_user!);

    await _firebaseService.updateUserProfile(uid, updates);
  }

  Future<void> refreshProfile() async {
    final uid = _activeUid;
    if (uid == null) {
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final profile = await _firebaseService.getUserProfile(uid);
      if (profile != null) {
        _user = <String, dynamic>{
          ...(_user ?? <String, dynamic>{}),
          ...profile,
        };
        await _persist(_user!);
      }
    } catch (e) {
      _lastError = 'Erreur chargement profil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _activeUid = null;
    _user = null;
    _isLoading = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Map<String, dynamic> _composeUserData({
    required User firebaseUser,
    required String? role,
    required Map<String, dynamic>? profile,
  }) {
    final resolvedRole =
        _normalizeRole(role) ?? _normalizeRole(profile?['role']) ?? 'patient';

    return <String, dynamic>{
      ...?profile,
      'uid': firebaseUser.uid,
      'email': _pickFirstString(profile?['email'], firebaseUser.email),
      'fullName': _pickFirstString(
        profile?['fullName'],
        firebaseUser.displayName,
      ),
      'role': resolvedRole,
      'phone': _pickFirstString(profile?['phone']),
      'dateOfBirth': _pickFirstString(profile?['dateOfBirth']),
      'gender': _pickFirstString(profile?['gender']),
      'doctorUid': _pickFirstString(profile?['doctorUid']),
      'doctorName': _pickFirstString(
        profile?['doctorName'],
        profile?['assignedDoctorName'],
      ),
      'profileImageUrl': _pickFirstString(
        profile?['profileImageUrl'],
        profile?['photoUrl'],
        firebaseUser.photoURL,
      ),
    };
  }

  String? _normalizeRole(dynamic raw) {
    if (raw is! String) {
      return null;
    }
    final value = raw.trim().toLowerCase();
    if (value == 'doctor' || value == 'patient') {
      return value;
    }
    return null;
  }

  String? _pickFirstString([dynamic a, dynamic b, dynamic c]) {
    final values = <dynamic>[a, b, c];
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _readString(String key) {
    final value = _user?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Future<Map<String, dynamic>?> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {}

    return null;
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = _sanitizeMapForJson(data);
    await prefs.setString(_storageKey, jsonEncode(sanitized));
  }

  Map<String, dynamic> _sanitizeMapForJson(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _sanitizeForJson(value)));
  }

  dynamic _sanitizeForJson(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', _sanitizeForJson(item)));
    }
    if (value is Iterable) {
      return value.map(_sanitizeForJson).toList();
    }
    return value;
  }

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
