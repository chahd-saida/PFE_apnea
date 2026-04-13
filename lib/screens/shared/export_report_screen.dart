import 'package:flutter/material.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  DateTimeRange? _selectedDateRange;
  bool _includeGeneralSummary = true;
  bool _includeEcgGraphs = true;
  bool _includeSpo2Graphs = true;
  bool _includeApneaEvents = true;
  bool _includePersonalNotes = true;
  String _selectedFormat = 'PDF';
  final TextEditingController _emailController = TextEditingController();

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Rapport')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Période :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDateRange == null
                          ? 'Sélectionner une période'
                          : '${_formatDate(_selectedDateRange!.start)} → ${_formatDate(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📊 Inclure :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Résumé général'),
              value: _includeGeneralSummary,
              onChanged: (bool? value) {
                setState(() {
                  _includeGeneralSummary = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Graphiques ECG'),
              value: _includeEcgGraphs,
              onChanged: (bool? value) {
                setState(() {
                  _includeEcgGraphs = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Graphiques SpO₂'),
              value: _includeSpo2Graphs,
              onChanged: (bool? value) {
                setState(() {
                  _includeSpo2Graphs = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Événements apnée'),
              value: _includeApneaEvents,
              onChanged: (bool? value) {
                setState(() {
                  _includeApneaEvents = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Notes personnelles'),
              value: _includePersonalNotes,
              onChanged: (bool? value) {
                setState(() {
                  _includePersonalNotes = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '📤 Format :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Radio<String>(
                  value: 'PDF',
                  groupValue: _selectedFormat,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
                const Text('PDF'),
                Radio<String>(
                  value: 'CSV',
                  groupValue: _selectedFormat,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
                const Text('CSV'),
                Radio<String>(
                  value: 'DICOM',
                  groupValue: _selectedFormat,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
                const Text('DICOM'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '📧 Envoyer à :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email du destinataire (ex: médecin@clinic.com)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Logic to generate and send report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Génération et envoi du rapport...'),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Générer et Envoyer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                // Logic to download report locally
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Téléchargement du rapport...')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Télécharger local'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
