import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service de messagerie pour gérer les conversations et messages entre patients et médecins
/// Gère le streaming des conversations, l'envoi de messages et les notifications push
class MessagingService {
  /// URL du backend pour envoyer les notifications push
  /// À adapter selon votre environnement (localhost, IP serveur, etc.)
  static const String _backendUrl =
      'http://TON_IP:8000'; // adapte selon ton env

  /// Constructeur avec injection optionnelle de Firestore (utile pour les tests)
  MessagingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instance de Firestore pour accéder à la base de données
  final FirebaseFirestore _firestore;

  // ========== MESSAGING ==========

  /// Stream en temps réel des conversations d'un utilisateur
  /// Retourne les conversations triées par date du dernier message (plus récentes d'abord)
  /// Paramètre:
  ///   - uid: identifiant unique de l'utilisateur
  Stream<List<Map<String, dynamic>>> streamConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        // ← PAS de orderBy ici → évite d'avoir besoin d'un index composite dans Firestore
        .snapshots()
        .map((snapshot) {
          // Convertir les documents en maps avec l'ID du document
          final list = snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();

          // Tri côté client par lastMessageAt décroissant (plus récentes en premier)
          list.sort((a, b) {
            DateTime? aTime, bTime;
            final aRaw = a['lastMessageAt'];
            final bRaw = b['lastMessageAt'];
            if (aRaw is Timestamp) aTime = aRaw.toDate();
            if (bRaw is Timestamp) bTime = bRaw.toDate();
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return list;
        });
  }

  /// Stream en temps réel des messages d'une conversation
  /// Retourne les messages triés par date croissante (les plus anciens d'abord)
  /// Paramètre:
  ///   - conversationId: identifiant unique de la conversation
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

  /// Récupère ou crée une conversation entre un médecin et un patient
  /// Si une conversation existe déjà, retourne son ID
  /// Sinon, crée une nouvelle conversation avec les informations des utilisateurs
  /// Paramètres:
  ///   - doctorUid: identifiant du médecin
  ///   - patientUid: identifiant du patient
  Future<String> getOrCreateConversation({
    required String doctorUid,
    required String patientUid,
  }) async {
    try {
      // Chercher les conversations via le patienté (autorisé pour les deux rôles)
      final query = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: patientUid)
          .get();

      // Filtrer côté client pour trouver la conversation avec ce médecin spécifique
      final existing = query.docs.where((doc) {
        final data = doc.data();
        final participants = data['participants'] as List<dynamic>? ?? [];
        return participants.contains(doctorUid);
      }).toList();

      // Retourner l'ID de la première conversation existante
      if (existing.isNotEmpty) return existing.first.id;
    } catch (_) {
      // Si la recherche échoue, on crée une nouvelle conversation
    }

    // Récupérer les noms complets des utilisateurs pour affichage
    String doctorName = 'Médecin';
    String patientName = 'Patient';

    try {
      final doctorDoc = await _firestore
          .collection('users')
          .doc(doctorUid)
          .get();
      doctorName =
          (doctorDoc.data()?['fullName'] as String?)?.trim() ?? 'Médecin';
    } catch (_) {}

    try {
      final patientDoc = await _firestore
          .collection('users')
          .doc(patientUid)
          .get();
      patientName =
          (patientDoc.data()?['fullName'] as String?)?.trim() ?? 'Patient';
    } catch (_) {}

    // Créer une nouvelle conversation avec les détails des participants
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

    // Retourner l'ID de la nouvelle conversation créée
    return ref.id;
  }

  /// Envoie un message dans une conversation
  /// Crée le message et met à jour le dernier message de la conversation
  /// Envoie également une notification push au destinataire si son UID est fourni
  /// Paramètres:
  ///   - conversationId: identifiant de la conversation
  ///   - senderId: identifiant de l'expéditeur
  ///   - senderName: nom de l'expéditeur (affiché dans le message)
  ///   - text: contenu du message
  ///   - recipientUid: identifiant du destinataire (optionnel, pour la notification)
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? recipientUid, // ← nouveau paramètre
  }) async {
    // Utiliser une batch pour garantir la cohérence des données
    final batch = _firestore.batch();

    // Créer une référence pour le nouveau message
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    // Ajouter le message à la batch
    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mettre à jour les détails de la conversation
    final convRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      // Limiter l'affichage du dernier message à 60 caractères
      'lastMessage': text.trim().length > 60
          ? '${text.trim().substring(0, 60)}...'
          : text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // Exécuter toutes les opérations de la batch de manière atomique
    await batch.commit();

    // Envoyer la notification push si on connaît le destinataire
    if (recipientUid != null && recipientUid.isNotEmpty) {
      _sendPushNotification(
        recipientUid: recipientUid,
        senderName: senderName,
        messageText: text.trim(),
        conversationId: conversationId,
      );
    }
  }

  /// Envoie une notification push au destinataire via le backend
  /// Cette méthode est non-bloquante: si l'envoi échoue, le message reste quand même sauvegardé dans Firestore
  /// Paramètres:
  ///   - recipientUid: identifiant du destinataire de la notification
  ///   - senderName: nom de l'expéditeur (affiché dans la notification)
  ///   - messageText: contenu du message (affiché dans la notification)
  ///   - conversationId: identifiant de la conversation (pour redirection)
  Future<void> _sendPushNotification({
    required String recipientUid,
    required String senderName,
    required String messageText,
    required String conversationId,
  }) async {
    try {
      // Envoyer une requête HTTP POST au backend pour déclencher la notification push
      await http
          .post(
            Uri.parse('$_backendUrl/api/notify_message'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'recipientUid': recipientUid,
              'senderName': senderName,
              'messageText': messageText,
              'conversationId': conversationId,
            }),
          )
          // Timeout de 5 secondes pour éviter les blocages
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Ne pas lever d'erreur: la notification est optionnelle
      // Le message est déjà sauvegardé dans Firestore
      debugPrint('⚠️ Notification push échouée (non bloquant): $e');
    }
  }
}
