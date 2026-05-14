import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  String? _selectedGender;
  bool _acceptCGU = false;
  bool _acceptMedicalConsent = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  // Étape courante du stepper
  int _currentStep = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptCGU || !_acceptMedicalConsent) {
      _showSnack(l10n.acceptTermsConsentRequiredMessage);
      return;
    }
    if (_selectedRole == null) {
      _showSnack(l10n.roleRequiredError);
      return;
    }
    if (_selectedGender == null) {
      _showSnack(l10n.genderRequiredMessage);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final error = await auth.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
      );

      if (!mounted) return;

      if (error != null) {
        _showSnack(error);
        return;
      }

      final role = auth.role;
      if (role == 'doctor') {
        context.go(RouteNames.doctorDashboard);
      } else if (role == 'patient') {
        context.go(RouteNames.patientDashboard);
      } else {
        context.go(RouteNames.fixProfile);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ── Validation par étape ──────────────────────────────────────────────────

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _selectedRole != null;
      case 1:
        return _fullNameController.text.trim().isNotEmpty &&
            _dobController.text.trim().isNotEmpty &&
            _selectedGender != null &&
            _phoneController.text.trim().isNotEmpty;

      case 2:
        return _emailController.text.trim().isNotEmpty &&
            _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) {
      _showSnack('Veuillez remplir tous les champs obligatoires.');
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _register();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  int get _totalSteps => _selectedRole == 'doctor' ? 4 : 4;

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(title: Text(l10n.registerTitle), centerTitle: true),
      body: Column(
        children: [
          // ── Barre de progression ────────────────────────────────────
          _buildProgressBar(isDark),

          // ── Contenu ─────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStep(l10n, isDark),
                  ),
                ),
              ),
            ),
          ),

          // ── Navigation ──────────────────────────────────────────────
          _buildNavigation(l10n, isDark),
        ],
      ),
    );
  }

  // ── Barre de progression ──────────────────────────────────────────────────

  Widget _buildProgressBar(bool isDark) {
    final labels = ['Rôle', 'Profil', 'Pro', 'Compte'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceLight,
          ),
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _currentStep;
          final current = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: (done || current)
                              ? AppColors.primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.surfaceLight),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: current
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: current
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _totalSteps - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Étapes ────────────────────────────────────────────────────────────────

  Widget _buildStep(AppLocalizations l10n, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _stepRole(l10n, isDark);
      case 1:
        return _stepProfile(l10n, isDark);
      case 2:
        return _stepAccount(l10n, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Étape 0 : Rôle ────────────────────────────────────────────────────────

  Widget _stepRole(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Vous êtes…',
          'Sélectionnez votre rôle pour personnaliser votre expérience.',
          isDark,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _roleCard(
                value: 'patient',
                label: l10n.rolePatient,
                icon: Icons.person_outline_rounded,
                desc: 'Suivre mes données de santé',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _roleCard(
                value: 'doctor',
                label: l10n.roleDoctor,
                icon: Icons.medical_services_outlined,
                desc: 'Gérer et surveiller mes patients',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _roleCard({
    required String value,
    required String label,
    required IconData icon,
    required String desc,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.surfaceLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMedium),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Étape 1 : Profil ──────────────────────────────────────────────────────

  Widget _stepProfile(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Informations personnelles',
          'Ces informations servent à identifier votre profil.',
          isDark,
        ),
        const SizedBox(height: 24),

        _buildField(
          controller: _fullNameController,
          label: l10n.fullNameLabel,
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          validator: (v) =>
              (v == null || v.isEmpty) ? l10n.fullNameRequiredError : null,
        ),
        const SizedBox(height: 14),

        // Date de naissance
        TextFormField(
          controller: _dobController,
          readOnly: true,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
          decoration: _inputDeco(
            l10n.dateOfBirthLabel,
            Icons.calendar_today_outlined,
            isDark,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? l10n.dateOfBirthRequiredError : null,
          onTap: () async {
            FocusScope.of(context).unfocus();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _dobController.text = picked.toIso8601String().split('T')[0];
              });
            }
          },
        ),
        const SizedBox(height: 14),

        // Genre
        _buildGenderSelector(l10n, isDark),
        const SizedBox(height: 14),

        _buildField(
          controller: _phoneController,
          label: l10n.phoneLabel,
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboard: TextInputType.phone,
          validator: (v) =>
              (v == null || v.isEmpty) ? l10n.phoneRequiredError : null,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGenderSelector(AppLocalizations l10n, bool isDark) {
    final genders = [
      ('H', l10n.genderMaleShort, Icons.male_rounded),
      ('F', l10n.genderFemaleShort, Icons.female_rounded),
      ('Autre', l10n.genderOther, Icons.transgender_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.genderLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textBody,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: genders.map((g) {
            final selected = _selectedGender == g.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: g.$1 != 'Autre' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.surfaceLight),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        g.$3,
                        size: 20,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMedium),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        g.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMedium),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Étape 3 : Compte ──────────────────────────────────────────────────────

  Widget _stepAccount(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Créer votre compte',
          'Ces identifiants vous permettront de vous connecter.',
          isDark,
        ),
        const SizedBox(height: 24),

        _buildField(
          controller: _emailController,
          label: l10n.emailLabel,
          icon: Icons.email_outlined,
          isDark: isDark,
          keyboard: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return l10n.emailRequiredError;
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
              return l10n.emailInvalidError;
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Mot de passe
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
          decoration: _inputDeco(
            l10n.passwordLabel,
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
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return l10n.passwordRequiredError;
            if (v.length < 6) return l10n.passwordMin6Error;
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Confirmation
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmVisible,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
          ),
          decoration: _inputDeco(
            l10n.confirmPasswordLabel,
            Icons.lock_reset_outlined,
            isDark,
            suffix: IconButton(
              icon: Icon(
                _isConfirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textMedium,
              ),
              onPressed: () =>
                  setState(() => _isConfirmVisible = !_isConfirmVisible),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty)
              return l10n.confirmPasswordRequiredError;
            if (v != _passwordController.text)
              return l10n.passwordsDontMatchError;
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Checkboxes consentements
        _buildCheckTile(
          label: l10n.acceptTermsLabel,
          value: _acceptCGU,
          isDark: isDark,
          onChanged: (v) => setState(() => _acceptCGU = v ?? false),
        ),
        const SizedBox(height: 8),
        _buildCheckTile(
          label: l10n.acceptMedicalConsentLabel,
          value: _acceptMedicalConsent,
          isDark: isDark,
          onChanged: (v) => setState(() => _acceptMedicalConsent = v ?? false),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Navigation bas de page ────────────────────────────────────────────────

  Widget _buildNavigation(AppLocalizations l10n, bool isDark) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton retour
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Retour',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Bouton suivant / créer
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
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
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep ? l10n.signUpButton : 'Continuer',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isLastStep
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
            height: 1.5,
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

  Widget _buildCheckTile({
    required String label,
    required bool value,
    required bool isDark,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withValues(alpha: 0.06)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.surfaceLight),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? AppColors.primary
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.textLight),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textBody,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
