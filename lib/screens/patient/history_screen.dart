import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return [];
    }
    return _firebaseService.getMeasurementRecords(uid: user.uid, limit: 50);
  }

  Future<void> _refreshHistory() async {
    final updated = _loadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _historyFuture = updated;
    });
    await updated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
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
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: l10n.filterAll,
                    onChanged: (String? newValue) {},
                    items:
                        <String>[
                          l10n.filterAll,
                          l10n.filterGood,
                          l10n.filterFair,
                          l10n.filterBad,
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text('Filtre: $value'),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data ?? <Map<String, dynamic>>[];
                if (entries.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshHistory,
                    child: ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
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

                return RefreshIndicator(
                  onRefresh: _refreshHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      print(
                        'Clés disponibles : ${entry.keys}',
                      ); // ← AJOUTEZ CECI
                      final id = entry['id'] as String; // ← ID Firestore
                      print('>>> ID Firestore : $id');
                      print('>>> ID récupéré : $id');
                      final date = _formatDate(
                        entry['timestamp'],
                        l10n.unknownDate,
                      );
                      final score =
                          _extractInt(entry, ['score', 'sleepScore']) ?? 0;
                      final apneas =
                          _extractInt(entry, [
                            'apneas',
                            'apneaCount',
                          ])?.toString() ??
                          '0';
                      return _buildNightEntry(
                        context,
                        id,
                        date,
                        score,
                        apneas,
                      ); // ← on passe l’ID
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const PatientChatbotFAB(),
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
    );
  }

  static Widget _buildNightEntry(
    BuildContext context,
    String id,
    String date,
    int score,
    String apneas,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ListTile(
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.scoreEntry('$score/100')),
            Text(l10n.apneasEntry(apneas)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () {
          debugPrint('>>> Navigation vers nightDetail: $id');
          context.push(RouteNames.nightDetail(id));
        },
      ),
    );
  }

  static String _formatDate(dynamic value, String unknownLabel) {
    if (value == null) {
      return unknownLabel;
    }
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Timestamp) {
      date = value.toDate();
    }
    if (date == null) {
      return unknownLabel;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static int? _extractInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toInt();
      }
    }
    return null;
  }
}
