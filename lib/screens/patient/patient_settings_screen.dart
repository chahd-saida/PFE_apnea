// lib/screens/auth/patient_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:apnea_project/l10n/app_localizations.dart'; // Internationalisation (FR/EN/AR)
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/locale_provider.dart'; // Langue de l'app
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart'; // Données profil
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/auth_service.dart'; // Changement de mot de passe
import 'package:apnea_project/services/settings_service.dart'; // SharedPreferences local
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
// Chargement initial
  bool _isLoading = true;
  bool _notificationsEnabled = true; // Maître : active/désactive tout
  bool _alertNotificationsEnabled = true; // Alertes d'apnée
  bool _remindersEnabled = true; // Rappels de surveillance

// Formulaire mot de passe 
  bool _showPasswordForm = false; // Affiche/masque le formulaire
  bool _isUpdatingPassword = false; // Bloque la double-soumission
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _showCurrentPwd = false;// Bascule visibilité des 3 champs
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;
  String? _pwdError; // Message d'erreur inline sous le formulaire
// Suppression de compte
  bool _isDeletingAccount = false; // Bloque le double-clic sur "Supprimer"

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charge les préférences depuis SharedPreferences
  }

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }
//SettingsService lit depuis SharedPreferences (stockage local du téléphone).
// C'est rapide, pas besoin d'internet.
  Future<void> _loadSettings() async {
    final notif = await _settingsService.getNotificationsEnabled();
    final reminders = await _settingsService.getRemindersEnabled();
    if (!mounted) return; // Sécurité si le widget est détruit pendant l'await
    setState(() {
      _notificationsEnabled = notif;
      _alertNotificationsEnabled = notif;  // Synchronisé avec le maître
      _remindersEnabled = reminders;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
     // 1. Mise à jour locale immédiate (UX réactive)
    setState(() {
      _notificationsEnabled = value;
      _alertNotificationsEnabled = value;
      _remindersEnabled = value;
    });
      // 2. Persistance locale
    await _settingsService.setNotificationsEnabled(value);
    await _settingsService.setRemindersEnabled(value);

  // 3. Synchronisation Firestore
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        if (!value) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({
            'fcmToken': FieldValue.delete(), // Supprime le token push → plus de notifications
            'notificationsEnabled': false,
          });
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'notificationsEnabled': true});
        }
        _showSnack(
          value ? '🔔 Notifications activées' : '🔕 Notifications désactivées',
        );
      } catch (_) {}
    }
  }

  Future<void> _toggleAlertNotifications(bool value) async {
    setState(() => _alertNotificationsEnabled = value);
    await _settingsService.setNotificationsEnabled(value);
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'alertNotificationsEnabled': value});
    }
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _remindersEnabled = value);
    await _settingsService.setRemindersEnabled(value);
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'remindersEnabled': value});
    }
  }
//validation côté client en 4 étapes avant d'appeler Firebase 
  Future<void> _handlePasswordChange() async {
    if (_isUpdatingPassword) return;
    final l10n = AppLocalizations.of(context)!;

    final current = _currentPwdCtrl.text.trim();
    final newPwd  = _newPwdCtrl.text.trim();
    final confirm = _confirmPwdCtrl.text.trim();
    // Étape 1 : Vérifier que tous les champs sont remplis
    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _pwdError = l10n.passwordFillAllFieldsError);
      return;
    }
    // Étape 2 : Vérifier que les mots de passe correspondent
    if (newPwd != confirm) {
      setState(() => _pwdError = l10n.passwordConfirmationMismatchError);
      return;
    }
    // Étape 3 : Vérifier la longueur minimale
    if (newPwd.length < 8) {
      setState(() => _pwdError = l10n.passwordMinLengthError);
      return;
    }
    // Étape 4 : Vérifier la présence de lettres ET chiffres (via regex)
    if (!RegExp(r'[A-Za-z]').hasMatch(newPwd) ||
        !RegExp(r'\d').hasMatch(newPwd)) {
    // Nettoyage des champs + fermeture du formulaire
      setState(() => _pwdError = l10n.passwordLettersNumbersError);
      return;
    }

    setState(() { _isUpdatingPassword = true; _pwdError = null; });
    try {
      await _authService.changePassword(
        currentPassword: current,
        newPassword: newPwd,
      );
      if (!mounted) return;
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      setState(() { _showPasswordForm = false; _isUpdatingPassword = false; });
      _showSnack('✅ ${l10n.passwordUpdateSuccessMessage}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Mot de passe actuel incorrect.';
          break;
        default:
          msg = l10n.passwordUpdateError(e.message ?? e.code);
      }
      setState(() { _pwdError = msg; _isUpdatingPassword = false; });
    } catch (e) {
      setState(() {
        _pwdError = l10n.passwordUpdateError(e.toString());
        _isUpdatingPassword = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
      // Étape 1 : Demander confirmation avec un dialog destructif
    final confirmed = await _showDeleteDialog();
    if (!confirmed) return;

    setState(() => _isDeletingAccount = true);
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
          // Étape 2 : Supprimer le document Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
      // Étape 3 : Supprimer le compte Firebase Auth
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      // Étape 4 : Nettoyer l'état local et rediriger vers logi
      await context.read<UserProfileProvider>().clear();
      context.read<AuthProvider>().clearSession();
      context.go(RouteNames.login);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReauthDialog(); // Firebase exige une ré-authentification récente
      } else {
        _showSnack('Erreur : ${e.message}', isError: true);
      }
      if (mounted) setState(() => _isDeletingAccount = false);
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),// Icône d'avertissement
              SizedBox(width: 8),
              Text('Supprimer le compte', style: TextStyle(fontSize: 17)),
            ]),
            content: const Text(
              'Cette action est irréversible. Toutes vos données seront supprimées.\n\nÊtes-vous certain ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),// Retourne false
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),  // Retourne true
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ?? false;// Si l'utilisateur ferme sans choisir → considéré comme "Annuler"
  }
// Créer une credential avec l'email + mot de passe saisi
  void _showReauthDialog() {
    final pwdCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation requise'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Entrez votre mot de passe pour confirmer.'),
          const SizedBox(height: 12),
          TextField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = firebase_auth.FirebaseAuth.instance.currentUser;
                final cred = firebase_auth.EmailAuthProvider.credential(
                  email: user?.email ?? '',
                  password: pwdCtrl.text,
                );
                // Ré-authentifier l'utilisateur (renouvelle la session)
                await user?.reauthenticateWithCredential(cred);
                // Relancer la suppression (maintenant autorisée)
                await _deleteAccount();
              } catch (_) {
                _showSnack('Mot de passe incorrect.', isError: true);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating, // Flotte au-dessus du contenu
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    final themeProvider   = context.watch<ThemeProvider>();// Mode sombre
    final localeProvider  = context.watch<LocaleProvider>(); // Langue active
    final l10n            = AppLocalizations.of(context)!;  // Textes traduits
    final profile         = context.watch<UserProfileProvider>(); // Profil utilisateur
    final languageCode    = localeProvider.languageCode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: const PatientChatbotFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
        onTap: (i) {
          switch (i) {
            case 0: context.go(RouteNames.patientDashboard); break;
            case 1: context.go(RouteNames.patientHistory);   break;
            case 2: context.go(RouteNames.realtimeMonitoring); break;
            case 3: context.go(RouteNames.relaxation);       break;
            case 4: context.go(RouteNames.patientSettings);  break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.homeLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              label: l10n.historyLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.monitor_heart_rounded),
              label: l10n.monitoringShortLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.spa_rounded),
              label: l10n.relaxationLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: l10n.settingsShortLabel),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mon Compte ─────────────────────────────────────
                  _sectionHeader('👤 ${l10n.accountTitle}', isDark),
                  const SizedBox(height: 10),
                  _PatientAccountCard(
                      profile: profile, isDark: isDark, l10n: l10n),
                  const SizedBox(height: 24),

                  // ── Sécurité ───────────────────────────────────────
                  _sectionHeader('🔐 Sécurité', isDark),
                  const SizedBox(height: 10),
                  _buildPasswordSection(isDark, l10n),
                  const SizedBox(height: 24),

                  // ── Notifications ──────────────────────────────────
                  _sectionHeader('🔔 ${l10n.notificationsTitle}', isDark),
                  const SizedBox(height: 10),
                  _buildNotificationsSection(isDark, l10n),
                  const SizedBox(height: 24),

                  // ── Capteurs — "Guide de connexion" SUPPRIMÉ ───────
                  _sectionHeader('📡 ${l10n.sensorsTitle}', isDark),
                  const SizedBox(height: 10),
                  _buildCard(isDark, [
                    _buildNavTile(
                      icon: Icons.devices_other_rounded,
                      label: l10n.manageDevicesLabel,
                      isDark: isDark,
                      isLast: true,          // ← isLast: true (seul élément)
                      onTap: () => context.push(RouteNames.patientDevices),
                    ),
                    // "Guide de connexion" SUPPRIMÉ
                  ]),
                  const SizedBox(height: 24),

                  // ── Apparence & Langue ─────────────────────────────
                  _sectionHeader('🎨 ${l10n.appPreferencesTitle}', isDark),
                  const SizedBox(height: 10),
                  _buildCard(isDark, [
                    _buildSwitchTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      label: l10n.darkModeLabel,
                      value: themeProvider.isDarkMode,
                      onChanged: (v) =>
                          context.read<ThemeProvider>().setDarkMode(v),
                      isDark: isDark,
                      isLast: false,
                    ),
                    _buildLanguageTile(languageCode, l10n, isDark),
                  ]),
                  const SizedBox(height: 24),

                  // ── Support — "À propos" SUPPRIMÉ ──────────────────
                  _sectionHeader('ℹ️ ${l10n.infoSupportTitle}', isDark),
                  const SizedBox(height: 10),
                  _buildCard(isDark, [
                    _buildNavTile(
                      icon: Icons.help_outline_rounded,
                      label: l10n.helpFaqLabel,
                      isDark: isDark,
                      isLast: false,
                      onTap: () => context.push(RouteNames.help),
                    ),
                    _buildNavTile(
                      icon: Icons.privacy_tip_outlined,
                      label: l10n.privacyPolicyLabel,
                      isDark: isDark,
                      isLast: true,          // ← isLast: true (dernier élément)
                      onTap: () => context.push(RouteNames.privacy),
                    ),
                    // "À propos" SUPPRIMÉ
                  ]),
                  const SizedBox(height: 24),

                  // ── Déconnexion & Suppression ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.logout),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(l10n.logoutLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDeletingAccount ? null : _deleteAccount,
                      icon: _isDeletingAccount
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.delete_forever_rounded,
                              size: 18, color: Colors.red),
                      label: Text(
                        _isDeletingAccount
                            ? 'Suppression…'
                            : l10n.deleteAccountLabel,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Notifications ────────────────────────────────────────────────
  Widget _buildNotificationsSection(bool isDark, AppLocalizations l10n) {
    return _buildCard(isDark, [
      _buildSwitchTile(
        icon: _notificationsEnabled
            ? Icons.notifications_active_rounded
            : Icons.notifications_off_rounded,
        label: 'Toutes les notifications',
        subtitle: _notificationsEnabled ? 'Activées' : 'Désactivées',
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
        isDark: isDark,
        isLast: false,
        accent: true,
      ),
      AnimatedOpacity(
        opacity: _notificationsEnabled ? 1.0 : 0.4, // Grisé si désactivé
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_notificationsEnabled,  // Bloque les taps si désactivé
          child: Column(children: [
            _buildNavTile(
              icon: Icons.notifications_active_rounded,
              label: l10n.alertsCenterLabel,
              isDark: isDark,
              isLast: false,
              onTap: () =>
                  context.go(RouteNames.patientDashboard, extra: true),
              iconColor: AppColors.warning,
            ),
            _buildSwitchTile(
              icon: Icons.airline_seat_flat_rounded,
              label: l10n.apneaAlertsLabel,
              subtitle: 'Alertes d\'apnée détectées',
              value: _alertNotificationsEnabled,
              onChanged: _toggleAlertNotifications,
              isDark: isDark,
              isLast: false,
              iconColor: AppColors.error,
            ),
            _buildSwitchTile(
              icon: Icons.alarm_rounded,
              label: l10n.remindersLabel,
              subtitle: 'Rappels de surveillance',
              value: _remindersEnabled,
              onChanged: _toggleReminders,
              isDark: isDark,
              isLast: true,
              iconColor: AppColors.info,
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── Mot de passe ─────────────────────────────────────────────────
  Widget _buildPasswordSection(bool isDark, AppLocalizations l10n) {
    return Column(children: [
      _buildCard(isDark, [
        GestureDetector(
          onTap: () => setState(() {
            _showPasswordForm = !_showPasswordForm;
            _pwdError = null;
          }),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.changePasswordLabel,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const Text('Modifier votre mot de passe actuel',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                    ]),
              ),
              Icon(
                _showPasswordForm
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMedium,
              ),
            ]),
          ),
        ),
      ]),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _showPasswordForm
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCard(isDark, [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _buildPwdField(
                        ctrl: _currentPwdCtrl,
                        label: l10n.currentPasswordLabel,
                        show: _showCurrentPwd,
                        toggle: () => setState(
                            () => _showCurrentPwd = !_showCurrentPwd),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPwdField(
                        ctrl: _newPwdCtrl,
                        label: l10n.newPasswordLabel,
                        show: _showNewPwd,
                        toggle: () =>
                            setState(() => _showNewPwd = !_showNewPwd),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPwdField(
                        ctrl: _confirmPwdCtrl,
                        label: l10n.confirmNewPasswordLabel,
                        show: _showConfirmPwd,
                        toggle: () => setState(
                            () => _showConfirmPwd = !_showConfirmPwd),
                        isDark: isDark,
                      ),
                      if (_pwdError != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 14, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_pwdError!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingPassword
                              ? null
                              : _handlePasswordChange,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isUpdatingPassword
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(l10n.updateLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildPwdField({
    required TextEditingController ctrl,
    required String label,
    required bool show,
    required VoidCallback toggle,
    required bool isDark,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: !show,
      style: TextStyle(fontSize: 14,
          color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 18, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18, color: AppColors.textMedium,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _buildLanguageTile(
      String languageCode, AppLocalizations l10n, bool isDark) {
    final langs = [
      ('fr', '🇫🇷 Français'),
      ('en', '🇬🇧 English'),
      ('ar', '🇸🇦 العربية'),
    ];
    final current = langs.firstWhere((e) => e.$1 == languageCode,
        orElse: () => langs.first);

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choisir la langue',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ...langs.map((lang) => ListTile(
                  leading: Text(lang.$2.split(' ').first,
                      style: const TextStyle(fontSize: 20)),
                  title: Text(lang.$2.split(' ').last),
                  trailing: languageCode == lang.$1
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    context.read<LocaleProvider>().setLocaleCode(lang.$1);
                    Navigator.pop(ctx); // Ferme le bottom sheet
                    //setLocaleCode du LocaleProvider change la locale de toute l'application 
                    // tous les textes l10n.xxx se mettent à jour immédiatement grâce au context.watch en tête de build
                  },
                )),
              ]),
        ),
      ),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l10n.languageLabel,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600))),
          Text(current.$2,
              style: TextStyle(fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textMedium),
        ]),
      ),
    );
  }

  // ── Builders génériques ──────────────────────────────────────────
  Widget _sectionHeader(String title, bool isDark) {
    return Text(title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.textMedium));
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect( // Coupe les coins de tous les enfants
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required void Function(bool) onChanged,
    required bool isDark,
    required bool isLast, // Si false → affiche un Divider en bas
    String? subtitle,
    bool accent = false,// Si true → icône verte quand activé (interrupteur maître)
    Color? iconColor, // Couleur personnalisable de l'icône
  }) {
    final color = iconColor ?? AppColors.primary;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: (accent && value ? AppColors.success : color)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18,
                color: accent && value ? AppColors.success : color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textDark)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMedium)),
                ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent ? AppColors.success : AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
      if (!isLast)
        Divider(
          height: 1, indent: 66, // Aligné après l'icône
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
    ]);
  }
// Identique à _buildSwitchTile mais avec une flèche ">" à droite
// et un GestureDetector (onTap) au lieu d'un Switch
  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool isLast,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppColors.primary;
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textDark)),
            ),
            Icon(Icons.chevron_right_rounded, size: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium),
          ]),
        ),
      ),
      if (!isLast)
        Divider(
          height: 1, indent: 66,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// CARTE MON COMPTE PATIENT
// ─────────────────────────────────────────────────────────────
// widget extrait de la classe principale pour alléger le build affiche Avatar nom,
// email,medecin, et boutons "Modifier le profil" + "Messages" 
class _PatientAccountCard extends StatelessWidget {
  const _PatientAccountCard({
    required this.profile,
    required this.isDark,
    required this.l10n,
  });
  final UserProfileProvider profile;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.profileImageUrl;
    final name     = profile.fullName;
    final email    = profile.email;
    final doctor   = profile.doctorName;
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        // Avatar + infos
        // Avatar avec anneau bleu

        Row(children: [
          Container(
            padding: const EdgeInsets.all(2),  // Crée l'anneau visible
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE0E7FF),
              backgroundImage:
                  (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(initial,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textDark)),
                  Text(email,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMedium)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Patient',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ]),
          ),
        ]),

        // Médecin traitant
        if (doctor != null && doctor.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.medical_services_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Médecin traitant : $doctor',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // Boutons actions
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.patientProfile),
              icon: const Icon(Icons.edit_rounded, size: 15),
              label: Text(l10n.editProfileLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.patientMessages),
              icon: const Icon(Icons.chat_rounded, size: 15),
              label: const Text('Messages',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}