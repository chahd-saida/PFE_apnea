// Fixed: Improved UI — 2-col grid, proper sizing, greeting in topbar, cleaner cards

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';

class DashboardPatientScreen extends StatefulWidget {
  const DashboardPatientScreen({super.key});

  @override
  State<DashboardPatientScreen> createState() => _DashboardPatientScreenState();
}

class _DashboardPatientScreenState extends State<DashboardPatientScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _pulseController;

  bool _isMonitoring = false;
  bool _showLastSession = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Bonjour';
    if (hour >= 12 && hour < 18) return 'Bon après-midi';
    return 'Bonne nuit';
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 50) return 'Moyen';
    return 'Mauvais';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF388E3C);
    if (score >= 50) return const Color(0xFFF57C00);
    return const Color(0xFFC62828);
  }

  Color _getScoreBgColor(int score) {
    if (score >= 80) return const Color(0xFFE8F5E9);
    if (score >= 50) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Patient')),
        body: const Center(
          child: Text('Session expirée. Veuillez vous reconnecter.'),
        ),
      );
    }

    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(isDarkMode: isDarkMode),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: firebaseService.streamUserProfile(user.uid),
                builder: (context, userSnap) {
                  if (userSnap.hasError) {
                    return const _ErrorState(
                      message: 'Erreur chargement profil.',
                    );
                  }
                  if (!userSnap.hasData) {
                    return const _DashboardLoadingShimmer();
                  }

                  final profile = userSnap.data;
                  final fullName =
                      (profile?['fullName'] as String?)?.trim() ?? 'Patient';
                  final firstName = fullName.split(' ').first;

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: firebaseService.streamMeasurementRecords(
                      uid: user.uid,
                      limit: 1,
                    ),
                    builder: (context, measSnap) {
                      if (measSnap.hasError) {
                        return const _ErrorState(
                          message: 'Erreur chargement mesures.',
                        );
                      }
                      if (!measSnap.hasData) {
                        return const _DashboardLoadingShimmer();
                      }

                      final records = measSnap.data ?? [];
                      if (records.isEmpty) {
                        return _EmptyState(fullName: fullName);
                      }

                      final latest = records.first;
                      final score =
                          _extractDouble(latest, [
                            'score',
                            'sleepScore',
                          ])?.round() ??
                          0;
                      final apneas =
                          _extractInt(latest, ['apneas', 'apneaCount']) ?? 0;
                      final spo2 =
                          _extractInt(latest, ['spo2', 'avgSpo2']) ?? 0;
                      final heartRate =
                          _extractInt(latest, ['heartRate', 'avgHeartRate']) ??
                          0;
                      final temperature =
                          _extractDouble(latest, [
                            'temperature',
                            'avgTemperature',
                          ]) ??
                          0.0;
                      final date =
                          (latest['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                      return FadeTransition(
                        opacity: _fadeController,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            children: [
                              // Greeting + date
                              _GreetingRow(
                                greeting: _getGreeting(),
                                firstName: firstName,
                                date: _formatDate(date),
                                isDarkMode: isDarkMode,
                              ),
                              const SizedBox(height: 16),

                              // Sleep score card
                              _ScoreCard(
                                score: score,
                                label: _getScoreLabel(score),
                                scoreColor: _getScoreColor(score),
                                scoreBgColor: _getScoreBgColor(score),
                                isDarkMode: isDarkMode,
                                onTap: () =>
                                    context.goNamed(RouteNames.patientHistory),
                              ),
                              const SizedBox(height: 16),

                              // 2-column vitals grid
                              _VitalsGrid(
                                apneas: apneas,
                                spo2: spo2,
                                heartRate: heartRate,
                                temperature: temperature,
                                isDarkMode: isDarkMode,
                                onAlerts: () =>
                                    context.goNamed(RouteNames.patientAlerts),
                                onMonitor: () => context.goNamed(
                                  RouteNames.realtimeMonitoring,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Monitoring button
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return _MonitoringButton(
                                    isMonitoring: _isMonitoring,
                                    pulseValue: _pulseController.value,
                                    onTap: () {
                                      setState(() {
                                        _isMonitoring = !_isMonitoring;
                                        if (!_isMonitoring) {
                                          _showLastSession = true;
                                        }
                                      });
                                      context.goNamed(
                                        RouteNames.realtimeMonitoring,
                                      );
                                    },
                                  );
                                },
                              ),

                              if (_showLastSession) ...[
                                const SizedBox(height: 12),
                                _LastSessionBar(isDarkMode: isDarkMode),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(isDarkMode: isDarkMode),
    );
  }

  static double? _extractDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  static int? _extractInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v is num) return v.toInt();
    }
    return null;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isDarkMode});
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF0077B6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.greeting,
    required this.firstName,
    required this.date,
    required this.isDarkMode,
  });
  final String greeting, firstName, date;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '$greeting, $firstName !',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Color(0xFF0077B6),
              ),
              const SizedBox(width: 5),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0077B6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.label,
    required this.scoreColor,
    required this.scoreBgColor,
    required this.isDarkMode,
    required this.onTap,
  });
  final int score;
  final String label;
  final Color scoreColor, scoreBgColor;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score sommeil',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0077B6),
                      height: 1,
                    ),
                  ),
                  Text(
                    'sur 100',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scoreBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 13,
                          color: scoreColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: score / 100.0),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        backgroundColor: isDarkMode
                            ? Colors.white12
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                  Text(
                    '${score}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({
    required this.apneas,
    required this.spo2,
    required this.heartRate,
    required this.temperature,
    required this.isDarkMode,
    required this.onAlerts,
    required this.onMonitor,
  });
  final int apneas, spo2, heartRate;
  final double temperature;
  final bool isDarkMode;
  final VoidCallback onAlerts, onMonitor;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFE65100),
        bgColor: const Color(0xFFFFF3E0),
        label: 'Événements',
        value: '$apneas',
        valueColor: const Color(0xFFE65100),
        tag: 'Modéré',
        tagColor: const Color(0xFFE65100),
        tagBg: const Color(0xFFFFF3E0),
        onTap: onAlerts,
      ),
      _StatData(
        icon: Icons.air,
        iconColor: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        label: 'SpO₂ moyen',
        value: '$spo2%',
        valueColor: const Color(0xFF1565C0),
        tag: 'Normal',
        tagColor: const Color(0xFF1565C0),
        tagBg: const Color(0xFFE3F2FD),
        onTap: onMonitor,
      ),
      _StatData(
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFC62828),
        bgColor: const Color(0xFFFFEBEE),
        label: 'FC moyenne',
        value: '$heartRate BPM',
        valueColor: const Color(0xFFC62828),
        tag: 'Normal',
        tagColor: const Color(0xFFC62828),
        tagBg: const Color(0xFFFFEBEE),
        onTap: onMonitor,
      ),
      _StatData(
        icon: Icons.thermostat_rounded,
        iconColor: const Color(0xFF00695C),
        bgColor: const Color(0xFFE0F2F1),
        label: 'Température',
        value: '${temperature.toStringAsFixed(1)}°C',
        valueColor: const Color(0xFF00695C),
        tag: 'Normal',
        tagColor: const Color(0xFF00695C),
        tagBg: const Color(0xFFE0F2F1),
        onTap: onMonitor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 370;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isNarrow ? 1.05 : 1.18,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) =>
              _StatCard(data: stats[i], isDarkMode: isDarkMode),
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor, bgColor, valueColor, tagColor, tagBg;
  final String label, value, tag;
  final VoidCallback onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data, required this.isDarkMode});
  final _StatData data;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 18),
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
            Text(
              data.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: data.valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: data.tagBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data.tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoringButton extends StatelessWidget {
  const _MonitoringButton({
    required this.isMonitoring,
    required this.pulseValue,
    required this.onTap,
  });
  final bool isMonitoring;
  final double pulseValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isMonitoring
        ? const Color(0xFFD32F2F)
        : const Color(0xFF0077B6);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: pulseValue * 0.3 + 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 22,
        ),
        label: Text(
          isMonitoring ? 'Arrêter surveillance' : 'Démarrer surveillance',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
    );
  }
}

class _LastSessionBar extends StatelessWidget {
  const _LastSessionBar({required this.isDarkMode});
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 10),
          Text(
            'Dernière session : 0h 45min',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.isDarkMode});
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF0077B6),
        unselectedItemColor: isDarkMode ? Colors.white38 : Colors.black38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: 0,
        onTap: (i) {
          const routes = [
            RouteNames.patientDashboard,
            RouteNames.patientHistory,
            RouteNames.realtimeMonitoring,
            RouteNames.relaxation,
            RouteNames.patientSettings,
          ];
          context.goNamed(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_rounded),
            label: 'Surveil.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_rounded),
            label: 'Détente',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Param.',
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error / Empty ───────────────────────────────────────────────────

class _DashboardLoadingShimmer extends StatelessWidget {
  const _DashboardLoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 24, width: 180, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 140, width: double.infinity, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Container(height: 110, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 110, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Container(height: 110, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 110, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.fullName});
  final String fullName;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.nights_stay_rounded,
            size: 64,
            color: Color(0xFF0077B6),
          ),
          const SizedBox(height: 16),
          Text(
            'Bonjour, $fullName',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aucune mesure disponible. Lancez une session pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.goNamed(RouteNames.realtimeMonitoring),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Démarrer surveillance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
