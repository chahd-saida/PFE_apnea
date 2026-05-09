import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

class NightDetailScreen extends StatefulWidget {
  final String nightId;

  const NightDetailScreen({super.key, required this.nightId});

  @override
  State<NightDetailScreen> createState() => _NightDetailScreenState();
}

class _NightDetailScreenState extends State<NightDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;
  late Future<Map<String, dynamic>?> _measurementFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('🌙 NightDetailScreen nightId = "${widget.nightId}"');
    _measurementFuture = _firebaseService.getMeasurementById(widget.nightId);
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
      await _firebaseService.saveDoctorNote(
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
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la nuit')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _measurementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur lors du chargement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return _buildFallbackView(widget.nightId, user?.uid ?? '');
          }
          return _buildDetailView(data, user?.uid ?? '');
        },
      ),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  Widget _buildDetailView(Map<String, dynamic> data, String uid) {
    try {
      final timestamp = _extractDateTime(data['timestamp']);
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final apneas = (data['apneas'] as num?)?.toInt() ?? 0;
      final spo2 =
          ((data['avgSpo2'] ?? data['spo2']) as num?)?.toDouble() ?? 0.0;
      final heartRate =
          ((data['avgHeartRate'] ?? data['heartRate']) as num?)?.toDouble() ??
          0.0;
      final duration = (data['durationMinutes'] as num?)?.toInt() ?? 0;

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

      // Utilisation de SingleChildScrollView + Column pour éviter les problèmes de layout
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timestamp != null) _buildDateHeader(timestamp),
            const SizedBox(height: 16),
            _buildScoreCard(score, scoreColor, scoreLabel, duration),
            const SizedBox(height: 16),
            // Grille avec Row (plus fiable que GridView)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildVitalCard(
                    'SpO₂',
                    '${spo2.toStringAsFixed(1)}%',
                    Icons.air,
                    _getSpo2Color(spo2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalCard(
                    'FC moy.',
                    '${heartRate.toStringAsFixed(0)} bpm',
                    Icons.favorite,
                    _getHeartRateColor(heartRate),
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
            const SizedBox(height: 20),
            _buildGraphSection(),
            const SizedBox(height: 20),
            _buildNotesSection(uid),
            const SizedBox(height: 80),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur lors du traitement des données',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Exception: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Version sans date (pour compatibilité si timestamp manquant)
  Widget _buildDetailViewWithoutDate(
    int score,
    int apneas,
    double spo2,
    double heartRate,
    int duration,
    String uid,
  ) {
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
          _buildScoreCard(score, scoreColor, scoreLabel, duration),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildVitalCard(
                  'SpO₂',
                  '${spo2.toStringAsFixed(1)}%',
                  Icons.air,
                  _getSpo2Color(spo2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalCard(
                  'FC moy.',
                  '${heartRate.toStringAsFixed(0)} bpm',
                  Icons.favorite,
                  _getHeartRateColor(heartRate),
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
          const SizedBox(height: 20),
          _buildGraphSection(),
          const SizedBox(height: 20),
          _buildNotesSection(uid),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Fonctions de couleurs pour éviter la répétition
  Color _getSpo2Color(double spo2) {
    if (spo2 < 90) return AppColors.error;
    if (spo2 < 95) return AppColors.warning;
    return AppColors.primary;
  }

  Color _getHeartRateColor(double heartRate) {
    return (heartRate < 45 || heartRate > 100)
        ? AppColors.error
        : AppColors.success;
  }

  Color _getApneaColor(int apneas) {
    if (apneas >= 5) return AppColors.error;
    if (apneas >= 3) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildFallbackView(String measurementId, String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mesure introuvable (ID: $measurementId)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.nights_stay,
                    size: 48,
                    color: AppColors.textMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Données détaillées indisponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lancez une session de surveillance pour voir vos données détaillées.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.realtimeMonitoring),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer surveillance'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    const weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
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
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${date.day} $month ${date.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'sur 100',
                    style: TextStyle(color: AppColors.textMedium),
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
                      ),
                    ),
                  ),
                  if (duration > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Durée: ${_formatDuration(duration)}',
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  Widget _buildGraphSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Graphiques détaillés',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Graphiques SpO₂, FC et mouvements',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    Text(
                      'Disponibles avec le capteur BLE',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Événements clés',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildEventItem('Apnée détectée', '02:15', AppColors.error),
            _buildEventItem('SpO₂ < 92%', '03:00', AppColors.warning),
            _buildEventItem('Mouvement agité', '04:30', AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(String label, String time, Color color) {
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
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String uid) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                hintStyle: TextStyle(color: AppColors.textLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
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
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Partage bientôt disponible.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }
}
