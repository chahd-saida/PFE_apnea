import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User, UserCredential;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/theme/app_dimensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedRole;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _firebaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw StateError(l10n.loginErrorGeneric);
      }

      if (!mounted) {
        return;
      }
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchRole(user.uid);

      if (!mounted) {
        return;
      }

      final resolvedRole = authProvider.role;
      if (resolvedRole != 'doctor' && resolvedRole != 'patient') {
        context.go(RouteNames.fixProfile);
        return;
      }

      if (_selectedRole != null && _selectedRole != resolvedRole) {
        await _firebaseService.signOut();
        authProvider.clearSession();

        final resolvedRoleLabel = resolvedRole == 'doctor'
            ? l10n.roleDoctor
            : l10n.rolePatient;
        throw StateError(
          l10n.roleMismatchError(resolvedRoleLabel),
        );
      }

      if (resolvedRole == 'doctor') {
        context.go(RouteNames.doctorDashboard);
      } else {
        context.go(RouteNames.patientDashboard);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      final message = _mapAuthError(AppLocalizations.of(context)!, e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on StateError catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unexpectedError)),
      );
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
      case 'user-not-found':
        return l10n.loginUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.loginWrongCredentials;
      case 'invalid-email':
        return l10n.loginInvalidEmail;
      case 'operation-not-allowed':
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND':
        return l10n.firebaseAuthNotConfigured;
      default:
        return e.message ?? l10n.loginErrorGeneric;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_hospital, size: 80, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),
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
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      tooltip: _isPasswordVisible
                          ? l10n.hidePasswordTooltip
                          : l10n.showPasswordTooltip,
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
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
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: Text(l10n.loginButton),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.biometricSoonMessage)),
                    );
                  },
                  child: Text(l10n.biometricLoginLabel),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        context.push(RouteNames.register);
                      },
                      child: Text(l10n.signUpButton),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(RouteNames.forgotPassword);
                      },
                      child: Text(l10n.forgotPasswordButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
