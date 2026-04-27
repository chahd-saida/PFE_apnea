import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/settings_service.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String _language = 'fr';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final language = await _settingsService.getLanguage();
    final notificationsEnabled = await _settingsService
        .getNotificationsEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _language = language;
      _notificationsEnabled = notificationsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _onDarkModeChanged(bool value) async {
    await context.read<ThemeProvider>().setDarkMode(value);
  }

  Future<void> _onLanguageChanged(String code) async {
    await _settingsService.setLanguage(code);
    if (!mounted) {
      return;
    }
    setState(() {
      _language = code;
    });
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

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Préférences de l\'application',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Langue'),
                          subtitle: Text(
                            _language == 'fr' ? 'Français' : _language,
                          ),
                          trailing: DropdownButton<String>(
                            value: _language,
                            items: const [
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text('Français'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
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
                          title: const Text('Mode sombre'),
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            _onDarkModeChanged(value);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Notifications'),
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
                  const Text(
                    'ℹ️ Informations et Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Aide et FAQ'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.help);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Politique de confidentialité'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.privacy);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('À propos'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Page À propos en préparation.'),
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
                          label: const Text('Déconnexion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Supprimer compte'),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alertes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
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
