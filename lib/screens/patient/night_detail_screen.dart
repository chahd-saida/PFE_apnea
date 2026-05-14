// lib/screens/patient/night_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/note_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class NightDetailScreen extends StatefulWidget {
  final String nightId;
  const NightDetailScreen({super.key, required this.nightId});

  @override
  State<NightDetailScreen> createState() => _NightDetailScreenState();
}

class _NightDetailScreenState extends State<NightDetailScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;
  late Future<Map<String, dynamic>?> _measurementFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('NightDetailScreen → nightId="${widget.nightId}"');
    _measurementFuture = _loadMeasurement();
  }

  /// Charge la mesure par ID Firestore direct.
  /// L'ID vient de getMeasurementRecords → doc.id, donc correspond exactement.
  Future<Map<String, dynamic>?> _loadMeasurement() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('measurements')
          .doc(widget.nightId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = <String, dynamic>{...doc.data()!, 'id': doc.id};
        debugPrint('✅ Mesure trouvée: ${doc.id} — score=${data['score']}');
        return data;
      }
      debugPrint('⚠️ Aucun document avec id=${widget.nightId}');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur chargement mesure: $e');
      rethrow;
    }
  }

  void _retry() {
    setState(() => _measurementFuture = _loadMeasurement());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote(String patientId) async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    setState(() => _isSavingNote = true);
    try {
      final user = context.read<AuthProvider>().user;
      await _noteService.saveDoctorNote(
        patientId: patientId,
        doctorUid: user?.uid ?? '',
        doctorName: 'Patient',
        note: note,
        measurementId: widget.nightId,
      );
      _noteController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note enregistrée avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la nuit')),
      floatingActionButton: const PatientChatbotFAB(),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _measurementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorView('${snapshot.error}');
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return _buildFallbackView();
          }

          return _buildDetailView(data, uid);
        },
      ),
    );
  }

  // ─── Vue principale avec les données réelles ───────────────────────────
  Widget _buildDetailView(Map<String, dynamic> data, String uid) {
    final timestamp = _extractDateTime(data['timestamp']);

    // SpO2 — accepte avgSpo2 ou spo2
    final spo2Raw = data['avgSpo2'] ?? data['spo2'];
    final spo2 = (spo2Raw as num?)?.toDouble() ?? 0.0;

    // Fréquence cardiaque — accepte avgHeartRate ou heartRate
    final hrRaw = data['avgHeartRate'] ?? data['heartRate'];
    final heartRate = (hrRaw as num?)?.toDouble() ?? 0.0;

    final score = (data['score'] as num?)?.toInt() ?? 0;
    final apneas = (data['apneas'] as num?)?.toInt() ?? 0;
    final duration = (data['durationMinutes'] as num?)?.toInt() ?? 0;

    // Température si disponible
    final tempRaw = data['avgTemperature'] ?? data['temperature'];
    final temperature = (tempRaw as num?)?.toDouble();

    final scoreColor = score >= 80
        ? Colors.green
        : score >= 50
        ? Colors.orange
        : Colors.red;
    final scoreLabel = score >= 80
        ? 'Excellent'
        : score >= 50
        ? 'Moyen'
        : 'Mauvais';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête date ──────────────────────────────────────────
          if (timestamp != null) _buildDateHeader(timestamp),
          if (timestamp != null) const SizedBox(height: 16),

          // ── Score de sommeil ──────────────────────────────────────
          _buildScoreCard(score, scoreColor, scoreLabel, duration),
          const SizedBox(height: 16),

          // ── Vitaux en grille 3 colonnes ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildVitalCard(
                  'SpO₂',
                  spo2 > 0 ? '${spo2.toStringAsFixed(1)}%' : '--',
                  Icons.air,
                  spo2 > 0 ? _getSpo2Color(spo2) : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalCard(
                  'FC moy.',
                  heartRate > 0 ? '${heartRate.toStringAsFixed(0)} bpm' : '--',
                  Icons.favorite,
                  heartRate > 0
                      ? _getHeartRateColor(heartRate)
                      : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalCard(
                  'Apnées',
                  '$apneas',
                  Icons.warning_amber_rounded,
                  _getApneaColor(apneas),
                ),
              ),
            ],
          ),

          // ── Température si disponible ─────────────────────────────
          if (temperature != null && temperature > 0) ...[
            const SizedBox(height: 12),
            _buildTemperatureCard(temperature),
          ],

          const SizedBox(height: 20),

          // ── Résumé textuel ────────────────────────────────────────
          _buildSummaryCard(
            score: score,
            spo2: spo2,
            heartRate: heartRate,
            apneas: apneas,
            duration: duration,
          ),

          const SizedBox(height: 20),

          // ── Notes personnelles ────────────────────────────────────
          _buildNotesSection(uid),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Résumé clinique simple ────────────────────────────────────────────
  Widget _buildSummaryCard({
    required int score,
    required double spo2,
    required double heartRate,
    required int apneas,
    required int duration,
  }) {
    final lines = <String>[];

    if (duration > 0) {
      lines.add('⏱ Durée de la session : ${_formatDuration(duration)}');
    }
    if (spo2 > 0) {
      if (spo2 < 90) {
        lines.add(
          '🔴 SpO₂ critique (${spo2.toStringAsFixed(1)}%) — consulter un médecin',
        );
      } else if (spo2 < 94) {
        lines.add('🟠 SpO₂ légèrement bas (${spo2.toStringAsFixed(1)}%)');
      } else {
        lines.add('🟢 SpO₂ normale (${spo2.toStringAsFixed(1)}%)');
      }
    }
    if (heartRate > 0) {
      if (heartRate < 45 || heartRate > 100) {
        lines.add('🔴 FC anormale (${heartRate.toStringAsFixed(0)} bpm)');
      } else {
        lines.add('🟢 FC normale (${heartRate.toStringAsFixed(0)} bpm)');
      }
    }
    if (apneas >= 5) {
      lines.add('🔴 Nombre élevé d\'apnées ($apneas événements)');
    } else if (apneas >= 3) {
      lines.add('🟠 Apnées modérées ($apneas événements)');
    } else if (apneas > 0) {
      lines.add('🟡 Quelques apnées détectées ($apneas événements)');
    } else {
      lines.add('🟢 Aucune apnée détectée');
    }

    if (lines.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Résumé de la nuit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Carte température ─────────────────────────────────────────────────
  Widget _buildTemperatureCard(double temp) {
    final color = temp > 38.0
        ? AppColors.error
        : temp > 37.5
        ? AppColors.warning
        : AppColors.success;
    final label = temp > 38.0
        ? 'Fièvre'
        : temp > 37.5
        ? 'Légère fièvre'
        : 'Normal';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.thermostat_rounded, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Température corporelle',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                Text(
                  '${temp.toStringAsFixed(1)} °C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Fallback ──────────────────────────────────────────────────────────
  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.nights_stay,
              size: 64,
              color: AppColors.textMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Données introuvables',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${widget.nightId}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.realtimeMonitoring),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer une surveillance'),
              style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _retry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  // ─── Erreur ────────────────────────────────────────────────────────────
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(minimumSize: Size.zero),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers couleur ───────────────────────────────────────────────────
  Color _getSpo2Color(double v) => v < 90
      ? AppColors.error
      : v < 95
      ? AppColors.warning
      : AppColors.primary;

  Color _getHeartRateColor(double v) =>
      (v < 45 || v > 100) ? AppColors.error : AppColors.success;

  Color _getApneaColor(int v) => v >= 5
      ? AppColors.error
      : v >= 3
      ? AppColors.warning
      : AppColors.success;

  // ─── En-tête date ──────────────────────────────────────────────────────
  Widget _buildDateHeader(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    const weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekdays[date.weekday - 1],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '${date.day} ${months[date.month - 1]} ${date.year}  '
                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score card ────────────────────────────────────────────────────────
  Widget _buildScoreCard(int score, Color color, String label, int duration) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score de sommeil',
                    style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 16,
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (duration > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Vital card ────────────────────────────────────────────────────────
  Widget _buildVitalCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Notes section ─────────────────────────────────────────────────────
  Widget _buildNotesSection(String uid) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📝 Notes personnelles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajouter une note sur cette nuit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            // ── Fix: minimumSize override pour éviter le crash Row ───
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSavingNote ? null : () => _saveNote(uid),
                  icon: _isSavingNote
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _isSavingNote ? 'Enregistrement...' : 'Sauvegarder',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers statiques ─────────────────────────────────────────────────
  static DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h == 0 ? '${m} min' : '${h}h ${m.toString().padLeft(2, '0')}min';
  }
}
