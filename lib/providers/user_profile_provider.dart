// Import pour la gestion des timers et des operations asynchrones
import 'dart:async';
// Import pour le decodage/encodage JSON
import 'dart:convert';

// Import Firestore pour les timestamps
import 'package:cloud_firestore/cloud_firestore.dart';
// Import Firebase Auth pour l'authentification utilisateur
import 'package:firebase_auth/firebase_auth.dart' show User;
// Import Flutter pour Material Design et BuildContext
import 'package:flutter/material.dart';
// Import Provider pour la gestion d'etat reactive
import 'package:provider/provider.dart';
// Import SharedPreferences pour le stockage local des preferences
import 'package:shared_preferences/shared_preferences.dart';

// Import du provider d'authentification pour lier l'utilisateur Firebase
import 'package:apnea_project/providers/auth_provider.dart';
// Import du service de gestion des profils utilisateurs
import 'package:apnea_project/services/user_service.dart';

// Helper pour acceder au UserProfileProvider depuis le context de maniere reactive
UserProfileProvider useUser(BuildContext context) {
  return context.watch<UserProfileProvider>();
}

// Helper pour acceder au profil medecin de maniere type-safe
// Retourne null si l'utilisateur n'est pas un medecin
UserProfileProvider? useDoctorProfile(BuildContext context) {
  final profile = context.watch<UserProfileProvider>();
  if (profile.role != 'doctor') return null;
  return profile;
}

// Provider de gestion du profil utilisateur (medecin ou patient)
// Gere le chargement, la persistence en cache et la synchronisation du profil
// Combine les donnees Firebase Auth avec le profil Firestore
class UserProfileProvider extends ChangeNotifier {
  // Constructeur avec injection optionnelle du service (pour les tests)
  UserProfileProvider({UserService? userService})
    : _userService = userService ?? UserService();

  // Cle pour la persistence du profil en cache local (SharedPreferences)
  static const _storageKey = 'session.userProfile';

  // Service pour acceder aux donnees utilisateur depuis Firestore
  final UserService _userService;

  // Abonnement au flux en temps reel du profil utilisateur depuis Firestore
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  // UID de l'utilisateur actuellement charge
  String? _activeUid;
  // Donnees du profil utilisateur complet (Firebase + Firestore)
  Map<String, dynamic>? _user;
  // Indicateur si le chargement du profil est en cours
  bool _isLoading = false;
  // Dernier message d'erreur lors du chargement du profil
  String? _lastError;

  // ── Getters publics ───────────────────────────────────────────────────────

  // Retourne l'ensemble des donnees du profil utilisateur
  Map<String, dynamic>? get user => _user;
  // Retourne true si le chargement est en cours
  bool get isLoading => _isLoading;
  // Retourne le dernier message d'erreur (null si pas d'erreur)
  String? get lastError => _lastError;

  // Retourne le nom complet de l'utilisateur
  String get fullName => _readString('fullName') ?? 'Utilisateur';
  // Retourne l'email de l'utilisateur
  String get email => _readString('email') ?? 'Non renseigné';
  // Retourne le role normalise (doctor ou patient)
  String get role => _normalizeRole(_user?['role']) ?? 'patient';
  // Retourne le numero de telephone
  String get phone => _readString('phone') ?? 'Non renseigné';

  // UID du medecin assigné (pour les patients)
  String? get doctorUid => _readString('doctorUid');
  // Nom du medecin assigné (pour les patients)
  String? get doctorName =>
      _readString('doctorName') ?? _readString('assignedDoctorName');

  // Specialite medicale (pour les medecins)
  String get specialization =>
      _readString('specialization') ?? 'Non renseignée';

  // URL de la photo de profil de l'utilisateur
  String? get profileImageUrl =>
      _readString('profileImageUrl') ?? _readString('photoUrl');

  // ── bindAuth ──────────────────────────────────────────────────────────────

  // Lie ce provider au provider d'authentification Firebase
  // Initialise le chargement du profil quand l'utilisateur se connecte
  // Nettoie les donnees quand l'utilisateur se deconnecte
  void bindAuth(AuthProvider authProvider) {
    final firebaseUser = authProvider.user;
    if (firebaseUser == null) {
      unawaited(clear());
      return;
    }

    final uid = firebaseUser.uid;

    if (_activeUid == uid) {
      // Meme utilisateur: fusionner les donnees mise a jour
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

    // Nouvel utilisateur: reinitialiser et charger son profil
    unawaited(_initializeForUser(firebaseUser, authProvider.role));
  }

  // ── _initializeForUser ────────────────────────────────────────────────────

  // Initialise le provider pour un nouvel utilisateur
  // Charge le cache local d'abord, puis s'abonne au flux Firestore en temps reel
  Future<void> _initializeForUser(User firebaseUser, String? role) async {
    _activeUid = firebaseUser.uid;
    _isLoading = true;
    notifyListeners();

    // Annuler l'abonnement precedent s'il existe
    await _profileSubscription?.cancel();

    // Charger le cache pendant que le stream se met en place
    final cached = await _loadCached();
    if (cached != null && cached['uid'] == firebaseUser.uid) {
      _user = _composeUserData(
        firebaseUser: firebaseUser,
        role: role,
        profile: cached,
      );
      notifyListeners();
    }

    // S'abonner aux mises a jour du profil depuis Firestore
    _profileSubscription = _userService
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
            _lastError = 'Erreur chargement profil : $error';
            _isLoading = false;
            notifyListeners();
          },
        );

    _isLoading = false;
    notifyListeners();
  }

  // ── updateProfile ─────────────────────────────────────────────────────────

  // Met a jour le profil utilisateur de maniere optimiste
  // Applique les changements localement immediatement, puis persiste dans Firestore
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final uid = _activeUid;
    if (uid == null) return;

    // Mise a jour optimiste locale: appliquer les changements immediatement
    _user = <String, dynamic>{...(_user ?? {}), ...updates};
    notifyListeners();
    await _persist(_user!);

    // Persistance dans Firestore: appel direct au service
    await _userService.updateUserProfile(uid, updates);
  }

  // ── refreshProfile ────────────────────────────────────────────────────────

  // Recharge le profil depuis Firestore (force un rafraichissement)
  // Utile pour synchroniser manuellement apres une mise a jour
  Future<void> refreshProfile() async {
    final uid = _activeUid;
    if (uid == null) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final profile = await _userService.getUserProfile(uid);
      if (profile != null) {
        _user = <String, dynamic>{...(_user ?? {}), ...profile};
        await _persist(_user!);
      }
    } catch (e) {
      _lastError = 'Erreur chargement profil : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── clear ─────────────────────────────────────────────────────────────────

  // Nettoie completement le provider (utilisateur deconnecte)
  // Annule les abonnements et supprime le cache local
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

  // ── _composeUserData ──────────────────────────────────────────────────────

  // Fusionne les donnees Firebase Auth avec le profil Firestore
  // Priorise les donnees du profil, puis comble les lacunes avec Firebase Auth
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
      // Assignation medecin (patient uniquement)
      'doctorUid': _pickFirstString(profile?['doctorUid']),
      'doctorName': _pickFirstString(
        profile?['doctorName'],
        profile?['assignedDoctorName'],
      ),
      // Photo de profil
      'profileImageUrl': _pickFirstString(
        profile?['profileImageUrl'],
        profile?['photoUrl'],
        firebaseUser.photoURL,
      ),
    };
  }

  // ── Helpers prives ────────────────────────────────────────────────────────

  // Normalise le role en minuscule et valide qu'il est 'doctor' ou 'patient'
  String? _normalizeRole(dynamic raw) {
    if (raw is! String) return null;
    final value = raw.trim().toLowerCase();
    return (value == 'doctor' || value == 'patient') ? value : null;
  }

  // Retourne le premier parametre non-vide (utilisé pour l'ordre de priorite)
  String? _pickFirstString([dynamic a, dynamic b, dynamic c]) {
    for (final value in [a, b, c]) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  // Extrait une valeur string du profil utilisateur et la valide
  String? _readString(String key) {
    final value = _user?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  // Charge le profil utilisateur cache depuis SharedPreferences
  Future<Map<String, dynamic>?> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return null;
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
    } catch (_) {}
    return null;
  }

  // Persiste le profil utilisateur dans SharedPreferences
  // Utilise le JSON encode pour le stockage local
  Future<void> _persist(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = _sanitizeMapForJson(data);
    await prefs.setString(_storageKey, jsonEncode(sanitized));
  }

  // Nettoie recursivement la map pour JSON en convertissant les types non-serialisables
  Map<String, dynamic> _sanitizeMapForJson(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, _sanitizeForJson(v)));

  // Convertit les types non-serialisables en types JSON valides
  // (Timestamp -> ISO8601, DateTime -> ISO8601, Map/List recursifs)
  dynamic _sanitizeForJson(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map)
      return value.map((k, v) => MapEntry('\$k', _sanitizeForJson(v)));
    if (value is Iterable) return value.map(_sanitizeForJson).toList();
    return value;
  }

  // Compare deux maps de maniere robuste pour egales
  // Utile pour eviter les notifications inutiles si les donnees n'ont pas change
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value)
        return false;
    }
    return true;
  }

  // Nettoyage: annule les abonnements Firestore lors de la destruction du provider
  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
