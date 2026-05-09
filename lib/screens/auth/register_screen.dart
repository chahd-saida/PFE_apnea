import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_dimensions.dart';

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
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptCGU || !_acceptMedicalConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.acceptTermsConsentRequiredMessage)),
      );
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.roleRequiredError)),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genderRequiredMessage)),
      );
      return;
    }

    if (_selectedRole == 'doctor') {
      if (_specializationController.text.trim().isEmpty ||
          _medicalLicenseController.text.trim().isEmpty ||
          _yearsOfExperienceController.text.trim().isEmpty ||
          _clinicNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.doctorProfessionalInfoRequiredMessage)),
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
      final message = _mapAuthError(AppLocalizations.of(context)!, e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final message = e.code == 'permission-denied'
          ? l10n.firestoreWriteDenied
          : (e.message ?? l10n.registerDatabaseError);
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

  String _mapAuthError(AppLocalizations l10n, FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return l10n.registerEmailAlreadyInUse;
      case 'invalid-email':
        return l10n.loginInvalidEmail;
      case 'weak-password':
        return l10n.registerWeakPassword;
      case 'operation-not-allowed':
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND':
        return l10n.firebaseAuthNotConfigured;
      default:
        return e.message ?? l10n.registerErrorGeneric;
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
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
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
                      return l10n.roleRequiredError;
                    }
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.roleLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                fieldState: state,
                                value: 'patient',
                                label: l10n.rolePatient,
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                fieldState: state,
                                value: 'doctor',
                                label: l10n.roleDoctor,
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
                  decoration: InputDecoration(
                    labelText: l10n.fullNameLabel,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fullNameRequiredError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: l10n.dateOfBirthLabel,
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.dateOfBirthRequiredError;
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
                      Text(l10n.genderLabel),
                      const Radio<String>(value: 'H'),
                      Text(l10n.genderMaleShort),
                      const Radio<String>(value: 'F'),
                      Text(l10n.genderFemaleShort),
                      const Radio<String>(value: 'Autre'),
                      Text(l10n.genderOther),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailRequiredError;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return l10n.emailInvalidError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.phoneRequiredError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _profileImageUrlController,
                  decoration: InputDecoration(
                    labelText: l10n.profilePhotoUrlOptionalLabel,
                    prefixIcon: const Icon(Icons.image_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null ||
                        !uri.hasScheme ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return l10n.urlInvalidError;
                    }
                    return null;
                  },
                ),
                if (_selectedRole == 'doctor') ...[
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _specializationController,
                    decoration: InputDecoration(
                      labelText: l10n.specializationLabel,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l10n.specializationRequiredError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _medicalLicenseController,
                    decoration: InputDecoration(
                      labelText: l10n.medicalLicenseNumberLabel,
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l10n.medicalLicenseNumberRequiredError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _yearsOfExperienceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.yearsOfExperienceLabel,
                      prefixIcon: const Icon(Icons.timeline_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l10n.yearsOfExperienceRequiredError;
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return l10n.numberInvalidError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: InputDecoration(
                      labelText: l10n.clinicHospitalLabel,
                      prefixIcon: const Icon(Icons.local_hospital_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole != 'doctor') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l10n.clinicHospitalRequiredError;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequiredError;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMin6Error;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.confirmPasswordRequiredError;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordsDontMatchError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                CheckboxListTile(
                  title: Text(l10n.acceptTermsLabel),
                  value: _acceptCGU,
                  onChanged: (bool? value) {
                    setState(() {
                      _acceptCGU = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text(l10n.acceptMedicalConsentLabel),
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
                        child: Text(l10n.signUpButton),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.go(RouteNames.login);
                  },
                  child: Text(l10n.alreadyHaveAccountLoginButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
