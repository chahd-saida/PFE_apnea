import 'package:flutter/material.dart';

class DoctorAnalysisScreen extends StatelessWidget {
  final String patientId;
  final String nightDate;

  const DoctorAnalysisScreen({
    super.key,
    required this.patientId,
    required this.nightDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse Détaillée')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$patientId - $nightDate',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '📈 Signaux :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilterChip(
                  label: const Text('ECG'),
                  selected: true,
                  onSelected: (bool selected) {},
                ),
                FilterChip(
                  label: const Text('SpO₂'),
                  selected: true,
                  onSelected: (bool selected) {},
                ),
                FilterChip(
                  label: const Text('FC'),
                  selected: false,
                  onSelected: (bool selected) {},
                ),
                FilterChip(
                  label: const Text('Mvt'),
                  selected: false,
                  onSelected: (bool selected) {},
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  'Zone pour les graphiques multi-signaux avec zoom et export',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚠️ Événements annotés :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• 23:45 - Apnée obstructive'),
                const Text('• 02:15 - Apnée centrale'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // Add annotation logic
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Ajouter annotation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '📋 Diagnostic :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'SAS léger/moyen/sévère...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Save diagnosis
                },
                child: const Text('Enregistrer diagnostic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
