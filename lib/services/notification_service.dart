// lib/services/notification_service.dart
import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:firebase_messaging/firebase_messaging.dart'; // Pour les notifications push FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Pour afficher les notifs locales
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour sauvegarder les tokens FCM
import 'package:firebase_auth/firebase_auth.dart'; // Pour identifier l'utilisateur
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:flutter/material.dart'; // Pour Color (iconographie)

/// Handler pour les notifications FCM reçues en ARRIÈRE-PLAN
/// Cette fonction doit être top-level (pas dans une classe) pour que Firebase la trouve
/// Elle est appelée automatiquement par FCM quand une notification arrive et l'app n'est pas au premier plan
/// Note: Les notifications avec payload 'notification' sont affichées automatiquement par FCM
@pragma(
  'vm:entry-point',
) // Indique au compilateur Dart que cette fonction doit être conservée
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé dans main.dart
  // Les notifications background sont affichées automatiquement par FCM
  debugPrint('📨 Background : ${message.notification?.title}');
}

/// Service centralisé pour gérer toutes les notifications
/// Combine Firebase Cloud Messaging (FCM) pour les notifications push et flutter_local_notifications pour l'affichage
/// Responsabilités:
/// - Demander les permissions utilisateur
/// - Créer les canaux de notification Android (obligatoire depuis Android 8)
/// - Gérer les tokens FCM et les sauvegarder dans Firestore
/// - Afficher les notifications en foreground (quand l'app est ouverte)
class NotificationService {
  // ── Pattern Singleton ─────────────────────────────────────────────────────
  // Assure qu'une seule instance du service existe dans toute l'app
  // Permet un accès global: NotificationService().method()
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Instance FirebaseMessaging pour gérer les notifications push FCM
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Instance FlutterLocalNotificationsPlugin pour afficher les notifications locales
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  // ── Canaux de Notification Android ───────────────────────────────────────
  // Obligatoires depuis Android 8.0 (API level 26)
  // Chaque canal a son propre son, vibration et importance
  // L'id doit correspondre exactement à channel_id dans le backend (main.py)

  /// Canal pour les alertes d'apnée (critiques)
  /// - Importance: max (interrompt l'utilisateur)
  /// - Son: activé
  /// - Vibration: activée
  static const AndroidNotificationChannel _apneaChannel =
      AndroidNotificationChannel(
        'apnea_alerts_channel',
        'Alertes Apnée',
        description: 'Alertes critiques d\'apnée du sommeil',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  /// Canal pour les messages du médecin
  /// - Importance: high (notification visible mais ne déverrouille pas l'écran)
  /// - Son: activé
  /// - Vibration: désactivée
  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
        'messages_channel',
        'Messages',
        description: 'Messages de votre médecin',
        importance: Importance.high,
        playSound: true,
      );

  // ── Initialisation du service de notifications ──────────────────────────
  /// Initialise le service de notifications — DOIT être appelé dans main.dart au démarrage
  /// Effectue les étapes suivantes:
  /// 1. Demande les permissions utilisateur
  /// 2. Crée les canaux Android
  /// 3. Initialise flutter_local_notifications
  /// 4. Configure la présentation des notifications en foreground
  /// 5. Met en place les listeners
  /// 6. Sauvegarde le token FCM
  Future<void> init() async {
    // Étape 1: Demander la permission aux notifications
    // Obligatoire sur iOS et Android 13+
    // Sur Android < 13, la permission est accordée automatiquement
    final settings = await _fcm.requestPermission(
      alert: true, // Permettre les alertes
      badge: true, // Permettre les badges (nombre de notifications)
      sound: true, // Permettre les sons
      provisional: false, // Demande explicite, pas provisoire
    );

    debugPrint('🔔 Permission notifications : ${settings.authorizationStatus}');

    // Si refusé sur iOS/Android 13+, on arrête ici
    // Sur Android < 13, authorized est retourné automatiquement
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Notifications refusées par l\'utilisateur');
      return;
    }

    // Étape 2: Créer les canaux Android AVANT d'initialiser flutter_local_notifications
    // Cela doit être fait sur la plateforme Android directement
    final androidPlugin = _localNotifs
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_apneaChannel);
    await androidPlugin?.createNotificationChannel(_messagesChannel);

    // Étape 3: Initialiser flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // déjà demandé via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      // Callback quand l'utilisateur tape sur une notification
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        debugPrint('🔔 Notification tapée : ${resp.payload}');
      },
    );

    // Étape 4: Configurer la présentation des notifications en FOREGROUND
    // Par défaut, les notifications FCM sont silencieuses quand l'app est ouverte
    // Cette configuration les affiche avec son et alerte
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Étape 5: Écouter les messages en foreground et les afficher via local notifs
    // Quand FCM reçoit un message et l'app est ouverte, on utilise _handleForegroundMessage
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Étape 6: Sauvegarder le token si l'utilisateur est déjà connecté
    await refreshTokenIfLoggedIn();

    // Étape 7: Écouter les renouvellements de token FCM
    // Le token peut changer à tout moment (mises à jour FCM, etc.)
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 Token FCM renouvelé');
      await _saveToken(newToken);
    });

    debugPrint('✅ NotificationService initialisé');
  }

  // ── Gestion des tokens FCM ─────────────────────────────────────────────────
  // Le token FCM identifie l'appareil et permet au backend d'envoyer des notifications
  // Il doit être sauvegardé dans Firestore pour que le backend puisse l'utiliser

  /// Récupère et sauvegarde le token FCM si l'utilisateur est déjà connecté
  /// Appelé au démarrage de l'app (dans la méthode init)
  /// Utile pour récupérer le token de l'utilisateur qui s'était connecté avant
  Future<void> refreshTokenIfLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Pas d'utilisateur connecté
    final token = await _fcm.getToken();
    if (token == null) return; // FCM pas ready
    await _saveToken(token, uid: user.uid);
  }

  /// Récupère et sauvegarde le token FCM après un login réussi
  /// Appelé depuis le contrôleur d'authentification après une connexion réussie
  /// Paramètre: uid = l'ID unique de l'utilisateur qui vient de se connecter
  Future<void> saveTokenAfterLogin(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _saveToken(token, uid: uid);
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde token après login : $e');
    }
  }

  /// Sauvegarde le token FCM dans Firestore
  /// Le token sera utilisé par le backend pour envoyer des notifications push
  /// Paramètres:
  ///   - token: le token FCM de l'appareil
  ///   - uid: (optionnel) l'ID utilisateur (utilisé si pas d'utilisateur connecté)
  Future<void> _saveToken(String token, {String? uid}) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // Impossible de sauvegarder sans utilisateur
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token, // Le token pour les notifications
        'fcmTokenUpdatedAt':
            FieldValue.serverTimestamp(), // Quand il a été mis à jour
        'notificationsEnabled':
            true, // Marquer les notifications comme activées
        'platform': Platform.isAndroid
            ? 'android'
            : 'ios', // Plateforme de l'appareil
      });
      debugPrint(
        '✅ FCM token sauvegardé pour $userId : '
        '${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde token Firestore : $e');
    }
  }

  /// Supprime le token FCM lors de la déconnexion
  /// Le backend ne pourra plus envoyer de notifications à cet appareil
  /// Appelé depuis le contrôleur d'authentification lors du logout
  Future<void> clearToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Supprimer le token de Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      // Supprimer le token localement sur l'appareil
      await _fcm.deleteToken();
      debugPrint('🗑️ FCM token supprimé');
    } catch (e) {
      debugPrint('⚠️ Erreur suppression token : $e');
    }
  }

  // ── Affichage des notifications en FOREGROUND ───────────────────────────
  // Quand l'app est ouverte, FCM n'affiche pas automatiquement les notifications
  // On doit utiliser flutter_local_notifications pour les afficher

  /// Gère l'affichage des notifications reçues quand l'app est au premier plan
  /// Appelé par le listener FirebaseMessaging.onMessage dans init()
  /// Affiche la notification avec le bon canal et le bon style selon le type
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return; // Pas de notification à afficher

    debugPrint('📨 Foreground : ${notif.title} — ${notif.body}');

    // Déterminer le type de notification pour choisir le canal et le style
    final type = message.data['type'] ?? '';
    final isApnea = type == 'apnea_alert'; // True si c'est une alerte d'apnée

    // Choisir le bon canal Android selon le type
    final channelId = isApnea ? _apneaChannel.id : _messagesChannel.id;
    final channelName = isApnea ? _apneaChannel.name : _messagesChannel.name;

    // Afficher la notification avec flutter_local_notifications
    await _localNotifs.show(
      message.hashCode, // ID unique de la notification
      notif.title, // Titre
      notif.body, // Contenu
      NotificationDetails(
        // Configuration Android
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: isApnea ? Importance.max : Importance.high, // Priorité
          priority: isApnea ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: isApnea, // Vibration seulement pour les apnées
          // Couleur de l'icône de notification selon le type
          color: isApnea
              ? const Color(0xFFEF4444) // rouge pour apnée (critique)
              : const Color(0xFF1E3A8A), // bleu pour messages (info)
        ),
        // Configuration iOS
        iOS: const DarwinNotificationDetails(
          presentAlert: true, // Afficher comme alerte
          presentBadge: true, // Afficher le badge
          presentSound: true, // Jouer le son
        ),
      ),
      payload:
          type, // Données à passer quand l'utilisateur tape sur la notification
    );
  }
}
