import 'dart:io'; // Pour les opérations fichiers et plateforme
import 'dart:typed_data'; // Pour manipuler les données binaires (Uint8List)

import 'package:path_provider/path_provider.dart'; // Pour accéder aux répertoires de l'appareil
import 'package:pdf/pdf.dart'; // Pour créer et manipuler les PDFs
import 'package:pdf/widgets.dart' as pw; // Pour les widgets PDF
import 'package:printing/printing.dart'; // Pour partager les PDFs

/// Point d'entrée pour générer un rapport PDF
/// Crée un objet Patient à partir des données et délègue la génération au service
/// Paramètre: data = les données du rapport (patient, résultats, notes, etc.)
/// Retourne: Uint8List = les bytes du PDF généré
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

/// Modèle de données pour les informations du patient
/// Contient les informations personnelles et médicales utilisées dans le rapport
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.age,
    this.gender,
    this.medicalId,
  });

  /// Identifiant unique du patient dans la base de données
  final String id;

  /// Nom complet du patient (affiché en en-tête du rapport)
  final String fullName;

  /// Âge du patient (peut être nul si non renseigné)
  final int? age;

  /// Sexe du patient (M/F ou autre)
  final String? gender;

  /// Numéro de dossier médical (peut être nul)
  final String? medicalId;
}

/// Modèle de données pour le contenu du rapport PDF
/// Regroupe toutes les informations: données du patient, résultats médicaux, notes du docteur, etc.
/// Permet de configurer quelles sections inclure dans le rapport
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

  /// Nom du médecin qui génère le rapport (affiché en signature)
  final String doctorName;

  /// Date/heure de génération du rapport
  final DateTime generatedAt;

  /// Données du patient
  final String? patientId;
  final String? patientFullName;
  final int? patientAge;
  final String? patientGender;
  final String? patientMedicalId;

  /// Période analysée
  final DateTime? startDate;
  final DateTime? endDate;

  /// Résultats médicaux
  final double? averageSpo2; // Saturation en oxygène moyenne (%)
  final double? averageHeartRate; // Fréquence cardiaque moyenne (bpm)
  final int? totalApneas; // Nombre total d'apnées détectées
  final int? totalSessions; // Nombre de sessions de monitoring
  /// Notes cliniques du médecin
  final List<Map<String, dynamic>> notes;

  /// Flags de configuration: quelles sections inclure dans le rapport
  final bool includeClinicalData; // Inclure SpO2 et FC moyennes
  final bool includeApneaEvents; // Inclure les événements d'apnée
  final bool includeDoctorDiagnosis; // Inclure les notes du médecin
  final bool includeRecommendations; // Inclure les recommandations
}

/// Service centralisé pour générer des rapports PDF médicaux
/// Combine les données du patient et des résultats en un document formaté professionnel
/// Responsabilités:
/// - Générer le contenu du rapport (en-tête, sections, signature)
/// - Sauvegarder le PDF localement sur l'appareil
/// - Partager le PDF via les applications système
class PdfReportService {
  /// Génère le rapport PDF complet
  /// Crée un document multi-page avec toutes les sections conditionnellement incluses
  /// Paramètres:
  ///   - patient: informations du patient
  ///   - data: données du rapport (résultats, notes, dates, etc.)
  /// Retourne: Uint8List = bytes du PDF généré
  Future<Uint8List> generatePdfReport(Patient patient, ReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28), // Marges de 28pt
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.openSansRegular(), // Police de base
            bold: await PdfGoogleFonts.openSansBold(), // Police gras
          ),
        ),
        // Construire les sections du rapport
        build: (context) => <pw.Widget>[
          _header(patient, data), // En-tête avec titre et infos de base
          pw.SizedBox(height: 16),
          _patientSection(patient), // Tableau avec détails du patient
          pw.SizedBox(height: 14),
          _analysisSection(data), // Résultats d'analyse et sévérité
          // Inclure les sections optionnelles selon les flags
          if (data.includeClinicalData) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _clinicalSection(data), // SpO2 et FC moyennes
          ],
          if (data.includeDoctorDiagnosis) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _doctorNotesSection(data.notes), // Notes et diagnostics du médecin
          ],
          if (data.includeRecommendations) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            _recommendationSection(
              data,
            ), // Recommandations basées sur les résultats
          ],
          pw.SizedBox(height: 20),
          _signature(data.doctorName, data.generatedAt), // Signature du médecin
        ],
      ),
    );

    // Convertir le document en bytes
    final bytes = await pdf.save();
    if (bytes.isEmpty) {
      throw Exception('Le fichier PDF généré est vide.');
    }
    return bytes;
  }

  /// Sauvegarde les bytes du PDF dans le système de fichiers local
  /// Localisation: Documents app (Android/iOS) ou Temp directory en fallback
  /// Paramètres:
  ///   - bytes: les bytes du PDF à sauvegarder
  ///   - fileName: nom du fichier (ex: "rapport_apnea.pdf")
  /// Retourne: File = le fichier PDF sauvegardé
  /// Lance une exception si la sauvegarde échoue
  Future<File> savePdfToLocal({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final directory = await _resolveWritableDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    // Écrire les bytes du PDF dans le fichier
    await file.writeAsBytes(bytes, flush: true);

    // Vérifier que le fichier a bien été créé
    final exists = await file.exists();
    if (!exists) {
      throw FileSystemException('Le fichier PDF n\'a pas pu être enregistré.');
    }

    return file;
  }

  /// Partage le PDF via le système de partage de l'appareil
  /// Affiche le sélecteur d'applications (Mail, Drive, Slack, etc.)
  /// Paramètres:
  ///   - bytes: les bytes du PDF à partager
  ///   - fileName: nom du fichier dans le partage
  /// Lance une exception si le PDF est vide
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Impossible de partager un PDF vide.');
    }
    // Utiliser le plugin printing pour afficher le sélecteur système de partage
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Résout le répertoire accessible pour sauvegarder les fichiers
  /// Stratégie:
  /// 1. Sur Android/iOS: utilise le répertoire Documents de l'app (persistant)
  /// 2. En fallback: utilise le répertoire Temp (peut être nettoyé)
  /// Retourne: Directory = le répertoire accessible et writable
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

  /// Construit l'en-tête du rapport (en haut de la première page)
  /// Affiche le titre, le nom du patient, l'ID et la date de génération
  /// Style: fond bleu clair avec bordure
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

  /// Construit la section des informations patient
  /// Affiche dans un tableau: nom, ID, âge, sexe, numéro de dossier
  /// Affiche "Non renseigné" ou "N/A" si les données manquent
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

  /// Construit la section des résultats d'analyse
  /// Affiche: période analysée, nombre de sessions, nombre d'apnées, sévérité
  /// Utilise _severityLabel pour évaluer la gravité basée sur le nombre d'apnées
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

  /// Construit la section des données cliniques
  /// Affiche: SpO2 moyenne (%) et fréquence cardiaque moyenne (bpm)
  /// Formatée avec 1 décimale pour SpO2 et entier pour FC
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

  /// Construit la section des notes et diagnostics du médecin
  /// Affiche les 5 notes les plus récentes (ou moins si moins disponibles)
  /// Format: "Date Heure - Diagnostic (si présent) | Note (si présente)"
  /// Affiche un message si aucune note n'est disponible
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

  /// Construit la section des recommandations cliniques
  /// Génère des recommandations basées sur:
  /// - Nombre d'apnées (classement de sévérité)
  /// - SpO2 moyenne (alerte si < 92%)
  /// - Recommande un contrôle médical dans 2-4 semaines
  /// Sévérité: ≥30 = sévère, ≥15 = modérée, ≥5 = légère, <5 = absente significative
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

  /// Construit la section de signature du rapport
  /// Affiche: date du rapport, espace de signature et nom du médecin en gras
  /// Cette section atteste l'authenticité du rapport
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

  /// Widget réutilisable pour créer une section du rapport
  /// Fournit: titre, bordure, arrondis, espacement cohérent
  /// Paramètres:
  ///   - title: titre de la section (affichée en gras)
  ///   - child: contenu de la section (peut être n'importe quel widget)
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

  /// Crée une ligne de tableau avec label (gras) et valeur
  /// Paramètres:
  ///   - label: l'étiquette (colonne 1, en gras)
  ///   - value: la valeur (colonne 2)
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

  /// Détermine le label de sévérité basé sur le nombre d'apnées
  /// Classification:
  ///   - ≥30 apnées = sévère (indication spécialiste immédiate)
  ///   - 15-29 apnées = modérée (suivi rapproché)
  ///   - 5-14 apnées = légère (monitoring)
  ///   - <5 apnées = absence significative (suivi régulier)
  String _severityLabel(int apneas) {
    if (apneas >= 30) return 'Sévérité apnée: sévère';
    if (apneas >= 15) return 'Sévérité apnée: modérée';
    if (apneas >= 5) return 'Sévérité apnée: légère';
    return 'Sévérité apnée: absence significative';
  }

  /// Convertit différents formats de date/heure en objet DateTime
  /// Accepte: DateTime, Firestore Timestamp, String ISO 8601
  /// Retourne null si la conversion échoue
  /// Utilisé pour normaliser les dates des notes du médecin
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

  /// Formate une date au format DD/MM/YYYY
  /// Exemple: 15/03/2024
  /// Utilisé dans l'en-tête et la signature du rapport
  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  /// Formate une date et heure au format DD/MM/YYYY HH:MM
  /// Exemple: 15/03/2024 14:30
  /// Utilisé pour afficher les dates des notes du médecin avec l'heure
  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$min';
  }
}
