import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/settings_service.dart';

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
  String _language = 'fr';

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
    final language = await _settingsService.getLanguage();
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _remindersEnabled = remindersEnabled;
      _language = language;
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

  String? _validatePassword(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(trimmed);
    final hasNumber = RegExp(r'\d').hasMatch(trimmed);
    if (!hasLetter || !hasNumber) {
      return 'Le mot de passe doit contenir des lettres et des chiffres.';
    }
    return null;
  }

  Future<void> _handlePasswordChange() async {
    if (_isUpdatingPassword) {
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _passwordError = 'Veuillez remplir tous les champs.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError = 'La confirmation ne correspond pas au mot de passe.';
      });
      return;
    }

    final validationError = _validatePassword(newPassword);
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
        const SnackBar(content: Text('Mot de passe mis à jour avec succès.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUpdatingPassword = false;
        _passwordError = 'Erreur lors de la mise à jour: $e';
      });
    }
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
                    '👤 Mon Compte',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Modifier profil'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.patientProfile);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock),
                          title: const Text('Changer mot de passe'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            setState(() {
                              _showPasswordForm = !_showPasswordForm;
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.fingerprint),
                          title: const Text('Connexion biométrique'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Connexion biométrique bientôt disponible.',
                                ),
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
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _passwordError!,
                          style: TextStyle(color: Colors.red.shade700),
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
                              decoration: const InputDecoration(
                                labelText: 'Mot de passe actuel',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Nouveau mot de passe',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirmer le nouveau mot de passe',
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
                                      ? 'Mise à jour...'
                                      : 'Mettre à jour',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Text(
                    '🔔 Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: const Text('Centre d\'alertes'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.patientAlerts);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Alertes apnée'),
                          value: _notificationsEnabled,
                          onChanged: (bool value) {
                            _onNotificationsChanged(value);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Rappels'),
                          value: _remindersEnabled,
                          onChanged: (bool value) {
                            _onRemindersChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '🔌 Capteurs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.devices_other),
                          title: const Text('Gérer appareils'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.patientDevices);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Guide de connexion'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push(RouteNames.help);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Surveil.',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Détente'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
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
