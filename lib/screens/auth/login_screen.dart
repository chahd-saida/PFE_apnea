import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User, UserCredential;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService    = FirebaseService();

  String? _selectedRole;
  bool    _isLoading         = false;
  bool    _isPasswordVisible = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // Couleurs du design
  static const _bg      = Color(0xFFF5F0EB);
  static const _teal    = Color(0xFF3D8B85);
  static const _tealDk  = Color(0xFF2E6B66);
  static const _textDk  = Color(0xFF1A1A2E);
  static const _textMd  = Color(0xFF6B7280);
  static const _border  = Color(0xFFE5DDD5);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final UserCredential cred = await _firebaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final User? user = cred.user;
      if (user == null) throw StateError(l10n.loginErrorGeneric);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.fetchRole(user.uid);
      if (!mounted) return;
      final role = auth.role;
      if (role != 'doctor' && role != 'patient') {
        context.go(RouteNames.fixProfile); return;
      }
      if (_selectedRole != null && _selectedRole != role) {
        await _firebaseService.signOut();
        auth.clearSession();
        throw StateError(l10n.roleMismatchError(
            role == 'doctor' ? l10n.roleDoctor : l10n.rolePatient));
      }
      context.go(role == 'doctor'
          ? RouteNames.doctorDashboard
          : RouteNames.patientDashboard);
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnack(_mapAuthError(AppLocalizations.of(context)!, e));
    } on StateError catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context)!.unexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  String _mapAuthError(AppLocalizations l10n, FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':          return l10n.loginUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':      return l10n.loginWrongCredentials;
      case 'invalid-email':           return l10n.loginInvalidEmail;
      case 'operation-not-allowed':
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND': return l10n.firebaseAuthNotConfigured;
      default:                        return e.message ?? l10n.loginErrorGeneric;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // ── Fond décoratif ──────────────────────────────────────────
        Positioned.fill(child: _buildBackground()),

        // ── Contenu ─────────────────────────────────────────────────
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 60),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          // Sélecteur langue
                          _buildLangSwitcher(l10n),
                          const SizedBox(height: 24),
                          // Logo
                          _buildLogo(),
                          const SizedBox(height: 32),
                          // Slogan
                          _buildSlogan(),
                          const SizedBox(height: 32),
                          // Toggle rôle
                          _buildRoleToggle(l10n),
                          const SizedBox(height: 24),
                          // Email
                          _buildField(
                            controller: _emailController,
                            hint: 'Adresse e-mail',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.emailRequiredError;
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                                return l10n.emailInvalidError;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Mot de passe
                          _buildField(
                            controller: _passwordController,
                            hint: 'Mot de passe',
                            icon: Icons.lock_outline_rounded,
                            obscure: !_isPasswordVisible,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                              child: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _textMd, size: 18,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.passwordRequiredError;
                              if (v.length < 6) return l10n.passwordMin6Error;
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          // Bouton connexion
                          _buildConnectButton(l10n),
                          const SizedBox(height: 20),
                          // Liens bas
                          _buildFooter(l10n),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Fond décoratif (vagues + cercles) ─────────────────────────────────────
  Widget _buildBackground() {
    return CustomPaint(painter: _BgPainter());
  }

  // ── Sélecteur langue ──────────────────────────────────────────────────────
  Widget _buildLangSwitcher(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _langBtn('FR', true),
          _langBtn('EN', false),
          _langBtn('AR', false),
        ]),
      ),
    );
  }

  Widget _langBtn(String code, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: active ? _teal : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(code,
      style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: active ? Colors.white : _textMd,
      )),
  );

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_teal, _tealDk],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _teal.withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.monitor_heart_rounded,
          color: Colors.white, size: 38,
        ),
      ),
    );
  }

  // ── Slogan ────────────────────────────────────────────────────────────────
  Widget _buildSlogan() {
    return const Text(
      'Respirez.\nNous veillons.',
      style: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w900,
        color: _textDk, height: 1.15,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.left,
    );
  }

  // ── Toggle rôle Patient / Médecin ─────────────────────────────────────────
  Widget _buildRoleToggle(AppLocalizations l10n) {
    return FormField<String>(
      validator: (_) => _selectedRole == null ? l10n.roleRequiredError : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              Expanded(child: _toggleOption(
                state: state,
                value: 'patient',
                label: l10n.rolePatient,
              )),
              Expanded(child: _toggleOption(
                state: state,
                value: 'doctor',
                label: l10n.roleDoctor,
              )),
            ]),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required FormFieldState<String> state,
    required String value,
    required String label,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = value);
        state.didChange(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? _teal : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _textMd,
          ),
        ),
      ),
    );
  }

  // ── Champ texte ───────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(hint,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: _textMd,
            )),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14, color: _textDk, fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint == 'Adresse e-mail'
                ? 'claire.dupont@mail.com'
                : '••••••••',
            hintStyle: TextStyle(color: _textMd.withValues(alpha: 0.5), fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(icon, color: _textMd, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _teal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // ── Bouton Se connecter ───────────────────────────────────────────────────
  Widget _buildConnectButton(AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _isLoading ? _teal.withValues(alpha: 0.7) : _teal,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _teal.withValues(alpha: 0.4),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    l10n.loginButton,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16,
                    ),
                  ),
                ]),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.push(RouteNames.forgotPassword),
          style: TextButton.styleFrom(foregroundColor: _textMd),
          child: Text(l10n.forgotPasswordButton,
              style: const TextStyle(fontSize: 13)),
        ),
        Container(width: 4, height: 4,
          decoration: const BoxDecoration(
            color: _textMd, shape: BoxShape.circle)),
        TextButton(
          onPressed: () => context.push(RouteNames.register),
          style: TextButton.styleFrom(foregroundColor: _teal),
          child: Text(l10n.signUpButton,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Painter fond décoratif ────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintCircle = Paint()
      ..color = const Color(0xFF3D8B85).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Cercles décoratifs
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), 80, paintCircle);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), 120, paintCircle);

    // Vague en bas
    final wavePaint = Paint()
      ..color = const Color(0xFF3D8B85).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.88);
    wavePath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.82,
      size.width * 0.5,  size.height * 0.88,
    );
    wavePath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.94,
      size.width,        size.height * 0.88,
    );
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // Deuxième vague
    final wave2 = Paint()
      ..color = const Color(0xFF3D8B85).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final wavePath2 = Path();
    wavePath2.moveTo(0, size.height * 0.93);
    wavePath2.quadraticBezierTo(
      size.width * 0.3, size.height * 0.87,
      size.width * 0.6, size.height * 0.93,
    );
    wavePath2.quadraticBezierTo(
      size.width * 0.8, size.height * 0.97,
      size.width,       size.height * 0.93,
    );
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();
    canvas.drawPath(wavePath2, wave2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}