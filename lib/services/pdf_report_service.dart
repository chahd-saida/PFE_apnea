import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List> generatePdfReport(ReportData data) async {
  final patient = Patient(
    id: data.patientId ?? 'patient_inconnu',
    fullName: data.patientFullName ?? 'Patient',
    age: data.patientAge,
    gender: data.patientGender,
    medicalId: data.patientMedicalId,
  );
  return PdfReportService().generatePdfReport(patient, data);
}

class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.age,
    this.gender,
    this.medicalId,
  });

  final String id;
  final String fullName;
  final int? age;
  final String? gender;
  final String? medicalId;
}

class ReportData {
  const ReportData({
    required this.doctorName,
    required this.generatedAt,
    this.patientId,
    this.patientFullName,
    this.patientAge,
    this.patientGender,
    this.patientMedicalId,
    this.startDate,
    this.endDate,
    this.averageSpo2,
    this.averageHeartRate,
    this.totalApneas,
    this.totalSessions,
    this.notes = const <Map<String, dynamic>>[],
    this.includeClinicalData = true,
    this.includeApneaEvents = true,
    this.includeDoctorDiagnosis = true,
    this.includeRecommendations = true,
  });

  final String doctorName;
  final DateTime generatedAt;
  final String? patientId;
  final String? patientFullName;
  final int? patientAge;
  final String? patientGender;
  final String? patientMedicalId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? averageSpo2;
  final double? averageHeartRate;
  final int? totalApneas;
  final int? totalSessions;
  final List<Map<String, dynamic>> notes;
  final bool includeClinicalData;
  final bool includeApneaEvents;
  final bool includeDoctorDiagnosis;
  final bool includeRecommendations;
}

class PdfReportService {
  Future<Uint8List> generatePdfReport(Patient patient, ReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.openSansRegular(),
            bold: await PdfGoogleFonts.openSansBold(),
          ),
        ),
        build: (context) => <pw.Widget>[
          _header(patient, data),
          pw.SizedBox(height: 16),
          _patientSection(patient),
          pw.SizedBox(height: 14),
          _analysisSection(data),
          if (data.includeClinicalData) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _clinicalSection(data),
          ],
          if (data.includeDoctorDiagnosis) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _doctorNotesSection(data.notes),
          ],
          if (data.includeRecommendations) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _recommendationSection(data),
          ],
          pw.SizedBox(height: 20),
          _signature(data.doctorName, data.generatedAt),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (bytes.isEmpty) {
      throw Exception('Le fichier PDF généré est vide.');
    }
    return bytes;
  }

  Future<File> savePdfToLocal({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final directory = await _resolveWritableDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final exists = await file.exists();
    if (!exists) {
      throw FileSystemException('Le fichier PDF n\'a pas pu être enregistré.');
    }

    return file;
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Impossible de partager un PDF vide.');
    }
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  Future<Directory> _resolveWritableDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      if (await docs.exists()) {
        return docs;
      }
    }

    final fallback = await getTemporaryDirectory();
    return fallback;
  }

  pw.Widget _header(Patient patient, ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Rapport Médical du Sommeil',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Patient: ${patient.fullName}'),
          pw.Text('Identifiant: ${patient.id}'),
          pw.Text('Date génération: ${_formatDate(data.generatedAt)}'),
        ],
      ),
    );
  }

  pw.Widget _patientSection(Patient patient) {
    return _sectionCard(
      title: 'Informations patient',
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
        },
        children: <pw.TableRow>[
          _row('Nom complet', patient.fullName),
          _row('ID patient', patient.id),
          _row('Age', patient.age?.toString() ?? 'Non renseigné'),
          _row(
            'Sexe',
            patient.gender?.trim().isNotEmpty == true
                ? patient.gender!
                : 'Non renseigné',
          ),
          _row(
            'Numéro dossier',
            patient.medicalId?.trim().isNotEmpty == true
                ? patient.medicalId!
                : 'N/A',
          ),
        ],
      ),
    );
  }

  pw.Widget _analysisSection(ReportData data) {
    return _sectionCard(
      title: 'Résultats d\'analyse',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (data.startDate != null && data.endDate != null)
            pw.Text(
              'Période: ${_formatDate(data.startDate!)} - ${_formatDate(data.endDate!)}',
            ),
          pw.Text('Total sessions analysées: ${data.totalSessions ?? 0}'),
          pw.Text('Indice apnée détectée: ${data.totalApneas ?? 0} événements'),
          pw.Text(_severityLabel(data.totalApneas ?? 0)),
        ],
      ),
    );
  }

  pw.Widget _clinicalSection(ReportData data) {
    return _sectionCard(
      title: 'Données cliniques',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'SpO2 moyenne: ${data.averageSpo2?.toStringAsFixed(1) ?? 'N/A'} %',
          ),
          pw.Text(
            'Fréquence cardiaque moyenne: ${data.averageHeartRate?.toStringAsFixed(0) ?? 'N/A'} bpm',
          ),
        ],
      ),
    );
  }

  pw.Widget _doctorNotesSection(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) {
      return _sectionCard(
        title: 'Diagnostic médecin',
        child: pw.Text('Aucune note clinique disponible.'),
      );
    }

    final latest = notes.take(5).map((note) {
      final date = _extractDateTime(note['createdAt']);
      final diagnosis = (note['diagnosis'] as String?)?.trim();
      final text = (note['note'] as String?)?.trim();
      final content = <String>[
        if (diagnosis != null && diagnosis.isNotEmpty) 'Diagnostic: $diagnosis',
        if (text != null && text.isNotEmpty) 'Note: $text',
      ].join(' | ');
      return '${date != null ? _formatDateTime(date) : 'Date inconnue'} - $content';
    }).toList();

    return _sectionCard(
      title: 'Diagnostic médecin',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: latest
            .map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Bullet(text: entry),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _recommendationSection(ReportData data) {
    final apneas = data.totalApneas ?? 0;
    final spo2 = data.averageSpo2 ?? 0;

    final recommendations = <String>[
      if (apneas >= 30)
        'Orientation prioritaire vers un spécialiste du sommeil pour bilan approfondi.'
      else if (apneas >= 15)
        'Suivi rapproché recommandé et réévaluation des habitudes de sommeil.'
      else
        'Maintenir un suivi régulier et les mesures d\'hygiène du sommeil.',
      if (spo2 > 0 && spo2 < 92)
        'Surveillance de la saturation nocturne renforcée.',
      'Contrôle clinique recommandé dans 2 à 4 semaines.',
    ];

    return _sectionCard(
      title: 'Recommandations',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: recommendations
            .map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Bullet(text: line),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _signature(String doctorName, DateTime generatedAt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('Date: ${_formatDate(generatedAt)}'),
            pw.SizedBox(height: 20),
            pw.Text('Signature médecin:'),
            pw.SizedBox(height: 24),
            pw.Text(
              doctorName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionCard({required String title, required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value)),
      ],
    );
  }

  String _severityLabel(int apneas) {
    if (apneas >= 30) return 'Sévérité apnée: sévère';
    if (apneas >= 15) return 'Sévérité apnée: modérée';
    if (apneas >= 5) return 'Sévérité apnée: légère';
    return 'Sévérité apnée: absence significative';
  }

  DateTime? _extractDateTime(dynamic value) {
    if (value is DateTime) return value;
    final hasToDate = value != null && value.toString().contains('Timestamp');
    if (hasToDate) {
      try {
        final date = value.toDate();
        if (date is DateTime) return date;
      } catch (_) {}
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$min';
  }
}
