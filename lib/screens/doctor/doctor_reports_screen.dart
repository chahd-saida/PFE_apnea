import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  String? _selectedPatient;
  DateTimeRange? _selectedDateRange;
  bool _includeClinicalData = true;
  bool _includeSignalGraphs = true;
  bool _includeApneaEvents = true;
  bool _includeDoctorDiagnosis = true;
  bool _includeRecommendations = true;
  String _selectedFormat = 'PDF Médical';

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
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération Rapports'),
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
            const Text(
              '👤 Patient :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedPatient,
              hint: const Text('Sélectionner un patient'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items:
                  <String>[
                        'Ahmed Ben',
                        'Fatima Omar',
                        'Youssef Ali',
                      ] // Placeholder patient list
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPatient = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
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
              '📊 Sections :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Données cliniques'),
              value: _includeClinicalData,
              onChanged: (bool? value) {
                setState(() {
                  _includeClinicalData = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Graphiques signaux'),
              value: _includeSignalGraphs,
              onChanged: (bool? value) {
                setState(() {
                  _includeSignalGraphs = value ?? false;
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
              title: const Text('Diagnostic médecin'),
              value: _includeDoctorDiagnosis,
              onChanged: (bool? value) {
                setState(() {
                  _includeDoctorDiagnosis = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Recommandations'),
              value: _includeRecommendations,
              onChanged: (bool? value) {
                setState(() {
                  _includeRecommendations = value ?? false;
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
                  value: 'PDF Médical',
                  groupValue: _selectedFormat,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
                const Text('PDF Médical'),
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
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Logic to generate report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Génération du rapport...')),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text('Générer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                // Logic to send report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Envoi du rapport...')),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                context.goNamed(RouteNames.exportReport);
              },
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder dossier'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
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
        currentIndex: 3, // Highlight 'Rapport'
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
