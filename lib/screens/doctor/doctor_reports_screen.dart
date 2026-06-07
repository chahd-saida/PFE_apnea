import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/stats_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/note_service.dart';
import 'package:apnea_project/services/user_service.dart';
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
  // Services pour acceder aux donnees du backend
  final StatsService _statsService = StatsService();
  final MeasurementService _measurementService = MeasurementService();
  final NoteService _noteService = NoteService();
  final UserService _userService = UserService();
  final PdfReportService _pdfReportService = PdfReportService();

  // Donnees du patient selectionne
  // Stocke l'UID unique, le nom et les donnees completes du patient
  String? _selectedPatientUid;
  String? _selectedPatientName;
  Map<String, dynamic>? _selectedPatientData;

  // Filtrage temporel
  // Permet au medecin de selectionner une plage de dates pour le rapport
  DateTimeRange? _selectedDateRange;

  // Sections du rapport a inclure (toutes activees par defaut)
  // Chaque booleen controle l'inclusion d'une section specifique du PDF
  bool _includeClinicalData = true; // SpO2, FC, sessions
  bool _includeApneaEvents = true; // Evenements d'apnee detectes
  bool _includeDoctorDiagnosis = true; // Notes et diagnostics du medecin
  bool _includeRecommendations = true; // Recommandations de traitement

  // Gestion de l'etat de generation et sauvegarde
  // Suivi du processus de generation et stockage du PDF genere
  bool _isGenerating = false; // Indique si la generation est en cours
  bool _isPreviewLoading = false; // Indique si l'apercu se charge
  Uint8List? _lastPdfBytes; // Les octets du dernier PDF genere
  String? _lastSavedFilePath; // Chemin d'acces du fichier PDF sauvegarde

  // Donnees statistiques du patient selectionne
  // Donnees mises en cache lors de la selection d'un patient
  Map<String, dynamic>?
  _patientStats; // Stats compilees (SpO2 moy., FC, apnees, etc.)
  int _noteCount = 0; // Nombre de notes medicales enregistrees
  bool _loadingStats = false; // Indicateur de chargement des stats

  // Getters utilitaires pour simplifier les conditions
  // Verifie si un patient a ete selectionne
  bool get _hasPatient => _selectedPatientUid != null;

  // Verifie si un PDF a ete genere et contient des donnees
  bool get _hasPdf => _lastPdfBytes != null && _lastPdfBytes!.isNotEmpty;

  // Compte le nombre de sections activees pour affichage dans l'UI
  int get _activeSectionsCount => [
    _includeClinicalData,
    _includeApneaEvents,
    _includeDoctorDiagnosis,
    _includeRecommendations,
  ].where((b) => b).length;

  // Dialogue de selection de la plage de dates
  // Affiche un calendrier permettant au medecin de choisir le debut et la fin de periode
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  // Recuperation et mise en cache des statistiques du patient
  // Appelle les services pour obtenir les donnees consolidees du patient
  Future<void> _loadPatientStats(String patientUid) async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _statsService.getPatientStats(
        patientUid,
        getMeasurementRecords: _measurementService.getMeasurementRecords,
      );
      final notes = await _noteService.getPatientNotes(patientUid);
      setState(() {
        _patientStats = stats;
        _noteCount = notes.length;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  // Processus principal de generation du rapport PDF
  // Valide les donnees, appelle le service PDF et sauvegarde localement
  Future<void> _generateReport() async {
    if (!_hasPatient) {
      _showSnack('Veuillez sélectionner un patient.', isError: true);
      return;
    }
    if (!_includeClinicalData &&
        !_includeApneaEvents &&
        !_includeDoctorDiagnosis &&
        !_includeRecommendations) {
      _showSnack('Sélectionnez au moins une section à inclure.', isError: true);
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
      final fileName =
          'rapport_${patient.fullName.replaceAll(' ', '_')}_${_fmtFileName(DateTime.now())}.pdf';
      final file = await _pdfReportService.savePdfToLocal(
        bytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;
      setState(() {
        _lastPdfBytes = bytes;
        _lastSavedFilePath = file.path;
      });
      _showSnack('✅ Rapport généré avec succès !');
    } on FileSystemException {
      _showSnack('Permission de stockage refusée.', isError: true);
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Affichage d'un apercu du PDF dans un dialogue modal
  // Genere le rapport si necessaire avant d'afficher l'apercu
  Future<void> _previewPdf() async {
    // Genere le PDF s'il n'existe pas encore
    if (!_hasPdf) {
      setState(() => _isPreviewLoading = true);
      await _generateReport();
      setState(() => _isPreviewLoading = false);
    }
    if (!_hasPdf || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 900,
          height: 700,
          child: PdfPreview(
            build: (_) => _lastPdfBytes!,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'rapport_${_selectedPatientName ?? 'patient'}.pdf',
          ),
        ),
      ),
    );
  }

  // Partage du PDF via les options de partage du systeme
  // Utilise les services natives pour envoyer le fichier
  Future<void> _sharePdf() async {
    // Genere le PDF s'il n'existe pas encore avant de le partager
    if (!_hasPdf) await _generateReport();
    if (!_hasPdf || !mounted) return;
    try {
      await _pdfReportService.sharePdf(
        bytes: _lastPdfBytes!,
        fileName: 'rapport_${_selectedPatientName ?? 'patient'}.pdf',
      );
    } catch (e) {
      _showSnack('Erreur de partage : $e', isError: true);
    }
  }

  // Assemblage des donnees du rapport a partir des services
  // Consolide tous les elements (stats, notes, etc.) en un objet ReportData
  Future<ReportData> _buildReportData({required String doctorName}) async {
    final patientId = _selectedPatientUid!;
    final stats = await _statsService.getPatientStats(
      patientId,
      getMeasurementRecords: _measurementService.getMeasurementRecords,
    );
    final allNotes = await _noteService.getPatientNotes(patientId);
    final notes = _filterByDateRange(
      allNotes,
      _selectedDateRange,
      key: 'createdAt',
    );

    return ReportData(
      doctorName: doctorName,
      generatedAt: DateTime.now(),
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      // Données cliniques : incluses seulement si la case est cochée
      averageSpo2: _includeClinicalData
          ? double.tryParse((stats['avgSpo2'] ?? '').toString())
          : null,
      averageHeartRate: _includeClinicalData
          ? double.tryParse((stats['avgHeartRate'] ?? '').toString())
          : null,
      // Apnées : incluses seulement si la case est cochée
      totalApneas: _includeApneaEvents
          ? (int.tryParse((stats['totalApneas'] ?? '').toString()) ?? 0)
          : 0,
      totalSessions:
          int.tryParse((stats['totalSessions'] ?? '').toString()) ?? 0,
      // Notes médecin : incluses seulement si la case est cochée
      notes: _includeDoctorDiagnosis ? notes : [],
      // Flags booléens transmis au service PDF
      includeClinicalData: _includeClinicalData,
      includeApneaEvents: _includeApneaEvents,
      includeDoctorDiagnosis: _includeDoctorDiagnosis,
      includeRecommendations: _includeRecommendations,
    );
  }

  // Construction d'un objet Patient a partir des donnees selectionnees
  // Extrait et nettoie les donnees du patient pour les passer au service PDF
  Patient _buildPatient() {
    final data = _selectedPatientData ?? {};
    return Patient(
      id: _selectedPatientUid ?? 'unknown',
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : (_selectedPatientName ?? 'Patient'),
      age: _computeAge(data['dateOfBirth']),
      gender: (data['gender'] as String?)?.trim(),
      medicalId: (data['medicalId'] as String?)?.trim(),
    );
  }

  // Filtrage des elements selon la plage de dates selectionnee
  // Retient uniquement les elements dont la date se situe dans la plage
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
      final dt = _extractDateTime(item[key]);
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  // Extraction securisee d'une DateTime depuis differents types
  // Gere DateTime, Timestamp Firestore, et chaines de caracteres ISO
  DateTime? _extractDateTime(dynamic v) {
    if (v is DateTime) return v; // Deja une DateTime
    try {
      final d = v.toDate(); // Essai de convertir depuis Timestamp Firestore
      if (d is DateTime) return d;
    } catch (_) {}
    if (v is String)
      return DateTime.tryParse(v); // Essai de parser une chaine ISO
    return null; // Impossible a convertir
  }

  // Calcul de l'age du patient en annees
  // Extrait la date de naissance et calcule l'age courant
  int? _computeAge(dynamic dob) {
    final d =
        _extractDateTime(dob) ??
        (dob is String ? DateTime.tryParse(dob) : null);
    if (d == null) return null; // Impossible a extraire
    final now = DateTime.now();
    var age = now.year - d.year; // Difference d'annees
    // Correction si l'anniversaire n'est pas encore passe cette annee
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return age < 0 ? null : age; // Valide seulement si age positif
  }

  // ── Helpers UI ──────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Formatage des dates pour affichage a l'utilisateur
  // Format francais : JJ/MM/YYYY
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Formatage des dates pour les noms de fichiers
  // Format compact : YYYYMMDD
  String _fmtFileName(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  // Extraction du nom de fichier depuis un chemin complet
  // Recupere la derniere composante du chemin (apres le dernier separateur)
  String _extractFileName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  // Construction de l'interface principale de generation de rapports
  @override
  Widget build(BuildContext context) {
    // Recupere l'utilisateur connecte et les preferences d'apparence
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rapports Médicaux',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push(RouteNames.doctorProfile),
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
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Sélection patient ───────────────────────────────
            _buildStep(
              number: '1',
              title: 'Patient',
              isDark: isDark,
              child: _PatientSelector(
                userService: _userService,
                doctorUid: user?.uid ?? '',
                selectedUid: _selectedPatientUid,
                isDark: isDark,
                onSelected: (uid, name, data) {
                  setState(() {
                    _selectedPatientUid = uid;
                    _selectedPatientName = name;
                    _selectedPatientData = data;
                    _lastPdfBytes = null;
                    _lastSavedFilePath = null;
                    _patientStats = null;
                  });
                  _loadPatientStats(uid);
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats patient (si sélectionné) ─────────────────────
            if (_hasPatient) ...[
              _PatientStatsPreview(
                stats: _patientStats,
                loading: _loadingStats,
                noteCount: _noteCount,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],

            // ── 2. Période ─────────────────────────────────────────
            _buildStep(
              number: '2',
              title: 'Période (optionnelle)',
              isDark: isDark,
              child: _DateRangePicker(
                range: _selectedDateRange,
                isDark: isDark,
                onTap: _selectDateRange,
                onClear: () => setState(() => _selectedDateRange = null),
                formatDate: _fmtDate,
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Sections à inclure ──────────────────────────────
            _buildStep(
              number: '3',
              title: 'Sections à inclure',
              subtitle: '$_activeSectionsCount/4 sections sélectionnées',
              isDark: isDark,
              child: _SectionsSelector(
                includeClinicalData: _includeClinicalData,
                includeApneaEvents: _includeApneaEvents,
                includeDoctorDiagnosis: _includeDoctorDiagnosis,
                includeRecommendations: _includeRecommendations,
                isDark: isDark,
                stats: _patientStats,
                noteCount: _noteCount,
                onChanged: (field, value) {
                  setState(() {
                    switch (field) {
                      case 'clinical':
                        _includeClinicalData = value;
                        break;
                      case 'apnea':
                        _includeApneaEvents = value;
                        break;
                      case 'diagnosis':
                        _includeDoctorDiagnosis = value;
                        break;
                      case 'recommendations':
                        _includeRecommendations = value;
                        break;
                    }
                    // Reset PDF si les options changent
                    _lastPdfBytes = null;
                    _lastSavedFilePath = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Actions ─────────────────────────────────────────
            _buildStep(
              number: '4',
              title: 'Générer',
              isDark: isDark,
              child: _ActionsSection(
                isGenerating: _isGenerating,
                isPreviewLoading: _isPreviewLoading,
                hasPdf: _hasPdf,
                hasPatient: _hasPatient,
                savedFilePath: _lastSavedFilePath,
                extractFileName: _extractFileName,
                onGenerate: _generateReport,
                onPreview: _previewPdf,
                onShare: _sharePdf,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget helper pour construire une etape numerotee
  // Affiche un numero cercle, le titre, et le contenu de l'etape
  Widget _buildStep({
    required String number,
    required String title,
    required Widget child,
    required bool isDark,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SÉLECTEUR PATIENT
// ─────────────────────────────────────────────────────────────

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({
    required this.userService,
    required this.doctorUid,
    required this.selectedUid,
    required this.isDark,
    required this.onSelected,
  });

  final UserService userService;
  final String doctorUid;
  final String? selectedUid;
  final bool isDark;
  final void Function(String uid, String name, Map<String, dynamic> data)
  onSelected;

  @override
  Widget build(BuildContext context) {
    if (doctorUid.isEmpty) return const Text('Session expirée.');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.streamDoctorPatients(doctorUid),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final patients = snap.data!;
        if (patients.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, color: AppColors.textMedium),
                const SizedBox(width: 12),
                const Text('Aucun patient assigné'),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedUid != null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade200),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedUid,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sélectionner un patient…',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
              items: patients.map((p) {
                final uid = p['uid'] as String? ?? '';
                final name = (p['fullName'] as String?)?.trim() ?? 'Patient';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
                return DropdownMenuItem<String>(
                  value: uid,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (uid) {
                if (uid == null) return;
                final p = patients.firstWhere((x) => x['uid'] == uid);
                onSelected(
                  uid,
                  (p['fullName'] as String?)?.trim() ?? 'Patient',
                  p,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS PREVIEW
// ─────────────────────────────────────────────────────────────

class _PatientStatsPreview extends StatelessWidget {
  const _PatientStatsPreview({
    required this.stats,
    required this.loading,
    required this.noteCount,
    required this.isDark,
  });
  final Map<String, dynamic>? stats;
  final bool loading;
  final int noteCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Affiche un spinner pendant le chargement des stats
    if (loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    // Cache le composant si pas de donnees disponibles
    if (stats == null) return const SizedBox.shrink();

    // Extrait les valeurs principales des statistiques
    final sessions = stats!['totalSessions'] ?? 0;
    final spo2 = stats!['avgSpo2']?.toString() ?? '—';
    final hr = stats!['avgHeartRate']?.toString() ?? '—';
    final apneas = stats!['totalApneas'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Aperçu des données',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniStat(
                label: 'Sessions',
                value: '$sessions',
                icon: Icons.nights_stay_rounded,
                isDark: isDark,
              ),
              _miniStat(
                label: 'SpO₂ moy.',
                value: '$spo2%',
                icon: Icons.air_rounded,
                isDark: isDark,
              ),
              _miniStat(
                label: 'FC moy.',
                value: '$hr bpm',
                icon: Icons.favorite_rounded,
                isDark: isDark,
              ),
              _miniStat(
                label: 'Apnées',
                value: '$apneas',
                icon: Icons.warning_amber_rounded,
                isDark: isDark,
                highlight: apneas > 0,
              ),
              _miniStat(
                label: 'Notes',
                value: '$noteCount',
                icon: Icons.note_alt_rounded,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.error
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE RANGE PICKER
// ─────────────────────────────────────────────────────────────

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.range,
    required this.isDark,
    required this.onTap,
    required this.onClear,
    required this.formatDate,
  });
  final DateTimeRange? range;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    // Verifie si une plage a ete definie
    final hasRange = range != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasRange
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 20,
              color: hasRange ? AppColors.primary : AppColors.textMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasRange
                    ? '${formatDate(range!.start)}  →  ${formatDate(range!.end)}'
                    : 'Toute la période disponible',
                style: TextStyle(
                  fontSize: 14,
                  color: hasRange
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium),
                  fontWeight: hasRange ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Affiche un bouton de fermeture si une plage est selectionnee
            if (hasRange)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isDark ? Colors.white54 : AppColors.textMedium,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTIONS SELECTOR — fonctionnel avec aperçu du contenu
// ─────────────────────────────────────────────────────────────

class _SectionsSelector extends StatelessWidget {
  const _SectionsSelector({
    required this.includeClinicalData,
    required this.includeApneaEvents,
    required this.includeDoctorDiagnosis,
    required this.includeRecommendations,
    required this.isDark,
    required this.onChanged,
    required this.stats,
    required this.noteCount,
  });

  final bool includeClinicalData,
      includeApneaEvents,
      includeDoctorDiagnosis,
      includeRecommendations;
  final bool isDark;
  final void Function(String field, bool value) onChanged;
  final Map<String, dynamic>? stats;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    // Extrait les valeurs pour afficher des apercus dans les descriptions
    final spo2 = stats?['avgSpo2']?.toString();
    final hr = stats?['avgHeartRate']?.toString();
    final apneas = stats?['totalApneas'] as int?;
    final sessions = stats?['totalSessions'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Column(
        // Affiche les 4 tuiles de selection en colonne
        children: [
          // Tuile 1: Donnees cliniques (SpO2, FC, sessions)
          _SectionTile(
            field: 'clinical',
            icon: Icons.monitor_heart_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Données cliniques',
            subtitle: spo2 != null
                ? 'SpO₂ moy. $spo2% · FC moy. $hr bpm · $sessions sessions'
                : 'SpO₂, fréquence cardiaque, sessions',
            isEnabled: includeClinicalData,
            isDark: isDark,
            onChanged: onChanged,
            isLast: false,
          ),
          _SectionTile(
            field: 'apnea',
            icon: Icons.airline_seat_flat_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Événements apnée',
            subtitle: apneas != null
                ? '$apneas événements détectés'
                : 'Liste et classification des épisodes',
            isEnabled: includeApneaEvents,
            isDark: isDark,
            onChanged: onChanged,
            isLast: false,
          ),
          // Tuile 3: Notes du medecin et diagnostic
          _SectionTile(
            field: 'diagnosis',
            icon: Icons.description_rounded,
            color: const Color(0xFF10B981),
            title: 'Notes & Diagnostic',
            subtitle: stats != null
                ? '$noteCount note${noteCount > 1 ? 's' : ''} médecin enregistrée${noteCount > 1 ? 's' : ''}'
                : 'Diagnostics et observations saisies',
            isEnabled: includeDoctorDiagnosis,
            isDark: isDark,
            onChanged: onChanged,
            isLast: false,
          ),
          // Tuile 4: Recommandations cliniques
          _SectionTile(
            field: 'recommendations',
            icon: Icons.lightbulb_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Recommandations',
            subtitle: 'Plan de traitement et conseils cliniques',
            isEnabled: includeRecommendations,
            isDark: isDark,
            onChanged: onChanged,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.field,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.isDark,
    required this.onChanged,
    required this.isLast,
  });

  final String field, title, subtitle;
  final IconData icon;
  final Color color;
  final bool isEnabled, isDark, isLast;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(field, !isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                )
              : BorderRadius.zero,
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withValues(alpha: 0.12)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isEnabled
                    ? color
                    : (isDark ? Colors.white30 : Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled
                          ? (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMedium)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isEnabled
                    ? color
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEnabled ? Icons.check_rounded : Icons.remove,
                size: 14,
                color: isEnabled
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIONS SECTION
// ─────────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.isGenerating,
    required this.isPreviewLoading,
    required this.hasPdf,
    required this.hasPatient,
    required this.savedFilePath,
    required this.extractFileName,
    required this.onGenerate,
    required this.onPreview,
    required this.onShare,
  });

  final bool isGenerating, isPreviewLoading, hasPdf, hasPatient;
  final String? savedFilePath;
  final String Function(String) extractFileName;
  final VoidCallback onGenerate, onPreview, onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bouton principal — Générer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isGenerating || !hasPatient) ? null : onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isGenerating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Génération en cours…',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        hasPdf
                            ? 'Regénérer le rapport'
                            : 'Générer le rapport PDF',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // BOUTONS SECONDAIRES : Apercu et Partage (visibles si PDF genere)
        if (hasPdf) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              // Aperçu
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPreviewLoading ? null : onPreview,
                  icon: isPreviewLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    'Aperçu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Bouton Partager (envoie via les options systeme)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Partager',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fichier sauvegardé
          if (savedFilePath != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      extractFileName(savedFilePath!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        // Message si pas de patient sélectionné
        if (!hasPatient) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'Sélectionnez d\'abord un patient',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
