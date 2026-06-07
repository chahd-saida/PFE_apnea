// lib/screens/patient/dashboard_patient_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/alert_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/theme/app_dimensions.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

const _teal = Color(0xFF4DBDB8);
const _navy = Color(0xFF1E3A8A);
const _navyLight = Color(0xFF3B82F6);
const _cardDark = Color(0xFF161D2E);
const _bgDark = Color(0xFF0A0E1A);

class DashboardPatientScreen extends StatefulWidget {
  const DashboardPatientScreen({super.key});
  @override
  State<DashboardPatientScreen> createState() => _DashboardPatientScreenState();
}

class _DashboardPatientScreenState extends State<DashboardPatientScreen>
    with TickerProviderStateMixin {
  // ── Contrôleurs d'animation pour les transitions visuelles ──────────────
  late final AnimationController
  _fadeCtrl; // Contrôle l'animation de fondu (fade)
  late final AnimationController
  _slideCtrl; // Contrôle l'animation de glissement
  late final AnimationController
  _pulseCtrl; // Crée l'effet de pulsation du badge "Live"

  // ── Services et état du dashboad ──────────────────────────────────────
  final AlertService _alertService = AlertService();
  bool _hasShownAlertsFromRoute =
      false; // Évite l'affichage répété des alertes au démarrage
  bool _isMonitoring = false; // Indique si le monitrage est actif
  bool _showLastSession = false; // Affiche la barre de dernière session

  @override
  void initState() {
    super.initState();
    // ── Initialisation des contrôleurs d'animation ────────────────────────
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    // Lance l'animation de glissement avec un léger délai pour créer un effet cascade
    Future.delayed(
      const Duration(milliseconds: 150),
      () => _slideCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Retourne le salut approprié en fonction de l'heure de la journée ──
  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning; // Avant midi
    if (h < 18) return l10n.greetingAfternoon; // Après-midi
    return l10n.greetingEvening; // Soir
  }

  // ── Retourne le libellé du score (Excellent, Moyen, Mauvais) ──────────
  String _scoreLabel(AppLocalizations l10n, int s) {
    if (s >= 80) return l10n.scoreExcellent;
    if (s >= 50) return l10n.scoreAverage;
    return l10n.scorePoor;
  }

  // ── Retourne la couleur du score selon sa valeur ──────────────────────
  Color _scoreColor(int s) => s >= 80
      ? AppColors.scoreGood
      : s >= 50
      ? AppColors.scoreAverage
      : AppColors.scorePoor;
  // ── Retourne la couleur de fond du score selon sa valeur ────────────────
  Color _scoreBgColor(int s) => s >= 80
      ? AppColors.scoreGoodBg
      : s >= 50
      ? AppColors.scoreAverageBg
      : AppColors.scorePoorBg;

  // ── Formate une date au format JJ/MM/AAAA ─────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Récupère une valeur double depuis une carte avec plusieurs clés alternatives ──
  static double? _dbl(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  // ── Récupère une valeur entière depuis une carte avec plusieurs clés alternatives ──
  static int? _int(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  // ── Marque toutes les alertes comme lues et affiche une confirmation ───
  Future<void> _markAllRead(String patientId) async {
    await _alertService.markAllAlertsAsRead(patientId);
    if (!mounted) return; // Vérifie que le widget est toujours actif
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.alertsAllMarkedRead)));
  }

  // ── Supprime une alerte et gère les erreurs ──────────────────────────
  Future<void> _deleteAlert(String alertId) async {
    try {
      await _alertService.deleteAlert(alertId);
    } catch (_) {
      if (!mounted) return; // Vérifie que le widget est toujours actif
      final l10n = AppLocalizations.of(context)!;
      // Affiche un message d'erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.alertDeleteError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Affiche le panneau des alertes si une navigation l'a demandé ────
  void _maybeShowAlertsFromRoute(String patientId) {
    if (_hasShownAlertsFromRoute) return; // Évite l'affichage répété
    final extra = GoRouterState.of(context).extra;
    if (extra == true) {
      _hasShownAlertsFromRoute = true;
      // Utilise addPostFrameCallback pour afficher après le rendu initial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAlertsSheet(patientId);
      });
    }
  }

  // ── Ouvre un panneau modal affichant toutes les alertes du patient ───
  void _openAlertsSheet(String patientId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Affiche une bottom sheet avec la liste des alertes
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.alertsCenterTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _markAllRead(patientId),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: Text(l10n.markAllReadButton),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _alertService.streamPatientAlerts(patientId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.alertsLoadError,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final alerts = snapshot.data ?? [];
                      if (alerts.isEmpty)
                        return _buildAlertsEmptyState(l10n, isDark);

                      final criticals = alerts
                          .where((a) => a['severity'] == 'critical')
                          .toList();
                      final warnings = alerts
                          .where((a) => a['severity'] == 'warning')
                          .toList();
                      final infos = alerts
                          .where(
                            (a) =>
                                a['severity'] != 'critical' &&
                                a['severity'] != 'warning',
                          )
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (criticals.isNotEmpty) ...[
                            _buildAlertSectionHeader(
                              l10n.alertsCriticalSection(criticals.length),
                              AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            ...criticals.map((a) => _buildAlertCard(a, isDark)),
                            const SizedBox(height: 20),
                          ],
                          if (warnings.isNotEmpty) ...[
                            _buildAlertSectionHeader(
                              l10n.alertsWarningSection(warnings.length),
                              AppColors.warning,
                            ),
                            const SizedBox(height: 8),
                            ...warnings.map((a) => _buildAlertCard(a, isDark)),
                            const SizedBox(height: 20),
                          ],
                          if (infos.isNotEmpty) ...[
                            _buildAlertSectionHeader(
                              l10n.alertsInfoSection(infos.length),
                              AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            ...infos.map((a) => _buildAlertCard(a, isDark)),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Construit la section "Dernières alertes" avec un StreamBuilder ──
  Widget _buildLatestAlertsSection({
    required String patientId,
    required bool isDark,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Écoute les alertes du patient en temps réel
      stream: _alertService.streamPatientAlerts(patientId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              AppLocalizations.of(context)!.alertsLoadError,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final alerts = snapshot.data ?? [];
        final latest = alerts.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? _cardDark : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernières alertes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: alerts.isEmpty
                        ? null
                        : () => _openAlertsSheet(patientId),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (alerts.isEmpty)
                _buildAlertsEmptyInline(AppLocalizations.of(context)!, isDark)
              else
                ...latest.map((a) => _buildAlertPreviewCard(a, isDark)),
            ],
          ),
        );
      },
    );
  }

  // ── Construit une miniature d'alerte pour la section d'aperçu ───────
  Widget _buildAlertPreviewCard(Map<String, dynamic> alert, bool isDark) {
    // Extrait les données de l'alerte avec valeurs par défaut
    final severity = alert['severity'] as String? ?? 'info';
    final message = alert['message'] as String? ?? 'Alerte';
    final isRead = alert['read'] as bool? ?? false;
    final alertId = alert['id'] as String?;
    final createdAt = _formatTimestamp(alert['createdAt']);
    final type = alert['type'] as String?;
    final colors = _severityColors(severity);

    return GestureDetector(
      onTap: () async {
        if (!isRead && alertId != null)
          await _alertService.markAlertAsRead(alertId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.3),
            width: isRead ? 0.5 : 1.2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(colors.icon, color: colors.iconColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _alertService.getAlertTypeLabel(type ?? ''),
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.textDark,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: TextStyle(fontSize: 11, color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Construit une carte d'alerte avec glissement pour suppression ────
  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    // Extrait les données de l'alerte avec valeurs par défaut
    final severity = alert['severity'] as String? ?? 'info';
    final message = alert['message'] as String? ?? 'Alerte';
    final isRead = alert['read'] as bool? ?? false;
    final alertId = alert['id'] as String?;
    final createdAt = _formatTimestamp(alert['createdAt']);
    final type = alert['type'] as String?;
    final colors = _severityColors(severity);

    // Utilise Dismissible pour permettre la suppression par glissement
    return Dismissible(
      key: Key(alertId ?? message),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteAlertDialogTitle),
          content: Text(l10n.deleteAlertDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.deleteButton),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        if (alertId != null) _deleteAlert(alertId);
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead && alertId != null)
            await _alertService.markAlertAsRead(alertId);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.3),
              width: isRead ? 0.5 : 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(colors.icon, color: colors.iconColor, size: 22),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _alertService.getAlertTypeLabel(type ?? ''),
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.textDark,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  createdAt,
                  style: TextStyle(fontSize: 11, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noActiveAlertsTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allVitalsNormalMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsEmptyInline(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.allVitalsNormalMessage,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSectionHeader(String title, Color color) => Text(
    title,
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
  );

  _SeverityColors _severityColors(String severity) {
    switch (severity) {
      case 'critical':
        return _SeverityColors(
          icon: Icons.warning_rounded,
          iconColor: AppColors.error,
          bg: AppColors.error.withValues(alpha: 0.1),
          badgeBg: AppColors.error.withValues(alpha: 0.15),
          border: AppColors.error,
        );
      case 'warning':
        return _SeverityColors(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.warning,
          bg: AppColors.warning.withValues(alpha: 0.1),
          badgeBg: AppColors.warning.withValues(alpha: 0.15),
          border: AppColors.warning,
        );
      default:
        return _SeverityColors(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.primary,
          bg: AppColors.primary.withValues(alpha: 0.1),
          badgeBg: AppColors.primary.withValues(alpha: 0.15),
          border: AppColors.primary,
        );
    }
  }

  // ── Formate un timestamp au format JJ/MM/AAAA à HH:MM ───────────────
  static String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    // Gère plusieurs types de timestamps (DateTime, String, Timestamp Firestore)
    if (value is DateTime)
      date = value;
    else if (value is String)
      date = DateTime.tryParse(value);
    else if (value is Timestamp)
      date = value.toDate();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        ' à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ── Récupère les localisations et l'état utilisateur ──────────────────
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    // Vérifie que l'utilisateur est toujours connecté
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardTitle)),
        body: Center(child: Text(l10n.sessionExpiredMessage)),
      );
    }

    _maybeShowAlertsFromRoute(user.uid);

    final userService = UserService();
    final measurementService = MeasurementService();

    return Scaffold(
      backgroundColor: isDark ? _bgDark : AppColors.background,
      body: Column(
        children: [
          _GradientHeader(isDark: isDark, pulseCtrl: _pulseCtrl),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: userService.streamUserProfile(user.uid),
              builder: (context, userSnap) {
                if (userSnap.hasError)
                  return _ErrorState(message: l10n.errorLoadingProfile);
                if (!userSnap.hasData) return _LoadingShimmer(isDark: isDark);

                final profile = userSnap.data;
                final fullName =
                    (profile?['fullName'] as String?)?.trim() ?? 'Patient';
                final firstName = fullName.split(' ').first;

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: measurementService.streamMeasurementRecords(
                    uid: user.uid,
                    limit: 1,
                  ),
                  builder: (context, measSnap) {
                    if (measSnap.hasError)
                      return _ErrorState(
                        message: l10n.errorLoadingMeasurements,
                      );
                    if (!measSnap.hasData)
                      return _LoadingShimmer(isDark: isDark);

                    final records = measSnap.data ?? [];
                    if (records.isEmpty) return _EmptyState(fullName: fullName);

                    final latest = records.first;
                    final score =
                        _dbl(latest, ['score', 'sleepScore'])?.round() ?? 0;
                    final apneas = _int(latest, ['apneas', 'apneaCount']) ?? 0;
                    final spo2 = _int(latest, ['spo2', 'avgSpo2']) ?? 0;
                    final heartRate =
                        _int(latest, ['heartRate', 'avgHeartRate']) ?? 0;
                    final temperature =
                        _dbl(latest, ['temperature', 'avgTemperature']) ?? 0.0;
                    final date =
                        (latest['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    return FadeTransition(
                      opacity: _fadeCtrl,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _slideCtrl,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            const SizedBox(height: 16),
                            _GreetingRow(
                              greeting: '${_greeting(l10n)}, $firstName !',
                              date: _fmtDate(date),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _ScoreCard(
                              score: score,
                              label: _scoreLabel(l10n, score),
                              scoreColor: _scoreColor(score),
                              scoreBgColor: _scoreBgColor(score),
                              isDark: isDark,
                              onTap: () =>
                                  context.go(RouteNames.patientHistory),
                            ),
                            const SizedBox(height: 14),
                            _QuickActionsRow(
                              isDark: isDark,
                              onAlerts: () => _openAlertsSheet(user.uid),
                            ),
                            const SizedBox(height: 14),
                            _VitalsGrid(
                              apneas: apneas,
                              spo2: spo2,
                              heartRate: heartRate,
                              temperature: temperature,
                              isDark: isDark,
                              onAlerts: () => _openAlertsSheet(user.uid),
                              onMonitor: () =>
                                  context.go(RouteNames.realtimeMonitoring),
                            ),
                            const SizedBox(height: 14),
                            _buildLatestAlertsSection(
                              patientId: user.uid,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => _MonitoringButton(
                                isMonitoring: _isMonitoring,
                                pulseValue: _pulseCtrl.value,
                                onTap: () {
                                  setState(() {
                                    _isMonitoring = !_isMonitoring;
                                    if (!_isMonitoring) _showLastSession = true;
                                  });
                                  context.go(RouteNames.realtimeMonitoring);
                                },
                              ),
                            ),
                            if (_showLastSession) ...[
                              const SizedBox(height: 10),
                              _LastSessionBar(isDark: isDark),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(isDark: isDark),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── WIDGETS PERSONNALISÉS ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

// ── EN-TÊTE AVEC DÉGRADÉ : Affiche le titre et le badge "Live" ─────────────────
class _GradientHeader extends StatelessWidget {
  final bool isDark;
  final AnimationController pulseCtrl;
  const _GradientHeader({required this.isDark, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, Color(0xFF1A4FA8), _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Apnea Detect',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4ADE80),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4ADE80,
                              ).withValues(alpha: 0.4 + 0.4 * pulseCtrl.value),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.go(RouteNames.patientProfile),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LIGNE DE SALUTATION : Affiche le message d'accueil et la date ──────────────
class _GreetingRow extends StatelessWidget {
  final String greeting, date;
  final bool isDark;
  const _GreetingRow({
    required this.greeting,
    required this.date,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.black87,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _navy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _navy.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 11, color: _navy),
            const SizedBox(width: 5),
            Text(
              date,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ── CARTE DE SCORE : Affiche le score de sommeil avec barre circulaire ─────────
class _ScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final Color scoreColor, scoreBgColor;
  final bool isDark;
  final VoidCallback onTap;
  const _ScoreCard({
    required this.score,
    required this.label,
    required this.scoreColor,
    required this.scoreBgColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [_cardDark, const Color(0xFF1A2236)]
                : [Colors.white, const Color(0xFFF0F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : _navy.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bedtime_rounded, size: 14, color: _teal),
                      const SizedBox(width: 5),
                      Text(
                        l10n.sleepScoreLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _navy,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Badge coloré affichant le label du score
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scoreBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: scoreColor),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Barre circulaire animée du score
            SizedBox(
              width: 95,
              height: 95,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle de fond
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withValues(alpha: 0.06),
                    ),
                  ),
                  // Barre circulaire avec animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: score / 100.0),
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LIGNE D'ACTIONS RAPIDES : 5 boutons de navigation ────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAlerts;
  const _QuickActionsRow({required this.isDark, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    // Définit les 5 actions rapides avec icône, label et callback
    final actions = [
      _QAction(
        'Alertes',
        Icons.notifications_active_rounded,
        AppColors.error,
        onAlerts,
      ),
      _QAction(
        'Historique',
        Icons.bar_chart_rounded,
        _navyLight,
        () => context.go(RouteNames.patientHistory),
      ),
      _QAction(
        'Détente',
        Icons.self_improvement_rounded,
        const Color(0xFF7C3AED),
        () => context.go(RouteNames.relaxation),
      ),
      _QAction(
        'Profil',
        Icons.person_rounded,
        _teal,
        () => context.go(RouteNames.patientProfile),
      ),
      _QAction(
        'Stats',
        Icons.bar_chart_rounded,
        _navy,
        () => context.go(RouteNames.patientHistory, extra: 1),
      ),
    ];
    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
                child: GestureDetector(
                  onTap: a.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? _cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.icon, color: a.color, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QAction(this.label, this.icon, this.color, this.onTap);
}

class _SeverityColors {
  final IconData icon;
  final Color iconColor, bg, badgeBg, border;
  const _SeverityColors({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.badgeBg,
    required this.border,
  });
}

// ── GRILLE DE SIGNES VITAUX : 4 cartes avec apnées, SpO2, fréq. cardiaque, température ──
class _VitalsGrid extends StatelessWidget {
  final int apneas, spo2, heartRate;
  final double temperature;
  final bool isDark;
  final VoidCallback onAlerts, onMonitor;
  const _VitalsGrid({
    required this.apneas,
    required this.spo2,
    required this.heartRate,
    required this.temperature,
    required this.isDark,
    required this.onAlerts,
    required this.onMonitor,
  });

  // ── Badge dynamique des apnées selon leur nombre ──────────────────────
  String _apneaTag(int n) {
    if (n >= 5) return 'Critique';
    if (n >= 3) return 'Modéré';
    if (n >= 1) return 'Léger';
    return 'Normal';
  }

  // ── Couleur du badge des apnées selon leur nombre ─────────────────────
  Color _apneaTagColor(int n) {
    if (n >= 5) return AppColors.error;
    if (n >= 3) return AppColors.warning;
    if (n >= 1) return AppColors.eventOrange;
    return AppColors.success;
  }

  // ── Couleur de fond du badge des apnées selon leur nombre ──────────────
  Color _apneaTagBg(int n) {
    if (n >= 5) return AppColors.error.withValues(alpha: 0.1);
    if (n >= 3) return AppColors.warning.withValues(alpha: 0.1);
    if (n >= 1) return AppColors.eventOrangeBg;
    return AppColors.success.withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Construit les 4 cartes de signes vitaux avec leurs données
    final vitals = [
      _Vital(
        icon: Icons.warning_amber_rounded,
        iconColor: _apneaTagColor(apneas),
        iconBg: _apneaTagBg(apneas),
        valueColor: _apneaTagColor(apneas),
        tagColor: _apneaTagColor(apneas),
        tagBg: _apneaTagBg(apneas),
        label: l10n.eventsLabel,
        value: '$apneas',
        tag: _apneaTag(apneas), // CORRECTION : dynamique
        onTap: onAlerts,
      ),
      _Vital(
        icon: Icons.air,
        iconColor: AppColors.spo2,
        iconBg: AppColors.spo2Bg,
        valueColor: AppColors.spo2,
        tagColor: AppColors.spo2,
        tagBg: AppColors.spo2Bg,
        label: l10n.avgSpo2Label,
        value: '$spo2%',
        tag: l10n.normalLabel,
        onTap: onMonitor,
      ),
      _Vital(
        icon: Icons.favorite_rounded,
        iconColor: AppColors.heartRate,
        iconBg: AppColors.heartRateBg,
        valueColor: AppColors.heartRate,
        tagColor: AppColors.heartRate,
        tagBg: AppColors.heartRateBg,
        label: l10n.avgHeartRateLabel,
        value: '$heartRate bpm',
        tag: l10n.normalLabel,
        onTap: onMonitor,
      ),
      _Vital(
        icon: Icons.thermostat_rounded,
        iconColor: AppColors.temperature,
        iconBg: AppColors.temperatureBg,
        valueColor: AppColors.temperature,
        tagColor: AppColors.temperature,
        tagBg: AppColors.temperatureBg,
        label: l10n.temperatureLabel,
        value: '${temperature.toStringAsFixed(1)}°C',
        tag: l10n.normalLabel,
        onTap: onMonitor,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: c.maxWidth < 370 ? 1.05 : 1.2,
        ),
        itemCount: vitals.length,
        itemBuilder: (_, i) => _VitalCard(v: vitals[i], isDark: isDark),
      ),
    );
  }
}

class _Vital {
  final IconData icon;
  final Color iconColor, iconBg, valueColor, tagColor, tagBg;
  final String label, value, tag;
  final VoidCallback onTap;
  const _Vital({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.valueColor,
    required this.tagColor,
    required this.tagBg,
    required this.label,
    required this.value,
    required this.tag,
    required this.onTap,
  });
}

class _VitalCard extends StatefulWidget {
  final _Vital v;
  final bool isDark;
  const _VitalCard({required this.v, required this.isDark});
  @override
  State<_VitalCard> createState() => _VitalCardState();
}

class _VitalCardState extends State<_VitalCard>
    with SingleTickerProviderStateMixin {
  // Contrôleur pour l'animation de pression au toucher
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Crée une carte avec effet tactile (scale down quand pressée)
    final v = widget.v;
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        v.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: 1 - 0.025 * _c.value,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? _cardDark : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: v.iconColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: v.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(v.icon, color: v.iconColor, size: 17),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ],
                ),
                Text(
                  v.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  v.value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: v.valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: v.tagBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v.tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: v.tagColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── BOUTON MONITRAGE : Bouton prominent pour lancer/arrêter le monitrage ──────
class _MonitoringButton extends StatelessWidget {
  final bool isMonitoring;
  final double pulseValue;
  final VoidCallback onTap;
  const _MonitoringButton({
    required this.isMonitoring,
    required this.pulseValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isMonitoring ? AppColors.error : _navy;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15 + pulseValue * 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 22,
        ),
        label: Text(
          isMonitoring ? l10n.stopMonitoringButton : l10n.startMonitoringButton,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── BARRE DERNIÈRE SESSION : Affiche un lien vers la dernière session ────────
class _LastSessionBar extends StatelessWidget {
  final bool isDark;
  const _LastSessionBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: _teal),
          const SizedBox(width: 8),
          Text(
            l10n.lastSessionLabel,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 11,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ],
      ),
    );
  }
}

// ── BARRE DE NAVIGATION INFÉRIEURE : Navigation à 5 onglets ──────────────────
class _BottomNav extends StatelessWidget {
  final bool isDark;
  const _BottomNav({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _navy,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        currentIndex: 0,
        onTap: (i) {
          // Liste des 5 routes de navigation
          const routes = [
            RouteNames.patientDashboard,
            RouteNames.patientHistory,
            RouteNames.realtimeMonitoring,
            RouteNames.relaxation,
            RouteNames.patientSettings,
          ];
          context.go(routes[i]);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.homeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_rounded),
            label: l10n.historyLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monitor_heart_rounded),
            label: l10n.monitoringShortLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.spa_rounded),
            label: l10n.relaxationLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: l10n.settingsShortLabel,
          ),
        ],
      ),
    );
  }
}

// ── ÉTATS DE CHARGEMENT, ERREUR ET VIDE ────────────────────────────────────────

// ── SHIMMER DE CHARGEMENT : Affiche un chargement style squelette ──────────────
class _LoadingShimmer extends StatelessWidget {
  final bool isDark;
  const _LoadingShimmer({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 22,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              2,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 1 ? 12 : 0),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── ÉTAT D'ERREUR : Affiche un message d'erreur avec icône ────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ── ÉTAT VIDE : Affiche un message quand aucune mesure n'existe ────────────────
class _EmptyState extends StatelessWidget {
  final String fullName;
  const _EmptyState({required this.fullName});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_navy, _teal]),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nights_stay_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${l10n.greetingEvening}, ${fullName.split(' ').first} !',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noMeasurementsMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.realtimeMonitoring),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.startMonitoringButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
