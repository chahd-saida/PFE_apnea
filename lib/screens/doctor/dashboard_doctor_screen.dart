import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';

class DashboardDoctorScreen extends StatelessWidget {
  const DashboardDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final clinicName = doctorProfile?.clinicName ?? 'Clinique du Sommeil';
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Médecin'),
        automaticallyImplyLeading: false, // Hide back button on dashboard
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => context.pushNamed(RouteNames.doctorProfile),
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
            Text(
              'Bonjour, Dr. $doctorName',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '🏥 $clinicName',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '📋 Patients suivis : 24',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '🔔 Alertes aujourd\'hui : 2',
                      style: TextStyle(fontSize: 16, color: Colors.orange),
                    ),
                    Text(
                      '⚠️ Critiques : 1',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🚨 Alertes Prioritaires',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Ahmed Ben'),
                subtitle: const Text('5 apnées cette nuit, SpO₂ min : 82%'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  final encodedPatientId = Uri.encodeComponent(
                    'sample-patient-id',
                  );
                  context.pushNamed(
                    RouteNames.doctorPatientProfilePath,
                    pathParameters: {'patientId': encodedPatientId},
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(RouteNames.doctorPatients);
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Patients'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(RouteNames.doctorMessages);
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Stats'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(RouteNames.doctorAlerts);
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Alertes'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(RouteNames.doctorSettings);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Param.'),
                ),
              ],
            ),
          ],
        ),
      ),
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
        currentIndex: 0, // Highlight 'Accueil'
        onTap: (index) {
          switch (index) {
            case 0:
              context.goNamed(RouteNames.doctorDashboard);
              break;
            case 1:
              context.goNamed(RouteNames.doctorPatients);
              break;
            case 2:
              context.goNamed(RouteNames.doctorAlerts);
              break;
            case 3:
              context.goNamed(RouteNames.doctorReports);
              break;
            case 4:
              context.goNamed(RouteNames.doctorSettings);
              break;
          }
        },
      ),
    );
  }
}
