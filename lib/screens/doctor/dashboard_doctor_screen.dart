import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

class DashboardDoctorScreen extends StatelessWidget {
  const DashboardDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark         = Theme.of(context).brightness == Brightness.dark;
    final doctorProfile  = useDoctorProfile(context);
    final doctorName     = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl       = doctorProfile?.profileImageUrl;
    final doctorUid      = context.watch<AuthProvider>().user?.uid ?? '';
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar:
          const DoctorBottomNavigationBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────
            _Header(
              name:     doctorName,
              photoUrl: photoUrl,
              isDark:   isDark,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Stats réelles ────────────────────────────────────
                  _SectionTitle(
                    title: 'Vue d\'ensemble',
                    icon:  Icons.dashboard_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _StatsGrid(
                    doctorUid:       doctorUid,
                    firebaseService: firebaseService,
                    isDark:          isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Patients récents ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title:  'Mes patients',
                        icon:   Icons.people_alt_rounded,
                        isDark: isDark,
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(RouteNames.doctorPatients),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Voir tous',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PatientsList(
                    doctorUid:       doctorUid,
                    firebaseService: firebaseService,
                    isDark:          isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Alertes récentes ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title:  'Alertes récentes',
                        icon:   Icons.warning_amber_rounded,
                        isDark: isDark,
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(RouteNames.doctorAlerts),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Voir toutes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AlertsList(
                    doctorUid:       doctorUid,
                    firebaseService: firebaseService,
                    isDark:          isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Actions rapides ──────────────────────────────────
                  _SectionTitle(
                    title:  'Actions rapides',
                    icon:   Icons.flash_on_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _QuickActions(isDark: isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.photoUrl,
    required this.isDark,
  });

  final String  name;
  final String? photoUrl;
  final bool    isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 20,
        left:   24,
        right:  24,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color:      Colors.white70,
                    fontSize:   13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                    color:       Colors.white,
                    fontSize:    22,
                    fontWeight:  FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.doctorProfile),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius:          24,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage:
                    (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size:  26,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour,';
    if (h < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}

// ── Stats réelles ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.doctorUid,
    required this.firebaseService,
    required this.isDark,
  });

  final String          doctorUid;
  final FirebaseService firebaseService;
  final bool            isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.streamDoctorPatients(doctorUid),
      builder: (context, patientsSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: firebaseService.streamDoctorAlerts(doctorUid),
          builder: (context, alertsSnap) {
            final patients      = patientsSnap.data ?? [];
            final alerts        = alertsSnap.data ?? [];
            final totalPatients = patients.length;
            final critical      = alerts
                .where((a) => a['severity'] == 'critical')
                .length;
            final unread = alerts
                .where((a) => a['read'] == false)
                .length;

            return GridView.count(
              crossAxisCount:  2,
              crossAxisSpacing: 14,
              mainAxisSpacing:  14,
              shrinkWrap:      true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  label:  'Patients',
                  value:  totalPatients.toString(),
                  icon:   Icons.people_alt_rounded,
                  color:  AppColors.primary,
                  isDark: isDark,
                  loading: !patientsSnap.hasData,
                ),
                _StatCard(
                  label:  'Alertes critiques',
                  value:  critical.toString(),
                  icon:   Icons.warning_rounded,
                  color:  AppColors.error,
                  isDark: isDark,
                  loading: !alertsSnap.hasData,
                ),
                _StatCard(
                  label:  'Non lues',
                  value:  unread.toString(),
                  icon:   Icons.notifications_outlined,
                  color:  AppColors.warning,
                  isDark: isDark,
                  loading: !alertsSnap.hasData,
                ),
                _StatCard(
                  label:  'Total alertes',
                  value:  alerts.length.toString(),
                  icon:   Icons.bar_chart_rounded,
                  color:  AppColors.success,
                  isDark: isDark,
                  loading: !alertsSnap.hasData,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.loading,
  });

  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;
  final bool    isDark;
  final bool    loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
        ),
        boxShadow: [
          BoxShadow(
            color:  color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:         color.withValues(alpha: 0.1),
              borderRadius:  BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? Container(
                      height: 20,
                      width:  40,
                      decoration: BoxDecoration(
                        color:         isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.surfaceLight,
                        borderRadius:  BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.w800,
                        color:      isDark
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:    isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Liste patients réels ──────────────────────────────────────────────────────

class _PatientsList extends StatelessWidget {
  const _PatientsList({
    required this.doctorUid,
    required this.firebaseService,
    required this.isDark,
  });

  final String          doctorUid;
  final FirebaseService firebaseService;
  final bool            isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.streamDoctorPatients(doctorUid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final patients = snap.data!;

        if (patients.isEmpty) {
          return _EmptyState(
            icon:    Icons.person_add_outlined,
            message: 'Aucun patient pour l\'instant.\n'
                     'Ajoutez votre premier patient.',
            isDark:  isDark,
          );
        }

        // Afficher max 3 patients dans le dashboard
        final displayed = patients.take(3).toList();

        return Column(
          children: displayed.map((patient) {
            final uid      = patient['uid'] as String? ?? '';
            final name     = (patient['fullName'] as String?)?.trim()
                ?? 'Patient';
            final gender   = patient['gender'] as String? ?? '';
            final age      = patient['age'];
            final initials = name.isNotEmpty
                ? name[0].toUpperCase()
                : 'P';

            return GestureDetector(
              onTap: () => context.push(
                RouteNames.doctorPatientProfile(
                    Uri.encodeComponent(uid)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius:          20,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color:      AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize:   16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                              color:      isDark
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (age != null) '$age ans',
                              if (gender.isNotEmpty) gender,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color:    isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size:  13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textLight,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Liste alertes réelles ─────────────────────────────────────────────────────

class _AlertsList extends StatelessWidget {
  const _AlertsList({
    required this.doctorUid,
    required this.firebaseService,
    required this.isDark,
  });

  final String          doctorUid;
  final FirebaseService firebaseService;
  final bool            isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.streamDoctorAlerts(doctorUid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final alerts = snap.data!;

        if (alerts.isEmpty) {
          return _EmptyState(
            icon:    Icons.check_circle_outline_rounded,
            message: 'Aucune alerte active.\nTous vos patients vont bien.',
            isDark:  isDark,
            color:   AppColors.success,
          );
        }

        // Afficher max 3 alertes
        final displayed = alerts.take(3).toList();

        return Column(
          children: displayed.map((alert) {
            final severity  = alert['severity'] as String? ?? 'info';
            final message   = alert['message']  as String?
                ?? alert['type'] as String?
                ?? 'Alerte';
            final patientId = alert['patientId'] as String?
                ?? alert['patientUid'] as String? ?? '';
            final isRead    = alert['read'] as bool? ?? false;

            final color = severity == 'critical'
                ? AppColors.error
                : severity == 'warning'
                    ? AppColors.warning
                    : AppColors.info;

            return GestureDetector(
              onTap: () {
                if (patientId.isNotEmpty) {
                  context.push(
                    RouteNames.doctorPatientProfile(
                        Uri.encodeComponent(patientId)),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: color, width: 4),
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surfaceLight,
                    ),
                    right: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surfaceLight,
                    ),
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surfaceLight,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  leading: Container(
                    width:  38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:         color.withValues(alpha: 0.1),
                      borderRadius:  BorderRadius.circular(10),
                    ),
                    child: Icon(
                      severity == 'critical'
                          ? Icons.warning_rounded
                          : Icons.notifications_outlined,
                      color: color,
                      size:  18,
                    ),
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color:      isDark
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: !isRead
                      ? Container(
                          width:  8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Actions rapides ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'Patients',
        Icons.people_alt_rounded,
        AppColors.primary,
        () => context.go(RouteNames.doctorPatients),
      ),
      (
        'Rapports',
        Icons.picture_as_pdf_rounded,
        AppColors.error,
        () => context.go(RouteNames.doctorReports),
      ),
      (
        'Messages',
        Icons.chat_outlined,
        AppColors.success,
        () => context.go(RouteNames.doctorMessages),
      ),
      (
        'Paramètres',
        Icons.settings_rounded,
        AppColors.textMedium,
        () => context.go(RouteNames.doctorSettings),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final (label, icon, color, onTap) = a;
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width:  54,
                height: 54,
                decoration: BoxDecoration(
                  color:         color.withValues(alpha: 0.1),
                  borderRadius:  BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:     isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textBody,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  final String  title;
  final IconData icon;
  final bool    isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w700,
            color:      isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
    this.color = AppColors.textMedium,
  });

  final IconData icon;
  final String   message;
  final bool     isDark;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color:    isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
                height:   1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}