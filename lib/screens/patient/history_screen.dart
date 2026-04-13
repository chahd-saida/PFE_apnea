import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des Nuits')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: 'Toutes',
                    onChanged: (String? newValue) {},
                    items: <String>['Toutes', 'Bonnes', 'Moyennes', 'Mauvaises']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text('Filtre: $value'),
                          );
                        })
                        .toList(),
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
                  return const Center(
                    child: Text(
                      'Impossible de charger l\'historique.',
                      style: TextStyle(color: Colors.red),
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
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              'Aucun historique trouvé. Lancez une première surveillance pour voir les données ici.',
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
                      final date = _formatDate(entry['timestamp']);
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
                        date,
                        '$score/100',
                        apneas,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
        currentIndex: 1,
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

  static Widget _buildNightEntry(
    BuildContext context,
    String date,
    String score,
    String apneas,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ListTile(
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Score: $score'), Text('Apnées: $apneas')],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.pushNamed(
            RouteNames.nightDetailPath,
            pathParameters: {'nightId': Uri.encodeComponent(date)},
          );
        },
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) {
      return 'Date inconnue';
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
      return 'Date inconnue';
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
