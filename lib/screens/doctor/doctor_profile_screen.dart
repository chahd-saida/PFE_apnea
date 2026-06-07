// ════════════════════════════════════════════════════════════════════════════════════
// ÉCRAN DE PROFIL DU MÉDECIN/DOCTEUR
// Ce fichier gère l'affichage et l'édition du profil personnel du docteur avec upload
// de photo, modification du nom, spécialité, téléphone, et photo de profil.
// ════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

// ────────────────────────────────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL - PROFIL DU DOCTEUR
// StatefulWidget affichant le profil avec possibilité d'édition des informations
// ────────────────────────────────────────────────────────────────────────────────────

/// Écran principal affichant et permettant l'édition du profil du docteur
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

/// État du screen de profil du docteur
class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  // ────────────────────────────────────────────────────────────────────────────────────
  // CONTRÔLEURS DE FORMULAIRE
  // ────────────────────────────────────────────────────────────────────────────────────
  // Contrôleur pour le champ "Nom complet"
  final _nameCtrl = TextEditingController();
  // Contrôleur pour le champ "Téléphone"
  final _phoneCtrl = TextEditingController();
  // Contrôleur pour le champ "Spécialisation"
  final _specializationCtrl = TextEditingController();
  // Contrôleur pour l'URL de la photo de profil
  final _photoCtrl = TextEditingController();

  // Flag indiquant si les champs ont été initialisés depuis le provider
  bool _initialized = false;
  // Flag indiquant si la sauvegarde est en cours
  bool _isSaving = false;
  // Flag indiquant si nous sommes en mode édition
  bool _isEditing = false;
  // Message d'erreur à afficher si la sauvegarde échoue
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Charger le profil du docteur au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProfileProvider>().refreshProfile();
    });
  }

  @override
  void dispose() {
    // Libérer les ressources des contrôleurs de texte
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specializationCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  /// Remplit les champs de texte avec les données du profil du docteur
  /// Paramètre: p (UserProfileProvider contenant les données du profil)
  void _hydrate(UserProfileProvider p) {
    // Remplir le champ nom: vide si la valeur par défaut est 'Utilisateur'
    _nameCtrl.text = p.fullName == 'Utilisateur' ? '' : p.fullName;
    // Remplir le champ téléphone: vide si la valeur par défaut est 'Non renseigné'
    _phoneCtrl.text = p.phone == 'Non renseigné' ? '' : p.phone;
    // Remplir le champ spécialisation: vide si la valeur par défaut est 'Non renseignée'
    _specializationCtrl.text = p.specialization == 'Non renseignée'
        ? ''
        : p.specialization;
    // Remplir le champ URL de photo
    _photoCtrl.text = p.profileImageUrl ?? '';
    // Marquer comme initialisé
    setState(() => _initialized = true);
  }

  /// Sauvegarde les modifications du profil du docteur sur Firestore
  /// Paramètre: p (UserProfileProvider pour la mise à jour)
  Future<void> _save(UserProfileProvider p) async {
    // Éviter les sauvegardes multiples simultanées
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      // Récupérer l'URL de la photo (vide si aucune)
      final img = _photoCtrl.text.trim();
      // Appeler la méthode de mise à jour du provider
      await p.updateProfile({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'specialization': _specializationCtrl.text.trim(),
        // Mettre null si l'URL est vide (pour supprimer la photo)
        'profileImageUrl': img.isEmpty ? null : img,
      });
      if (!mounted) return;
      // Quitter le mode édition et afficher un message de succès
      setState(() => _isEditing = false);
      _showSnack('✅ Profil mis à jour avec succès !');
    } catch (e) {
      if (!mounted) return;
      // Afficher le message d'erreur
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Affiche une notification snackbar avec un message
  /// Paramètres: msg (message à afficher), isError (true pour style erreur)
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        // Couleur verte pour succès, rouge pour erreur
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier le mode sombre/clair
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Récupérer le profil du docteur depuis le provider
    final p = context.watch<UserProfileProvider>();

    // Vérifier que l'utilisateur est un docteur (sinon afficher accès refusé)
    if (p.role != 'doctor') {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Médecin')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go(RouteNames.accessDenied),
            child: const Text('Accès refusé'),
          ),
        ),
      );
    }

    // Initialiser les champs si ce n'est pas encore fait et les données sont chargées
    if (!_initialized && p.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialized) _hydrate(p);
      });
    }

    // Récupérer les informations du profil
    final photoUrl = p.profileImageUrl;
    final email = p.email;
    // Première lettre du nom pour l'avatar (fallback: 'M' pour Médecin)
    final initial = p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF1F5F9),
      // Bouton d'action flottant pour accéder au chatbot
      floatingActionButton: const DoctorChatbotFAB(),
      // Barre de navigation inférieure avec onglets
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 4),
      // Afficher un spinner si le profil se charge, sinon afficher le contenu
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ────────────────────────────────────────────────────────────────────────────────
                // APPBAR COLLAPSIBLE AVEC PHOTO ET INFORMATIONS DE PROFIL
                // ────────────────────────────────────────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  // Bouton pour basculer entre mode édition et mode lecture
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          _errorMessage = null;
                          // Charger les données si on entre en mode édition
                          if (_isEditing) _hydrate(p);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0E3FA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // ────────────────────────────────────────────────────────────────────────────
                            // AVATAR AVEC BORDURE BLANCHE
                            // ────────────────────────────────────────────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFFE0E7FF),
                                backgroundImage:
                                    (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Afficher le nom complet du docteur
                            Text(
                              p.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ────────────────────────────────────────────────────────────────────────────
                            // BADGE DE SPÉCIALISATION
                            // ────────────────────────────────────────────────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.specialization == 'Non renseignée'
                                            ? 'Médecin'
                                            : p.specialization,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // ────────────────────────────────────────────────────────────────────────────
                        // MODE LECTURE: AFFICHER LES INFORMATIONS
                        // ────────────────────────────────────────────────────────────────────────────
                        if (!_isEditing) ...[
                          _InfoSection(
                            title: 'Informations professionnelles',
                            icon: Icons.medical_services_rounded,
                            isDark: isDark,
                            items: [
                              _InfoItem(
                                icon: Icons.badge_rounded,
                                label: 'Spécialisation',
                                value: p.specialization,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Section d'informations personnelles (email, téléphone)
                          _InfoSection(
                            title: 'Informations personnelles',
                            icon: Icons.person_rounded,
                            isDark: isDark,
                            items: [
                              _InfoItem(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: email,
                              ),
                              _InfoItem(
                                icon: Icons.phone_outlined,
                                label: 'Téléphone',
                                value: p.phone,
                              ),
                            ],
                          ),
                        ],

                        // ────────────────────────────────────────────────────────────────────────────
                        // MODE ÉDITION: FORMULAIRES MODIFIABLES
                        // ────────────────────────────────────────────────────────────────────────────
                        if (_isEditing) ...[
                          // Section 1: Informations professionnelles (Nom, Spécialisation)
                          _buildEditSection(
                            title: 'Informations professionnelles',
                            icon: Icons.medical_services_rounded,
                            isDark: isDark,
                            fields: [
                              _FieldDef(
                                ctrl: _nameCtrl,
                                label: 'Nom complet',
                                icon: Icons.person_outline_rounded,
                              ),
                              _FieldDef(
                                ctrl: _specializationCtrl,
                                label: 'Spécialisation',
                                icon: Icons.badge_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Section 2: Contact et Photo (Téléphone, URL Photo)
                          _buildEditSection(
                            title: 'Contact & Photo',
                            icon: Icons.person_rounded,
                            isDark: isDark,
                            fields: [
                              _FieldDef(
                                ctrl: _phoneCtrl,
                                label: 'Téléphone',
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                              ),
                              _FieldDef(
                                ctrl: _photoCtrl,
                                label: 'Photo de profil (URL)',
                                icon: Icons.image_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ────────────────────────────────────────────────────────────────────────────
                          // EMAIL EN LECTURE SEULE (avec icône cadenas)
                          // ────────────────────────────────────────────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppColors.textMedium,
                                ),
                                const SizedBox(width: 10),
                                // Afficher l'email (non modifiable)
                                Text(
                                  'Email : $email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ────────────────────────────────────────────────────────────────────────────
                          // AFFICHAGE DES MESSAGES D'ERREUR
                          // ────────────────────────────────────────────────────────────────────────────
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ────────────────────────────────────────────────────────────────────────────
                          // BOUTONS D'ACTION (Annuler / Sauvegarder)
                          // ────────────────────────────────────────────────────────────────────────────
                          Row(
                            children: [
                              // Bouton Annuler (retour au mode lecture)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => setState(() {
                                          _isEditing = false;
                                          _errorMessage = null;
                                        }),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textMedium,
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Annuler',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Bouton Sauvegarder (enregistrer les modifications)
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : () => _save(p),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.primary
                                        .withValues(alpha: 0.5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  // Afficher un spinner si la sauvegarde est en cours
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    _isSaving
                                        ? 'Enregistrement…'
                                        : 'Sauvegarder',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Construit une section éditable avec champs de texte
  /// Paramètres: title (titre de la section), icon (icône), isDark (thème sombre),
  /// fields (liste des champs à afficher)
  Widget _buildEditSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<_FieldDef> fields,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section avec titre et ligne de séparation
        _sectionHeader(title, icon, isDark),
        const SizedBox(height: 10),
        // Conteneur avec tous les champs empilés
        Container(
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
            children: fields.asMap().entries.map((e) {
              final idx = e.key;
              final f = e.value;
              return Column(
                children: [
                  // Construire chaque champ de saisie
                  _buildField(f, isDark),
                  // Ajouter un séparateur entre les champs (sauf le dernier)
                  if (idx < fields.length - 1)
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Construit un champ de saisie de texte
  /// Paramètres: f (définition du champ), isDark (thème sombre)
  Widget _buildField(_FieldDef f, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      // Champ de texte avec label et icône de préfixe
      child: TextFormField(
        controller: f.ctrl,
        keyboardType: f.keyboard,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
        decoration: InputDecoration(
          labelText: f.label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
          ),
          prefixIcon: Icon(f.icon, size: 18, color: AppColors.primary),
          // Aucune bordure pour une apparence plus épurée
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Construit l'en-tête d'une section avec icône, titre et ligne de séparation
  /// Paramètres: title (titre), icon (icône), isDark (thème sombre)
  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        // Icône de la section
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        // Titre de la section
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 10),
        // Ligne de séparation extensible
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════════
// WIDGET DE SECTION D'INFORMATIONS (MODE LECTURE)
// Affiche les informations du profil sous forme de cartes en mode consultation
// ════════════════════════════════════════════════════════════════════════════════════

/// Widget affichant une section d'informations avec plusieurs éléments
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.items,
  });
  // Titre de la section
  final String title;
  // Icône à afficher avec le titre
  final IconData icon;
  // Thème sombre activé?
  final bool isDark;
  // Liste des éléments d'information à afficher
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la section avec titre et ligne de séparation
        Row(
          children: [
            // Icône de la section
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            // Titre de la section
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            // Ligne de séparation
            Expanded(
              child: Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Conteneur avec les éléments de la section
        Container(
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
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Column(
                children: [
                  // Afficher chaque élément d'information
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Icône de l'élément
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 17,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Label et valeur de l'élément
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label (ex: "Email", "Téléphone")
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Valeur de l'élément
                              Text(
                                item.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  // Gris clair si "Non renseigné", sinon couleur normale
                                  color:
                                      item.value == 'Non renseigné' ||
                                          item.value == 'Non renseignée'
                                      ? (isDark
                                            ? Colors.white38
                                            : Colors.grey.shade400)
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Séparateur entre les éléments (sauf le dernier)
                  if (idx < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 66,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════════
// MODÈLES INTERNES
// Structures de données pour les éléments d'information et les champs de saisie
// ════════════════════════════════════════════════════════════════════════════════════

/// Classe représentant un élément d'information à afficher (label, icône, valeur)
class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  // Icône à afficher
  final IconData icon;
  // Label ou libellé de l'information
  final String label;
  // Valeur de l'information
  final String value;
}

/// Classe représentant un champ de saisie avec son contrôleur et ses propriétés
class _FieldDef {
  const _FieldDef({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard,
  });
  // Contrôleur de texte pour ce champ
  final TextEditingController ctrl;
  // Label du champ
  final String label;
  // Icône de préfixe
  final IconData icon;
  // Type de clavier (par défaut: texte normal)
  final TextInputType? keyboard;
}
