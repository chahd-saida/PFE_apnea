import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NoteService {
  NoteService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ========== NOTES / DIAGNOSIS ==========

  Future<void> saveDoctorNote({
    required String patientId,
    required String doctorUid,
    required String doctorName,
    required String note,
    String? measurementId,
    String? diagnosis,
  }) async {
    await _firestore.collection('notes').add({
      'patientId': patientId,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'note': note.trim(),
      'diagnosis': diagnosis?.trim(),
      'measurementId': measurementId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamPatientNotes(String patientId) {
    return _firestore
        .collection('notes')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getPatientNotes(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('Erreur récupération notes: $e');
      return [];
    }
  }
}
