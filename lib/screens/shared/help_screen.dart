import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide et FAQ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions Fréquemment Posées',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              title: const Text('Comment connecter mon capteur ESP32?'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '1. Assurez-vous que votre capteur ESP32 est allumé et en mode appairage.\n2. Allez dans Paramètres > Gestion Capteurs.\n3. Cliquez sur \'Rechercher nouveau\' et sélectionnez votre appareil.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Comment interpréter mon score de sommeil?'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Votre score de sommeil est calculé en fonction de plusieurs paramètres (durée, qualité, événements...). Un score élevé indique un sommeil réparateur.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Que faire en cas d\'alerte critique?'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'En cas d\'alerte critique, veuillez contacter immédiatement votre médecin ou les services d\'urgence.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('support@sleepapneadetect.com'),
                onTap: () {
                  // Open email client
                },
              ),
            ),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('+213 XX XX XX XX'),
                onTap: () {
                  // Dial phone number
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

