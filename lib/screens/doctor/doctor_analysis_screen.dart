import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/services/note_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

/// Ecran d'analyse detaillee des donnees d'une nuit pour un patient
/// Permet au docteur de voir les resumés de mesure, ajouter des annotations
/// et enregistrer un diagnostic ou des notes cliniques
class DoctorAnalysisScreen extends StatefulWidget {
  /// ID du patient (URL-encode)
  final String patientId;

  /// Date de la nuit a analyser (format: YYYY-MM-DD, URL-encodee)
  final String nightDate;

  const DoctorAnalysisScreen({
    super.key,
    required this.patientId,
    required this.nightDate,
  });

  @override
  State<DoctorAnalysisScreen> createState() => _DoctorAnalysisScreenState();
}

/// Etat du widget DoctorAnalysisScreen
/// Gere l'affichage des donnees de mesure, les champs de diagnostic
/// et les selections de signaux a afficher
class _DoctorAnalysisScreenState extends State<DoctorAnalysisScreen> {
  /// Service pour acceder aux notes stockees en Firestore
  final NoteService _noteService = NoteService();

  /// Service pour recuperer les enregistrements de mesure
  final MeasurementService _measurementService = MeasurementService();

  /// Service pour acceder aux profils utilisateurs
  final UserService _userService = UserService();

  /// Controleur pour le champ Diagnostic
  final TextEditingController _diagnosisController = TextEditingController();

  /// Controleur pour le champ Notes cliniques
  final TextEditingController _noteController = TextEditingController();

  /// Flag pour indiquer que l'enregistrement est en cours
  bool _isSaving = false;

  /// Selections des signaux a afficher (4 types de signaux)
  bool _ecgSelected = true; // ECG (electrocardiogramme)
  bool _spo2Selected = true; // SpO2 (saturation oxygene)
  bool _hrSelected = false; // HR (frequence cardiaque)
  bool _movementSelected = false; // Mouvement du patient

  /// Libere les ressources des controleurs au moment du dispose
  @override
  void dispose() {
    _diagnosisController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Sauvegarde le diagnostic et les notes cliniques en Firestore
  /// Affiche un snackbar de confirmation ou d'erreur
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

  /// Construit l'interface avec sections principales:
  /// - En-tete avec info patient
  /// - Resume des mesures
  /// - Selecteur de signaux
  /// - Zone pour graphes
  /// - Evenements annotes
  /// - Notes precedentes
  /// - Section diagnostic avec sauvegarde
  @override
  Widget build(BuildContext context) {
    /// Decode les parametres URL-encodes
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

  /// Charge les donnees de mesure du patient pour une nuit donnee
  /// Retourne null si aucune donnee n'existe
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

  /// En-tete avec infos du patient et date de la nuit
  /// Affiche: Avatar avec initiale + Nom + Date
  Widget _buildPatientHeader(String patientId, String date) {
    return FutureBuilder<Map<String, dynamic>?>(
      /// Charge le profil du patient en background
      future: _userService.getUserProfile(patientId),
      builder: (context, snap) {
        /// Recupere le nom complet du profil patient
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

  /// Affiche un resume des mesures principales en 4 chips colorees
  /// Score (0-100) | SpO2 (%) | FC moyenne (bpm) | Apnees (nombre)
  Widget _buildMeasurementSummary(Map<String, dynamic> data) {
    /// Extraction des donnees de mesure avec valeurs par defaut
    final score = (data['score'] as num?)?.toInt() ?? 0; // Score apnea 0-100
    final spo2 =
        (data['avgSpo2'] ?? data['spo2'] as num?)?.toDouble() ??
        0; // Saturation O2
    final hr =
        (data['avgHeartRate'] ?? data['heartRate'] as num?)?.toDouble() ??
        0; // FC moyenne
    final apneas =
        (data['apneas'] as num?)?.toInt() ?? 0; // Nombre d'apnees detectees

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

  /// Cree un chip pour afficher une metrique (valeur + etiquette + couleur)
  /// Utilise pour Score, SpO2, FC, Apnees dans le resume
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        /// Colonne: valeur en grand + label en petit
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

  /// Barre de selection pour choisir les signaux a afficher sur le graphe
  /// 4 options: ECG, SpO2, Frequence cardiaque, Mouvement
  /// Utilise FilterChip pour une selection/deselection facile
  Widget _buildSignalSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Titre avec icone graphe
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

  /// Zone de graphe multi-signaux
  /// Affiche un placeholder indiquant que les donnees BLE sont requises
  /// Hauteur: 200px, fond gris clair
  Widget _buildGraphArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      /// Placeholder: icone + texte informatif
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

  /// Section affichant les evenements detectes pendant la nuit
  /// Exemples: Apnee obstructive, apnee centrale, desaturation
  /// Permet au docteur d'ajouter des annotations supplementaires
  Widget _buildEventsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Titre avec icone alerte
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

  /// Affiche une ligne d'evenement avec:
  /// - Point colore (indicateur de severite)
  /// - Heure de l'evenement
  /// - Description de l'evenement
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

  /// Affiche les notes precedentes du patient (max 3 dernieres)
  /// Utilise un Stream pour mise a jour en temps reel
  /// Affiche diagnostic + notes cliniques pour chaque entree
  Widget _buildPreviousNotes(String patientId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      /// Stream Firestore des notes du patient
      stream: _noteService.streamPatientNotes(patientId),
      builder: (context, snapshot) {
        /// Recupere la liste des notes ou liste vide
        final notes = snapshot.data ?? [];
        if (notes.isEmpty)
          return const SizedBox.shrink(); // Rien si aucune note

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

                /// Affiche max 3 dernieres notes
                ...notes.take(3).map((note) {
                  /// Extraction des donnees: date, texte de note, diagnostic
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

  /// Formulaire pour saisir le diagnostic et les notes cliniques
  /// Contient 2 champs texte (diagnostic + notes) et un bouton de sauvegarde
  /// En attente de mise a jour Firestore, affiche un spinner
  Widget _buildDiagnosisSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Titre avec icone formulaire
            const Text(
              '📋 Diagnostic médecin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// Champ pour entrer le diagnostic (ex: SAS leger, modere, severe)
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

            /// Champ multi-ligne pour observations et recommandations
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

  /// Retourne la couleur basee sur le score (0-100)
  /// Vert: >= 80 | Orange: 50-79 | Rouge: < 50
  Color _scoreColor(int score) => score >= 80
      ? Colors.green
      : score >= 50
      ? Colors.orange
      : Colors.red;

  /// Retourne la couleur basee sur la SpO2
  /// Rouge: < 90% (dangereux) | Orange: 90-94% (precaire) | Bleu: >= 95% (OK)
  Color _spo2Color(double spo2) => spo2 < 90
      ? Colors.red
      : spo2 < 95
      ? Colors.orange
      : Colors.blue;

  /// Retourne la couleur basee sur le nombre d'apnees
  /// Vert: 0-2 (OK) | Orange: 3-4 (modere) | Rouge: >= 5 (severe)
  Color _apneaColor(int apneas) => apneas >= 5
      ? Colors.red
      : apneas >= 3
      ? Colors.orange
      : Colors.green;

  /// Utilitaire: Formate un timestamp en chaine lisible (JJ/MM/YYYY)
  /// Gere: DateTime natif, String ISO 8601, Timestamp Firestore
  /// Retourne une chaine vide si la valeur est null ou invalide
  static String _formatTimestamp(dynamic value) {
    if (value == null) return '';

    /// Convertit differents formats en DateTime
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Timestamp) {
      date = value.toDate();
    }

    if (date == null) return '';

    /// Retourne format JJ/MM/YYYY
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
