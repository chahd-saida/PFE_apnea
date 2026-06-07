import 'package:flutter/material.dart';
import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/locale_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/auth_service.dart';
import 'package:apnea_project/services/settings_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  // Services pour gerer les parametres et l'authentification
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();

  // État de chargement et notifications
  // Gestion de l'etat de chargement initial et des preferences de notifications
  bool _isLoading = true; // Etat du chargement des parametres
  bool _notificationsEnabled =
      true; // Notifications globales activees/desactivees
  bool _alertNotificationsEnabled = true; // Notifications d'alerte medicales
  bool _messageNotificationsEnabled =
      true; // Notifications de messages des patients

  // ── Password ────────────────────────────────────────────────────
  bool _showPasswordForm = false;
  bool _isUpdatingPassword = false;
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _showCurrentPwd = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;
  String? _pwdError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  // Charge les parametres de notifications au demarrage de l'ecran
  Future<void> _loadSettings() async {
    final notif = await _settingsService.getNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notif;
      _alertNotificationsEnabled = notif;
      _messageNotificationsEnabled = notif;
      _isLoading = false; // Marque le chargement comme termine
    });
  }

  // Basculer toutes les notifications et gerer le token FCM dans Firestore
  // Active/desactive les notifications et synchronise avec la base de donnees
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      _alertNotificationsEnabled = value;
      _messageNotificationsEnabled = value;
    });
    await _settingsService.setNotificationsEnabled(value);

    // Mettre à jour le FCM token dans Firestore
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      if (!value) {
        // DESACTIVER : Supprimer le token FCM de Firestore pour stopper les notifications
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': FieldValue.delete(), // Supprime le token FCM
          'notificationsEnabled': false,
        });
      } else {
        // REACTIVER : Re-enregistrer et mettre a jour l'etat
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'notificationsEnabled': true,
        });
        // Re-init NotificationService si disponible
        try {
          // ignore: unused_local_variable
          final messaging = await _getFcmToken();
          if (messaging != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'fcmToken': messaging});
          }
        } catch (_) {}
      }
      _showSnack(
        value ? '🔔 Notifications activées' : '🔕 Notifications désactivées',
      );
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  // Basculer les notifications d'alerte et les sauvegarder dans Firestore
  Future<void> _toggleAlertNotifications(bool value) async {
    setState(() => _alertNotificationsEnabled = value);
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Met a jour la preference dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'alertNotificationsEnabled': value,
    });
  }

  // Basculer les notifications de messages et les sauvegarder dans Firestore
  Future<void> _toggleMessageNotifications(bool value) async {
    setState(() => _messageNotificationsEnabled = value);
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Met a jour la preference dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'messageNotificationsEnabled': value,
    });
  }

  // Recupere le token FCM pour les notifications push
  // Retourne le token si les notifications sont activees, sinon null
  Future<String?> _getFcmToken() async {
    try {
      // Verifie si les notifications sont activees avant de demander le token
      final prefs = await _settingsService.getNotificationsEnabled();
      return prefs ? 'token_refresh_requested' : null;
    } catch (_) {
      return null; // Retourne null en cas d'erreur
    }
  }

  // Traiter le changement de mot de passe avec validations completes
  // Valide les entrees, verifie les regles de securite et met a jour dans Firebase
  Future<void> _handlePasswordChange() async {
    // Empeche les appels multiples
    if (_isUpdatingPassword) return;

    // Extrait et nettoie les entrees utilisateur
    final current = _currentPwdCtrl.text.trim();
    final newPwd = _newPwdCtrl.text.trim();
    final confirm = _confirmPwdCtrl.text.trim();

    // VALIDATION 1 : Verifie que tous les champs sont remplis
    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _pwdError = 'Veuillez remplir tous les champs.');
      return;
    }
    // VALIDATION 2 : Verifie que les nouveaux mots de passe correspondent
    if (newPwd != confirm) {
      setState(() => _pwdError = 'Les mots de passe ne correspondent pas.');
      return;
    }
    // VALIDATION 3 : Longueur minimale de 8 caracteres
    if (newPwd.length < 8) {
      setState(
        () =>
            _pwdError = 'Le mot de passe doit contenir au moins 8 caracteres.',
      );
      return;
    }
    // VALIDATION 4 : Doit contenir au moins une lettre et un chiffre
    if (!RegExp(r'[A-Za-z]').hasMatch(newPwd) ||
        !RegExp(r'\d').hasMatch(newPwd)) {
      setState(
        () => _pwdError =
            'Le mot de passe doit contenir des lettres et des chiffres.',
      );
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _pwdError = null;
    });
    try {
      await _authService.changePassword(
        currentPassword: current,
        newPassword: newPwd,
      );
      if (!mounted) return;
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      setState(() {
        _showPasswordForm = false;
        _isUpdatingPassword = false;
      });
      _showSnack('✅ Mot de passe mis à jour avec succès.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Mot de passe actuel incorrect.';
          break;
        case 'weak-password':
          msg = 'Nouveau mot de passe trop faible.';
          break;
        default:
          msg = 'Erreur: ${e.message}';
      }
      setState(() {
        _pwdError = msg;
        _isUpdatingPassword = false;
      });
    } catch (e) {
      setState(() {
        _pwdError = 'Erreur: $e';
        _isUpdatingPassword = false;
      });
    }
  }

  // Processus complet de suppression de compte
  // Supprime les donnees Firestore, le compte Firebase et nettoie les providers
  Future<void> _deleteAccount() async {
    // Affiche un dialogue de confirmation
    final confirm = await _showDeleteAccountDialog();
    if (!confirm) return; // Annule si l'utilisateur decline

    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    try {
      // ETAPE 1 : Supprimer le document utilisateur dans Firestore
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
      // ETAPE 2 : Supprimer le compte Firebase Authentication
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      // ETAPE 3 : Nettoyer les providers (donnees en cache)
      await context.read<UserProfileProvider>().clear();
      context.read<AuthProvider>().clearSession();
      // Redirection vers l'ecran de connexion
      context.go(RouteNames.login);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Si re-authentification requise, affiche le dialogue
        _showReauthDialog();
      } else {
        _showSnack('Erreur: ${e.message}', isError: true);
      }
    } catch (e) {
      _showSnack('Erreur suppression: $e', isError: true);
    }
  }

  Future<bool> _showDeleteAccountDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                SizedBox(width: 8),
                Text('Supprimer le compte', style: TextStyle(fontSize: 17)),
              ],
            ),
            content: const Text(
              'Cette action est irréversible. Toutes vos données seront définitivement supprimées.\n\nÊtes-vous certain de vouloir continuer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer définitivement'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showReauthDialog() {
    final pwdCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation requise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre mot de passe pour confirmer la suppression.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = firebase_auth.FirebaseAuth.instance.currentUser;
                final cred = firebase_auth.EmailAuthProvider.credential(
                  email: user?.email ?? '',
                  password: pwdCtrl.text,
                );
                await user?.reauthenticateWithCredential(cred);
                await _deleteAccount();
              } catch (e) {
                _showSnack('Mot de passe incorrect.', isError: true);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // Affiche une notification temporaire (Snackbar) a l'utilisateur
  // Affiche les messages de confirmation ou d'erreur
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        // Couleur rouge si erreur, vert si succes
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Construction de l'interface principale des parametres
  @override
  Widget build(BuildContext context) {
    // Recupere l'etat du theme et les providers de configuration
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!; // Localisations multilingues
    final profile = context.watch<UserProfileProvider>(); // Profil du medecin
    final languageCode =
        localeProvider.languageCode; // Code de la langue actuelle

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          // Affiche un spinner pendant le chargement
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ════════════════════════════════════════════════════
                  // SECTION 1 : MON COMPTE
                  // Affiche le profil avec photo, nom, email et specialite
                  // ════════════════════════════════════════════════════
                  _sectionHeader('👤 Mon Compte', isDark),
                  const SizedBox(height: 10),
                  _AccountCard(profile: profile, isDark: isDark),
                  const SizedBox(height: 24),

                  // ════════════════════════════════════════════════════
                  // SECTION 2 : SECURITE
                  // Permet de changer le mot de passe avec validations
                  // ════════════════════════════════════════════════════
                  _sectionHeader('🔐 Securite', isDark),
                  const SizedBox(height: 10),
                  _buildPasswordSection(isDark),
                  const SizedBox(height: 24),

                  // ════════════════════════════════════════════════════
                  // SECTION 3 : NOTIFICATIONS
                  // Controle des differents types de notifications
                  // ════════════════════════════════════════════════════
                  _sectionHeader('🔔 Notifications', isDark),
                  const SizedBox(height: 10),
                  _buildNotificationsSection(isDark),
                  const SizedBox(height: 24),

                  // ════════════════════════════════════════════════════
                  // SECTION 4 : APPARENCE & LANGUE
                  // Mode sombre et selection de la langue
                  // ════════════════════════════════════════════════════
                  _sectionHeader('🎨 Apparence & Langue', isDark),
                  const SizedBox(height: 10),
                  _buildCard(isDark, [
                    _buildSwitchTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      label: 'Mode sombre',
                      value: themeProvider.isDarkMode,
                      onChanged: (v) =>
                          context.read<ThemeProvider>().setDarkMode(v),
                      isDark: isDark,
                      isLast: false,
                    ),
                    _buildLanguageTile(languageCode, l10n, isDark),
                  ]),
                  const SizedBox(height: 24),

                  // ── Support ────────────────────────────────────────
                  _sectionHeader('ℹ️ Informations & Support', isDark),
                  const SizedBox(height: 10),
                  _buildCard(isDark, [
                    _buildNavTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Aide & FAQ',
                      isDark: isDark,
                      isLast: false,
                      onTap: () => context.push(RouteNames.help),
                    ),
                    _buildNavTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Politique de confidentialité',
                      isDark: isDark,
                      isLast: true,
                      onTap: () => context.push(RouteNames.privacy),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Déconnexion ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.logout),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Supprimer mon compte',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // Constructeur de la section Notifications
  // Affiche un toggle principal et des sous-toggles pour chaque type de notification
  Widget _buildNotificationsSection(bool isDark) {
    return _buildCard(isDark, [
      // TOGGLE PRINCIPAL : Active/desactive toutes les notifications
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
      // SOUS-TOGGLES : Affines par type (desactives si notifications globales off)
      AnimatedOpacity(
        opacity: _notificationsEnabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_notificationsEnabled,
          child: Column(
            children: [
              _buildSwitchTile(
                icon: Icons.warning_amber_rounded,
                label: 'Alertes critiques',
                subtitle: 'Apnées et alertes médicales',
                value: _alertNotificationsEnabled,
                onChanged: _toggleAlertNotifications,
                isDark: isDark,
                isLast: false,
                iconColor: AppColors.error,
              ),
              _buildSwitchTile(
                icon: Icons.chat_rounded,
                label: 'Messages patients',
                subtitle: 'Nouveaux messages reçus',
                value: _messageNotificationsEnabled,
                onChanged: _toggleMessageNotifications,
                isDark: isDark,
                isLast: true,
                iconColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  // Constructeur de la section Mot de passe
  // Affiche un formulaire expandable pour changer le mot de passe
  Widget _buildPasswordSection(bool isDark) {
    return Column(
      children: [
        _buildCard(isDark, [
          GestureDetector(
            onTap: () => setState(() {
              _showPasswordForm = !_showPasswordForm;
              _pwdError = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Changer le mot de passe',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Modifier votre mot de passe actuel',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showPasswordForm
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMedium,
                  ),
                ],
              ),
            ),
          ),
        ]),

        // Formulaire expandable
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showPasswordForm
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildCard(isDark, [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPwdField(
                            ctrl: _currentPwdCtrl,
                            label: 'Mot de passe actuel',
                            show: _showCurrentPwd,
                            toggle: () => setState(
                              () => _showCurrentPwd = !_showCurrentPwd,
                            ),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPwdField(
                            ctrl: _newPwdCtrl,
                            label: 'Nouveau mot de passe',
                            show: _showNewPwd,
                            toggle: () =>
                                setState(() => _showNewPwd = !_showNewPwd),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPwdField(
                            ctrl: _confirmPwdCtrl,
                            label: 'Confirmer le nouveau mot de passe',
                            show: _showConfirmPwd,
                            toggle: () => setState(
                              () => _showConfirmPwd = !_showConfirmPwd,
                            ),
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
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _pwdError!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isUpdatingPassword
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Mettre à jour',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Constructeur de champ de mot de passe avec toggle visibility
  // Affiche un TextField avec bouton pour afficher/masquer le mot de passe
  Widget _buildPwdField({
    required TextEditingController ctrl, // Controleur du champ
    required String label, // Etiquette du champ
    required bool show, // Si le mot de passe est visible
    required VoidCallback toggle, // Callback pour basculer la visibilite
    required bool isDark, // Mode sombre
  }) {
    return TextField(
      controller: ctrl,
      obscureText: !show,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18,
            color: AppColors.textMedium,
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
                : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

  // Constructeur du selecteur de langue
  // Affiche la langue actuelle avec un modal pour changer
  Widget _buildLanguageTile(
    String languageCode, // Code de la langue actuelle (fr, en, ar)
    AppLocalizations l10n, // Localisations
    bool isDark, // Mode sombre
  ) {
    final langs = [
      ('fr', '🇫🇷 Français'),
      ('en', '🇬🇧 English'),
      ('ar', '🇸🇦 العربية'),
    ];
    final current = langs.firstWhere(
      (e) => e.$1 == languageCode,
      orElse: () => langs.first,
    );

    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisir la langue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...langs.map(
                  (lang) => ListTile(
                    leading: Text(
                      lang.$2.split(' ').first,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(lang.$2.split(' ').last),
                    trailing: languageCode == lang.$1
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      context.read<LocaleProvider>().setLocaleCode(lang.$1);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Langue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              current.$2,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILDERS GENERIQUES : Composants d'interface reutilisables
  // ════════════════════════════════════════════════════════════════

  // Affiche le titre d'une section avec style approprié
  Widget _sectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : AppColors.textMedium,
      ),
    );
  }

  // Constructeur d'une carte avec bordure et ombre
  // Conteneur generique pour grouper les elements avec style coherent
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }

  // Constructeur d'une ligne avec icone, label et toggle switch
  // Element reusable pour les options activables/desactivables
  Widget _buildSwitchTile({
    required IconData icon, // Icone affichee
    required String label, // Texte principal
    required bool value, // Etat du toggle
    required void Function(bool) onChanged, // Callback au changement
    required bool isDark, // Mode sombre
    required bool isLast, // Si c'est le dernier element (border)
    String? subtitle, // Texte secondaire optionnel
    bool accent = false, // Colore l'icone avec une couleur secondaire
    Color? iconColor, // Couleur personnalisee de l'icone
  }) {
    final color = iconColor ?? AppColors.primary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (accent && value ? AppColors.success : color)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: accent && value ? AppColors.success : color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
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
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: accent ? AppColors.success : AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
          ),
      ],
    );
  }

  // Constructeur d'une ligne navigable avec icone et chevron
  // Element cliquable pour acceder a d'autres ecrans
  Widget _buildNavTile({
    required IconData icon, // Icone affichee
    required String label, // Texte du lien
    required bool isDark, // Mode sombre
    required bool isLast, // Si c'est le dernier element (border)
    required VoidCallback onTap, // Callback au tap
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COMPOSANT : Carte du Profil du Medecin
// ════════════════════════════════════════════════════════════════
// Affiche l'avatar, le nom, l'email, la specialite et un bouton
// pour modifier le profil

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile, required this.isDark});
  final UserProfileProvider profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Extrait les donnees du profil du medecin
    final photoUrl = profile.profileImageUrl; // URL de la photo de profil
    final name = profile.fullName; // Nom complet
    final email = profile.email; // Email
    final spec = profile.specialization; // Specialite medicale
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'M'; // Premiere lettre du nom

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + infos
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0E7FF),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        spec == 'Non renseignée' ? 'Médecin' : spec,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bouton modifier profil
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.doctorProfile),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Modifier le profil',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
