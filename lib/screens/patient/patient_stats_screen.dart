import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';

class PatientStatsScreen extends StatelessWidget {
  const PatientStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Session expirée.')),
      );
    }

    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes statistiques')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: firebaseService.getPatientStats(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                  future: firebaseService.getMeasurementRecords(
                    uid: user.uid,
                    limit: 7,
                  ),
                  builder: (context, measSnapshot) {
                    final records = measSnapshot.data ?? [];
                    if (records.isEmpty) {
                      return const Text('Aucune mesure récente.');
                    }

                    return Column(
                      children: records.map((r) {
                        final score = (r['score'] as num?)?.toInt() ?? 0;
                        final date = _formatDate(r['timestamp']);
                        final duration =
                            (r['durationMinutes'] as num?)?.toInt() ?? 0;
                        final apneas =
                            (r['apneas'] as num?)?.toInt() ?? 0;
                        final scoreColor = score >= 80
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
                                color: scoreColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
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
                                color: scoreColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                score >= 80
                                    ? 'Excellent'
                                    : score >= 50
                                    ? 'Moyen'
                                    : 'Mauvais',
                                style: TextStyle(
                                  color: scoreColor,
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

                // Score trend visualization
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
                          future: firebaseService.getMeasurementRecords(
                            uid: user.uid,
                            limit: 10,
                          ),
                          builder: (context, measSnapshot) {
                            final records =
                                (measSnapshot.data ?? []).reversed.toList();
                            if (records.isEmpty) {
                              return const Text('Aucune donnée.');
                            }

                            final maxScore = 100.0;
                            return SizedBox(
                              height: 120,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: records.take(10).map((r) {
                                  final score =
                                      (r['score'] as num?)?.toDouble() ?? 0;
                                  final height = (score / maxScore) * 100;
                                  final color = score >= 80
                                      ? Colors.green
                                      : score >= 50
                                      ? Colors.orange
                                      : Colors.red;

                                  return Tooltip(
                                    message:
                                        '${score.toInt()}/100\n${_formatDate(r['timestamp'])}',
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: height.clamp(4.0, 100.0),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                BorderRadius.circular(4),
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
      ),
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
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '--';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Timestamp) {
      date = value.toDate();
    }
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDuration(int minutes) {
    if (minutes == 0) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }
}