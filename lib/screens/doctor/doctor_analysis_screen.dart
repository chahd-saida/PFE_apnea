import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/services/note_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class DoctorAnalysisScreen extends StatefulWidget {
  final String patientId;
  final String nightDate;

  const DoctorAnalysisScreen({
    super.key,
    required this.patientId,
    required this.nightDate,
  });

  @override
  State<DoctorAnalysisScreen> createState() => _DoctorAnalysisScreenState();
}

class _DoctorAnalysisScreenState extends State<DoctorAnalysisScreen> {
  final NoteService _noteService = NoteService();
  final MeasurementService _measurementService = MeasurementService();
  final UserService _userService = UserService();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSaving = false;
  bool _ecgSelected = true;
  bool _spo2Selected = true;
  bool _hrSelected = false;
  bool _movementSelected = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveDiagnosis() async {
    final diagnosis = _diagnosisController.text.trim();
    final note = _noteController.text.trim();

    if (diagnosis.isEmpty && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un diagnostic ou une note.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = context.read<AuthProvider>().user;
      final doctorProfile = context.read<UserProfileProvider>();
      final doctorName = doctorProfile.fullName;

      await _noteService.saveDoctorNote(
        patientId: Uri.decodeComponent(widget.patientId),
        doctorUid: user?.uid ?? '',
        doctorName: doctorName,
        note: note.isEmpty ? diagnosis : note,
        diagnosis: diagnosis.isEmpty ? null : diagnosis,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostic enregistré avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      _diagnosisController.clear();
      _noteController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedPatientId = Uri.decodeComponent(widget.patientId);
    final decodedDate = Uri.decodeComponent(widget.nightDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse Détaillée'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveDiagnosis,
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label: const Text(
              'Sauvegarder',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadMeasurementData(decodedPatientId, decodedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final measurementData = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientHeader(decodedPatientId, decodedDate),
                const SizedBox(height: 16),

                if (measurementData != null)
                  _buildMeasurementSummary(measurementData),
                const SizedBox(height: 16),

                _buildSignalSelector(),
                const SizedBox(height: 12),
                _buildGraphArea(),
                const SizedBox(height: 20),

                _buildEventsSection(),
                const SizedBox(height: 20),

                _buildPreviousNotes(decodedPatientId),
                const SizedBox(height: 20),

                _buildDiagnosisSection(),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: const DoctorChatbotFAB(),
    );
  }

  Future<Map<String, dynamic>?> _loadMeasurementData(
    String patientId,
    String date,
  ) async {
    try {
      final records = await _measurementService.getMeasurementRecords(
        uid: patientId,
        limit: 100,
      );
      if (records.isEmpty) return null;
      return records.first;
    } catch (_) {
      return null;
    }
  }

  Widget _buildPatientHeader(String patientId, String date) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userService.getUserProfile(patientId),
      builder: (context, snap) {
        final name = (snap.data?['fullName'] as String?)?.trim() ?? 'Patient';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade300,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nuit du $date',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementSummary(Map<String, dynamic> data) {
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final spo2 = (data['avgSpo2'] ?? data['spo2'] as num?)?.toDouble() ?? 0;
    final hr =
        (data['avgHeartRate'] ?? data['heartRate'] as num?)?.toDouble() ?? 0;
    final apneas = (data['apneas'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Résumé de la nuit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem('Score', '$score/100', _scoreColor(score)),
                _buildSummaryItem(
                  'SpO₂',
                  '${spo2.toStringAsFixed(1)}%',
                  _spo2Color(spo2),
                ),
                _buildSummaryItem(
                  'FC moy.',
                  '${hr.toStringAsFixed(0)} bpm',
                  Colors.pink,
                ),
                _buildSummaryItem('Apnées', '$apneas', _apneaColor(apneas)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSignalSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Signaux à afficher :',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('ECG'),
                  selected: _ecgSelected,
                  onSelected: (v) => setState(() => _ecgSelected = v),
                  selectedColor: Colors.red.shade100,
                ),
                FilterChip(
                  label: const Text('SpO₂'),
                  selected: _spo2Selected,
                  onSelected: (v) => setState(() => _spo2Selected = v),
                  selectedColor: Colors.blue.shade100,
                ),
                FilterChip(
                  label: const Text('Fréquence cardiaque'),
                  selected: _hrSelected,
                  onSelected: (v) => setState(() => _hrSelected = v),
                  selectedColor: Colors.pink.shade100,
                ),
                FilterChip(
                  label: const Text('Mouvement'),
                  selected: _movementSelected,
                  onSelected: (v) => setState(() => _movementSelected = v),
                  selectedColor: Colors.green.shade100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Graphiques multi-signaux',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Données capteur BLE requises',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Événements annotés',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildEventRow('23:45', 'Apnée obstructive', Colors.red),
            _buildEventRow('02:15', 'Apnée centrale', Colors.orange),
            _buildEventRow('03:30', 'SpO₂ < 90%', Colors.red),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter annotation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(String time, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPreviousNotes(String patientId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _noteService.streamPatientNotes(patientId),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Notes précédentes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...notes.take(3).map((note) {
                  final date = _formatTimestamp(note['createdAt']);
                  final text = note['note'] as String? ?? '';
                  final diagnosis = note['diagnosis'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (diagnosis != null && diagnosis.isNotEmpty)
                          Text(
                            'Diagnostic: $diagnosis',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (text.isNotEmpty)
                          Text(text, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosisSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Diagnostic médecin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnostic',
                hintText: 'Ex: SAS léger, SAS modéré, SAS sévère...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes cliniques',
                hintText:
                    'Observations, recommandations, plan de traitement...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDiagnosis,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Enregistrement...' : 'Enregistrer le diagnostic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) => score >= 80
      ? Colors.green
      : score >= 50
      ? Colors.orange
      : Colors.red;
  Color _spo2Color(double spo2) => spo2 < 90
      ? Colors.red
      : spo2 < 95
      ? Colors.orange
      : Colors.blue;
  Color _apneaColor(int apneas) => apneas >= 5
      ? Colors.red
      : apneas >= 3
      ? Colors.orange
      : Colors.green;

  static String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Timestamp) {
      date = value.toDate();
    }
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
