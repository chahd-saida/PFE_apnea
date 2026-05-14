import 'package:flutter/material.dart';
import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/locale_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/settings_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  bool _isLoading = true;
  bool _showPasswordForm = false;
  bool _isUpdatingPassword = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled = await _settingsService
        .getNotificationsEnabled();
    final remindersEnabled = await _settingsService.getRemindersEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _remindersEnabled = remindersEnabled;
      _isLoading = false;
    });
  }

  Future<void> _onNotificationsChanged(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _settingsService.setNotificationsEnabled(value);
  }

  Future<void> _onRemindersChanged(bool value) async {
    setState(() {
      _remindersEnabled = value;
    });
    await _settingsService.setRemindersEnabled(value);
  }

  Future<void> _onDarkModeChanged(bool value) async {
    await context.read<ThemeProvider>().setDarkMode(value);
  }

  Future<void> _onLanguageChanged(String code) async {
    await context.read<LocaleProvider>().setLocaleCode(code);
  }

  Future<void> _logout() async {
    context.push(RouteNames.logout);
  }

  Future<void> _deleteAccount() async {
    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      return;
    }
    await user.delete();
    if (!mounted) {
      return;
    }
    context.go(RouteNames.login);
  }

  String? _validatePassword(AppLocalizations l10n, String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return l10n.passwordMinLengthError;
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(trimmed);
    final hasNumber = RegExp(r'\d').hasMatch(trimmed);
    if (!hasLetter || !hasNumber) {
      return l10n.passwordLettersNumbersError;
    }
    return null;
  }

  Future<void> _handlePasswordChange() async {
    if (_isUpdatingPassword) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _passwordError = l10n.passwordFillAllFieldsError;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError = l10n.passwordConfirmationMismatchError;
      });
      return;
    }

    final validationError = _validatePassword(l10n, newPassword);
    if (validationError != null) {
      setState(() {
        _passwordError = validationError;
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
    });

    try {
      await _firebaseService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingPassword = false;
        _showPasswordForm = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordUpdateSuccessMessage)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUpdatingPassword = false;
        _passwordError = l10n.passwordUpdateError(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final languageCode = localeProvider.languageCode;
    final languageName = switch (languageCode) {
      'en' => l10n.languageEnglish,
      'ar' => l10n.languageArabic,
      _ => l10n.languageFrench,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(l10n.editProfileLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.patientProfile);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock),
                          title: Text(l10n.changePasswordLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            setState(() {
                              _showPasswordForm = !_showPasswordForm;
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.fingerprint),
                          title: Text(l10n.biometricLoginLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.biometricSoonMessage),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_showPasswordForm) ...[
                    const SizedBox(height: 16),
                    if (_passwordError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _passwordError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: l10n.currentPasswordLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: l10n.newPasswordLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: l10n.confirmNewPasswordLabel,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUpdatingPassword
                                    ? null
                                    : _handlePasswordChange,
                                child: Text(
                                  _isUpdatingPassword
                                      ? l10n.updatingLabel
                                      : l10n.updateLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Text(
                    l10n.notificationsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(l10n.alertsCenterLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.go(
                              RouteNames.patientDashboard,
                              extra: true,
                            );
                          },
                        ),
                        SwitchListTile(
                          title: Text(l10n.apneaAlertsLabel),
                          value: _notificationsEnabled,
                          onChanged: (bool value) {
                            _onNotificationsChanged(value);
                          },
                        ),
                        SwitchListTile(
                          title: Text(l10n.remindersLabel),
                          value: _remindersEnabled,
                          onChanged: (bool value) {
                            _onRemindersChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.sensorsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.devices_other),
                          title: Text(l10n.manageDevicesLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.patientDevices);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(l10n.connectionGuideLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.help);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.appPreferencesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(l10n.languageLabel),
                          subtitle: Text(languageName),
                          trailing: DropdownButton<String>(
                            value: languageCode,
                            items: [
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text(l10n.languageFrench),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(l10n.languageEnglish),
                              ),
                              DropdownMenuItem(
                                value: 'ar',
                                child: Text(l10n.languageArabic),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              _onLanguageChanged(value);
                            },
                          ),
                        ),
                        SwitchListTile(
                          title: Text(l10n.darkModeLabel),
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            _onDarkModeChanged(value);
                          },
                        ),
                        SwitchListTile(
                          title: Text(l10n.notificationsLabel),
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            await _settingsService.setNotificationsEnabled(
                              value,
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.infoSupportTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(l10n.helpFaqLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.help);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: Text(l10n.privacyPolicyLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.privacy);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.aboutLabel),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.aboutInProgressMessage),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.logoutLabel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: Text(l10n.deleteAccountLabel),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      floatingActionButton: const PatientChatbotFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.homeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l10n.historyLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monitor_heart),
            label: l10n.monitoringShortLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.spa),
            label: l10n.relaxationLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsShortLabel,
          ),
        ],
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.patientDashboard);
              break;
            case 1:
              context.go(RouteNames.patientHistory);
              break;
            case 2:
              context.go(RouteNames.realtimeMonitoring);
              break;
            case 3:
              context.go(RouteNames.relaxation);
              break;
            case 4:
              context.go(RouteNames.patientSettings);
              break;
          }
        },
      ),
    );
  }
}
