import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  // 4 contrôleurs pour les champs éditables
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _genderController = TextEditingController();

  bool _initialized = false;// Empêche la réinitialisation des champs à chaque rebuild
  bool _isSaving = false; // Bloque le double-appui sur "Sauvegarder"
  String? _errorMessage;  // Affiche une erreur inline si la sauvegarde échoue

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProfileProvider>().refreshProfile();
    });
  }

  @override
  //Les 4 contrôleurs doivent être libérés explicitement quand le widget est détruit.
  // Sans dispose, ils continuent d'occuper de la mémoire — une fuite mémoire classique en Flutter
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    super.dispose();
  }
// transfère les données du provider vers les contrôleurs UI.
  void _hydrateFromProfile(UserProfileProvider userProfile) {
    final user = userProfile.user; // Map<String, dynamic> depuis Firestore
    _fullNameController.text = userProfile.fullName;
    _phoneController.text = userProfile.phone;
    _dateOfBirthController.text = _formatDate(user?['dateOfBirth']);
    _genderController.text = (user?['gender'] as String?)?.trim() ?? '';
    setState(() => _initialized = true);  // Verrouille l'initialisation
  }

  String _formatDate(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  Future<void> _handleSave(UserProfileProvider userProfile) async {
    if (_isSaving) return; // Évite les doubles soumissions
    setState(() {
      _isSaving = true;
      _errorMessage = null; // Réinitialise l'erreur précédente
    });

    try {
      await userProfile.updateProfile({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'gender': _genderController.text.trim(),
        // 'doctorUid' est intentionnellement absent : assigné uniquement par le médecin
        //sécurité explicite : seul le médecin peut assigner un patient à son compte
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          backgroundColor: AppColors.success, // Vert = succès
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur : $e');  // Affiche erreur inline
    } finally {
      if (mounted) setState(() => _isSaving = false); // Réactive le bouton
    }
  }
//context.watch abonne le widget aux changements du UserProfileProvider. Dès qu'une donnée du profil change 
// (ex: après refreshProfile()), le widget se reconstruit.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = context.watch<UserProfileProvider>();
//attend que les données soient disponibles avant d'alimenter les champs
    if (!_initialized && userProfile.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //Le double-check !_initialized évite une réinitialisation si la méthode est
        // déclenchée deux fois dans la même frame.
        if (!_initialized) _hydrateFromProfile(userProfile);
      });
    }

    final doctorName =
        (userProfile.user?['doctorName'] as String?)?.trim() ??
        (userProfile.user?['doctorUid'] != null
            ? 'Médecin assigné'
            : 'Non assigné');

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil'), centerTitle: true),
      floatingActionButton: const PatientChatbotFAB(),
      body: userProfile.isLoading
          ? const Center(child: CircularProgressIndicator()) // Chargement Firestore en cours
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo + nom + badge "Patient"
                  _buildAvatarSection(userProfile, isDark),
                  const SizedBox(height: 28),

                  // Médecin assigné (lecture seule)
                  _buildDoctorCard(doctorName, isDark),
                  const SizedBox(height: 24),

                  // Informations personnelles 
                  _sectionTitle('Informations personnelles', isDark),
                  const SizedBox(height: 12),

                  // Champ éditable
                  _buildField(
                    controller: _fullNameController,
                    label: 'Nom complet',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Champ éditable
                  _buildField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // Champ éditable
                  _buildField(
                    controller: _dateOfBirthController,
                    label: 'Date de naissance',
                    icon: Icons.calendar_today_outlined,
                    isDark: isDark,
                    readOnly: true,
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1990),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateOfBirthController.text = picked
                              .toIso8601String()
                              .split('T')[0];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Champ éditable
                  _buildField(
                    controller: _genderController,
                    label: 'Genre',
                    icon: Icons.wc_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Email lecture seule(non modifiable)
                  _buildReadOnly(
                    value: userProfile.email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),

                  if (_errorMessage != null) ...[ // Bannière d'erreur conditionnelle
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

                  const SizedBox(height: 28),

                  // ── Bouton sauvegarder ───────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _handleSave(userProfile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.5,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _isSaving ? 'Enregistrement...' : 'Sauvegarder',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _buildAvatarSection(UserProfileProvider userProfile, bool isDark) {
    final photoUrl = userProfile.profileImageUrl;
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)  // Photo depuis l'URL du profil
              : null, // Sinon → icône par défaut
          child: (photoUrl == null || photoUrl.isEmpty)
              ? const Icon(
                  Icons.person_rounded,
                  size: 44,
                  color: AppColors.primary,
                )
              : null,// child ignoré si backgroundImage est défini
        ),
        const SizedBox(height: 12),
        Text(
          userProfile.fullName.isEmpty ? 'Patient' : userProfile.fullName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.spo2Bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Patient',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.spo2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Carte médecin assigné (lecture seule, non modifiable) ─────────────────
  Widget _buildDoctorCard(String doctorName, bool isDark) {
    final hasDoctor = doctorName != 'Non assigné';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Couleurs différentes selon l'état 
        color: hasDoctor
            ? AppColors.primary.withValues(alpha: 0.05) // Bleu léger = assigné
            : (isDark ? AppColors.darkSurface : Colors.white), // Neutre = non assigné
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(
          color: hasDoctor
              ? AppColors.primary.withValues(alpha: 0.2)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasDoctor
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 20,
              color: hasDoctor ? AppColors.primary : AppColors.textMedium,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Médecin traitant',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasDoctor
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textDark)
                        : AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          // Icône cadenas = non modifiable
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textLight,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
        ),
        const SizedBox(width: 10),
        // Ligne qui remplit l'espace restant
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboard, // null = clavier par défaut
    bool readOnly = false, // true = affichage seul sans modification
    VoidCallback? onTap,       // Pour le DatePicker de la date de naissance
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,  // Empêche la saisie manuelle
      keyboardType: keyboard,
      onTap: onTap,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
      ),
      decoration: _inputDeco(label, icon, isDark),
    );
  }

  Widget _buildReadOnly({
    required String value,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
      ),
      decoration: _inputDeco(label, icon, isDark),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.surfaceLight;
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: AppColors.textMedium, size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surfaceLight,
        ),
      ),
    );
  }
}
