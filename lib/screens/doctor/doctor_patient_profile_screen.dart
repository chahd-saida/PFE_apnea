import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';

class DoctorPatientProfileScreen extends StatelessWidget {
  const DoctorPatientProfileScreen({super.key, required this.patientId});

  final String patientId;

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'Date inconnue';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int? _computeAge(dynamic rawDob) {
    DateTime? dob;
    if (rawDob is Timestamp) {
      dob = rawDob.toDate();
    } else if (rawDob is DateTime) {
      dob = rawDob;
    } else if (rawDob is String) {
      dob = DateTime.tryParse(rawDob);
    }
    if (dob == null) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .snapshots();

    final nightsQuery = FirebaseFirestore.instance
        .collection('measurements')
        .where('uid', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Patient')),
            body: const Center(
              child: Text('Erreur chargement profil patient.'),
            ),
          );
        }
        if (!userSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Patient')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = userSnapshot.data?.data() ?? <String, dynamic>{};
        final fullName =
            (data['fullName'] as String?)?.trim().isNotEmpty == true
            ? data['fullName'] as String
            : 'Patient';
        final diagnosis = (data['diagnosis'] as String?) ?? 'Non renseigné';
        final assignedDoctor =
            (data['doctorName'] as String?) ??
            (data['assignedDoctorName'] as String?) ??
            'Non assigné';
        final age = _computeAge(data['dateOfBirth']);

        return Scaffold(
          appBar: AppBar(title: Text(fullName)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        age != null ? 'Age: $age ans' : 'Age: Non renseigné',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    title: const Text('Diagnostic'),
                    subtitle: Text(diagnosis),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Médecin assigné'),
                    subtitle: Text(assignedDoctor),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '5 dernières nuits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: nightsQuery,
                  builder: (context, nightsSnapshot) {
                    if (nightsSnapshot.hasError) {
                      return const Text('Erreur chargement historique nuits.');
                    }
                    if (!nightsSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = nightsSnapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Aucune nuit enregistrée.'),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final night = doc.data();
                        final score = night['score'] ?? '--';
                        final apneas = night['apneas'] ?? '--';
                        final date = _formatDate(night['timestamp']);
                        return Card(
                          child: ListTile(
                            title: Text(date),
                            subtitle: Text('Score: $score | Apnées: $apneas'),
                            onTap: () {
                              context.pushNamed(
                                RouteNames.doctorAnalysisPath,
                                pathParameters: {
                                  'patientId': Uri.encodeComponent(patientId),
                                  'nightDate': Uri.encodeComponent(date),
                                },
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
