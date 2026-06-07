// ════════════════════════════════════════════════════════════════════════════════════
// ÉCRAN DE LISTE DES PATIENTS DU DOCTEUR
// Ce fichier gère l'affichage de tous les patients assignés à un docteur avec filtrage,
// recherche, et gestion des statuts de santé en temps réel via Firestore.
// ════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/screens/doctor/add_patient_screen.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';
import 'package:apnea_project/theme/app_colors.dart';

// ────────────────────────────────────────────────────────────────────────────────────
// MODÈLE DE STATUT DU PATIENT
// Énumération et classe pour gérer les différents états de santé et activité d'un patient
// ────────────────────────────────────────────────────────────────────────────────────

enum PatientStatus { actif, recent, inactif, enAlerte, aucuneDonnee }

/// Classe contenant les informations de style pour afficher le statut d'un patient
/// (label, couleur, icône, couleur de fond)
class _StatusInfo {
  const _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.bgColor,
  });
  final String label;
  final Color color;
  final IconData icon;
  final Color bgColor;
}

/// Détermine le statut d'un patient basé sur:
/// - La présence d'une alerte critique non lue
/// - La date de la dernière mesure enregistrée
/// Retourne un objet _StatusInfo avec label, couleur et icône appropriés
_StatusInfo _resolveStatus(DateTime? lastMeasurement, bool hasAlert) {
  // Priorité 1: Si le patient a une alerte critique, retourner le statut 'En alerte'
  if (hasAlert) {
    return _StatusInfo(
      label: 'En alerte',
      color: AppColors.error,
      icon: Icons.warning_amber_rounded,
      bgColor: AppColors.error.withValues(alpha: 0.1),
    );
  }
  // Priorité 2: Si aucune mesure n'existe, retourner le statut 'Aucune donnée'
  if (lastMeasurement == null) {
    return _StatusInfo(
      label: 'Aucune donnée',
      color: Colors.grey,
      icon: Icons.help_outline_rounded,
      bgColor: Colors.grey.withValues(alpha: 0.1),
    );
  }
  // Calculer la différence entre maintenant et la dernière mesure
  final diff = DateTime.now().difference(lastMeasurement);
  // Statut 'Actif aujourd'hui': mesure moins de 24h ago
  if (diff.inHours < 24) {
    return _StatusInfo(
      label: 'Actif aujourd\'hui',
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
      bgColor: AppColors.success.withValues(alpha: 0.1),
    );
  } // Statut 'Récent': mesure dans les 7 derniers jours
  else if (diff.inDays <= 7) {
    return _StatusInfo(
      label: 'Récent (${diff.inDays}j)',
      color: AppColors.info,
      icon: Icons.access_time_rounded,
      bgColor: AppColors.info.withValues(alpha: 0.1),
    );
  } // Statut 'Inactif': mesure plus de 7 jours ago
  else {
    return _StatusInfo(
      label: 'Inactif (${diff.inDays}j)',
      color: AppColors.warning,
      icon: Icons.schedule_rounded,
      bgColor: AppColors.warning.withValues(alpha: 0.1),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL - LISTE DES PATIENTS
// StatefulWidget affichant la liste des patients du docteur avec filtrage et recherche
// ────────────────────────────────────────────────────────────────────────────────────

/// Écran principal listant tous les patients assignés au docteur
class DoctorPatientsListScreen extends StatefulWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  State<DoctorPatientsListScreen> createState() =>
      _DoctorPatientsListScreenState();
}

/// État de l'écran listant les patients du docteur
class _DoctorPatientsListScreenState extends State<DoctorPatientsListScreen> {
  // Paramètre de recherche pour filtrer les patients par nom
  String _searchQuery = '';
  // Filtre actif sélectionné par l'utilisateur
  String _selectedFilter = 'Tous';
  // Liste des options de filtrage disponibles
  final _filterOptions = ['Tous', 'Actif', 'Récent', 'Inactif', 'En alerte'];

  /// Vérifie si le statut d'un patient correspond au filtre sélectionné
  /// Paramètres: filterLabel (inutilisé), status (statut du patient à vérifier)
  /// Retourne: true si le patient doit être affiché, false sinon
  bool _matchesFilter(String filterLabel, _StatusInfo status) {
    // Tous les patients correspondent au filtre 'Tous'
    if (_selectedFilter == 'Tous') return true;
    // Filtrer les patients actifs
    if (_selectedFilter == 'Actif') return status.label.startsWith('Actif');
    // Filtrer les patients avec activité récente
    if (_selectedFilter == 'Récent') return status.label.startsWith('Récent');
    // Filtrer les patients inactifs (incluant ceux sans données)
    if (_selectedFilter == 'Inactif') {
      return status.label.startsWith('Inactif') ||
          status.label == 'Aucune donnée';
    }
    // Filtrer les patients en alerte
    if (_selectedFilter == 'En alerte') return status.label == 'En alerte';
    return true;
  }

  @override
  /// Construit l'écran principal avec AppBar, liste des patients et boutons d'action
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur actuel (docteur)
    final user = context.watch<AuthProvider>().user;
    // Récupérer le profil du docteur depuis le provider
    final doctorProfile = useDoctorProfile(context);
    // URL de la photo de profil du docteur
    final photoUrl = doctorProfile?.profileImageUrl;
    // Vérifier si le mode sombre est activé
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Vérifier que l'utilisateur est authentifié
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session expirée.')));
    }

    // Instancier les services métier pour les opérations utilisateur et mesures
    final userService = UserService();
    final measurementService = MeasurementService();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      // BARRE SUPÉRIEURE (AppBar) avec titre et profil du docteur
      appBar: AppBar(
        title: const Text('Mes Patients'),
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
      // Bouton d'action flottant pour accéder au chatbot
      floatingActionButton: const DoctorChatbotFAB(),
      // Barre de navigation inférieure avec onglets
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 1),
      body: Column(
        children: [
          // ──────────────────────────────────────────────────────────────────────────────────
          // BARRE DE RECHERCHE ET FILTRES
          // Zone supérieure contenant la barre de recherche et les boutons de filtrage
          // ──────────────────────────────────────────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Champ de saisie pour rechercher les patients par nom
                  child: TextField(
                    // Mettre à jour la requête de recherche à chaque modification
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom…',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium,
                      ),
                      // Afficher un bouton X pour effacer la recherche si du texte est présent
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Liste horizontale des options de filtrage
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final opt = _filterOptions[i];
                      // Vérifier si cette option est le filtre sélectionné
                      final selected = _selectedFilter == opt;
                      return GestureDetector(
                        // Mettre à jour le filtre sélectionné au tap
                        onTap: () => setState(() => _selectedFilter = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMedium),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────────────────────────────
          // LISTE PRINCIPALE DES PATIENTS
          // Affiche les patients filtrés et recherchés, chargés depuis Firestore en temps réel
          // ──────────────────────────────────────────────────────────────────────────────────
          Expanded(
            // StreamBuilder pour écouter les changements de liste des patients en temps réel
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Flux Firestore des patients assignés au docteur
              stream: userService.streamDoctorPatients(user.uid),
              builder: (context, snap) {
                // Afficher un spinner pendant le chargement
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Afficher l'erreur si la requête Firestore échoue
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snap.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                // Récupérer la liste de tous les patients
                final allPatients = snap.data ?? [];

                // Afficher un message vide si aucun patient n'est assigné
                if (allPatients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun patient assigné',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // FutureBuilder pour charger les dernières mesures de chaque patient
                return FutureBuilder<Map<String, DateTime?>>(
                  // Charger les timestamps des dernières mesures pour chaque patient
                  future: _loadLastMeasurements(
                    allPatients,
                    measurementService,
                  ),
                  builder: (context, measSnap) {
                    // Map associant chaque UID patient à sa dernière date de mesure
                    final measurements = measSnap.data ?? {};

                    // Filtrer et rechercher les patients selon les critères de l'utilisateur
                    final filtered = allPatients.where((p) {
                      // Récupérer le nom du patient et le convertir en minuscules pour la recherche
                      final name =
                          (p['fullName'] as String?)?.toLowerCase() ?? '';
                      // Récupérer l'ID unique du patient
                      final uid = p['uid'] as String? ?? '';
                      // Vérifier si le nom correspond à la requête de recherche
                      final matchSearch =
                          _searchQuery.isEmpty ||
                          name.contains(_searchQuery.toLowerCase());
                      // Déterminer le statut du patient
                      final status = _resolveStatus(measurements[uid], false);
                      // Vérifier si le statut correspond au filtre actif
                      final matchFilter = _matchesFilter(
                        _selectedFilter,
                        status,
                      );
                      // Inclure le patient seulement s'il passe les deux filtres
                      return matchSearch && matchFilter;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun patient pour "$_selectedFilter".',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMedium,
                          ),
                        ),
                      );
                    }

                    // ListView affichant les cartes des patients filtrés
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final uid = p['uid'] as String? ?? '';
                        final lastMeas = measurements[uid];
                        return _PatientCard(
                          patient: p,
                          lastMeasurement: lastMeas,
                          isDark: isDark,
                          doctorUid: user.uid,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ──────────────────────────────────────────────────────────────────────────────────
          // BARRE D'ACTION FIXE EN BAS
          // Contient les boutons pour ajouter et assigner des patients
          // ──────────────────────────────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ─── Bouton pour créer un nouveau patient ───
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AddPatientScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ─── Bouton pour assigner un patient existant ───
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignDialog(context),
                    icon: const Icon(Icons.person_search_rounded, size: 16),
                    label: const Text(
                      'Assigner',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Charge les timestamps des dernières mesures pour tous les patients
  /// Paramètres: patients (liste des patients), svc (service de mesures)
  /// Retourne: Un map associant chaque UID patient à sa dernière date de mesure
  Future<Map<String, DateTime?>> _loadLastMeasurements(
    List<Map<String, dynamic>> patients,
    MeasurementService svc,
  ) async {
    // Map pour stocker les résultats UID -> DateTime
    final result = <String, DateTime?>{};
    // Charger les mesures de tous les patients en parallèle
    await Future.wait(
      patients.map((p) async {
        // Récupérer l'UID du patient
        final uid = p['uid'] as String? ?? '';
        // Ignorer les patients sans UID valide
        if (uid.isEmpty) return;
        try {
          // Récupérer le timestamp de la dernière mesure
          result[uid] = await svc.getPatientLastMeasurementTimestamp(uid);
        } catch (_) {
          // En cas d'erreur, associer null (aucune donnée)
          result[uid] = null;
        }
      }),
    );
    return result;
  }

  /// Affiche un dialogue pour assigner un patient existant par email
  /// Paramètre: context (contexte de build)
  void _showAssignDialog(BuildContext context) {
    // Récupérer l'utilisateur (docteur) actuel
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    // Contrôleur pour le champ email
    final emailController = TextEditingController();
    // Flag pour gérer l'état de chargement
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assigner un patient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez l\'email du patient pour l\'assigner à votre liste.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email du patient',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Récupérer et valider l'email saisi
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      // Afficher l'indicateur de chargement
                      setDialogState(() => isLoading = true);
                      // Appeler le service pour assigner le patient
                      final err = await UserService().assignPatientByEmail(
                        email: email,
                        doctorUid: user.uid,
                      );
                      // Fermer le dialogue si le contexte existe toujours
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      // Afficher un message de succès ou d'erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Patient assigné avec succès !'),
                          backgroundColor: err == null
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Assigner'),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════════
// WIDGET CARTE PATIENT
// Affiche les informations d'un patient unique avec son statut et ses dernières données
// ════════════════════════════════════════════════════════════════════════════════════

/// Widget affichant une carte représentant un patient avec ses infos principales
class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.lastMeasurement,
    required this.isDark,
    required this.doctorUid,
  });

  final Map<String, dynamic> patient;
  final DateTime? lastMeasurement;
  final bool isDark;
  final String doctorUid;

  @override
  /// Construit la carte d'affichage du patient avec avatar, infos et statut
  Widget build(BuildContext context) {
    // Récupérer les informations du patient
    final uid = patient['uid'] as String? ?? '';
    final name = (patient['fullName'] as String?)?.trim() ?? 'Patient';
    final age = patient['age'];
    final gender = patient['gender'] as String? ?? '';
    // Extraire la première lettre du nom pour l'avatar
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    // StreamBuilder pour vérifier les alertes critiques en temps réel
    return StreamBuilder<QuerySnapshot>(
      // Écouter les alertes critiques non lues pour ce patient
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('patientId', isEqualTo: uid)
          .where('severity', isEqualTo: 'critical')
          .where('read', isEqualTo: false)
          .limit(1)
          .snapshots(),
      builder: (context, alertSnap) {
        // Vérifier s'il y a des alertes critiques
        final hasAlert = (alertSnap.data?.docs.isNotEmpty) == true;
        // Déterminer le statut du patient
        final status = _resolveStatus(lastMeasurement, hasAlert);

        // Conteneur cliquable pour ouvrir le profil du patient
        return GestureDetector(
          // Naviguer vers le profil détaillé du patient au tap
          onTap: () => context.push(
            RouteNames.doctorPatientProfile(Uri.encodeComponent(uid)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasAlert
                    ? AppColors.error.withValues(alpha: 0.3)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100),
              ),
              boxShadow: [
                BoxShadow(
                  color: hasAlert
                      ? AppColors.error.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ─── AVATAR CIRCULAIRE AVEC PREMIÈRE LETTRE DU NOM ───
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: status.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // ─── INFORMATIONS DU PATIENT (Nom, Age, Genre, Statut, Dernière mesure) ───
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Badge de statut coloré avec icône
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 12, color: status.color),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Afficher l'âge et le genre du patient
                      Text(
                        _buildSubtitle(age, gender),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMedium,
                        ),
                      ),
                      // Afficher la date formatée de la dernière mesure si elle existe
                      if (lastMeasurement != null)
                        Text(
                          'Dernière session : ${_formatDate(lastMeasurement!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construit la sous-titre affichant l'âge et le genre du patient
  /// Paramètres: age (âge du patient), gender (genre du patient)
  /// Retourne: String formatée avec âge et genre séparés par ' · '
  String _buildSubtitle(dynamic age, String gender) {
    // Créer une liste pour construire le sous-titre
    final parts = <String>[];
    // Ajouter l'âge s'il existe
    if (age != null) parts.add('$age ans');
    // Ajouter le genre s'il est non vide
    if (gender.isNotEmpty) parts.add(gender);
    // Joindre avec le séparateur
    return parts.join(' · ');
  }

  /// Formate une date en format relatif (Il y a X jours) ou absolu (JJ/MM/YYYY)
  /// Paramètre: dt (DateTime à formater)
  /// Retourne: String formatée en français avec expression relative ou absolue
  String _formatDate(DateTime dt) {
    // Calculer la différence avec maintenant
    final now = DateTime.now();
    final diff = now.difference(dt);
    // Moins d'une heure: afficher en minutes
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    // Moins de 24 heures: afficher en heures
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    // Hier: cas spécial pour 1 jour
    if (diff.inDays == 1) return 'Hier';
    // Moins de 7 jours: afficher en jours
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    // Plus de 7 jours: afficher la date complète au format JJ/MM/YYYY
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
