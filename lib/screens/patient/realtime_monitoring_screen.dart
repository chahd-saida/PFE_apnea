// lib/screens/patient/realtime_monitoring_screen.dart
//
// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN DE SURVEILLANCE TEMPS RÉEL — RealtimeMonitoringScreen
// ═══════════════════════════════════════════════════════════════════════════════
//
// Rôle : Affiche en temps réel les données de l'ESP32 (BPM, SpO₂, température,
//         position, ECG) reçues via WebSocket, avec graphiques et journal d'alertes.
//
// CORRECTION APPORTÉE (sans modifier l'affichage) :
//   • _addEvent() écrit maintenant chaque alerte dans Firestore via AlertService
//     afin que le médecin puisse les voir dans son centre d'alertes.
//   • Un throttle de 30 secondes par type d'alerte évite le flood Firestore.
//   • Le doctorUid est résolu automatiquement depuis le profil patient
//     (délégué à alert_service.dart qui lit 'assignedDoctorId' dans Firestore).
//   • Tous les widgets, painters, layouts et comportements sont INCHANGÉS.
// ═══════════════════════════════════════════════════════════════════════════════

// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_theme.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/monitoring_provider.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/monitoring_service.dart';
import 'package:apnea_project/services/alert_service.dart'; // ← AJOUT : service alertes Firestore
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — inchangés
// ─────────────────────────────────────────────────────────────────────────────
const _navy = Color(0xFF1E3A8A); // Bleu marine — SpO₂ et bouton démarrage
const _teal = Color(0xFF4DBDB8); // Turquoise — chronomètre et accents
const _purple = Color(0xFF7C3AED); // Violet — position/accéléromètre
const _red = Color(0xFFEF5350); // Rouge — FC, alarmes critiques
const _green = Color(0xFF00BFA5); // Vert — température, statut OK
const _orange = Color(0xFFF57C00); // Orange — avertissements
const _cardDk = Color(0xFF161D2E); // Fond des cartes en mode sombre

// ─────────────────────────────────────────────────────────────────────────────
// ESP DATA MODEL — inchangé
// Représente une trame de données reçue via WebSocket depuis l'ESP32.
// Les deux sous-objets du JSON sont 'donnees' (capteurs bruts) et 'ia'
// (résultat du modèle de stacking RF+ET+LightGBM côté serveur FastAPI).
// ─────────────────────────────────────────────────────────────────────────────
class _EspData {
  // ── Données capteurs (ESP32) ───────────────────────────────────────────────
  final double bpm, spo2, temperature, bpmEcg; // MAX30102 + AD8232
  final bool electrodesOk, alarmeActive, doigtDetecte;
  final String position, raisonAlarme; // MPU6050
  final double accX, accY, accZ; // Accéléromètre
  final DateTime receivedAt; // Horodatage réception locale

  // ── Résultats IA (FastAPI) ─────────────────────────────────────────────────
  final bool apnee; // true si apnée détectée par le modèle de stacking
  final double score, confiance; // Score global et confiance du modèle (0→1)
  final String severite, messageIa; // "modere"/"severe" + message explicatif

  const _EspData({
    this.bpm = 0,
    this.spo2 = 0,
    this.temperature = 0,
    this.bpmEcg = 0,
    this.electrodesOk = true,
    this.alarmeActive = false,
    this.doigtDetecte = false,
    this.position = 'INCONNU',
    this.raisonAlarme = '',
    this.accX = 0,
    this.accY = 0,
    this.accZ = 0,
    required this.receivedAt,
    this.apnee = false,
    this.score = 0,
    this.confiance = 0,
    this.severite = '',
    this.messageIa = '',
  });

  /// Désérialise une trame WebSocket réelle provenant de l'ESP32.
  /// Le JSON a deux sous-objets : 'donnees' (capteurs) et 'ia' (modèle IA).
  /// Chaque champ a un fallback défensif (?? 0, ?? false, ?? '') pour ne
  /// jamais planter si un champ est absent ou null.
  factory _EspData.fromWebSocket(Map<String, dynamic> raw) {
    final d = raw['donnees'] as Map<String, dynamic>? ?? {};
    final ia = raw['ia'] as Map<String, dynamic>? ?? {};
    return _EspData(
      bpm: (d['bpm'] as num?)?.toDouble() ?? 0,
      spo2: (d['spo2'] as num?)?.toDouble() ?? 0,
      temperature: (d['temperature'] as num?)?.toDouble() ?? 0,
      bpmEcg: (d['bpm_ecg'] as num?)?.toDouble() ?? 0,
      electrodesOk: (d['electrodes_ok'] as bool?) ?? true,
      alarmeActive: (d['alarme_active'] as bool?) ?? false,
      doigtDetecte: (d['doigt_detecte'] as bool?) ?? false,
      position: (d['position'] as String?) ?? 'INCONNU',
      raisonAlarme: (d['raison_alarme'] as String?) ?? '',
      accX: (d['acc_x'] as num?)?.toDouble() ?? 0,
      accY: (d['acc_y'] as num?)?.toDouble() ?? 0,
      accZ: (d['acc_z'] as num?)?.toDouble() ?? 0,
      receivedAt: DateTime.now(),
      apnee: (ia['apnee'] as bool?) ?? false,
      score: (ia['score'] as num?)?.toDouble() ?? 0,
      confiance: (ia['confiance'] as num?)?.toDouble() ?? 0,
      severite: (ia['severite'] as String?) ?? '',
      messageIa: (ia['message'] as String?) ?? '',
    );
  }

  /// Désérialise une trame simulée (MonitoringService) utilisée quand
  /// l'ESP32 physique est absent. Permet de tester l'UI sans matériel.
  // factory _EspData.fromSimulated(Map<String, dynamic> payload) => _EspData(
  //bpm:         (payload['heartRate']   as num?)?.toDouble() ?? 0,
  //spo2:        (payload['spo2']        as num?)?.toDouble() ?? 0,
  // temperature: (payload['temperature'] as num?)?.toDouble() ?? 36.5,
  // doigtDetecte: true,
  // electrodesOk: true,
  // receivedAt: DateTime.now(),
  //);

  factory _EspData.fromSimulated(Map<String, dynamic> payload) {
    final isApnea = (payload['_simPhase'] as String?) == 'apnea';
    final progress = (payload['_simProgress'] as double?) ?? 0.0;
    final score = isApnea ? (0.3 + progress * 0.6).clamp(0.0, 1.0) : 0.05;
    final confiance = isApnea ? (0.25 + progress * 0.65).clamp(0.0, 1.0) : 0.04;
    final apnee = isApnea && score >= 0.5;
    final severite = !isApnea
        ? ''
        : score >= 0.8
        ? 'severe'
        : score >= 0.6
        ? 'modere'
        : 'legere';
    final messageIa = !isApnea
        ? ''
        : score >= 0.8
        ? 'Apnée sévère — SpO₂ critique'
        : score >= 0.6
        ? 'Apnée modérée détectée'
        : 'Début de désaturation';
    return _EspData(
      bpm: (payload['heartRate'] as num?)?.toDouble() ?? 0,
      spo2: (payload['spo2'] as num?)?.toDouble() ?? 0,
      temperature: (payload['temperature'] as num?)?.toDouble() ?? 36.5,
      doigtDetecte: true,
      electrodesOk: true,
      receivedAt: DateTime.now(),
      apnee: apnee,
      score: score,
      confiance: confiance,
      severite: severite,
      messageIa: messageIa,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RealtimeMonitoringScreen extends StatefulWidget {
  /// [monitoringService] : injecteur de dépendance pour les tests unitaires.
  /// En production, null → MonitoringService() est instancié.
  const RealtimeMonitoringScreen({super.key, this.monitoringService});
  final MonitoringService? monitoringService;

  @override
  State<RealtimeMonitoringScreen> createState() =>
      _RealtimeMonitoringScreenState();
}

class _RealtimeMonitoringScreenState extends State<RealtimeMonitoringScreen>
    with TickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────────────────────
  late final MonitoringService _monitoringService;
  final MeasurementService _measurementService = MeasurementService();

  // ── AJOUT : AlertService pour écrire les alertes dans Firestore ───────────
  // Instancié une seule fois et réutilisé dans _addEvent().
  // Le doctorUid est résolu automatiquement par le service depuis le profil
  // Firestore du patient (champ 'assignedDoctorId').
  final AlertService _alertService = AlertService();

  // ── AJOUT : Throttle anti-flood Firestore ─────────────────────────────────
  // Évite d'écrire la même alerte (même titre) plus d'une fois par 30 secondes.
  // Clé : titre de l'alerte | Valeur : DateTime du dernier envoi Firestore.
  final Map<String, DateTime> _lastFirestoreAlert = {};
  static const Duration _alertCooldown = Duration(seconds: 30);

  // ── État WebSocket / session ───────────────────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _streamSub; // Stream simulé
  bool _isMonitoring = false; // Surveillance active ?
  bool _isConnected = false; // ESP32 connecté via WebSocket ?
  DateTime? _sessionStart; // Heure de début de session

  // ── Buffers de données ────────────────────────────────────────────────────
  _EspData? _live; // Dernière trame reçue
  final List<_EspData> _history = []; // 40 dernières trames (graphiques)
  final List<Map<String, dynamic>> _events = []; // Journal local (15 max)
  final List<double> _bpmHist = []; // Historique BPM pour moyennes
  final List<double> _spo2Hist = []; // Historique SpO₂ pour moyennes

  static const int _maxHistory = 40; // Taille du buffer glissant

  int _apneaCount = 0; //compteur des apnées
  DateTime?
  _lastApneaCountedAt; // Cooldown pour éviter de compter la même apnée plusieurs fois

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl; // Point clignotant AppBar
  late final AnimationController _fadeCtrl; // Fondu d'entrée de l'écran
  late final AnimationController _slideCtrl; // Glissement des cartes
  late final AnimationController _btnCtrl; // Pulsation du bouton démarrage
  late final AnimationController _heartCtrl; // Battement de l'icône FC

  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;

  // ── initState ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _monitoringService = widget.monitoringService ?? MonitoringService();

    // Animations définies une seule fois pour toute la durée de vie de l'écran.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true); // Aller-retour en boucle (0→1→0→1…)

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward(); // Joue une seule fois au démarrage

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Déclenche l'animation de slide 200ms après le build
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideCtrl.forward();
    });

    // ── Brancher le WebSocket via MonitoringProvider ───────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid ?? 'patient_unknown';
      final monitor = context.read<MonitoringProvider>();

      // ÉTAPE 1 : démarrer le WebSocket
      monitor.startMonitoring(uid);

      // ÉTAPE 2 : attacher les callbacks du screen
      // Dans initState → WidgetsBinding.instance.addPostFrameCallback
      monitor.attachScreenCallbacks(
        onConnectionChanged: (connected) {
          if (mounted) setState(() => _isConnected = connected);
        },
        onDonnees: (raw) {
          if (!mounted || !_isMonitoring) return;

          final esp = _EspData.fromWebSocket(raw); // ← esp est défini ICI
          _onData(esp);

          if (esp.alarmeActive && esp.raisonAlarme.isNotEmpty) {
            _addEvent(
              esp.raisonAlarme,
              'critical',
              Icons.warning_amber_rounded,
            );
          }

          // ✅ CORRECTION — bloc apnée avec cooldown
          if (esp.apnee &&
              (esp.severite == 'modere' || esp.severite == 'severe')) {
            _addEvent(
              'Apnée ${esp.severite.toUpperCase()} — IA: ${(esp.confiance * 100).round()}%',
              'critical',
              Icons.air_outlined,
            );
            final now = DateTime.now();
            if (_lastApneaCountedAt == null ||
                now.difference(_lastApneaCountedAt!) >=
                    const Duration(seconds: 60)) {
              setState(() => _apneaCount++);
              _lastApneaCountedAt = now;
              debugPrint('🫁 Apnée comptée : $_apneaCount');
            }
          }
        },
      );

      // Vérifier la disponibilité du serveur FastAPI
      ApiService().checkHealth().then((online) {
        if (mounted) {
          debugPrint(
            '🖥️ Serveur FastAPI: ${online ? "EN LIGNE" : "HORS LIGNE"}',
          );
        }
      });
    });
  }

  // ── dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _streamSub?.cancel(); // Arrêter le stream simulé
    _sessionTimer?.cancel();
    // Libérer tous les AnimationControllers pour éviter les fuites mémoire
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _btnCtrl.dispose();
    _heartCtrl.dispose();
    _monitoringService.dispose(); // Fermer la connexion WebSocket proprement
    super.dispose();
  }

  // ── _onData ────────────────────────────────────────────────────────────────
  /// Traite une nouvelle trame de données ESP32.
  /// Met à jour les buffers et déclenche les vérifications de seuils médicaux.
  void _onData(_EspData esp) {
    setState(() {
      _live = esp;
      _history.add(esp);
      if (_history.length > _maxHistory) _history.removeAt(0); // Buffer FIFO

      if (esp.bpm > 0) _bpmHist.add(esp.bpm);
      if (esp.spo2 > 0) _spo2Hist.add(esp.spo2);

      _heartCtrl.forward(from: 0); // Déclenche l'animation de battement

      // ── Vérifications des seuils médicaux ─────────────────────────────
      // SpO₂ < 90% = critique selon OMS
      if (esp.spo2 > 0 && esp.spo2 < 90)
        _addEvent(
          'SpO₂ critique : ${esp.spo2.round()}%',
          'critical',
          Icons.warning,
        );
      // 90–94% = bas
      else if (esp.spo2 > 0 && esp.spo2 < 94)
        _addEvent(
          'SpO₂ bas : ${esp.spo2.round()}%',
          'warning',
          Icons.info_outline,
        );

      // Tachycardie > 100 bpm
      if (esp.bpm > 0 && esp.bpm > 100)
        _addEvent(
          'Tachycardie : ${esp.bpm.round()} bpm',
          'warning',
          Icons.favorite,
        );

      // Fièvre > 38°C
      if (esp.temperature > 38.0)
        _addEvent(
          'Fièvre : ${esp.temperature.toStringAsFixed(1)}°C',
          'warning',
          Icons.thermostat,
        );

      // MAX30102 mal positionné
      if (!esp.doigtDetecte && esp.spo2 == 0)
        _addEvent('Doigt non détecté (MAX30102)', 'info', Icons.touch_app);

      // AD8232 mal connecté
      if (!esp.electrodesOk)
        _addEvent(
          'Électrodes ECG non connectées (AD8232)',
          'critical',
          Icons.electrical_services,
        );
    });
  }

  // ── _addEvent ──────────────────────────────────────────────────────────────
  /// Ajoute une alerte dans le journal local ET dans Firestore.
  ///
  /// CORRECTION PRINCIPALE :
  ///   Avant : seul setState() était appelé → alerte visible uniquement dans
  ///   le journal local du patient, jamais dans le dashboard médecin.
  ///
  ///   Après : AlertService.createAlert() est appelé de façon asynchrone
  ///   (sans bloquer l'UI) pour écrire l'alerte dans Firestore avec le
  ///   doctorUid du patient. Le médecin la voit alors dans son centre d'alertes.
  ///
  /// Throttle anti-flood :
  ///   La même alerte (même titre) ne peut pas être envoyée à Firestore plus
  ///   d'une fois par [_alertCooldown] (30 s). Le journal local n'est pas
  ///   affecté par ce throttle (il conserve sa logique de dédoublonnage à 10 s).
  void _addEvent(String title, String severity, IconData icon) {
    final now = DateTime.now();

    // ── Dédoublonnage local (10 s) — logique originale inchangée ─────────
    if (_events.any(
      (e) =>
          e['title'] == title &&
          now.difference(e['timestamp'] as DateTime).inSeconds < 10,
    )) {
      return;
    }

    // ── Mise à jour du journal local (affichage patient) ─────────────────
    setState(() {
      _events.insert(0, {
        'title': title,
        'severity': severity,
        'icon': icon,
        'timestamp': now,
      });
      if (_events.length > 15) _events.removeLast(); // Max 15 alertes locales

      // Incrémenter le compteur d'apnées si c'est une alerte de type apnée
      if (title.toLowerCase().contains('apnée') ||
          title.toLowerCase().contains('apnea')) {
        _apneaCount++;
      }
    });

    // ── AJOUT : Écriture dans Firestore (pour le médecin) ─────────────────
    // Throttle 30 s : on n'envoie pas la même alerte à Firestore trop souvent
    // pour éviter de saturer la base (les données arrivent à 1 Hz).
    final lastSent = _lastFirestoreAlert[title];
    if (lastSent != null && now.difference(lastSent) < _alertCooldown) {
      // Toujours sous cooldown → ne pas ré-envoyer à Firestore
      return;
    }
    _lastFirestoreAlert[title] =
        now; // Mettre à jour l'horodatage du dernier envoi

    // Récupérer l'UID Firebase du patient connecté
    final patientId = context.read<AuthProvider>().user?.uid;
    if (patientId == null || patientId.isEmpty) return;

    // Écriture asynchrone — ne bloque pas l'UI (pas de await ici)
    // Le doctorUid est résolu automatiquement par AlertService depuis le profil
    // Firestore du patient (champ 'assignedDoctorId' ou 'doctorUid').
    _alertService
        .createAlert(
          patientId: patientId,
          severity: severity,
          message: title,
          type: _typeFromTitle(title), // Convertit le titre en type Firestore
        )
        .catchError((e) {
          // Erreur silencieuse — ne pas interrompre le monitoring
          debugPrint('[RealtimeMonitoring] ⚠️ Erreur Firestore alerte: $e');
        });
  }

  // ── _typeFromTitle ─────────────────────────────────────────────────────────
  /// Convertit le titre d'une alerte locale en type Firestore standardisé.
  /// Ces types correspondent aux valeurs attendues par AlertService.getAlertTypeLabel().
  String _typeFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('spo') || t.contains('saturation')) return 'spo2';
    if (t.contains('bpm') ||
        t.contains('tachycardie') ||
        t.contains('bradycardie') ||
        t.contains('cardiaque'))
      return 'heartRate';
    if (t.contains('apnée') || t.contains('apnea')) return 'apnea';
    if (t.contains('fièvre') || t.contains('temp')) return 'temperature';
    if (t.contains('ecg') || t.contains('électrode')) return 'ecg';
    return 'general';
  }

  // ── _toggleMonitoring ──────────────────────────────────────────────────────
  void _toggleMonitoring() =>
      _isMonitoring ? _stopMonitoring() : _startMonitoring();

  // ── _startMonitoring ───────────────────────────────────────────────────────
  /// Démarre la session de surveillance.
  /// Réinitialise tous les buffers et le throttle Firestore de la session précédente.
  void _startMonitoring() {
    _history.clear();
    _bpmHist.clear();
    _spo2Hist.clear();
    _events.clear();
    _lastFirestoreAlert.clear(); // Réinitialiser le throttle Firestore

    _apneaCount = 0;
    _lastApneaCountedAt = null; // Réinitialiser le cooldown d'apnées
    // Remettre le compteur à zéro à chaque nouvelle session

    _sessionStart = DateTime.now();
    _sessionDuration = Duration.zero;

    // Chronomètre : tick toutes les secondes
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted)
        setState(() => _sessionDuration += const Duration(seconds: 1));
    });

    // Abonnement au stream simulé — utilisé seulement si pas de données ESP32
    // réelles depuis plus de 3 secondes (fallback données de test)
    _streamSub?.cancel();
    _streamSub = _monitoringService.stream.listen((payload) {
      if (!mounted || !_isMonitoring) return;
      final lastReal = _live?.receivedAt;
      // Utiliser la simulation UNIQUEMENT si pas de données réelles depuis 3 s
      if (lastReal == null ||
          DateTime.now().difference(lastReal).inSeconds > 3) {
        final esp = _EspData.fromSimulated(payload);
        _onData(esp);

        // ✅ Comptage apnées — même logique que dans onDonnees
        if (esp.apnee &&
            (esp.severite == 'modere' || esp.severite == 'severe')) {
          _addEvent(
            'Apnée ${esp.severite.toUpperCase()} — IA: ${(esp.confiance * 100).round()}%',
            'critical',
            Icons.air_outlined,
          );
          final now = DateTime.now();
          if (_lastApneaCountedAt == null ||
              now.difference(_lastApneaCountedAt!) >=
                  const Duration(seconds: 60)) {
            setState(() => _apneaCount++);
            _lastApneaCountedAt = now;
            debugPrint('🫁 Apnée comptée : $_apneaCount');
          }
        }
      }
    });

    _monitoringService.startMonitoring();
    setState(() => _isMonitoring = true);
    _btnCtrl.repeat(reverse: true); // Pulsation du bouton "Arrêter"

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Surveillance démarrée'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── _stopMonitoring ────────────────────────────────────────────────────────
  /// Arrête la session et sauvegarde les moyennes dans Firestore via MeasurementService.
  Future<void> _stopMonitoring() async {
    final user = context.read<AuthProvider>().user;

    _monitoringService.stopMonitoring();
    await _streamSub?.cancel();
    _streamSub = null;
    _sessionTimer?.cancel();
    _btnCtrl.stop();

    // Calcul des moyennes sur toute la session et sauvegarde Firestore
    final end = DateTime.now();
    final start = _sessionStart;
    if (start != null &&
        user != null &&
        _bpmHist.isNotEmpty &&
        _spo2Hist.isNotEmpty) {
      try {
        await _measurementService.saveMonitoringSession(
          uid: user.uid,
          startTime: start,
          endTime: end,
          averageHeartRate: _bpmHist.reduce((a, b) => a + b) / _bpmHist.length,
          averageSpo2: _spo2Hist.reduce((a, b) => a + b) / _spo2Hist.length,
          apneas: _apneaCount, // passer le vrai compteur
        );
        debugPrint('✅ Session sauvegardée');
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde session: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isMonitoring = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.stop, color: Colors.white),
            SizedBox(width: 8),
            Text('Surveillance arrêtée'),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    // Synchronise _isConnected depuis le provider sans déclencher un rebuild
    // pendant le build (addPostFrameCallback diffère après le rendu)
    if (monitor.isConnected != _isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isConnected = monitor.isConnected);
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : AppColors.background,
      appBar: _buildAppBar(isDark),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Barre de statut session + connexion ────────────────────
              _SessionBar(
                isMonitoring: _isMonitoring,
                isConnected: _isConnected,
                isSimulating: !_isConnected && _isMonitoring,
                duration: _sessionDuration,
                isDark: isDark,
                onReconnect: () =>
                    context.read<MonitoringProvider>().reconnecter(),
              ),
              const SizedBox(height: 12),

              // ── Bannière résultat IA (si monitoring actif et sévérité non vide)
              if (_isMonitoring &&
                  _live != null &&
                  _live!.severite.isNotEmpty) ...[
                _IaBanner(data: _live!, isDark: isDark),
                const SizedBox(height: 10),
              ],

              // ── Statut des 4 capteurs (si monitoring actif)
              if (_isMonitoring && _live != null) ...[
                _SensorRow(data: _live!, isDark: isDark),
                const SizedBox(height: 12),
              ],

              // ── Carte fréquence cardiaque ──────────────────────────────
              _VitalCard(
                label: 'Fréquence cardiaque',
                value: _live?.bpm.round().toString() ?? '—',
                sub: _live != null && _live!.bpmEcg > 0
                    ? 'ECG: ${_live!.bpmEcg.round()} bpm'
                    : null,
                unit: 'bpm',
                icon: Icons.favorite_rounded,
                iconColor: _red,
                iconBg: const Color(0xFFFFEBEE),
                chartColor: _red,
                history: _history.map((e) => e.bpm).toList(),
                isMonitoring: _isMonitoring,
                isDark: isDark,
                heartCtrl: _heartCtrl,
                warning: _live != null && _live!.bpm > 100,
              ),
              const SizedBox(height: 10),

              // ── Carte SpO₂ ────────────────────────────────────────────
              _VitalCard(
                label: 'Saturation SpO₂',
                value: _live?.spo2.round().toString() ?? '—',
                unit: '%',
                icon: Icons.water_drop_rounded,
                iconColor: _navy,
                iconBg: const Color(0xFFE3F2FD),
                chartColor: _navy,
                history: _history.map((e) => e.spo2).toList(),
                isMonitoring: _isMonitoring,
                isDark: isDark,
                warning: _live != null && _live!.spo2 < 94 && _live!.spo2 > 0,
                critical: _live != null && _live!.spo2 < 90 && _live!.spo2 > 0,
              ),
              const SizedBox(height: 10),

              // ── Carte température ─────────────────────────────────────
              _VitalCard(
                label: 'Température corporelle',
                value: _live != null
                    ? _live!.temperature.toStringAsFixed(1)
                    : '—',
                unit: '°C',
                icon: Icons.thermostat_rounded,
                iconColor: _green,
                iconBg: const Color(0xFFE0F7F4),
                chartColor: _green,
                history: _history.map((e) => e.temperature).toList(),
                isMonitoring: _isMonitoring,
                isDark: isDark,
                warning: _live != null && _live!.temperature > 38.0,
              ),
              const SizedBox(height: 14),

              // ── Carte position + accéléromètre (si monitoring actif) ──
              if (_isMonitoring && _live != null) ...[
                _PositionCard(data: _live!, isDark: isDark),
                const SizedBox(height: 14),
              ],

              // ── Graphique multi-courbes temps réel ────────────────────
              _GraphCard(history: _history, isDark: isDark),
              const SizedBox(height: 14),

              // ── Journal des alertes locales ────────────────────────────
              _EventsCard(events: _events, isDark: isDark),
              const SizedBox(height: 14),

              // ── Bouton Démarrer / Arrêter ──────────────────────────────
              _CtrlBtn(
                isMonitoring: _isMonitoring,
                ctrl: _btnCtrl,
                onTap: _toggleMonitoring,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  /// AppBar avec titre, point de connexion animé et bouton paramètres.
  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
    backgroundColor: isDark ? const Color(0xFF0D1117) : _navy,
    foregroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () => context.canPop()
          ? context.pop()
          : context.go(RouteNames.patientDashboard),
    ),
    title: Row(
      children: [
        const Expanded(
          child: Text(
            'Surveillance Temps Réel',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Point clignotant : vert = ESP32 connecté, rouge = déconnecté
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? const Color(0xFF4ADE80) : _red,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? const Color(0xFF4ADE80) : _red)
                      .withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings_rounded, size: 20),
        onPressed: () => context.go(RouteNames.patientSettings),
      ),
    ],
  );

  // ── BottomNavigationBar ────────────────────────────────────────────────────
  Widget _buildNavBar() => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: 2,
    selectedItemColor: _navy,
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_rounded),
        label: 'Historique',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.monitor_heart_rounded),
        label: 'Surveil.',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.spa_rounded), label: 'Détente'),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded),
        label: 'Param.',
      ),
    ],
    onTap: (i) {
      switch (i) {
        case 0:
          context.go(RouteNames.patientDashboard);
          break;
        case 1:
          context.go(RouteNames.patientHistory);
          break;
        case 2:
          context.go(RouteNames.realtimeMonitoring);
          break;
        case 3:
          context.go(RouteNames.relaxation);
          break;
        case 4:
          context.go(RouteNames.patientSettings);
          break;
      }
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION BAR — inchangée
// Affiche le statut actif/inactif, le chronomètre et l'état de connexion ESP32.
// ─────────────────────────────────────────────────────────────────────────────
class _SessionBar extends StatelessWidget {
  //final bool isMonitoring, isConnected, isDark;
  final bool isMonitoring, isConnected, isDark, isSimulating;

  final Duration duration;
  final VoidCallback onReconnect;
  const _SessionBar({
    required this.isMonitoring,
    required this.isConnected,
    required this.isDark,
    required this.duration,
    required this.isSimulating,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? _cardDk : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // Pastille statut ACTIF / Inactif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isMonitoring
                ? _red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMonitoring ? _red : Colors.grey,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isMonitoring ? 'ACTIF' : 'Inactif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isMonitoring ? _red : Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Chronomètre (visible uniquement pendant le monitoring)
        if (isMonitoring) ...[
          const SizedBox(width: 10),
          const Icon(Icons.timer_outlined, size: 12, color: _teal),
          const SizedBox(width: 4),
          Text(
            // Format MM:SS — padLeft(2,'0') → "3:5" devient "03:05"
            '${duration.inMinutes.toString().padLeft(2, '0')}:'
            '${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
          ),
        ],
        const Spacer(),

        // Statut connexion WiFi/ESP32
        Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          size: 13,
          color: isConnected ? const Color(0xFF10B981) : Colors.grey,
        ),
        const SizedBox(width: 4),

        //Text(
        // isConnected ? 'ESP32 connecté' : 'Déconnecté',
        //style: TextStyle(
        // fontSize: 10,
        // color: isConnected ? const Color(0xFF10B981) : Colors.grey,
        // ),
        //),
        Text(
          isConnected ? 'ESP32 connecté' : 'Déconnecté',
          style: TextStyle(
            fontSize: 10,
            color: isConnected ? const Color(0xFF10B981) : Colors.grey,
          ),
        ),
        if (!isConnected && isSimulating) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _orange.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'SIM',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _orange,
              ),
            ),
          ),
        ],

        // Bouton Reconnecter (visible seulement si déconnecté)
        if (!isConnected) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 11, color: _orange),
                  SizedBox(width: 3),
                  Text(
                    'Reconnecter',
                    style: TextStyle(
                      fontSize: 9,
                      color: _orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IA BANNER — inchangée
// Affiche le résultat binaire du modèle de stacking (apnée / normal)
// avec la barre de score de confiance.
// ─────────────────────────────────────────────────────────────────────────────
class _IaBanner extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _IaBanner({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ok = !data.apnee;
    final color = ok ? const Color(0xFF10B981) : _red;
    final bg = ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon = ok
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                ok
                    ? '✅ Aucune apnée détectée'
                    : '🚨 Apnée détectée — ${data.severite.toUpperCase()}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (data.messageIa.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data.messageIa,
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Score IA ',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  // Barre de progression = score de confiance du modèle (0→1)
                  child: LinearProgressIndicator(
                    value: data.score,
                    minHeight: 5,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(data.score * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SENSOR STATUS ROW — inchangée
// Affiche l'état des 4 capteurs : MAX30102, AD8232, DS18B20, MPU6050.
// ─────────────────────────────────────────────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _SensorRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sensors = [
      (
        label: 'MAX30102',
        sub: 'SpO₂/HR',
        ok: data.doigtDetecte,
        icon: Icons.fingerprint,
      ),
      (
        label: 'AD8232',
        sub: 'ECG',
        ok: data.electrodesOk,
        icon: Icons.electrical_services,
      ),
      (
        label: 'DS18B20',
        sub: 'Temp',
        ok: data.temperature > 0,
        icon: Icons.thermostat_rounded,
      ),
      (
        label: 'MPU6050',
        sub: 'Accel',
        ok: true,
        icon: Icons.screen_rotation_rounded,
      ),
    ];

    return Row(
      children: sensors.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final color = s.ok ? const Color(0xFF10B981) : _red;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < sensors.length - 1 ? 8 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 16, color: color),
                  const SizedBox(height: 3),
                  Text(
                    s.sub,
                    style: TextStyle(
                      fontSize: 8,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    s.label,
                    style: TextStyle(fontSize: 7, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.ok ? const Color(0xFF10B981) : _red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VITAL CARD — inchangée
// Carte affichant une valeur vitale (BPM, SpO₂, Temp) avec mini-graphique.
// La bordure et l'ombre changent de couleur selon l'état d'alerte.
// ─────────────────────────────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final String label, value, unit;
  final String? sub;
  final IconData icon;
  final Color iconColor, iconBg, chartColor;
  final List<double> history;
  final bool isMonitoring, isDark, warning, critical;
  final AnimationController? heartCtrl;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    this.sub,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.chartColor,
    required this.history,
    required this.isMonitoring,
    required this.isDark,
    this.warning = false,
    this.critical = false,
    this.heartCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final alertColor = critical ? _red : _orange;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _cardDk : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (critical || warning)
              ? alertColor.withValues(alpha: 0.5)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
          // Bordure plus épaisse en état d'alerte
          width: (critical || warning) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            // Halo coloré en état d'alerte
            color: (critical || warning)
                ? alertColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône avec animation de battement cardiaque (pour la FC uniquement)
          AnimatedBuilder(
            animation: heartCtrl ?? const AlwaysStoppedAnimation(0),
            builder: (_, __) => Transform.scale(
              // Léger zoom à chaque nouvelle trame (_heartCtrl.forward(from:0))
              scale: heartCtrl != null ? 1.0 + 0.08 * heartCtrl!.value : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Valeur numérique + unité
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: (critical || warning)
                            ? alertColor
                            : (isDark ? Colors.white : const Color(0xFF1A365D)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // Mini sparkline (courbe des 15 dernières valeurs)
          SizedBox(
            width: 80,
            height: 42,
            child: isMonitoring && history.length >= 2
                ? CustomPaint(painter: SparklinePainter(history, chartColor))
                : CustomPaint(
                    painter: FlatLinePainter(
                      chartColor.withValues(alpha: 0.35),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POSITION CARD (MPU6050) — inchangée
// Affiche la position du patient et les axes X/Y/Z/|G| de l'accéléromètre.
// ─────────────────────────────────────────────────────────────────────────────
class _PositionCard extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _PositionCard({required this.data, required this.isDark});

  IconData _icon(String p) {
    switch (p.toUpperCase()) {
      case 'DOS':
      case 'VENTRE':
        return Icons.airline_seat_flat;
      case 'COUCHE_GAUCHE':
      case 'COUCHE_DROITE':
        return Icons.airline_seat_flat_angled;
      case 'ASSIS':
        return Icons.airline_seat_recline_normal;
      default:
        return Icons.device_unknown_rounded;
    }
  }

  Color _color(String p) {
    switch (p.toUpperCase()) {
      case 'DOS':
      case 'VENTRE':
        return _orange;
      default:
        return _teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final posColor = _color(data.position);
    // Norme du vecteur d'accélération → détecte les mouvements brusques
    final mag = math.sqrt(
      data.accX * data.accX + data.accY * data.accY + data.accZ * data.accZ,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _cardDk : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.screen_rotation_rounded,
                size: 13,
                color: _purple,
              ),
              const SizedBox(width: 6),
              Text(
                'Position & Accéléromètre',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Icône position avec fond coloré
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: posColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: posColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon(data.position), color: posColor, size: 26),
                    const SizedBox(height: 2),
                    Text(
                      data.position.length > 8
                          ? data.position.substring(0, 8)
                          : data.position,
                      style: TextStyle(fontSize: 7, color: Colors.grey[500]),
                    ),
                    Text(
                      'Position',
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Barres X/Y/Z/|G|
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _accBar('X', data.accX, _red, isDark),
                    const SizedBox(height: 5),
                    _accBar('Y', data.accY, _green, isDark),
                    const SizedBox(height: 5),
                    _accBar('Z', data.accZ, _navy, isDark),
                    const SizedBox(height: 5),
                    _accBar('|G|', mag, _purple, isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accBar(String axis, double val, Color color, bool isDark) => Row(
    children: [
      SizedBox(
        width: 22,
        child: Text(
          axis,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (val.abs() / 20).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        val.toStringAsFixed(1),
        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GRAPH CARD — inchangée
// Graphique temps réel multi-courbes FC / SpO₂ / Température.
// Les données sont filtrées (zéros du démarrage ignorés) et normalisées
// sur des plages médicales fixes pour permettre la comparaison visuelle.
// ─────────────────────────────────────────────────────────────────────────────
class _GraphCard extends StatelessWidget {
  final List<_EspData> history;
  final bool isDark;
  const _GraphCard({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Filtrer les données invalides (zéros du démarrage → évite les pics à 0)
    final validHistory = history
        .where((e) => e.bpm > 0 && e.spo2 > 0 && e.temperature > 30)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _cardDk : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 14, color: _teal),
              const SizedBox(width: 6),
              Text(
                'Graphique temps réel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF1A365D),
                ),
              ),
              const Spacer(),
              Text(
                '${validHistory.length}/${_RealtimeMonitoringScreenState._maxHistory} pts',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ClipRect empêche le débordement du canvas CustomPaint
          ClipRect(
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: validHistory.length < 3
                  ? Center(
                      child: Text(
                        'En attente de données…',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: CustomPaint(
                        painter: GraphPainter(validHistory, isDark),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Légende des 3 courbes
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _leg('FC (bpm)', _red),
              _leg('SpO₂ (%)', _navy),
              _leg('Temp (°C)', _green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leg(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS CARD — inchangée
// Journal des alertes locales (max 15, affiche les 5 plus récentes).
// ─────────────────────────────────────────────────────────────────────────────
class _EventsCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool isDark;
  const _EventsCard({required this.events, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? _cardDk : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              size: 13,
              color: _orange,
            ),
            const SizedBox(width: 6),
            Text(
              'Journal des alertes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1A365D),
              ),
            ),
            const Spacer(),
            if (events.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Aucune alerte',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...events.take(5).map((e) => _EventTile(event: e, isDark: isDark)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT TILE — inchangée
// Tuile d'une alerte dans le journal local : icône colorée + titre + horodatage.
// ─────────────────────────────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isDark;
  const _EventTile({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sev = event['severity'] as String? ?? 'info';
    final title = event['title'] as String? ?? '';
    final icon = event['icon'] as IconData? ?? Icons.info_outline;
    final timestamp = event['timestamp'] as DateTime? ?? DateTime.now();

    final borderColor = sev == 'critical'
        ? _red
        : sev == 'warning'
        ? _orange
        : _teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        // Accent coloré à gauche selon la sévérité
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: borderColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A365D),
                  ),
                ),
                const SizedBox(height: 2),
                // Horodatage format HH:MM:SS
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:'
                  '${timestamp.minute.toString().padLeft(2, '0')}:'
                  '${timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL BUTTON — inchangé
// Bouton Démarrer/Arrêter avec dégradé et légère pulsation pendant le monitoring.
// ─────────────────────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final bool isMonitoring;
  final AnimationController ctrl;
  final VoidCallback onTap;
  const _CtrlBtn({
    required this.isMonitoring,
    required this.ctrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => Transform.scale(
      // Pulsation 2.5% pendant la surveillance (subtile mais vivante)
      scale: isMonitoring ? 1.0 + 0.025 * ctrl.value : 1.0,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMonitoring
                ? [_red, const Color(0xFFC53030)] // Rouge → surveillance active
                : [_navy, const Color(0xFF1A4FA8)], // Bleu → prêt à démarrer
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (isMonitoring ? _red : _navy).withValues(
                alpha: 0.3 + 0.15 * ctrl.value,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  isMonitoring
                      ? 'Arrêter la surveillance'
                      : 'Démarrer la surveillance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS — inchangés
// ─────────────────────────────────────────────────────────────────────────────

/// Mini-graphique en courbe (sparkline) pour les cartes vitales.
/// Affiche les 15 dernières valeurs avec remplissage semi-transparent
/// et un cercle sur la dernière valeur.
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final recent = data.length > 15 ? data.sublist(data.length - 15) : data;
    final minVal = recent.reduce(math.min);
    final maxVal = recent.reduce(math.max);
    final range = (maxVal - minVal).abs();
    const pad = 4.0;

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < recent.length; i++) {
      final x = pad + (size.width - 2 * pad) / (recent.length - 1) * i;
      // Si toutes les valeurs sont identiques → ligne plate au centre
      final y = range < 0.01
          ? size.height / 2
          : size.height -
                pad -
                (recent[i] - minVal) / range * (size.height - 2 * pad);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fermer le fill vers le bas pour créer la surface sous la courbe
    fillPath.lineTo(size.width - pad, size.height - pad);
    fillPath.lineTo(pad, size.height - pad);
    fillPath.close();

    canvas.drawPath(fillPath, fill); // Surface semi-transparente
    canvas.drawPath(path, stroke); // Trait de la courbe

    // Cercle sur la dernière valeur (valeur actuelle)
    final lx = size.width - pad;
    final ly = range < 0.01
        ? size.height / 2
        : size.height -
              pad -
              (recent.last - minVal) / range * (size.height - 2 * pad);
    canvas.drawCircle(
      Offset(lx, ly),
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Ligne pointillée plate affichée quand le monitoring est inactif.
class FlatLinePainter extends CustomPainter {
  final Color color;
  FlatLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 6.0, dashGap = 4.0;
    double x = 0;
    final y = size.height / 2;

    // Tracé en tirets : dash 6px, gap 4px
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashW, size.width), y),
        paint,
      );
      x += dashW + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Graphique multi-courbes dans _GraphCard.
/// Trace 3 séries (FC, SpO₂, Temp) normalisées sur des plages médicales fixes
/// pour permettre la comparaison visuelle.
/// Optimisation : ne redessine que si le nombre de points ou la dernière valeur BPM change.
class GraphPainter extends CustomPainter {
  final List<_EspData> history;
  final bool isDark;
  GraphPainter(this.history, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    // Grille horizontale légère (3 lignes)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Courbes normalisées sur plages médicales fixes
    // FC: 40-140 bpm | SpO₂: 80-100% | Temp: 35-40°C
    _drawSeries(
      canvas,
      size,
      values: history.map((e) => e.bpm).toList(),
      minVal: 40,
      maxVal: 140,
      color: _red,
    );
    _drawSeries(
      canvas,
      size,
      values: history.map((e) => e.spo2).toList(),
      minVal: 80,
      maxVal: 100,
      color: _navy,
    );
    _drawSeries(
      canvas,
      size,
      values: history.map((e) => e.temperature).toList(),
      minVal: 35,
      maxVal: 40,
      color: _green,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Size size, {
    required List<double> values,
    required double minVal,
    required double maxVal,
    required Color color,
  }) {
    if (values.length < 2) return;
    final range = maxVal - minVal;
    if (range <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    bool started = false;

    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      // Ignorer les valeurs hors plage étendue (ex: zéros du démarrage)
      if (v < minVal * 0.5 || v > maxVal * 1.5) continue;

      final x = size.width / (values.length - 1) * i;
      // Clamp pour garder la courbe dans le canvas même si valeur hors plage
      final normalized = ((v - minVal) / range).clamp(0.0, 1.0);
      final y = size.height - (normalized * size.height);

      if (!started) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (!started) return;

    // Fermer le fill vers le bas
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Cercle sur la dernière valeur valide avec halo blanc
    if (values.isNotEmpty) {
      final lastV = values.last;
      if (lastV >= minVal * 0.5 && lastV <= maxVal * 1.5) {
        final lx = size.width;
        final normalized = ((lastV - minVal) / range).clamp(0.0, 1.0);
        final ly = size.height - (normalized * size.height);
        canvas.drawCircle(
          Offset(lx, ly),
          3.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(lx, ly),
          1.8,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  // Optimisation : ne redessiner que si les données ont réellement changé
  bool shouldRepaint(covariant GraphPainter old) =>
      old.history.length != history.length ||
      (history.isNotEmpty &&
          old.history.isNotEmpty &&
          old.history.last.bpm != history.last.bpm);
}
