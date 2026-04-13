// ignore_for_file: use_build_context_synchronously, unused_element, unused_local_variable, sized_box_for_whitespace

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/theme/app_theme.dart';
import 'package:apnea_project/providers/theme_provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/monitoring_service.dart';

class RealtimeMonitoringScreen extends StatefulWidget {
  const RealtimeMonitoringScreen({super.key, this.monitoringService});

  final MonitoringService? monitoringService;

  @override
  State<RealtimeMonitoringScreen> createState() =>
      _RealtimeMonitoringScreenState();
}

class _RealtimeMonitoringScreenState extends State<RealtimeMonitoringScreen>
    with TickerProviderStateMixin {
  late final MonitoringService _monitoringService;
  final FirebaseService _firebaseService = FirebaseService();

  StreamSubscription<Map<String, dynamic>>? _streamSubscription;
  bool _isMonitoring = false;
  bool _isConnected = false;
  DateTime? _sessionStart;

  // Vital signs data
  final List<int> _heartRates = <int>[];
  final List<int> _spo2Values = <int>[];
  final List<double> _temperatures = <double>[];

  // Graph data
  final List<Map<String, dynamic>> _graphData = [];
  Timer? _graphTimer;

  // Events
  final List<Map<String, dynamic>> _events = [];

  // Animation controllers
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _buttonPulseController;

  @override
  void initState() {
    super.initState();
    _monitoringService = widget.monitoringService ?? MonitoringService();

    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animations
    _startAnimations();

    // Check connection status
    _checkConnectionStatus();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  void _checkConnectionStatus() {
    // Simulate connection check
    setState(() {
      _isConnected = true;
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _graphTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonPulseController.dispose();
    _monitoringService.dispose();
    super.dispose();
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      unawaited(_stopMonitoring());
    } else {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _heartRates.clear();
    _spo2Values.clear();
    _temperatures.clear();
    _graphData.clear();
    _events.clear();
    _sessionStart = DateTime.now();

    _streamSubscription?.cancel();
    _streamSubscription = _monitoringService.stream.listen((payload) {
      final num? heartRate = payload['heartRate'];
      final num? spo2 = payload['spo2'];
      final heartRateInt = heartRate?.toInt();
      final spo2Int = spo2?.toInt();
      final timestamp = DateTime.now();

      if (heartRateInt != null) {
        _heartRates.add(heartRateInt);
      }
      if (spo2Int != null) {
        _spo2Values.add(spo2Int);
      }

      // Add temperature simulation
      final temp = 36.5 + (Random().nextDouble() * 1.5);
      _temperatures.add(temp);

      // Update graph data
      setState(() {
        _graphData.add({
          'time': timestamp,
          'heartRate': (heartRate ?? (60 + Random().nextInt(40))).toDouble(),
          'spo2': (spo2 ?? (95 + Random().nextInt(5))).toDouble(),
          'temperature': temp,
        });

        // Keep only last 20 data points
        if (_graphData.length > 20) {
          _graphData.removeAt(0);
        }

        // Check for events
        _checkForEvents(heartRateInt, spo2Int, temp);
      });
    });

    _monitoringService.startMonitoring();

    // Start graph animation
    _startGraphAnimation();

    setState(() {
      _isMonitoring = true;
    });

    _buttonPulseController.repeat(reverse: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Surveillance démarrée'),
          ],
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _startGraphAnimation() {
    _graphTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      // Simulate data if not receiving real data
      if (_graphData.isEmpty ||
          DateTime.now().difference(_graphData.last['time']).inSeconds > 2) {
        setState(() {
          _graphData.add({
            'time': DateTime.now(),
            'heartRate': (60 + Random().nextInt(40)).toDouble(),
            'spo2': (95 + Random().nextInt(5)).toDouble(),
            'temperature': 36.5 + (Random().nextDouble() * 1.5),
          });

          if (_graphData.length > 20) {
            _graphData.removeAt(0);
          }
        });
      }
    });
  }

  void _checkForEvents(int? heartRate, int? spo2, double temperature) {
    if (heartRate != null && heartRate > 100) {
      _addEvent('Fréquence cardiaque élevée', 'critical', Icons.warning);
    }
    if (spo2 != null && spo2 < 90) {
      _addEvent('SpO₂ bas', 'critical', Icons.warning);
    } else if (spo2 != null && spo2 < 95) {
      _addEvent('SpO₂ attention', 'warning', Icons.info);
    }
    if (temperature > 38.0) {
      _addEvent('Température élevée', 'warning', Icons.thermostat);
    }
  }

  void _addEvent(String title, String severity, IconData icon) {
    setState(() {
      _events.add({
        'title': title,
        'severity': severity,
        'icon': icon,
        'timestamp': DateTime.now(),
      });

      // Keep only last 10 events
      if (_events.length > 10) {
        _events.removeAt(0);
      }
    });
  }

  Future<void> _stopMonitoring() async {
    final user = context.read<AuthProvider>().user;
    _monitoringService.stopMonitoring();
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _graphTimer?.cancel();
    _buttonPulseController.stop();

    final end = DateTime.now();
    final start = _sessionStart;
    if (start != null &&
        user != null &&
        _heartRates.isNotEmpty &&
        _spo2Values.isNotEmpty) {
      final avgHeartRate =
          _heartRates.reduce((a, b) => a + b) / _heartRates.length;
      final avgSpo2 = _spo2Values.reduce((a, b) => a + b) / _spo2Values.length;
      await _firebaseService.saveMonitoringSession(
        uid: user.uid,
        startTime: start,
        endTime: end,
        averageHeartRate: avgHeartRate,
        averageSpo2: avgSpo2,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isMonitoring = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.stop, color: Colors.white),
            SizedBox(width: 8),
            Text('Surveillance arrêtée'),
          ],
        ),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.patientDashboard);
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Expanded(
              child: Text(
                'Surveillance en Temps Réel',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isConnected ? AppTheme.success : AppTheme.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isConnected ? AppTheme.success : AppTheme.danger)
                        .withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.goNamed(RouteNames.patientSettings);
            },
          ),
        ],
      ),
      body: Container(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _monitoringService.stream,
          builder: (context, snapshot) {
            final heartRate = _isMonitoring
                ? (snapshot.data?['heartRate'] as int? ?? 60)
                : 0;
            final spo2 = _isMonitoring
                ? (snapshot.data?['spo2'] as int? ?? 98)
                : 0;
            final temperature = _temperatures.isNotEmpty
                ? _temperatures.last
                : 36.5;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vital Signs Cards - Stacked Vertically
                  _buildMetricCard(
                    title: 'FC',
                    value: '$heartRate',
                    unit: 'bpm',
                    icon: Icons.favorite,
                    iconBgColor: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF7C3AED),
                    chartColor: const Color(0xFF7C3AED),
                    data: _heartRates,
                    isMonitoring: _isMonitoring,
                  ),
                  const SizedBox(height: 12),

                  _buildMetricCard(
                    title: 'SpO₂',
                    value: '$spo2',
                    unit: '%',
                    icon: Icons.water_drop,
                    iconBgColor: const Color(0xFFFDECEA),
                    iconColor: const Color(0xFFEF5350),
                    chartColor: const Color(0xFFEF5350),
                    data: _spo2Values,
                    isMonitoring: _isMonitoring,
                  ),
                  const SizedBox(height: 12),

                  _buildMetricCard(
                    title: 'Temp',
                    value: temperature.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat,
                    iconBgColor: const Color(0xFFE0F7F4),
                    iconColor: const Color(0xFF00BFA5),
                    chartColor: const Color(0xFF00BFA5),
                    data: _temperatures.map((t) => t.toInt()).toList(),
                    isMonitoring: _isMonitoring,
                  ),
                  const SizedBox(height: 16),

                  // Real-time Graph
                  _buildGraphSection(),
                  const SizedBox(height: 16),

                  // Events Section
                  _buildEventsSection(),
                  const SizedBox(height: 16),

                  // Control Button
                  _buildControlButton(),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Surveil.',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Détente'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
        ],
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.goNamed(RouteNames.patientDashboard);
              break;
            case 1:
              context.goNamed(RouteNames.patientHistory);
              break;
            case 2:
              context.goNamed(RouteNames.realtimeMonitoring);
              break;
            case 3:
              context.goNamed(RouteNames.relaxation);
              break;
            case 4:
              context.goNamed(RouteNames.patientSettings);
              break;
          }
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color chartColor,
    required List<int> data,
    required bool isMonitoring,
  }) {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Semantics(
          button: true,
          label: '$title $value $unit',
          child: GestureDetector(
            onTap: () {
              // Navigate to detail screen for this metric
              _navigateToMetricDetail(title);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE6F3FF).withValues(alpha: 0.9),
                    const Color(0xFFD1E9FF).withValues(alpha: 0.85),
                    const Color(0xFFB8DCFF).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFB8DCFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left - Icon Box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),

                  // Center - Label + Value
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A365D),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C5282),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right - Mini Sparkline Chart
                  SizedBox(
                    width: 70,
                    height: 35,
                    child: _buildSparklineChart(data, chartColor, isMonitoring),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMetricDetail(String metric) {
    // Navigate to detail screen for the specific metric
    // This would open a new screen with full history chart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails $metric - à implémenter'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSparklineChart(List<int> data, Color color, bool isMonitoring) {
    if (data.isEmpty || !isMonitoring) {
      // Show flat/dashed line when not monitoring
      return CustomPaint(painter: FlatLinePainter(color), child: Container());
    }

    // Show last 10 data points for the sparkline
    final recentData = data.length > 10 ? data.sublist(data.length - 10) : data;

    return CustomPaint(
      painter: SparklinePainter(recentData, color),
      child: Container(),
    );
  }

  Widget _buildGraphSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE6F3FF).withValues(alpha: 0.85),
                const Color(0xFFD1E9FF).withValues(alpha: 0.8),
                const Color(0xFFB8DCFF).withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFB8DCFF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, color: Color(0xFF1A365D)),
                  const SizedBox(width: 8),
                  const Text(
                    '📈 Graphique temps réel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Graph Container
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: _buildCustomGraph(),
              ),

              // Legend
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('FC', const Color(0xFFC62828)),
                  const SizedBox(width: 12),
                  _buildLegendItem('SpO₂', const Color(0xFF0077B6)),
                  const SizedBox(width: 12),
                  _buildLegendItem('Temp', const Color(0xFF00BFA5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomGraph() {
    if (_graphData.isEmpty) {
      return const Center(
        child: Text(
          'En attente de données...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomPaint(painter: GraphPainter(_graphData), child: Container());
  }

  Widget _buildEventsSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE6F3FF).withValues(alpha: 0.85),
                const Color(0xFFD1E9FF).withValues(alpha: 0.8),
                const Color(0xFFB8DCFF).withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFB8DCFF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFF1A365D)),
                  const SizedBox(width: 8),
                  const Text(
                    '⚠️ Événements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_events.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucun événement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A365D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _events
                      .map((event) => _buildEventCard(event))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final severity = event['severity'] as String;
    final icon = event['icon'] as IconData;
    final title = event['title'] as String;
    final timestamp = event['timestamp'] as DateTime;

    Color borderColor;

    switch (severity) {
      case 'critical':
        borderColor = const Color(0xFFC62828);
        break;
      case 'warning':
        borderColor = const Color(0xFFF57C00);
        break;
      default:
        borderColor = const Color(0xFF2E7D32);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A365D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C5282),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Center(
          child: Semantics(
            button: true,
            label: _isMonitoring
                ? 'Arrêter la surveillance'
                : 'Démarrer la surveillance',
            child: AnimatedBuilder(
              animation: _buttonPulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isMonitoring
                      ? 1.0 + (0.05 * _buttonPulseController.value)
                      : 1.0,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isMonitoring
                            ? [const Color(0xFFE53E3E), const Color(0xFFC53030)]
                            : [
                                const Color(0xFF3182CE),
                                const Color(0xFF2C5282),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isMonitoring
                                      ? const Color(0xFFE53E3E)
                                      : const Color(0xFF3182CE))
                                  .withValues(alpha: 0.4),
                          blurRadius: _isMonitoring ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _toggleMonitoring,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isMonitoring ? Icons.stop : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isMonitoring
                                    ? 'Arrêter Surveillance'
                                    : 'Démarrer Surveillance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  GraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 16.0;
    final graphWidth = size.width - (padding * 2);
    final graphHeight = size.height - (padding * 2);

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (graphHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    if (data.length < 2) return;

    // Draw lines for each metric
    _drawLine(
      canvas,
      data,
      'heartRate',
      AppTheme.danger,
      padding,
      graphWidth,
      graphHeight,
      40.0,
      120.0,
    );
    _drawLine(
      canvas,
      data,
      'spo2',
      AppTheme.primary,
      padding,
      graphWidth,
      graphHeight,
      85.0,
      100.0,
    );
    _drawLine(
      canvas,
      data,
      'temperature',
      AppTheme.warning,
      padding,
      graphWidth,
      graphHeight,
      36.0,
      38.0,
    );
  }

  void _drawLine(
    Canvas canvas,
    List<Map<String, dynamic>> data,
    String metric,
    Color color,
    double padding,
    double graphWidth,
    double graphHeight,
    double minValue,
    double maxValue,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final dynamic rawValue = point[metric];
      final value = rawValue is num ? rawValue.toDouble() : minValue;
      final x = padding + (graphWidth / (data.length - 1)) * i;
      final normalizedValue = (value - minValue) / (maxValue - minValue);
      final y = padding + graphHeight - (normalizedValue * graphHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;
    final padding = 4.0;

    // Find min and max values for normalization
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxValue - minValue;

    if (range == 0) return;

    // Build the path
    for (int i = 0; i < data.length; i++) {
      final x = padding + (width - 2 * padding) / (data.length - 1) * i;
      final normalizedValue = (data[i] - minValue) / range;
      final y = height - padding - (normalizedValue * (height - 2 * padding));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    fillPath.lineTo(width - padding, height - padding);
    fillPath.lineTo(padding, height - padding);
    fillPath.close();

    // Draw the fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw dots at each data point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = padding + (width - 2 * padding) / (data.length - 1) * i;
      final normalizedValue = (data[i] - minValue) / range;
      final y = height - padding - (normalizedValue * (height - 2 * padding));

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FlatLinePainter extends CustomPainter {
  final Color color;

  FlatLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final startX = 4.0;
    final endX = size.width - 4.0;

    // Draw dashed line
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    double currentX = startX;
    while (currentX < endX) {
      final endDashX = (currentX + dashWidth).clamp(0.0, endX);
      canvas.drawLine(
        Offset(currentX, centerY),
        Offset(endDashX, centerY),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
