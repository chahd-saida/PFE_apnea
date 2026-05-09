import 'package:flutter/material.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.connectionStatusLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('ESP32 #A1B2', style: TextStyle(fontSize: 18)),
                        Icon(Icons.bluetooth_connected, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.deviceConnectedLabel,
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 5),
                    const Text('🔋 85%'),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(l10n.disconnectButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              l10n.activeSensorsLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('ECG (AD8232)'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('SpO₂ (MAX30102)'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Mouvement (MPU6050)'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Température (DS18B20)'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    label: Text(l10n.searchNewDeviceButton),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline),
                    label: Text(l10n.connectionGuideLabel),
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
      floatingActionButton: const PatientChatbotFAB(),
    );
  }
}
