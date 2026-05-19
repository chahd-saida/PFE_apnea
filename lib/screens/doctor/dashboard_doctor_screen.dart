import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/alert_service.dart';
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
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl = doctorProfile?.profileImageUrl;
    final doctorUid = context.watch<AuthProvider>().user?.uid ?? '';
    final userService = UserService();
    final alertService = AlertService();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: doctorName, photoUrl: photoUrl, isDark: isDark),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Vue d'ensemble ───────────────────────────────────
                  _SectionTitle(
                    title: 'Vue d\'ensemble',
                    icon: Icons.dashboard_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _StatsGrid(
                    doctorUid: doctorUid,
                    userService: userService,
                    alertService: alertService,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── IA & Analyse de Risque ───────────────────────────
                  _SectionTitle(
                    title: 'IA & Analyse de Risque',
                    icon: Icons.psychology,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _AIRiskSection(doctorUid: doctorUid, isDark: isDark),
                  const SizedBox(height: 28),

                  // ── Patients critiques ───────────────────────────────
                  _SectionTitle(
                    title: 'Patients Critiques',
                    icon: Icons.warning_amber_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _CriticalPatientsSection(
                    doctorUid: doctorUid,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Mes patients ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title: 'Mes patients',
                        icon: Icons.people_alt_rounded,
                        isDark: isDark,
                      ),
                      TextButton(
                        onPressed: () => context.go(RouteNames.doctorPatients),
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
                    doctorUid: doctorUid,
                    userService: userService,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Alertes récentes ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        title: 'Alertes récentes',
                        icon: Icons.notifications_outlined,
                        isDark: isDark,
                      ),
                      TextButton(
                        onPressed: () => context.go(RouteNames.doctorAlerts),
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
                    doctorUid: doctorUid,
                    alertService: alertService,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Actions rapides ──────────────────────────────────
                  _SectionTitle(
                    title: 'Actions rapides',
                    icon: Icons.flash_on_rounded,
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

// ─────────────────────────────────────────────────────────────
// SECTION IA & ANALYSE DE RISQUE
// ─────────────────────────────────────────────────────────────

class _AIRiskSection extends StatelessWidget {
  const _AIRiskSection({required this.doctorUid, required this.isDark});

  final String doctorUid;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('doctorUid', isEqualTo: doctorUid)
          .where('role', isEqualTo: 'patient')
          .snapshots(),
      builder: (context, patientsSnap) {
        if (patientsSnap.connectionState == ConnectionState.waiting) {
          return _aiLoadingCard();
        }

        final patientDocs = patientsSnap.data?.docs ?? [];
        if (patientDocs.isEmpty) {
          return _aiNoDataCard('Aucun patient assigné pour l\'analyse IA.');
        }

        final ids = patientDocs.map((d) => d.id).take(10).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('measurements')
              .where('uid', whereIn: ids)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, measSnap) {
            if (measSnap.connectionState == ConnectionState.waiting) {
              return _aiLoadingCard();
            }

            final docs = measSnap.data?.docs ?? [];

            // Garder uniquement la mesure la plus récente par patient
            final latestByPatient = <String, Map<String, dynamic>>{};
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              final uid = (d['uid'] as String?) ?? '';
              if (!latestByPatient.containsKey(uid)) {
                latestByPatient[uid] = d;
              }
            }

            if (latestByPatient.isEmpty) {
              return _aiNoDataCard(
                'Aucune mesure disponible pour l\'analyse IA.',
              );
            }

            final stats = _computeStats(latestByPatient, patientDocs);
            return _buildAICard(context, stats);
          },
        );
      },
    );
  }

  _AIStats _computeStats(
    Map<String, Map<String, dynamic>> latestByPatient,
    List<QueryDocumentSnapshot> patientDocs,
  ) {
    double totalScore = 0;
    int highRiskCount = 0;
    int severeCount = 0;
    int moderateCount = 0;
    String? worstPatientId;
    double worstRisk = 0;

    for (final entry in latestByPatient.entries) {
      final d = entry.value;
      final score = (d['score'] as num?)?.toDouble() ?? 0.0;
      final apneas = (d['apneas'] as num?)?.toInt() ?? 0;
      final spo2 = (d['avgSpo2'] ?? d['spo2'] as num?)?.toDouble() ?? 100.0;

      totalScore += score;

      final isHighRisk = score < 50 || apneas >= 5 || spo2 < 92;
      if (isHighRisk) highRiskCount++;

      if (apneas >= 10 || spo2 < 88) {
        severeCount++;
      } else if (apneas >= 5 || spo2 < 92) {
        moderateCount++;
      }

      final risk =
          (100 - score) * 0.5 +
          apneas * 3.0 +
          (spo2 < 92 ? (92 - spo2) * 5 : 0);
      if (risk > worstRisk) {
        worstRisk = risk;
        worstPatientId = entry.key;
      }
    }

    final n = latestByPatient.length;
    final avgScore = n > 0 ? (totalScore / n) : 0.0;

    String worstPatientName = '—';
    if (worstPatientId != null) {
      final doc = patientDocs.firstWhere(
        (d) => d.id == worstPatientId,
        orElse: () => patientDocs.first,
      );
      final data = doc.data() as Map<String, dynamic>;
      worstPatientName =
          (data['fullName'] as String?)?.trim() ?? worstPatientId!;
    }

    String severity;
    if (severeCount > 0)
      severity = 'Sévère';
    else if (moderateCount > 0)
      severity = 'Modérée';
    else
      severity = 'Légère';

    return _AIStats(
      totalAnalysed: n,
      highRiskCount: highRiskCount,
      avgScore: avgScore,
      severity: severity,
      worstPatientName: worstPatientName,
      worstPatientId: worstPatientId,
    );
  }

  Widget _buildAICard(BuildContext context, _AIStats stats) {
    final severityColor = stats.severity == 'Sévère'
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
          // En-tête
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  stats.severity,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Métriques
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
          const SizedBox(height: 16),

          // Patient le plus à risque
          if (stats.worstPatientId != null)
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

  Widget _aiLoadingCard() {
    return Container(
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
  }

  Widget _aiNoDataCard(String msg) {
    return Container(
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
}

// ─────────────────────────────────────────────────────────────
// SECTION PATIENTS CRITIQUES
// ─────────────────────────────────────────────────────────────

class _CriticalPatientsSection extends StatelessWidget {
  const _CriticalPatientsSection({
    required this.doctorUid,
    required this.isDark,
  });

  final String doctorUid;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('doctorUid', isEqualTo: doctorUid)
          .where('severity', isEqualTo: 'critical')
          .where('read', isEqualTo: false)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _skeleton();
        }

        if (snap.hasError) {
          return _errorCard(snap.error.toString());
        }

        final docs = snap.data?.docs ?? [];
        final sorted = [...docs]
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];
            if (aTs is Timestamp && bTs is Timestamp) {
              return bTs.compareTo(aTs);
            }
            return 0;
          });

        if (docs.isEmpty) {
          return _emptyCard();
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _CriticalPatientTile(
              data: data,
              isDark: isDark,
              onTap: () {
                final patientId = data['patientId'] as String?;
                if (patientId != null && patientId.isNotEmpty) {
                  context.push(RouteNames.doctorPatientProfile(patientId));
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _skeleton() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucun patient critique',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tous vos patients sont stables.',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Erreur chargement : $error',
        style: const TextStyle(fontSize: 12, color: Colors.red),
      ),
    );
  }
}

class _CriticalPatientTile extends StatelessWidget {
  const _CriticalPatientTile({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final patientId = (data['patientId'] as String?) ?? '';
    final message = (data['message'] as String?) ?? 'Alerte critique';
    final type = (data['type'] as String?) ?? 'apnea';
    final value = (data['value'] as num?)?.toStringAsFixed(0) ?? '—';
    final createdAt = _formatTimestamp(data['createdAt']);
    final (icon, color, unit) = _resolveType(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
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
                          _shortenMessage(message),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$value$unit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 11,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      _PatientNameFetcher(patientId: patientId),
                      const Spacer(),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _resolveType(String type) {
    switch (type) {
      case 'spo2':
        return (Icons.air, const Color(0xFF3B82F6), '%');
      case 'heartRate':
        return (Icons.favorite, const Color(0xFFEF4444), ' bpm');
      case 'apnea':
        return (Icons.airline_seat_flat, const Color(0xFFF59E0B), ' evt');
      default:
        return (Icons.warning_amber_rounded, const Color(0xFFEF4444), '');
    }
  }

  String _shortenMessage(String msg) {
    final idx = msg.indexOf(':');
    return idx > 0 ? msg.substring(0, idx) : msg;
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}

class _PatientNameFetcher extends StatelessWidget {
  const _PatientNameFetcher({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    if (patientId.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Text(
            '...',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          );
        }
        final d = snap.data?.data() as Map<String, dynamic>?;
        final name = (d?['fullName'] as String?)?.trim();
        return Text(
          name != null && name.isNotEmpty ? name : patientId,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Modèle interne stats IA
// ─────────────────────────────────────────────────────────────

class _AIStats {
  const _AIStats({
    required this.totalAnalysed,
    required this.highRiskCount,
    required this.avgScore,
    required this.severity,
    required this.worstPatientName,
    required this.worstPatientId,
  });

  final int totalAnalysed;
  final int highRiskCount;
  final double avgScore;
  final String severity;
  final String worstPatientName;
  final String? worstPatientId;
}

// ─────────────────────────────────────────────────────────────
// Header
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
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
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
                radius: 24,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 26,
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

// ─────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.doctorUid,
    required this.userService,
    required this.alertService,
    required this.isDark,
  });

  final String doctorUid;
  final UserService userService;
  final AlertService alertService;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.streamDoctorPatients(doctorUid),
      builder: (context, patientsSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: alertService.streamDoctorAlerts(doctorUid),
          builder: (context, alertsSnap) {
            final patients = patientsSnap.data ?? [];
            final alerts = alertsSnap.data ?? [];
            final totalPatients = patients.length;
            final critical = alerts
                .where((a) => a['severity'] == 'critical')
                .length;
            final unread = alerts.where((a) => a['read'] == false).length;

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  label: 'Patients',
                  value: totalPatients.toString(),
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  loading: !patientsSnap.hasData,
                ),
                _StatCard(
                  label: 'Alertes critiques',
                  value: critical.toString(),
                  icon: Icons.warning_rounded,
                  color: AppColors.error,
                  isDark: isDark,
                  loading: !alertsSnap.hasData,
                ),
                _StatCard(
                  label: 'Non lues',
                  value: unread.toString(),
                  icon: Icons.notifications_outlined,
                  color: AppColors.warning,
                  isDark: isDark,
                  loading: !alertsSnap.hasData,
                ),
                _StatCard(
                  label: 'Total alertes',
                  value: alerts.length.toString(),
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.success,
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

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool loading;

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
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? Container(
                      height: 20,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Liste patients
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
            message:
                'Aucun patient pour l\'instant.\nAjoutez votre premier patient.',
            isDark: isDark,
          );
        }

        return Column(
          children: patients.take(3).map((patient) {
            final uid = patient['uid'] as String? ?? '';
            final name = (patient['fullName'] as String?)?.trim() ?? 'Patient';
            final gender = patient['gender'] as String? ?? '';
            final age = patient['age'];
            final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

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
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        initials,
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
                              color: isDark ? Colors.white : AppColors.textDark,
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
// Liste alertes
// ─────────────────────────────────────────────────────────────

class _AlertsList extends StatelessWidget {
  const _AlertsList({
    required this.doctorUid,
    required this.alertService,
    required this.isDark,
  });

  final String doctorUid;
  final AlertService alertService;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: alertService.streamDoctorAlerts(doctorUid),
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
            icon: Icons.check_circle_outline_rounded,
            message: 'Aucune alerte active.\nTous vos patients vont bien.',
            isDark: isDark,
            color: AppColors.success,
          );
        }

        return Column(
          children: alerts.take(3).map((alert) {
            final severity = alert['severity'] as String? ?? 'info';
            final message =
                alert['message'] as String? ??
                alert['type'] as String? ??
                'Alerte';
            final patientId =
                alert['patientId'] as String? ??
                alert['patientUid'] as String? ??
                '';
            final isRead = alert['read'] as bool? ?? false;

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
                      Uri.encodeComponent(patientId),
                    ),
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
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      severity == 'critical'
                          ? Icons.warning_rounded
                          : Icons.notifications_outlined,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: !isRead
                      ? Container(
                          width: 8,
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

// ─────────────────────────────────────────────────────────────
// Actions rapides
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Helpers communs
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textDark,
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
  final String message;
  final bool isDark;
  final Color color;

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
