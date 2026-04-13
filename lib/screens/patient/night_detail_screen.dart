import 'package:flutter/material.dart';

class NightDetailScreen extends StatelessWidget {
  final String nightId; // Example: pass night ID to fetch data

  const NightDetailScreen({super.key, required this.nightId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail Nuit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nightId, // Display the night ID or date
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Score Sommeil: 72', style: TextStyle(fontSize: 16)),
                    Text('Durée: 7h23', style: TextStyle(fontSize: 16)),
                    Text('Apnées: 3', style: TextStyle(fontSize: 16)),
                    Text('SpO₂ min: 88%', style: TextStyle(fontSize: 16)),
                    Text('FC min: 55 BPM', style: TextStyle(fontSize: 16)),
                    Text(
                      'Température moyenne: 36.8°C',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📈 Graphiques détaillés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  'Zone pour les graphiques ECG, SpO₂, FC, Mouvement',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚠️ Événements clés :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 02:15 - Apnée (30s)'),
                Text('• 03:00 - SpO₂ bas (88%)'),
                Text('• 04:30 - Mouvement agité'),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Logic to add a note
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('Ajouter Note'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Logic to share report
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
