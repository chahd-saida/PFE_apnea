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
import 'package:apnea_project/widgets/doctor_chatbot_fab.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled = await _settingsService
        .getNotificationsEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _isLoading = false;
    });
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
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.homeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: l10n.patientsLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_active),
            label: l10n.alertsLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsShortLabel,
          ),
        ],
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.doctorDashboard);
              break;
            case 1:
              context.go(RouteNames.doctorPatients);
              break;
            case 2:
              context.go(RouteNames.doctorAlerts);
              break;
            case 3:
              context.go(RouteNames.doctorSettings);
              break;
          }
        },
      ),
    );
  }
}
