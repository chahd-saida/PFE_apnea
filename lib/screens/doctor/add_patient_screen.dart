import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/models/patient.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/patient_provider.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dateNaissance;
  String? _sexe;
  bool _isPasswordVisible = false;
  bool _isSaving = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day))
      age--;
    return age;
  }

  void _onFormChanged() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final finalValid = formValid && _dateNaissance != null && _sexe != null;
    if (finalValid != _isFormValid) setState(() => _isFormValid = finalValid);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
      _onFormChanged();
    }
  }

  void _showSnack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _savePatient() async {
    FocusScope.of(context).unfocus();
    _onFormChanged();

    if (!_isFormValid || _dateNaissance == null || _sexe == null) {
      _showSnack('Veuillez corriger les champs invalides.');
      return;
    }

    // ✅ Lire doctorUid MAINTENANT de façon synchrone
    // avant tout appel async pour éviter de perdre le contexte
    final doctorUid = context.read<AuthProvider>().user?.uid;
    if (doctorUid == null) {
      _showSnack('Session expirée. Reconnectez-vous.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final patientProvider = context.read<PatientProvider>();

      final patient = Patient(
        id: 'temp', // sera remplacé par l'uid Auth réel
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        age: _computeAge(_dateNaissance!),
        sexe: _sexe!,
        dateNaissance: _dateNaissance,
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        email: _emailController.text.trim(),
        notesMedicales: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        doctorUid: doctorUid, // ✅ déjà dans le modèle
      );

      // ✅ doctorUid passé EXPLICITEMENT en plus du patient
      // → garanti dans FirebaseService même après des appels async
      final uid = await patientProvider.createPatientAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        doctorUid: doctorUid, // ← clé de la correction
        patient: patient,
      );

      if (!mounted) return;

      if (uid != null) {
        _showSnack(
          'Patient créé.\n'
          'Email : ${_emailController.text.trim()}\n'
          'Communiquez ces identifiants au patient.',
          error: false,
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).pop();
      } else {
        _showSnack(patientProvider.error ?? 'Échec de création du compte.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageText = _dateNaissance == null
        ? '—'
        : '${_computeAge(_dateNaissance!)} ans';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un patient'),
        centerTitle: true,
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _onFormChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Identité ─────────────────────────────────────────────
              _sectionTitle('Identité', Icons.person_outline_rounded, isDark),
              const SizedBox(height: 12),

              _buildField(
                controller: _nomController,
                label: 'Nom *',
                icon: Icons.badge_outlined,
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nom est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _prenomController,
                label: 'Prénom *',
                icon: Icons.person_outline,
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Prénom est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),

              // Date de naissance
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDeco(
                    'Date de naissance *',
                    Icons.calendar_month_outlined,
                    isDark,
                  ),
                  child: Text(
                    _dateNaissance == null
                        ? 'Sélectionner une date'
                        : '${_dateNaissance!.day.toString().padLeft(2, '0')}/'
                              '${_dateNaissance!.month.toString().padLeft(2, '0')}/'
                              '${_dateNaissance!.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateNaissance == null
                          ? (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textLight)
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Âge calculé (lecture seule)
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: ageText),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                ),
                decoration: _inputDeco('Âge', Icons.cake_outlined, isDark),
              ),
              const SizedBox(height: 12),

              // Sexe
              DropdownButtonFormField<String>(
                value: _sexe,
                decoration: _inputDeco('Sexe *', Icons.wc_outlined, isDark),
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textDark,
                ),
                items: const [
                  DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) {
                  setState(() => _sexe = v);
                  _onFormChanged();
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Sexe est obligatoire.' : null,
              ),
              const SizedBox(height: 24),

              // ── Contact ──────────────────────────────────────────────
              _sectionTitle('Contact', Icons.contact_phone_outlined, isDark),
              const SizedBox(height: 12),

              _buildField(
                controller: _telephoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                isDark: isDark,
                keyboard: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^[0-9+\s()-]{8,20}$').hasMatch(v.trim()))
                    return 'Numéro invalide.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Compte patient ───────────────────────────────────────
              _sectionTitle(
                'Compte patient',
                Icons.account_circle_outlined,
                isDark,
              ),
              const SizedBox(height: 4),
              _buildInfoBanner(isDark),
              const SizedBox(height: 12),

              _buildField(
                controller: _emailController,
                label: 'Email du patient *',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Email est obligatoire.';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                    return 'Format email invalide.';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Mot de passe avec toggle visibilité
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textDark,
                ),
                decoration: _inputDeco(
                  'Mot de passe temporaire *',
                  Icons.lock_outline_rounded,
                  isDark,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Mot de passe est obligatoire.';
                  if (v.length < 6) return 'Minimum 6 caractères.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Notes médicales ──────────────────────────────────────
              _sectionTitle('Notes médicales', Icons.notes_outlined, isDark),
              const SizedBox(height: 12),

              _buildField(
                controller: _notesController,
                label: 'Notes',
                icon: Icons.notes_outlined,
                isDark: isDark,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // ── Bouton enregistrer ───────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || !_isFormValid) ? null : _savePatient,
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
                      : const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(
                    _isSaving
                        ? 'Création du compte...'
                        : 'Créer le compte patient',
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
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le patient pourra se connecter avec cet email '
              'et ce mot de passe temporaire. '
              'Communiquez-lui ces identifiants.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
        ),
        const SizedBox(width: 10),
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
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
      ),
      decoration: _inputDeco(
        label,
        icon,
        isDark,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  InputDecoration _inputDeco(
    String label,
    IconData icon,
    bool isDark, {
    bool alignLabelWithHint = false,
    Widget? suffix,
  }) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.surfaceLight;

    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: AppColors.textMedium, size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 6), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
