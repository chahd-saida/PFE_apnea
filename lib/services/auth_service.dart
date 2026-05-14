import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ========== AUTHENTIFICATION ==========

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String userRole,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur inscription: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur connexion: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

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
    // Normalize role to lowercase to ensure consistency
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'doctor' && normalizedRole != 'patient') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Le rôle doit être "doctor" ou "patient".',
      );
    }

    final credential = await signUp(
      email: email.trim(),
      password: password,
      userRole: normalizedRole,
    );

    final user = credential.user;
    final uid = user?.uid;
    final trimmedProfileImageUrl = profileImageUrl?.trim();

    try {
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        if (trimmedProfileImageUrl != null &&
            trimmedProfileImageUrl.isNotEmpty) {
          await user.updatePhotoURL(trimmedProfileImageUrl);
        }
      }
    } catch (_) {}

    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'email': email.trim(),
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
          'createdAt': DateTime.now(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        try {
          await user?.delete();
        } catch (_) {}
        rethrow;
      }
    }

    return credential;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Aucun utilisateur connecté.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Email utilisateur indisponible.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
