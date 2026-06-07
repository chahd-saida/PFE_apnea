// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {

  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  bool  _emailLoading = false;
  bool  _emailSent    = false;

  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGIQUE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _sendPasswordResetEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _emailLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? l10n.resetLinkSendError);
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  // ── Helpers snackbar ──────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.login),
        ),
        title: Text(
          l10n.forgotPasswordTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A365D),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _emailSent
                ? _buildSuccess(l10n, isDark)
                : _buildForm(l10n, isDark),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FORMULAIRE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildForm(AppLocalizations l10n, bool isDark) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 24),

          // Titre
          Text(
            l10n.forgotPasswordTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 10),

          // Sous-titre
          Text(
            l10n.forgotPasswordInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white54 : AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 36),

          // Champ email
          _buildEmailField(l10n, isDark),
          const SizedBox(height: 24),

          // Bouton envoyer
          _buildSendButton(l10n),
          const SizedBox(height: 18),

          // Retour connexion
          _buildBackToLoginBtn(l10n, isDark),
        ],
      ),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n, bool isDark) {
    final fillColor   = isDark ? const Color(0xFF161D2E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.surfaceLight;

    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        hintText: 'exemple@email.com',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.email_outlined,
              size: 20, color: AppColors.textMedium),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textMedium),
        hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white24 : AppColors.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return l10n.emailRequiredError;
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
          return l10n.emailInvalidError;
        return null;
      },
    );
  }

  Widget _buildSendButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _emailLoading ? null : _sendPasswordResetEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: _emailLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.sendResetLinkButton),
                ],
              ),
      ),
    );
  }

  Widget _buildBackToLoginBtn(AppLocalizations l10n, bool isDark) {
    return TextButton.icon(
      onPressed: () => context.go(RouteNames.login),
      icon: const Icon(Icons.arrow_back_rounded,
          size: 16, color: AppColors.primary),
      label: Text(
        l10n.backToLoginButton,
        style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÉCRAN SUCCÈS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSuccess(AppLocalizations l10n, bool isDark) {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Icône succès animée
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                  width: 2),
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                size: 44, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 24),

        // Titre
        Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 12),

        // Email affiché
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            _emailCtrl.text.trim(),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          'Un lien de réinitialisation a été envoyé à cette adresse.\n'
          'Consultez aussi vos spams.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: isDark ? Colors.white54 : AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 36),

        // Bouton retour connexion
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.login),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Retour à la connexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Renvoyer avec autre adresse
        TextButton.icon(
          onPressed: () => setState(() {
            _emailSent = false;
            _emailCtrl.clear();
          }),
          icon: const Icon(Icons.refresh_rounded,
              size: 16, color: AppColors.textMedium),
          label: Text(
            'Utiliser une autre adresse',
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium),
          ),
        ),
      ],
    );
  }
}