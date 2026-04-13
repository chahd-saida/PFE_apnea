import 'package:flutter/material.dart';

class PatientAlertsScreen extends StatelessWidget {
  const PatientAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centre d\'Alertes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 Critiques (2)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Apnée prolongée'),
                subtitle: const Text('15/01 02:15 - 30s - SpO₂ 82%'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to alert detail
                },
              ),
            ),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Bradycardie sévère'),
                subtitle: const Text('15/01 03:00 - FC 40 BPM'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to alert detail
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '⚠️ Avertissements (5)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.orange),
                title: const Text('SpO₂ bas'),
                subtitle: const Text('14/01 23:45 - 88% pendant 15s'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to alert detail
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Mark all as read logic
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tout marquer comme lu'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Delete old alerts logic
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer ancien'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 50),
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

