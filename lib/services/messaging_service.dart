import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  MessagingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ========== MESSAGING ==========

  Stream<List<Map<String, dynamic>>> streamConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<String> getOrCreateConversation({
    required String doctorUid,
    required String patientUid,
  }) async {
    final query = await _firestore
        .collection('conversations')
        .where('doctorUid', isEqualTo: doctorUid)
        .where('patientUid', isEqualTo: patientUid)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final doctorDoc = await _firestore.collection('users').doc(doctorUid).get();
    final patientDoc = await _firestore
        .collection('users')
        .doc(patientUid)
        .get();

    final doctorName =
        (doctorDoc.data()?['fullName'] as String?)?.trim() ?? 'Médecin';
    final patientName =
        (patientDoc.data()?['fullName'] as String?)?.trim() ?? 'Patient';

    final ref = await _firestore.collection('conversations').add({
      'doctorUid': doctorUid,
      'patientUid': patientUid,
      'participants': [doctorUid, patientUid],
      'doctorName': doctorName,
      'patientName': patientName,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final convRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': text.trim().length > 60
          ? '${text.trim().substring(0, 60)}...'
          : text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
