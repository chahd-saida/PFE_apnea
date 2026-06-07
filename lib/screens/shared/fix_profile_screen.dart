import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/auth_service.dart';
import 'package:apnea_project/theme/app_colors.dart';

class FixProfileScreen extends StatefulWidget {
  const FixProfileScreen({super.key});

  @override
  State<FixProfileScreen> createState() => _FixProfileScreenState();
}

class _FixProfileScreenState extends State<FixProfileScreen> {
  bool _isLoggingOut = false;
  bool _isRetrying   = false;

  // ── Réessayer de charger le profil ──────────────────────────────
  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      final auth = context.read<AuthProvider>();
      final profile = context.read<UserProfileProvider>();

      // Recharger le profil depuis Firestore
      await profile.refreshProfile();

      if (!mounted) return;

      // Vérifier si le rôle est maintenant disponible
      final role = auth.role ?? profile.role;
      if (role == 'doctor') {
        context.go(RouteNames.doctorDashboard);
      } else if (role == 'patient') {
        context.go(RouteNames.patientDashboard);
      } else {
        // Toujours pas de rôle — rester sur cet écran
        _showSnack('Profil toujours introuvable. Veuillez vous reconnecter.');
      }
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  // ── Se déconnecter proprement ───────────────────────────────────
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService().signOut();
      if (!mounted) return;
      await context.read<UserProfileProvider>().clear();
      context.read<AuthProvider>().clearSession();
      context.go(RouteNames.login);
    } catch (e) {
      _showSnack('Erreur de déconnexion : $e', isError: true);
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration ────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      size: 40,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Titre ───────────────────────────────────────────
              Text(
                'Profil Incomplet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Description ─────────────────────────────────────
              Text(
                'Votre profil est incomplet ou votre rôle est introuvable. Réessayez ou reconnectez-vous.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Causes possibles ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _causeItem('Connexion internet instable', Icons.wifi_off_rounded, isDark),
                    const SizedBox(height: 10),
                    _causeItem('Compte non encore activé', Icons.hourglass_empty_rounded, isDark),
                    const SizedBox(height: 10),
                    _causeItem('Rôle non assigné au compte', Icons.badge_rounded, isDark),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Bouton Réessayer ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isRetrying || _isLoggingOut) ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _isRetrying ? 'Chargement…' : 'Réessayer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Bouton Se reconnecter ────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isRetrying || _isLoggingOut) ? null : _logout,
                  icon: _isLoggingOut
                      ? SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white54 : AppColors.textMedium,
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 16),
                  label: Text(
                    _isLoggingOut ? 'Déconnexion…' : 'Se reconnecter',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.textMedium,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _causeItem(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
            ),
          ),
        ),
      ],
    );
  }
}