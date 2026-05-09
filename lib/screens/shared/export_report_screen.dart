import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/pdf_report_service.dart';
import 'package:apnea_project/theme/app_colors.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfReportService _pdfReportService = PdfReportService();

  DateTimeRange? _selectedDateRange;
  bool _includeGeneralSummary = true;
  bool _includeEcgGraphs = true;
  bool _includeSpo2Graphs = true;
  bool _includeApneaEvents = true;
  bool _includePersonalNotes = true;
  String _selectedFormat = 'PDF';
  bool _isProcessing = false;

  final TextEditingController _emailController = TextEditingController();

  Uint8List? _cachedPdfBytes;
  File? _cachedPdfFile;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<File?> _generateAndSavePdf() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      _showError('Session expirée. Veuillez vous reconnecter.');
      return null;
    }

    if (_selectedFormat != 'PDF') {
      _showError('Seul le format PDF est disponible actuellement.');
      return null;
    }

    setState(() => _isProcessing = true);
    try {
      final profile = await _firebaseService.getUserProfile(user.uid);
      final stats = await _firebaseService.getPatientStats(user.uid);
      final allMeasurements = await _firebaseService.getMeasurementRecords(
        uid: user.uid,
        limit: 100,
      );
      final allNotes = await _firebaseService.getPatientNotes(user.uid);

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

      final reportData = ReportData(
        doctorName: (profile?['doctorName'] as String?)?.trim() ?? 'Médecin',
        generatedAt: DateTime.now(),
        patientId: user.uid,
        patientFullName:
            (profile?['fullName'] as String?)?.trim().isNotEmpty == true
            ? (profile?['fullName'] as String).trim()
            : 'Patient',
        patientAge: _computeAge(profile?['dateOfBirth']),
        patientGender: (profile?['gender'] as String?)?.trim(),
        patientMedicalId: (profile?['medicalId'] as String?)?.trim(),
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        averageSpo2: _includeSpo2Graphs || _includeGeneralSummary
            ? avgSpo2
            : null,
        averageHeartRate: _includeEcgGraphs || _includeGeneralSummary
            ? avgHeartRate
            : null,
        totalApneas: _includeApneaEvents ? totalApneas : 0,
        totalSessions: _includeGeneralSummary
            ? totalSessions
            : measurements.length,
        measurements: measurements,
        notes: _includePersonalNotes ? notes : <Map<String, dynamic>>[],
        includeClinicalData: _includeGeneralSummary,
        includeSignalGraphs: _includeEcgGraphs || _includeSpo2Graphs,
        includeApneaEvents: _includeApneaEvents,
        includeDoctorDiagnosis: _includePersonalNotes,
        includeRecommendations: true,
      );

      final pdfBytes = await generatePdfReport(reportData);
      if (pdfBytes.isEmpty) {
        throw Exception('Le fichier PDF généré est vide.');
      }

      final fileName = 'report_${user.uid}.pdf';
      final file = await _pdfReportService.savePdfToLocal(
        bytes: pdfBytes,
        fileName: fileName,
      );

      if (!mounted) return null;
      setState(() {
        _cachedPdfBytes = pdfBytes;
        _cachedPdfFile = file;
      });

      return file;
    } on FileSystemException {
      _showError(
        'Impossible d\'enregistrer le fichier dans le stockage local.',
      );
      return null;
    } catch (e) {
      _showError('Erreur lors de la génération du rapport: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<File?> _ensurePdfFile() async {
    final existing = _cachedPdfFile;
    if (existing != null && await existing.exists()) {
      return existing;
    }
    return _generateAndSavePdf();
  }

  Future<void> _onDownloadLocal() async {
    final file = await _generateAndSavePdf();
    if (file == null || !mounted) return;
    _showSuccess('Rapport téléchargé: ${_extractFileName(file.path)}');
  }

  Future<void> _onShare() async {
    final file = await _ensurePdfFile();
    if (file == null) return;

    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'Rapport médical',
        subject: 'Rapport médical PDF',
      );
      if (!mounted) return;
      _showSuccess('Partage du rapport lancé.');
    } catch (e) {
      _showError('Échec du partage: $e');
    }
  }

  Future<void> _onSend() async {
    final file = await _ensurePdfFile();
    if (file == null) return;

    final emailTarget = _emailController.text.trim();
    final text = emailTarget.isNotEmpty
        ? 'Rapport médical à destination de: $emailTarget'
        : 'Rapport médical (email/WhatsApp/...)';

    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: text,
        subject: 'Envoi rapport médical',
      );
      if (!mounted) return;
      _showSuccess('Envoi du rapport lancé.');
    } catch (e) {
      _showError('Échec de l\'envoi: $e');
    }
  }

  Future<void> _onPreviewPdf() async {
    Uint8List? bytes = _cachedPdfBytes;
    if (bytes == null || bytes.isEmpty) {
      final file = await _ensurePdfFile();
      if (file == null) return;
      bytes = await file.readAsBytes();
    }

    if (bytes.isEmpty) {
      _showError('Aperçu impossible: PDF vide.');
      return;
    }

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes!);
    } catch (e) {
      _showError('Impossible d\'ouvrir l\'aperçu PDF: $e');
    }
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
      final date = _extractDateTime(item[key]);
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

  String _extractFileName(String path) {
    if (path.isEmpty) return path;
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Rapport')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            const Text(
              '📊 Inclure :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Résumé général'),
              value: _includeGeneralSummary,
              onChanged: (value) =>
                  setState(() => _includeGeneralSummary = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Graphiques ECG'),
              value: _includeEcgGraphs,
              onChanged: (value) =>
                  setState(() => _includeEcgGraphs = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Graphiques SpO₂'),
              value: _includeSpo2Graphs,
              onChanged: (value) =>
                  setState(() => _includeSpo2Graphs = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Événements apnée'),
              value: _includeApneaEvents,
              onChanged: (value) =>
                  setState(() => _includeApneaEvents = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Notes personnelles'),
              value: _includePersonalNotes,
              onChanged: (value) =>
                  setState(() => _includePersonalNotes = value ?? false),
            ),
            const SizedBox(height: 20),
            const Text(
              '📤 Format :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: _selectedFormat,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFormat = value);
                }
              },
              child: const Row(
                children: [
                  Radio<String>(value: 'PDF'),
                  Text('PDF'),
                  Radio<String>(value: 'CSV'),
                  Text('CSV'),
                  Radio<String>(value: 'DICOM'),
                  Text('DICOM'),
                ],
              ),
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
                labelText: 'Email du destinataire (ex: medecin@clinic.com)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _onDownloadLocal,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isProcessing ? 'Traitement...' : 'Télécharger local',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _onShare,
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _onSend,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _onPreviewPdf,
              icon: const Icon(Icons.visibility),
              label: const Text('Aperçu PDF'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (_cachedPdfFile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dernier fichier: ${_extractFileName(_cachedPdfFile!.path)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
