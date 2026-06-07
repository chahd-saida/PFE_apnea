// lib/screens/doctor/dashboard_doctor_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardDoctorScreen extends StatelessWidget {
  const DashboardDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorProfile = useDoctorProfile(context);
    // useDoctorProfile() est un hook custom qui lit le UserProfileProvider

    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl = doctorProfile?.profileImageUrl;
    final doctorUid = context.watch<AuthProvider>().user?.uid ?? '';
    final userService = UserService();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF1F5F9),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: doctorName, photoUrl: photoUrl, isDark: isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: 'Vue d\'ensemble',
                    icon: Icons.dashboard_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _StatsGrid(
                    doctorUid: doctorUid,
                    userService: userService,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'IA & Analyse de Risque',
                    icon: Icons.psychology_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _AIRiskSection(doctorUid: doctorUid, isDark: isDark),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title: 'Mes patients',
                        icon: Icons.people_alt_rounded,
                        isDark: isDark,
                      ),
                      _ViewAllButton(
                        label: 'Voir tous',
                        onTap: () => context.go(RouteNames.doctorPatients),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PatientsList(
                    doctorUid: doctorUid,
                    userService: userService,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title: 'Alertes récentes',
                        icon: Icons.notifications_outlined,
                        isDark: isDark,
                      ),
                      _ViewAllButton(
                        label: 'Voir toutes',
                        onTap: () => context.go(RouteNames.doctorAlerts),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AlertsList(doctorUid: doctorUid, isDark: isDark),
                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'Actions rapides',
                    icon: Icons.flash_on_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
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

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.photoUrl,
    required this.isDark,
  });
  final String name;
  final String? photoUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
        ? 'Bon après-midi'
        : 'Bonsoir';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF0E3FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'En ligne',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.doctorProfile),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE0E7FF),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF1A56DB),
                        size: 28,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS GRID
// ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.doctorUid,
    required this.userService,
    required this.isDark,
  });
  final String doctorUid;
  final UserService userService;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.streamDoctorPatients(doctorUid),
      builder: (context, patientsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('alerts')
              .where('doctorUid', isEqualTo: doctorUid)
              .limit(100)
              .snapshots(),
          builder: (context, alertsSnap) {
            // Les deux streams sont lus simultanément
            final pLoading =
                patientsSnap.connectionState == ConnectionState.waiting;
            final aLoading =
                alertsSnap.connectionState == ConnectionState.waiting;

            final patients = patientsSnap.data ?? [];
            final alertDocs = alertsSnap.data?.docs ?? [];
            final alerts = alertDocs
                .map((d) => d.data() as Map<String, dynamic>)
                .toList();

            final totalPatients = patients.length;
            final critical = alerts
                .where((a) => a['severity'] == 'critical')
                .length;
            final unread = alerts.where((a) => a['read'] == false).length;
            final total = alerts.length;

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _StatCard(
                  label: 'Patients',
                  value: totalPatients.toString(),
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF1A56DB),
                  isDark: isDark,
                  loading: pLoading,
                  onTap: () => context.go(RouteNames.doctorPatients),
                ),
                _StatCard(
                  label: 'Critiques',
                  value: critical.toString(),
                  icon: Icons.warning_rounded,
                  color: AppColors.error,
                  isDark: isDark,
                  loading: aLoading,
                  onTap: () => context.go(RouteNames.doctorAlerts),
                ),
                _StatCard(
                  label: 'Non lues',
                  value: unread.toString(),
                  icon: Icons.notifications_active_outlined,
                  color: AppColors.warning,
                  isDark: isDark,
                  loading: aLoading,
                  onTap: () => context.go(RouteNames.doctorAlerts),
                ),
                _StatCard(
                  label: 'Total alertes',
                  value: total.toString(),
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                  loading: aLoading,
                  onTap: () => context.go(RouteNames.doctorAlerts),
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
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark, loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                loading
                    ? Container(
                        height: 24,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                          // Rectangle gris animé pendant le chargement ("skeleton")
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// IA & ANALYSE DE RISQUE
// ─────────────────────────────────────────────────────────────

class _AIRiskSection extends StatelessWidget {
  const _AIRiskSection({required this.doctorUid, required this.isDark});
  final String doctorUid;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // REQUÊTE 1 : récupérer tous les patients du médecin
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .where('doctorUid', isEqualTo: doctorUid)
          .snapshots(),
      builder: (context, patientsSnap) {
        if (patientsSnap.connectionState == ConnectionState.waiting) {
          return _aiLoadingCard();
        }
        final patientDocs = patientsSnap.data?.docs ?? [];
        if (patientDocs.isEmpty) {
          return _aiNoDataCard('Aucun patient assigné pour l\'analyse IA.');
        }
        // Limite à 10 car whereIn a une limite de 10 valeurs dans Firestore
        final ids = patientDocs.map((d) => d.id).take(10).toList();

        // REQUÊTE 2 : récupérer les mesures récentes de ces patients
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('measurements')
              .where('uid', whereIn: ids)
              .limit(50)
              .snapshots(),
          builder: (context, measSnap) {
            if (measSnap.connectionState == ConnectionState.waiting) {
              return _aiLoadingCard();
            }
            if (measSnap.hasError) {
              return _aiNoDataCard('Erreur chargement mesures.');
            }

            final docs = measSnap.data?.docs ?? [];
            // Trier par timestamp décroissant (plus récent en premier)
            final sorted = [...docs]
              ..sort((a, b) {
                final aRaw = (a.data() as Map)['timestamp'];
                final bRaw = (b.data() as Map)['timestamp'];
                DateTime? aT, bT;
                if (aRaw is Timestamp) {
                  aT = aRaw.toDate();
                } else if (aRaw is String) {
                  aT = DateTime.tryParse(aRaw);
                }
                if (bRaw is Timestamp) {
                  bT = bRaw.toDate();
                } else if (bRaw is String) {
                  bT = DateTime.tryParse(bRaw);
                }
                if (aT == null && bT == null) return 0;
                if (aT == null) return 1;
                if (bT == null) return -1;
                return bT.compareTo(aT);
              });

            if (sorted.isEmpty) {
              return _aiNoDataCard(
                'Aucune mesure disponible pour l\'analyse IA.',
              );
            }

            // Garder uniquement la mesure la plus récente par patient
            final latest = <String, Map<String, dynamic>>{};
            for (final doc in sorted) {
              final d = doc.data() as Map<String, dynamic>;
              final uid = (d['uid'] as String?) ?? '';
              if (uid.isNotEmpty && !latest.containsKey(uid)) latest[uid] = d;
            }

            if (latest.isEmpty) {
              return _aiNoDataCard(
                'Aucune mesure disponible pour l\'analyse IA.',
              );
            }

            // Construire la map patients pour lookup direct
            final patientMap = <String, Map<String, dynamic>>{};
            for (final doc in patientDocs) {
              patientMap[doc.id] = {
                ...(doc.data() as Map<String, dynamic>),
                'id': doc.id,
              };
            }

            return _buildAICard(context, _computeStats(latest, patientMap));
          },
        );
      },
    );
  }

  _AIStats _computeStats(
    Map<String, Map<String, dynamic>> latest,
    Map<String, Map<String, dynamic>> patientMap,
  ) {
    double totalScore = 0;
    int highRisk = 0, severe = 0, moderate = 0;
    String? worstId;
    double worstRisk = 0;

    for (final e in latest.entries) {
      final d = e.value;
      final score = (d['score'] as num?)?.toDouble() ?? 0.0;
      final apneas = (d['apneas'] as num?)?.toInt() ?? 0;
      final spo2Raw = d['avgSpo2'] ?? d['spo2'];
      final spo2 = (spo2Raw as num?)?.toDouble() ?? 100.0;
      totalScore += score;

      // Seuils médicaux de criticité
      if (score < 50 || apneas >= 5 || spo2 < 92) highRisk++;
      if (apneas >= 10 || spo2 < 88) {
        severe++;
      } else if (apneas >= 5 || spo2 < 92) {
        moderate++;
      }

      // Formule de score de risque composite
      final risk =
          (100 - score) * 0.5 +
          apneas * 3.0 +
          (spo2 < 92 ? (92 - spo2) * 5 : 0);
      if (risk > worstRisk) {
        worstRisk = risk;
        worstId = e.key;
      }
    }

    final n = latest.length;

    // Lookup direct dans la Map pour éviter le problème de type
    String worstName = '—';
    if (worstId != null) {
      final patientData = patientMap[worstId];
      worstName =
          (patientData?['fullName'] as String?)?.trim() ??
          (patientData?['displayName'] as String?)?.trim() ??
          worstId!;
    }

    return _AIStats(
      totalAnalysed: n,
      highRiskCount: highRisk,
      avgScore: n > 0 ? totalScore / n : 0.0,
      severity: severe > 0
          ? 'Sévère'
          : moderate > 0
          ? 'Modérée'
          : 'Légère',
      worstPatientName: worstName,
      worstPatientId: worstId,
    );
  }

  Widget _buildAICard(BuildContext context, _AIStats stats) {
    final sColor = stats.severity == 'Sévère'
        ? const Color(0xFFEF4444)
        : stats.severity == 'Modérée'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Prédiction IA des Risques',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Badge de sévérité globale (coloré selon le niveau)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  stats.severity,
                  style: TextStyle(
                    color: sColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _aiMetricBox(
                label: 'Analysés',
                value: '${stats.totalAnalysed}',
                icon: Icons.biotech,
              ),
              const SizedBox(width: 12),
              _aiMetricBox(
                label: 'À risque',
                value: '${stats.highRiskCount}',
                icon: Icons.warning_amber_rounded,
                highlight: stats.highRiskCount > 0,
              ),
              const SizedBox(width: 12),
              _aiMetricBox(
                label: 'Score moy.',
                value: '${stats.avgScore.toStringAsFixed(0)}/100',
                icon: Icons.bar_chart,
              ),
            ],
          ),
          if (stats.worstPatientId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient le plus à risque',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          stats.worstPatientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(
                      RouteNames.doctorPatientProfile(stats.worstPatientId!),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Voir profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiMetricBox({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFEF4444).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: highlight
              ? Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                )
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiLoadingCard() => Container(
    height: 160,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2E1065), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
    ),
  );

  Widget _aiNoDataCard(String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2E1065), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _AIStats {
  const _AIStats({
    required this.totalAnalysed,
    required this.highRiskCount,
    required this.avgScore,
    required this.severity,
    required this.worstPatientName,
    required this.worstPatientId,
  });
  final int totalAnalysed, highRiskCount;
  final double avgScore;
  final String severity, worstPatientName;
  final String? worstPatientId;
}

// ─────────────────────────────────────────────────────────────
// ALERTES RÉCENTES
// ─────────────────────────────────────────────────────────────

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.doctorUid, required this.isDark});
  final String doctorUid;
  final bool isDark;

  Stream<List<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('doctorUid', isEqualTo: doctorUid)
        .limit(20)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList();
          // Tri côté client par timestamp décroissant
          list.sort((a, b) {
            DateTime? at, bt;
            final ar = a['createdAt'];
            final br = b['createdAt'];
            if (ar is Timestamp) at = ar.toDate();
            if (br is Timestamp) bt = br.toDate();
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at); // Plus récent en premier
          });
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _AlertSkeleton(isDark: isDark);
        }
        if (snap.hasError) {
          return _alertEmpty(
            isDark: isDark,
            icon: Icons.error_outline_rounded,
            message: 'Impossible de charger les alertes.',
            color: AppColors.error,
          );
        }

        final alerts = snap.data ?? [];
        if (alerts.isEmpty) {
          return _alertEmpty(
            isDark: isDark,
            icon: Icons.check_circle_outline_rounded,
            message: 'Aucune alerte.\nTous vos patients vont bien.',
            color: AppColors.success,
          );
        }

        return Column(
          children: alerts.take(3).map((alert) {
            final severity = alert['severity'] as String? ?? 'info';
            final message =
                (alert['message'] as String?) ??
                (alert['type'] as String?) ??
                'Alerte';
            final patientId =
                (alert['patientId'] as String?) ??
                (alert['patientUid'] as String?) ??
                '';
            final isRead = alert['read'] as bool? ?? false;
            final createdAt = _formatTime(alert['createdAt']);
            final (color, icon) = _severityStyle(severity);

            return GestureDetector(
              onTap: () {
                if (patientId.isNotEmpty) {
                  context.push(
                    RouteNames.doctorPatientProfile(
                      Uri.encodeComponent(patientId),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRead
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade100)
                        : color.withValues(alpha: 0.3),
                    width: isRead ? 1 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isRead
                          ? Colors.transparent
                          : color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Indicateur "non lue" : point coloré
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _severityLabel(severity),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                createdAt,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
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

  (Color, IconData) _severityStyle(String severity) {
    switch (severity) {
      case 'critical':
        return (AppColors.error, Icons.warning_rounded);
      case 'warning':
        return (AppColors.warning, Icons.info_outline_rounded);
      default:
        return (AppColors.info, Icons.notifications_outlined);
    }
  }

  String _severityLabel(String s) {
    switch (s) {
      case 'critical':
        return 'CRITIQUE';
      case 'warning':
        return 'AVERT.';
      default:
        return 'INFO';
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  Widget _alertEmpty({
    required bool isDark,
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSkeleton extends StatelessWidget {
  const _AlertSkeleton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(14),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LISTE PATIENTS
// ─────────────────────────────────────────────────────────────

class _PatientsList extends StatelessWidget {
  const _PatientsList({
    required this.doctorUid,
    required this.userService,
    required this.isDark,
  });
  final String doctorUid;
  final UserService userService;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.streamDoctorPatients(doctorUid),
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
            icon: Icons.person_add_outlined,
            message: 'Aucun patient.\nAjoutez votre premier patient.',
            isDark: isDark,
          );
        }
        return Column(
          children: patients.take(3).map((p) {
            // Afficher seulement 3
            final uid = p['uid'] as String? ?? '';
            final name = (p['fullName'] as String?)?.trim() ?? 'Patient';
            final age = p['age'];
            final gender = p['gender'] as String? ?? '';
            final initial = name.isNotEmpty
                ? name[0].toUpperCase()
                : 'P'; // Initiale pour l'avatar
            final subtitle = [
              if (age != null) '$age ans',
              if (gender.isNotEmpty) gender,
            ].join(' · ');

            return GestureDetector(
              onTap: () => context.push(
                RouteNames.doctorPatientProfile(Uri.encodeComponent(uid)),
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
                        : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMedium,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
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

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
  });
  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    ],
  );
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.zero,
      // Supprime le padding minimum par défaut
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
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

class _EmptyState extends StatelessWidget {
  // Icône + message de placeholder quand une liste est vide
  // Réutilisé dans _PatientsList
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
  });
  final IconData icon;
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textMedium, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}