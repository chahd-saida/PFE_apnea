// lib/screens/patient/realtime_monitoring_screen.dart
// ignore_for_file: use_build_context_synchronously, sized_box_for_whitespace
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/theme/app_theme.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/monitoring_service.dart';
import 'package:apnea_project/services/websocket_service.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
const _navy   = Color(0xFF1E3A8A);
const _teal   = Color(0xFF4DBDB8);
const _purple = Color(0xFF7C3AED);
const _red    = Color(0xFFEF5350);
const _green  = Color(0xFF00BFA5);
const _orange = Color(0xFFF57C00);
const _cardDk = Color(0xFF161D2E);

// ─────────────────────────────────────────────────────────────────────────────
// ESP DATA MODEL  — mirrors models.py DonneesCapteursSchema + ResultatIASchema
// ─────────────────────────────────────────────────────────────────────────────
class _EspData {
  final double bpm;
  final double spo2;
  final double temperature;
  final double bpmEcg;
  final bool electrodesOk;
  final String position;
  final double accX, accY, accZ;
  final bool alarmeActive;
  final String raisonAlarme;
  final bool doigtDetecte;
  final DateTime receivedAt;
  // IA
  final bool apnee;
  final double score;
  final double confiance;
  final String severite;
  final String messageIa;

  const _EspData({
    this.bpm = 0, this.spo2 = 0, this.temperature = 0,
    this.bpmEcg = 0, this.electrodesOk = true,
    this.position = 'INCONNU',
    this.accX = 0, this.accY = 0, this.accZ = 0,
    this.alarmeActive = false, this.raisonAlarme = '',
    this.doigtDetecte = false,
    required this.receivedAt,
    this.apnee = false, this.score = 0,
    this.confiance = 0, this.severite = '', this.messageIa = '',
  });

  /// Parse WebSocket message from Python server
  factory _EspData.fromWebSocket(Map<String, dynamic> raw) {
    final d  = raw['donnees'] as Map<String, dynamic>? ?? {};
    final ia = raw['ia']      as Map<String, dynamic>? ?? {};
    return _EspData(
      bpm:          (d['bpm']           as num?)?.toDouble() ?? 0,
      spo2:         (d['spo2']          as num?)?.toDouble() ?? 0,
      temperature:  (d['temperature']   as num?)?.toDouble() ?? 0,
      bpmEcg:       (d['bpm_ecg']       as num?)?.toDouble() ?? 0,
      electrodesOk: (d['electrodes_ok'] as bool?) ?? true,
      position:     (d['position']      as String?) ?? 'INCONNU',
      accX:         (d['acc_x']         as num?)?.toDouble() ?? 0,
      accY:         (d['acc_y']         as num?)?.toDouble() ?? 0,
      accZ:         (d['acc_z']         as num?)?.toDouble() ?? 0,
      alarmeActive: (d['alarme_active'] as bool?) ?? false,
      raisonAlarme: (d['raison_alarme'] as String?) ?? '',
      doigtDetecte: (d['doigt_detecte'] as bool?) ?? false,
      receivedAt:   DateTime.now(),
      apnee:        (ia['apnee']        as bool?) ?? false,
      score:        (ia['score']        as num?)?.toDouble() ?? 0,
      confiance:    (ia['confiance']    as num?)?.toDouble() ?? 0,
      severite:     (ia['severite']     as String?) ?? '',
      messageIa:    (ia['message']      as String?) ?? '',
    );
  }

  /// Fallback: MonitoringService simulated data
  factory _EspData.fromSimulated(Map<String, dynamic> d) => _EspData(
    bpm:          (d['heartRate']   as num?)?.toDouble() ?? 0,
    spo2:         (d['spo2']        as num?)?.toDouble() ?? 0,
    temperature:  (d['temperature'] as num?)?.toDouble() ?? 36.5,
    doigtDetecte: true, electrodesOk: true,
    receivedAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RealtimeMonitoringScreen extends StatefulWidget {
  const RealtimeMonitoringScreen({super.key, this.monitoringService});
  final MonitoringService? monitoringService;

  @override
  State<RealtimeMonitoringScreen> createState() => _RealtimeMonitoringScreenState();
}

class _RealtimeMonitoringScreenState extends State<RealtimeMonitoringScreen>
    with TickerProviderStateMixin {

  late final MonitoringService _monitoringService;
  final FirebaseService    _firebaseService = FirebaseService();
  final WebSocketService   _wsService       = WebSocketService();

  StreamSubscription<Map<String, dynamic>>? _streamSub;
  bool _isMonitoring = false;
  bool _isConnected  = false;
  DateTime? _sessionStart;

  _EspData? _live;
  final List<_EspData>            _history  = [];
  final List<Map<String, dynamic>> _events   = [];
  final List<double> _bpmHist  = [];
  final List<double> _spo2Hist = [];

  static const int _maxHistory = 40;

  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _heartCtrl;

  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _monitoringService = widget.monitoringService ?? MonitoringService();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _btnCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _slideCtrl.forward(); });

    // WebSocket — real ESP32 data
    _wsService.onConnectionChanged = (c) { if (mounted) setState(() => _isConnected = c); };
    _wsService.onDonnees = (raw) {
      if (!mounted || !_isMonitoring) return;
      final esp = _EspData.fromWebSocket(raw);
      _onData(esp);
      if (esp.alarmeActive && esp.raisonAlarme.isNotEmpty) {
        _addEvent(esp.raisonAlarme, 'critical', Icons.warning_amber_rounded);
      }
      if (esp.apnee && (esp.severite == 'modere' || esp.severite == 'severe')) {
        _addEvent(
          'Apnée ${esp.severite.toUpperCase()} — IA: ${(esp.confiance * 100).round()}%',
          'critical', Icons.air_outlined,
        );
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? 'patient_unknown';
      _wsService.connecter(uid);
    });
  }

  void _onData(_EspData esp) {
    setState(() {
      _live = esp;
      _history.add(esp);
      if (_history.length > _maxHistory) _history.removeAt(0);
      if (esp.bpm  > 0) _bpmHist.add(esp.bpm);
      if (esp.spo2 > 0) _spo2Hist.add(esp.spo2);
      _heartCtrl.forward(from: 0);

      // Clinical events
      if (esp.spo2 > 0 && esp.spo2 < 90)   _addEvent('SpO₂ critique : ${esp.spo2.round()}%',          'critical', Icons.warning);
      else if (esp.spo2 > 0 && esp.spo2 < 94) _addEvent('SpO₂ bas : ${esp.spo2.round()}%',             'warning',  Icons.info_outline);
      if (esp.bpm > 0 && esp.bpm > 100)     _addEvent('Tachycardie : ${esp.bpm.round()} bpm',          'warning',  Icons.favorite);
      if (esp.temperature > 38.0)            _addEvent('Fièvre : ${esp.temperature.toStringAsFixed(1)}°C', 'warning', Icons.thermostat);
      if (!esp.doigtDetecte && esp.spo2 == 0) _addEvent('Doigt non détecté (MAX30102)',                 'info',     Icons.touch_app);
      if (!esp.electrodesOk)                 _addEvent('Électrodes ECG non connectées (AD8232)',         'critical', Icons.electrical_services);
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _sessionTimer?.cancel();
    _wsService.deconnecter();
    _pulseCtrl.dispose(); _fadeCtrl.dispose();
    _slideCtrl.dispose(); _btnCtrl.dispose(); _heartCtrl.dispose();
    _monitoringService.dispose();
    super.dispose();
  }

  void _toggleMonitoring() => _isMonitoring ? _stopMonitoring() : _startMonitoring();

  void _startMonitoring() {
    _history.clear(); _bpmHist.clear(); _spo2Hist.clear(); _events.clear();
    _sessionStart = DateTime.now(); _sessionDuration = Duration.zero;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionDuration += const Duration(seconds: 1));
    });

    _streamSub?.cancel();
    _streamSub = _monitoringService.stream.listen((payload) {
      if (!mounted || !_isMonitoring) return;
      final lastReal = _live?.receivedAt;
      if (lastReal == null || DateTime.now().difference(lastReal).inSeconds > 3) {
        _onData(_EspData.fromSimulated(payload));
      }
    });

    _monitoringService.startMonitoring();
    setState(() => _isMonitoring = true);
    _btnCtrl.repeat(reverse: true);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Surveillance démarrée')]),
      backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _stopMonitoring() async {
    final user = context.read<AuthProvider>().user;
    _monitoringService.stopMonitoring();
    await _streamSub?.cancel(); _streamSub = null;
    _sessionTimer?.cancel(); _btnCtrl.stop();

    final end = DateTime.now(); final start = _sessionStart;
    if (start != null && user != null && _bpmHist.isNotEmpty && _spo2Hist.isNotEmpty) {
      try {
        await _firebaseService.saveMonitoringSession(
          uid: user.uid, startTime: start, endTime: end,
          averageHeartRate: _bpmHist.reduce((a, b) => a + b) / _bpmHist.length,
          averageSpo2: _spo2Hist.reduce((a, b) => a + b) / _spo2Hist.length,
        );
        debugPrint('✅ Session sauvegardée');
      } catch (e) { debugPrint('❌ $e'); }
    }
    if (!mounted) return;
    setState(() => _isMonitoring = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [Icon(Icons.stop, color: Colors.white), SizedBox(width: 8), Text('Surveillance arrêtée')]),
      backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating,
    ));
  }

  void _addEvent(String title, String severity, IconData icon) {
    final now = DateTime.now();
    if (_events.any((e) => e['title'] == title && now.difference(e['timestamp'] as DateTime).inSeconds < 10)) return;
    setState(() {
      _events.insert(0, {'title': title, 'severity': severity, 'icon': icon, 'timestamp': now});
      if (_events.length > 15) _events.removeLast();
    });
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

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
              _SessionBar(isMonitoring: _isMonitoring, isConnected: _isConnected, duration: _sessionDuration, isDark: isDark),
              const SizedBox(height: 12),

              if (_isMonitoring && _live != null && _live!.severite.isNotEmpty) ...[
                _IaBanner(data: _live!, isDark: isDark),
                const SizedBox(height: 10),
              ],

              if (_isMonitoring && _live != null) ...[
                _SensorRow(data: _live!, isDark: isDark),
                const SizedBox(height: 12),
              ],

              // FC card
              _VitalCard(
                label: 'Fréquence cardiaque',
                value: _live?.bpm.round().toString() ?? '—',
                sub: _live != null && _live!.bpmEcg > 0 ? 'ECG: ${_live!.bpmEcg.round()} bpm' : null,
                unit: 'bpm', icon: Icons.favorite_rounded,
                iconColor: _red, iconBg: const Color(0xFFFFEBEE), chartColor: _red,
                history: _history.map((e) => e.bpm).toList(),
                isMonitoring: _isMonitoring, isDark: isDark, heartCtrl: _heartCtrl,
                warning: _live != null && _live!.bpm > 100,
              ),
              const SizedBox(height: 10),

              // SpO2 card
              _VitalCard(
                label: 'Saturation SpO₂',
                value: _live?.spo2.round().toString() ?? '—',
                unit: '%', icon: Icons.water_drop_rounded,
                iconColor: _navy, iconBg: const Color(0xFFE3F2FD), chartColor: _navy,
                history: _history.map((e) => e.spo2).toList(),
                isMonitoring: _isMonitoring, isDark: isDark,
                warning:  _live != null && _live!.spo2 < 94 && _live!.spo2 > 0,
                critical: _live != null && _live!.spo2 < 90 && _live!.spo2 > 0,
              ),
              const SizedBox(height: 10),

              // Temperature card
              _VitalCard(
                label: 'Température corporelle',
                value: _live != null ? _live!.temperature.toStringAsFixed(1) : '—',
                unit: '°C', icon: Icons.thermostat_rounded,
                iconColor: _green, iconBg: const Color(0xFFE0F7F4), chartColor: _green,
                history: _history.map((e) => e.temperature).toList(),
                isMonitoring: _isMonitoring, isDark: isDark,
                warning: _live != null && _live!.temperature > 38.0,
              ),
              const SizedBox(height: 14),

              if (_isMonitoring && _live != null) ...[
                _PositionCard(data: _live!, isDark: isDark),
                const SizedBox(height: 14),
              ],

              _GraphCard(history: _history, isDark: isDark),
              const SizedBox(height: 14),

              _EventsCard(events: _events, isDark: isDark),
              const SizedBox(height: 14),

              _CtrlBtn(isMonitoring: _isMonitoring, ctrl: _btnCtrl, onTap: _toggleMonitoring),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
    backgroundColor: isDark ? const Color(0xFF0D1117) : _navy,
    foregroundColor: Colors.white, elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.patientDashboard),
    ),
    title: Row(children: [
      const Expanded(
        child: Text('Surveillance Temps Réel',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
      ),
      AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isConnected ? const Color(0xFF4ADE80) : _red,
          boxShadow: [BoxShadow(
            color: (_isConnected ? const Color(0xFF4ADE80) : _red).withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value),
            blurRadius: 6)],
        ),
      )),
    ]),
    actions: [
      IconButton(icon: const Icon(Icons.settings_rounded, size: 20), onPressed: () => context.go(RouteNames.patientSettings)),
    ],
  );

  Widget _buildNavBar() => BottomNavigationBar(
    type: BottomNavigationBarType.fixed, currentIndex: 2,
    selectedItemColor: _navy, unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historique'),
      BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_rounded), label: 'Surveil.'),
      BottomNavigationBarItem(icon: Icon(Icons.spa_rounded), label: 'Détente'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Param.'),
    ],
    onTap: (i) {
      switch (i) {
        case 0: context.go(RouteNames.patientDashboard); break;
        case 1: context.go(RouteNames.patientHistory); break;
        case 2: context.go(RouteNames.realtimeMonitoring); break;
        case 3: context.go(RouteNames.relaxation); break;
        case 4: context.go(RouteNames.patientSettings); break;
      }
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SessionBar extends StatelessWidget {
  final bool isMonitoring, isConnected, isDark;
  final Duration duration;
  const _SessionBar({required this.isMonitoring, required this.isConnected, required this.isDark, required this.duration});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? _cardDk : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isMonitoring ? _red.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isMonitoring ? _red : Colors.grey)),
          const SizedBox(width: 5),
          Text(isMonitoring ? 'ACTIF' : 'Inactif',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isMonitoring ? _red : Colors.grey)),
        ]),
      ),
      if (isMonitoring) ...[
        const SizedBox(width: 10),
        const Icon(Icons.timer_outlined, size: 12, color: _teal),
        const SizedBox(width: 4),
        Text('${duration.inMinutes.toString().padLeft(2,'0')}:${(duration.inSeconds % 60).toString().padLeft(2,'0')}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
      ],
      const Spacer(),
      Icon(isConnected ? Icons.wifi : Icons.wifi_off, size: 13, color: isConnected ? const Color(0xFF10B981) : Colors.grey),
      const SizedBox(width: 4),
      Text(isConnected ? 'ESP32 connecté' : 'Déconnecté',
          style: TextStyle(fontSize: 10, color: isConnected ? const Color(0xFF10B981) : Colors.grey)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IA BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _IaBanner extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _IaBanner({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ok    = !data.apnee;
    final color = ok ? const Color(0xFF10B981) : _red;
    final bg    = ok ? const Color(0xFFE8F5E9)  : const Color(0xFFFFEBEE);
    final icon  = ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(
              data.apnee ? 'Apnée ${data.severite.toUpperCase()} détectée' : 'Respiration normale',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('${(data.confiance * 100).round()}%',
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (data.messageIa.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(data.messageIa, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 11)),
          ],
          const SizedBox(height: 6),
          Row(children: [
            Text('Score IA ', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.score, minHeight: 5,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )),
            const SizedBox(width: 6),
            Text('${(data.score * 100).round()}%', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ]),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SENSOR STATUS ROW (4 sensors)
// ─────────────────────────────────────────────────────────────────────────────

class _SensorRow extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _SensorRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sensors = [
      (label: 'MAX30102', sub: 'SpO₂/HR',  ok: data.doigtDetecte,     icon: Icons.fingerprint),
      (label: 'AD8232',   sub: 'ECG',       ok: data.electrodesOk,     icon: Icons.electrical_services),
      (label: 'DS18B20',  sub: 'Temp',      ok: data.temperature > 0,  icon: Icons.thermostat_rounded),
      (label: 'MPU6050',  sub: 'Accel',     ok: true,                  icon: Icons.screen_rotation_rounded),
    ];

    return Row(children: sensors.asMap().entries.map((entry) {
      final i = entry.key; final s = entry.value;
      final ok = s.ok; final color = ok ? const Color(0xFF10B981) : _red;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: i < sensors.length - 1 ? 8 : 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(s.icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(s.sub, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
            Text(s.label, style: TextStyle(fontSize: 7, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? const Color(0xFF10B981) : _red)),
          ]),
        ),
      ));
    }).toList());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VITAL CARD
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
    required this.label, required this.value, required this.unit,
    this.sub, required this.icon,
    required this.iconColor, required this.iconBg, required this.chartColor,
    required this.history, required this.isMonitoring, required this.isDark,
    this.warning = false, this.critical = false, this.heartCtrl,
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
          color: (critical || warning) ? alertColor.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [BoxShadow(
          color: (critical ? _red : iconColor).withValues(alpha: 0.07),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(children: [
        // Icon
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)),
            child: heartCtrl != null
                ? AnimatedBuilder(animation: heartCtrl!, builder: (_, __) => Transform.scale(
                    scale: 1.0 + 0.14 * math.sin(heartCtrl!.value * math.pi),
                    child: Icon(icon, color: iconColor, size: 26)))
                : Icon(icon, color: iconColor, size: 26),
          ),
          if (critical || warning) Positioned(top: -5, right: -5,
            child: Container(
              width: 15, height: 15,
              decoration: BoxDecoration(color: alertColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.priority_high, size: 8, color: Colors.white),
            )),
        ]),
        const SizedBox(width: 14),

        // Value
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800, height: 1,
              color: critical ? _red : isDark ? Colors.white : const Color(0xFF1A365D),
            )),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
          ]),
          if (sub != null) Text(sub!, style: const TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w600)),
        ])),

        // Sparkline
        SizedBox(width: 80, height: 42,
          child: isMonitoring && history.length >= 2
              ? CustomPaint(painter: SparklinePainter(history, chartColor))
              : CustomPaint(painter: FlatLinePainter(chartColor.withValues(alpha: 0.35)))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POSITION CARD (MPU6050)
// ─────────────────────────────────────────────────────────────────────────────

class _PositionCard extends StatelessWidget {
  final _EspData data;
  final bool isDark;
  const _PositionCard({required this.data, required this.isDark});

  IconData _icon(String p) {
    switch (p.toUpperCase()) {
      case 'DOS': case 'VENTRE': return Icons.airline_seat_flat;
      case 'COUCHE_GAUCHE': case 'COUCHE_DROITE': return Icons.airline_seat_flat_angled;
      case 'ASSIS': return Icons.airline_seat_recline_normal;
      default: return Icons.device_unknown_rounded;
    }
  }
  Color _color(String p) {
    switch (p.toUpperCase()) { case 'DOS': case 'VENTRE': return _orange; default: return _teal; }
  }

  @override
  Widget build(BuildContext context) {
    final posColor = _color(data.position);
    final mag = math.sqrt(data.accX * data.accX + data.accY * data.accY + data.accZ * data.accZ);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _cardDk : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.screen_rotation_rounded, size: 13, color: _purple),
          const SizedBox(width: 6),
          Text('Mouvement & Position (MPU6050)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF1A365D))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // Position pill
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: posColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: posColor.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Icon(_icon(data.position), color: posColor, size: 30),
              const SizedBox(height: 5),
              Text(data.position.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: posColor), textAlign: TextAlign.center),
              Text('Position', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ]),
          )),
          const SizedBox(width: 12),

          // Accelerometer bars
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _accBar('X', data.accX, _red, isDark),
            const SizedBox(height: 5),
            _accBar('Y', data.accY, _green, isDark),
            const SizedBox(height: 5),
            _accBar('Z', data.accZ, _navy, isDark),
            const SizedBox(height: 5),
            _accBar('|G|', mag, _purple, isDark),
          ])),
        ]),
      ]),
    );
  }

  Widget _accBar(String axis, double val, Color color, bool isDark) => Row(children: [
    SizedBox(width: 22, child: Text(axis, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (val.abs() / 20).clamp(0.0, 1.0), minHeight: 6,
        backgroundColor: color.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    )),
    const SizedBox(width: 6),
    Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// GRAPH CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GraphCard extends StatelessWidget {
  final List<_EspData> history;
  final bool isDark;
  const _GraphCard({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? _cardDk : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.show_chart_rounded, size: 14, color: _teal),
        const SizedBox(width: 6),
        Text('Graphique temps réel',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF1A365D))),
        const Spacer(),
        Text('${history.length}/${_RealtimeMonitoringScreenState._maxHistory} pts',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
      const SizedBox(height: 10),
      Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: history.length < 2
            ? Center(child: Text('En attente de données…', style: TextStyle(color: Colors.grey[400], fontSize: 12)))
            : CustomPaint(painter: GraphPainter(history, isDark), child: const SizedBox.expand()),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 4, children: [
        _leg('FC (bpm)', _red),
        _leg('SpO₂ (%)', _navy),
        _leg('Temp (°C)', _green),
      ]),
    ]),
  );

  Widget _leg(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 18, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS CARD
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
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.notifications_active_rounded, size: 13, color: _orange),
        const SizedBox(width: 6),
        Text('Journal des alertes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF1A365D))),
        const Spacer(),
        if (events.isNotEmpty) Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: _red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('${events.length}', style: const TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 10),
      if (events.isEmpty)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 15),
            SizedBox(width: 7),
            Text('Aucune alerte', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        )
      else
        ...events.take(8).map((e) {
          final sev = e['severity'] as String;
          final c = sev == 'critical' ? _red : sev == 'warning' ? _orange : _navy;
          final ts = e['timestamp'] as DateTime;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: isDark ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: c, width: 3)),
            ),
            child: Row(children: [
              Icon(e['icon'] as IconData, color: c, size: 15),
              const SizedBox(width: 9),
              Expanded(child: Text(e['title'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF1A365D)))),
              Text('${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}:${ts.second.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ]),
          );
        }),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CtrlBtn extends StatelessWidget {
  final bool isMonitoring;
  final AnimationController ctrl;
  final VoidCallback onTap;
  const _CtrlBtn({required this.isMonitoring, required this.ctrl, required this.onTap});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => Transform.scale(
      scale: isMonitoring ? 1.0 + 0.025 * ctrl.value : 1.0,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMonitoring ? [_red, const Color(0xFFC53030)] : [_navy, const Color(0xFF1A4FA8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(
            color: (isMonitoring ? _red : _navy).withValues(alpha: 0.3 + 0.15 * ctrl.value),
            blurRadius: 18, offset: const Offset(0, 6),
          )],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Text(isMonitoring ? 'Arrêter la surveillance' : 'Démarrer la surveillance',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final recent = data.length > 15 ? data.sublist(data.length - 15) : data;
    final min = recent.reduce(math.min), max = recent.reduce(math.max);
    final range = (max - min).abs();
    const pad = 4.0;

    final stroke = Paint()..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill   = Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill;

    final path = Path(), fillPath = Path();
    for (int i = 0; i < recent.length; i++) {
      final x = pad + (size.width - 2 * pad) / (recent.length - 1) * i;
      final y = range < 0.01 ? size.height / 2
          : size.height - pad - (recent[i] - min) / range * (size.height - 2 * pad);
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo(size.width - pad, size.height - pad);
    fillPath.lineTo(pad, size.height - pad);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, stroke);

    // Live dot
    final lx = size.width - pad;
    final ly = range < 0.01 ? size.height / 2
        : size.height - pad - (recent.last - min) / range * (size.height - 2 * pad);
    canvas.drawCircle(Offset(lx, ly), 3.5, Paint()..color = color);
    canvas.drawCircle(Offset(lx, ly), 3.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant CustomPainter o) => true;
}

class FlatLinePainter extends CustomPainter {
  final Color color;
  FlatLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const dw = 6.0, sp = 4.0;
    final cy = size.height / 2; double x = 2;
    while (x < size.width - 2) {
      canvas.drawLine(Offset(x, cy), Offset((x + dw).clamp(0, size.width - 2), cy), paint);
      x += dw + sp;
    }
  }

  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class GraphPainter extends CustomPainter {
  final List<_EspData> data;
  final bool isDark;
  GraphPainter(this.data, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final w = size.width - 2 * pad, h = size.height - 2 * pad;

    final grid = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = pad + h / 4 * i;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }

    if (data.length < 2) return;

    _line(canvas, data.map((e) => e.bpm).toList(),         _red,   pad, w, h, 30, 150);
    _line(canvas, data.map((e) => e.spo2).toList(),        _navy,  pad, w, h, 80, 100);
    _line(canvas, data.map((e) => e.temperature).toList(), _green, pad, w, h, 35, 40);
  }

  void _line(Canvas canvas, List<double> vals, Color color, double pad, double w, double h, double min, double max) {
    final paint = Paint()
      ..color = color..strokeWidth = 1.8
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < vals.length; i++) {
      final x  = pad + w / (vals.length - 1) * i;
      final nv = ((vals[i] - min) / (max - min)).clamp(0.0, 1.0);
      final y  = pad + h - nv * h;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(covariant CustomPainter o) => true;
}