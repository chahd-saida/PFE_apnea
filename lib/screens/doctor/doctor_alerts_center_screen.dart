import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/widgets/doctor_chatbot_fab.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';

class DoctorAlertsCenterScreen extends StatelessWidget {
  const DoctorAlertsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Centre d\'Alertes')),
        body: const Center(
          child: Text('Session expirée. Veuillez vous reconnecter.'),
        ),
      );
    }

    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'Alertes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => context.push(RouteNames.doctorProfile),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: firebaseService.streamDoctorAlerts(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Erreur chargement alertes.',
                    style: TextStyle(color: AppColors.error),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alerts = snapshot.data ?? <Map<String, dynamic>>[];
                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Aucune alerte active.'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔴 Alertes actives (${alerts.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...alerts.map((alert) {
                      final patientId = (alert['patientId'] as String?)?.trim();
                      final patientName = (alert['patientName'] as String?)
                          ?.trim();
                      final message = (alert['message'] as String?)?.trim();
                      final createdAtText = _formatTimestamp(
                        alert['createdAt'],
                      );
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: AppColors.error),
                          title: Text(
                            '🚨 ${patientName?.isNotEmpty == true ? patientName : 'Patient inconnu'}',
                          ),
                          subtitle: Text(
                            '${message?.isNotEmpty == true ? message : 'Aucun détail'}${createdAtText.isNotEmpty ? ' - $createdAtText' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Appel direct non disponible pour le moment.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  final candidateId =
                                      patientId?.isNotEmpty == true
                                      ? patientId!
                                      : null;
                                  if (candidateId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profil patient indisponible pour cette alerte.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final encodedPatientId = Uri.encodeComponent(
                                    candidateId,
                                  );
                                  context.push(
                                    RouteNames.doctorPatientProfile(
                                      encodedPatientId,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            final candidateId = patientId?.isNotEmpty == true
                                ? patientId!
                                : null;
                            if (candidateId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Aucun profil patient lié à cette alerte.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final encodedPatientId = Uri.encodeComponent(
                              candidateId,
                            );
                            context.push(
                              RouteNames.doctorPatientProfile(encodedPatientId),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              '⚙️ Configuration :',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Seuils d\'alerte'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configuration des seuils bientôt disponible.',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_phone),
                    title: const Text('Contacts urgence'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      context.push(RouteNames.doctorMessages);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Rapport',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
        ],
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.doctorDashboard);
              break;
            case 1:
              context.go(RouteNames.doctorPatients);
              break;
            case 2:
              context.go(RouteNames.doctorAlerts);
              break;
            case 3:
              context.go(RouteNames.doctorReports);
              break;
            case 4:
              context.go(RouteNames.doctorSettings);
              break;
          }
        },
      ),
    );
  }

  static String _formatTimestamp(dynamic value) {
    if (value == null) {
      return '';
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
      return '';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
