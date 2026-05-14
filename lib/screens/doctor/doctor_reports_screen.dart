import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/pdf_report_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';
import 'package:apnea_project/theme/app_colors.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfReportService _pdfReportService = PdfReportService();

  String? _selectedPatientUid;
  String? _selectedPatientName;
  Map<String, dynamic>? _selectedPatientData;
  DateTimeRange? _selectedDateRange;
  bool _includeClinicalData = true;
  bool _includeSignalGraphs = true;
  bool _includeApneaEvents = true;
  bool _includeDoctorDiagnosis = true;
  bool _includeRecommendations = true;
  bool _isGenerating = false;
  Uint8List? _lastPdfBytes;
  String? _lastSavedFilePath;

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _generateReport() async {
    if (_selectedPatientUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final patient = _buildPatient();
      final doctorName = context.read<UserProfileProvider>().fullName;
      final reportData = await _buildReportData(doctorName: doctorName);
      final bytes = await _pdfReportService.generatePdfReport(
        patient,
        reportData,
      );
      final fileName = 'report_${patient.id}.pdf';
      final file = await _pdfReportService.savePdfToLocal(
        bytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;
      setState(() {
        _lastPdfBytes = bytes;
        _lastSavedFilePath = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF généré et sauvegardé: ${_extractFileName(file.path)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } on FileSystemException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Permission de stockage refusée ou dossier inaccessible.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de génération du PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<ReportData> _buildReportData({required String doctorName}) async {
    final patientId = _selectedPatientUid!;
    final stats = await _firebaseService.getPatientStats(patientId);
    final allMeasurements = await _firebaseService.getMeasurementRecords(
      uid: patientId,
      limit: 100,
    );
    final allNotes = await _firebaseService.getPatientNotes(patientId);

    final measurements = _filterByDateRange(
      allMeasurements,
      _selectedDateRange,
      key: 'timestamp',
    );
    final notes = _filterByDateRange(
      allNotes,
      _selectedDateRange,
      key: 'createdAt',
    );

    final avgSpo2 = double.tryParse((stats['avgSpo2'] ?? '').toString());
    final avgHeartRate = double.tryParse(
      (stats['avgHeartRate'] ?? '').toString(),
    );
    final totalApneas =
        int.tryParse((stats['totalApneas'] ?? '').toString()) ?? 0;
    final totalSessions =
        int.tryParse((stats['totalSessions'] ?? '').toString()) ?? 0;

    return ReportData(
      doctorName: doctorName,
      generatedAt: DateTime.now(),
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      averageSpo2: avgSpo2,
      averageHeartRate: avgHeartRate,
      totalApneas: _includeApneaEvents ? totalApneas : 0,
      totalSessions: totalSessions,
      measurements: measurements,
      notes: notes,
      includeClinicalData: _includeClinicalData,
      includeSignalGraphs: _includeSignalGraphs,
      includeApneaEvents: _includeApneaEvents,
      includeDoctorDiagnosis: _includeDoctorDiagnosis,
      includeRecommendations: _includeRecommendations,
    );
  }

  List<Map<String, dynamic>> _filterByDateRange(
    List<Map<String, dynamic>> input,
    DateTimeRange? range, {
    required String key,
  }) {
    if (range == null) return input;

    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );

    return input.where((item) {
      final value = item[key];
      final date = _extractDateTime(value);
      if (date == null) return false;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  DateTime? _extractDateTime(dynamic value) {
    if (value is DateTime) return value;
    final hasToDate = value != null && value.toString().contains('Timestamp');
    if (hasToDate) {
      try {
        final converted = value.toDate();
        if (converted is DateTime) return converted;
      } catch (_) {}
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int? _computeAge(dynamic dateOfBirth) {
    final dob =
        _extractDateTime(dateOfBirth) ??
        (dateOfBirth is String ? DateTime.tryParse(dateOfBirth) : null);
    if (dob == null) return null;

    final now = DateTime.now();
    var age = now.year - dob.year;
    final hasBirthdayPassed =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasBirthdayPassed) {
      age -= 1;
    }
    return age < 0 ? null : age;
  }

  Patient _buildPatient() {
    final data = _selectedPatientData ?? <String, dynamic>{};
    final id = _selectedPatientUid ?? 'unknown_patient';
    final fullName = (data['fullName'] as String?)?.trim().isNotEmpty == true
        ? (data['fullName'] as String).trim()
        : (_selectedPatientName ?? 'Patient');
    return Patient(
      id: id,
      fullName: fullName,
      age: _computeAge(data['dateOfBirth']),
      gender: (data['gender'] as String?)?.trim(),
      medicalId: (data['medicalId'] as String?)?.trim(),
    );
  }

  String _extractFileName(String path) {
    if (path.isEmpty) return path;
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  Future<bool> _ensurePdfReady() async {
    if (_lastPdfBytes != null && _lastPdfBytes!.isNotEmpty) {
      return true;
    }
    await _generateReport();
    return _lastPdfBytes != null && _lastPdfBytes!.isNotEmpty;
  }

  Future<void> _previewPdf() async {
    final ready = await _ensurePdfReady();
    if (!ready || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: SizedBox(
            width: 900,
            height: 700,
            child: PdfPreview(
              build: (_) => _lastPdfBytes!,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'report_${_selectedPatientUid ?? 'patient'}.pdf',
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePdf() async {
    final ready = await _ensurePdfReady();
    if (!ready || !mounted) return;

    try {
      await _pdfReportService.sharePdf(
        bytes: _lastPdfBytes!,
        fileName: 'report_${_selectedPatientUid ?? 'patient'}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Partage du rapport lancé.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec du partage: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération Rapports'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('👤 Patient :'),
            const SizedBox(height: 10),
            _buildPatientSelector(user?.uid ?? ''),
            const SizedBox(height: 20),
            _buildSectionTitle('📅 Période :'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textMedium),
                  borderRadius: BorderRadius.circular(8),
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
            _buildSectionTitle('📊 Sections à inclure :'),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Données cliniques'),
                    subtitle: const Text('SpO₂, FC, température'),
                    value: _includeClinicalData,
                    onChanged: (v) =>
                        setState(() => _includeClinicalData = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Graphiques signaux'),
                    subtitle: const Text('Courbes ECG, SpO₂'),
                    value: _includeSignalGraphs,
                    onChanged: (v) =>
                        setState(() => _includeSignalGraphs = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Événements apnée'),
                    subtitle: const Text('Liste et classification'),
                    value: _includeApneaEvents,
                    onChanged: (v) =>
                        setState(() => _includeApneaEvents = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Diagnostic médecin'),
                    subtitle: const Text('Notes et diagnostics saisis'),
                    value: _includeDoctorDiagnosis,
                    onChanged: (v) =>
                        setState(() => _includeDoctorDiagnosis = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Recommandations'),
                    subtitle: const Text('Plan de traitement'),
                    value: _includeRecommendations,
                    onChanged: (v) =>
                        setState(() => _includeRecommendations = v ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('📤 Format :'),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PDF Médical',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Format standard pour dossier médical',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description),
              label: Text(_isGenerating ? 'Génération...' : 'Générer rapport'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Partager le PDF'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _previewPdf,
              icon: const Icon(Icons.visibility),
              label: const Text('Aperçu du PDF'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (_lastSavedFilePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Fichier local: ${_extractFileName(_lastSavedFilePath!)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPatientSelector(String doctorUid) {
    if (doctorUid.isEmpty) {
      return const Text('Session expirée.');
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.streamDoctorPatients(doctorUid),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (patients.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, color: AppColors.textLight),
                const SizedBox(width: 12),
                Text(
                  'Aucun patient assigné',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedPatientUid,
          hint: const Text('Sélectionner un patient'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          items: patients.map((patient) {
            final uid = patient['uid'] as String? ?? '';
            final name = (patient['fullName'] as String?)?.trim() ?? 'Patient';
            return DropdownMenuItem<String>(value: uid, child: Text(name));
          }).toList(),
          onChanged: (uid) {
            setState(() {
              _selectedPatientUid = uid;
              _selectedPatientData = patients.firstWhere(
                (p) => p['uid'] == uid,
                orElse: () => <String, dynamic>{'fullName': 'Patient'},
              );
              _selectedPatientName =
                  (_selectedPatientData?['fullName'] as String?)?.trim() ??
                  'Patient';
              _lastPdfBytes = null;
              _lastSavedFilePath = null;
            });
          },
        );
      },
    );
  }
}
