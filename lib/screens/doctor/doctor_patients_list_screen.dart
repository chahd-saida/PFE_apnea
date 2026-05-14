import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/screens/doctor/add_patient_screen.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';
import 'package:apnea_project/theme/app_colors.dart';

class DoctorPatientsListScreen extends StatefulWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  State<DoctorPatientsListScreen> createState() =>
      _DoctorPatientsListScreenState();
}

class _DoctorPatientsListScreenState extends State<DoctorPatientsListScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Patients')),
        body: const Center(
          child: Text('Session expirée. Veuillez vous reconnecter.'),
        ),
      );
    }

    final userService = UserService();
    final measurementService = MeasurementService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Patients'),
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: 'Tous',
                onChanged: (String? newValue) {},
                items: <String>['Tous', 'Actifs', 'En alerte', 'Inactifs']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Filtre: $value'),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: userService.streamDoctorPatients(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Erreur chargement patients.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                }

                final patients = snapshot.data ?? <Map<String, dynamic>>[];
                if (patients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucun patient assigné pour le moment.'),
                  );
                }

                return Column(
                  children: patients.map((patient) {
                    final patientUid = patient['uid'] as String? ?? '';
                    final fullName =
                        (patient['fullName'] as String?)?.trim().isNotEmpty ==
                            true
                        ? patient['fullName'] as String
                        : 'Patient';

                    return FutureBuilder<DateTime?>(
                      future: measurementService
                          .getPatientLastMeasurementTimestamp(patientUid),
                      builder: (context, lastMeasurementSnapshot) {
                        final lastDate = lastMeasurementSnapshot.data;
                        final lastDateLabel = lastDate == null
                            ? 'Aucune donnée'
                            : '${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}';
                        return _buildPatientEntry(
                          context,
                          patientId: patientUid,
                          name: fullName,
                          status: 'Actif',
                          lastData: lastDateLabel,
                          apneas: '--',
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddPatientScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter patient'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildPatientEntry(
    BuildContext context, {
    required String patientId,
    required String name,
    required String status,
    required String lastData,
    required String apneas,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.success,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut: $status'),
            Text('Dernière donnée: $lastData'),
            Text('Apnées (7j): $apneas'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          final encodedPatientId = Uri.encodeComponent(patientId);
          context.push(RouteNames.doctorPatientProfile(encodedPatientId));
        },
      ),
    );
  }
}
