// lib/screens/patient/history_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/stats_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final MeasurementService _measurementService = MeasurementService();
  final StatsService _statsService = StatsService();
  late Future<List<Map<String, dynamic>>> _historyFuture;
  String _searchQuery = ''; // texte saisi dans la barre de recherche
  String? _selectedFilter; // filtre sélectionné (Bon / Moyen / Mauvais)

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory(); // Lance le chargement dès l'ouverture
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return []; // Sécurité si session expirée
    return _measurementService.getMeasurementRecords(uid: user.uid, limit: 50);
  }

  Future<void> _refreshHistory() async {
    final updated = _loadHistory();
    if (!mounted) return; // Évite une exception si le widget est détruit
    setState(() => _historyFuture = updated);
    await updated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final extra = GoRouterState.of(context).extra;
    final initialIndex = extra is int && extra >= 0 && extra <= 1 ? extra : 0;

    return DefaultTabController(
      key: ValueKey<int>(initialIndex),
      length: 2,
      initialIndex: initialIndex, // Peut venir du paramètre de navigation
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.historyTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historique des nuits'),
              Tab(text: 'Statistiques'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildHistoryTab(l10n), _buildStatsTab(context)],
        ),
        floatingActionButton: const PatientChatbotFAB(), // Bouton chatbot IA
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.homeLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: l10n.historyLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.monitor_heart),
              label: l10n.monitoringShortLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.spa),
              label: l10n.relaxationLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: l10n.settingsShortLabel,
            ),
          ],
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
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
        ),
      ),
    );
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                //La recherche filtre en temps réel sur la date, le score et le nombre d'apnées.
                child: DropdownButton<String>(
                  value: _selectedFilter ?? l10n.filterAll,
                  onChanged: (v) => setState(() => _selectedFilter = v),
                  items:
                      <String>[
                            l10n.filterAll,
                            l10n.filterGood,
                            l10n.filterFair,
                            l10n.filterBad,
                          ]
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text('Filtre: $v'),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          //FutureBuilder est le pattern Flutter standard pour afficher un contenu asynchrone.
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    l10n.historyLoadError,
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final entries = snapshot.data ?? <Map<String, dynamic>>[];
              final filteredEntries = _filterEntries(entries, l10n);
              final uid = context.read<AuthProvider>().user?.uid ?? '';
              for (final e in entries.take(3)) {
                debugPrint('🔑 Clés disponibles : ${e.keys.toList()}');
                debugPrint('📦 Entrée complète : $e');
              }

              if (entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshHistory,
                  child: ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            l10n.historyEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filteredEntries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshHistory,
                  child: ListView(
                    children: [
                      const SizedBox(height: 120),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Aucune entrée ne correspond à votre recherche ou filtre.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    final id = entry['id'] as String? ?? '';
                    final date = _formatDate(
                      entry['timestamp'],
                      l10n.unknownDate,
                    );
                    final score =
                        _extractInt(entry, ['score', 'sleepScore']) ?? 0;
                    final apneas =
                        //_extractInt(entry, ['apneas', 'apneaCount']) ?? 0;
                        // Remplace par les vraies clés trouvées dans le debug
                        _extractInt(entry, ['apneas', 'apneaCount', 'apneaEvents', 'numberOfApneas']) ?? 0;
                    // timestamp pour filtrer les alertes de cette nuit
                    final ts = _extractDateTime(entry['timestamp']);
                    //Construction de chaque carte
                    return _NightEntryCard(
                      id: id,
                      date: date,
                      score: score,
                      apneas: apneas,
                      patientUid: uid,
                      timestamp: ts, //// Pour charger les alertes de cette nuit
                      onTap: () {
                        if (id.isEmpty) return;
                        context.push(RouteNames.nightDetail(id));
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Onglet statistiques (inchangé) ────────────────────────────────────────
  Widget _buildStatsTab(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Session expirée.'));

    return FutureBuilder<Map<String, dynamic>>(
      future: _statsService.getPatientStats(
        user.uid,
        getMeasurementRecords: _measurementService.getMeasurementRecords,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;
        final totalSessions = stats['totalSessions'] as int;
        final avgScore = stats['avgScore'] as int;
        final avgSpo2 = stats['avgSpo2'] as String;
        final avgHeartRate = stats['avgHeartRate'] as int;
        final totalApneas = stats['totalApneas'] as int;

        if (totalSessions == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune donnée disponible',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Commencez une session de surveillance pour voir vos statistiques.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Vue d\'ensemble',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    'Sessions totales',
                    '$totalSessions',
                    Icons.nights_stay_rounded,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Score moyen',
                    '$avgScore/100',
                    Icons.star_rounded,
                    avgScore >= 80
                        ? Colors.green
                        : avgScore >= 50
                        ? Colors.orange
                        : Colors.red,
                  ),
                  _buildStatCard(
                    'SpO₂ moyen',
                    '$avgSpo2%',
                    Icons.air,
                    Colors.teal,
                  ),
                  _buildStatCard(
                    'FC moyenne',
                    '$avgHeartRate bpm',
                    Icons.favorite,
                    Colors.pink,
                  ),
                  _buildStatCard(
                    'Total apnées',
                    '$totalApneas',
                    Icons.warning_amber_rounded,
                    totalApneas > 10 ? Colors.red : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '📅 Historique récent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _measurementService.getMeasurementRecords(
                  uid: user.uid,
                  limit: 7,
                ),
                builder: (context, measSnapshot) {
                  final records = measSnapshot.data ?? [];
                  if (records.isEmpty)
                    return const Text('Aucune mesure récente.');
                  return Column(
                    children: records.map((r) {
                      final score = (r['score'] as num?)?.toInt() ?? 0;
                      final date = _formatDateStats(r['timestamp']);
                      final duration =
                          (r['durationMinutes'] as num?)?.toInt() ?? 0;
                      final apneas = (r['apneas'] as num?)?.toInt() ?? 0;
                      final sc = score >= 80
                          ? Colors.green
                          : score >= 50
                          ? Colors.orange
                          : Colors.red;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: sc,
                                ),
                              ),
                            ),
                          ),
                          title: Text(date),
                          subtitle: Text(
                            'Durée: ${_formatDuration(duration)} · Apnées: $apneas',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              score >= 80
                                  ? 'Excellent'
                                  : score >= 50
                                  ? 'Moyen'
                                  : 'Mauvais',
                              style: TextStyle(
                                color: sc,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Évolution du score',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _measurementService.getMeasurementRecords(
                          uid: user.uid,
                          limit: 10,
                        ),
                        builder: (context, measSnapshot) {
                          final records = (measSnapshot.data ?? []).reversed
                              .toList();
                          if (records.isEmpty)
                            return const Text('Aucune donnée.');
                          return SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: records.take(10).map((r) {
                                final score =
                                    (r['score'] as num?)?.toDouble() ?? 0;
                                final height = (score / 100) * 100;
                                final color = score >= 80
                                    ? Colors.green
                                    : score >= 50
                                    ? Colors.orange
                                    : Colors.red;
                                return Tooltip(
                                  message:
                                      '${score.toInt()}/100\n${_formatDateStats(r['timestamp'])}',
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: height.clamp(4.0, 100.0),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${score.toInt()}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(dynamic value, String unknownLabel) {
    if (value == null) return unknownLabel;
    DateTime? date;
    if (value is DateTime)
      date = value;
    else if (value is String)
      date = DateTime.tryParse(value);
    else if (value is Timestamp)
      date = value.toDate();
    if (date == null) return unknownLabel;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateStats(dynamic value) {
    if (value == null) return '--';
    DateTime? date;
    if (value is DateTime)
      date = value;
    else if (value is String)
      date = DateTime.tryParse(value);
    else if (value is Timestamp)
      date = value.toDate();
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDuration(int minutes) {
    if (minutes == 0) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h == 0 ? '${m}min' : '${h}h${m.toString().padLeft(2, '0')}min';
  }

  static int? _extractInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v is num) return v.toInt();
    }
    return null;
  }

  static DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<Map<String, dynamic>> _filterEntries(
    List<Map<String, dynamic>> entries,
    AppLocalizations l10n,
  ) {
    return entries.where((entry) {
      // Vérifie si la recherche correspond à la date, au score ou aux apnées
      final date = _formatDate(entry['timestamp'], '').toLowerCase();
      final score = _extractInt(entry, ['score', 'sleepScore']) ?? 0;
      final apneas = _extractInt(entry, ['apneas', 'apneaCount']) ?? 0;
      final matchesSearch =
          date.contains(_searchQuery) ||
          score.toString().contains(_searchQuery) ||
          apneas.toString().contains(_searchQuery);
      if (!matchesSearch) return false;
      // Applique le filtre de qualité
      if (_selectedFilter == l10n.filterGood) return score >= 80;
      if (_selectedFilter == l10n.filterFair) return score >= 50 && score < 80;
      if (_selectedFilter == l10n.filterBad) return score < 50;
      return true;
    }).toList();
  }
}

// ── NIGHT ENTRY CARD — CORRECTION : badge alertes Firestore ──────────────────
class _NightEntryCard extends StatelessWidget {
  final String id, date, patientUid;
  final int score, apneas;
  final DateTime? timestamp;
  final VoidCallback onTap;

  const _NightEntryCard({
    required this.id,
    required this.date,
    required this.patientUid,
    required this.score,
    required this.apneas,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = score >= 80
        ? Colors.green
        : score >= 50
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icône score
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: scoreColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 13, color: scoreColor),
                        const SizedBox(width: 4),
                        Text(
                          'Score : $score/100',
                          style: TextStyle(color: scoreColor, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.air, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Apnées : $apneas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    //  badge alertes Firestore pour cette nuit
                    if (timestamp != null)
                      _AlertBadge(
                        patientUid: patientUid,
                        timestamp: timestamp!,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Badge asynchrone qui charge les alertes de la nuit depuis Firestore
class _AlertBadge extends StatefulWidget {
  final String patientUid;
  final DateTime timestamp;
  const _AlertBadge({required this.patientUid, required this.timestamp});
  @override
  State<_AlertBadge> createState() => _AlertBadgeState();
}

class _AlertBadgeState extends State<_AlertBadge> {
  int _critical = 0;
  int _warning = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    // Fenêtre de ±12h autour du timestamp de la session
    final start = widget.timestamp.subtract(const Duration(hours: 1));
    final end = widget.timestamp.add(const Duration(hours: 12));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('alerts')
          .where('patientId', isEqualTo: widget.patientUid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      // Compte les alertes 'critical' et 'warning'
      int c = 0, w = 0;
      for (final doc in snap.docs) {
        final sev = doc.data()['severity'] as String? ?? '';
        if (sev == 'critical')
          c++;
        else if (sev == 'warning')
          w++;
      }
      if (mounted)
        setState(() {
          _critical = c;
          _warning = w;
          _loaded = true;
        });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || (_critical == 0 && _warning == 0))
      return const SizedBox.shrink(); // Rien à afficher → widget invisible
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (_critical > 0)
            _pill(
              '$_critical critique${_critical > 1 ? 's' : ''}',
              AppColors.error,
            ),
          if (_critical > 0 && _warning > 0) const SizedBox(width: 6),
          if (_warning > 0) _pill('$_warning avertiss.', AppColors.warning),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notifications_active_rounded, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
