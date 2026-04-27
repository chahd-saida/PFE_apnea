import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _profileImageUrlController =
      TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _medicalLicenseController =
      TextEditingController();
  final TextEditingController _yearsOfExperienceController =
      TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedRole; // 'patient' | 'doctor'
  String? _selectedGender; // 'H', 'F', 'Autre'
  bool _acceptCGU = false;
  bool _acceptMedicalConsent = false;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptCGU || !_acceptMedicalConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez accepter les CGU et le consentement médical pour continuer.',
          ),
        ),
      );
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un rôle.')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre sexe.')),
      );
      return;
    }

    if (_selectedRole == 'doctor') {
      if (_specializationController.text.trim().isEmpty ||
          _medicalLicenseController.text.trim().isEmpty ||
          _yearsOfExperienceController.text.trim().isEmpty ||
          _clinicNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez compléter les informations professionnelles du médecin.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // Register user and ensure Firestore write completes
      await _firebaseService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        profileImageUrl: _profileImageUrlController.text.trim(),
        specialization: _selectedRole == 'doctor'
            ? _specializationController.text.trim()
            : null,
        medicalLicenseNumber: _selectedRole == 'doctor'
            ? _medicalLicenseController.text.trim()
            : null,
        yearsOfExperience: _selectedRole == 'doctor'
            ? _yearsOfExperienceController.text.trim()
            : null,
        clinicName: _selectedRole == 'doctor'
            ? _clinicNameController.text.trim()
            : null,
      );

      // Auto-login after registration
      final loginCred = await _firebaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Fetch the user role from Firestore to ensure it's up-to-date
      final user = loginCred.user;
      String? role;
      if (user != null) {
        // Try up to 5 times with a short delay in case of propagation lag
        for (int i = 0; i < 5; i++) {
          role = await _firebaseService.getUserRole(user.uid);
          if (role == 'doctor' || role == 'patient') {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (!mounted) {
        return;
      }

      // Redirect based on actual role from Firestore
      if (role == 'doctor') {
        context.go(RouteNames.doctorDashboard);
      } else if (role == 'patient') {
        context.go(RouteNames.patientDashboard);
      } else {
        context.go(RouteNames.fixProfile);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      final message = _mapAuthError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.code == 'permission-denied'
          ? 'Écriture refusée par Firestore. Vérifiez les règles de sécurité.'
          : (e.message ?? 'Erreur base de données lors de l\'inscription.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères).';
      case 'operation-not-allowed':
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase Auth n\'est pas configuré (active Email/Mot de passe dans Firebase Console > Authentication > Sign-in method).';
      default:
        return e.message ?? 'Erreur d\'inscription.';
    }
  }

  Widget _buildRoleCard({
    required FormFieldState<String> fieldState,
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
        fieldState.didChange(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _profileImageUrlController.dispose();
    _specializationController.dispose();
    _medicalLicenseController.dispose();
    _yearsOfExperienceController.dispose();
    _clinicNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Création de compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FormField<String>(
                  validator: (_) {
                    if (_selectedRole == null) {
                      return 'Veuillez sélectionner un rôle';
                    }
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rôle :',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                fieldState: state,
                                value: 'patient',
                                label: 'Patient',
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                fieldState: state,
                                value: 'doctor',
                                label: 'Médecin',
                                icon: Icons.local_hospital,
                              ),
                            ),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom complet';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance (AAAA-MM-JJ)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre date de naissance';
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dobController.text = pickedDate
                            .toIso8601String()
                            .split('T')[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),

                RadioGroup<String>(
                  groupValue: _selectedGender,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  child: Row(
                    children: [
                      const Text('Sexe: '),
                      const Radio<String>(value: 'H'),
                      const Text('H'),
                      const Radio<String>(value: 'F'),
                      const Text('F'),
                      const Radio<String>(value: 'Autre'),
                      const Text('Autre'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _profileImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Photo de profil (URL) - optionnel',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null ||
                        !uri.hasScheme ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return 'Veuillez entrer une URL valide (http/https)';
                    }
                    return null;
                  },
                ),
                if (_selectedRole == 'doctor') ...[
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _specializationController,
                    decoration: const InputDecoration(
                      labelText: 'Spécialisation',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la spécialisation';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _medicalLicenseController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de licence médicale',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer le numéro de licence';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _yearsOfExperienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Années d\'expérience',
                      prefixIcon: Icon(Icons.timeline_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer les années d\'expérience';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: const InputDecoration(
                      labelText: 'Clinique / Hôpital',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la clinique ou l\'hôpital';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                CheckboxListTile(
                  title: const Text('J\'accepte les CGU'),
                  value: _acceptCGU,
                  onChanged: (bool? value) {
                    setState(() {
                      _acceptCGU = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Consentement médical'),
                  value: _acceptMedicalConsent,
                  onChanged: (bool? value) {
                    setState(() {
                      _acceptMedicalConsent = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.go(RouteNames.login);
                  },
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
