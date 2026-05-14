import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/alert_service.dart';

import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

class DoctorAlertsCenterScreen extends StatefulWidget {
  const DoctorAlertsCenterScreen({super.key});

  @override
  State<DoctorAlertsCenterScreen> createState() =>
      _DoctorAlertsCenterScreenState();
}

class _DoctorAlertsCenterScreenState extends State<DoctorAlertsCenterScreen> {
  final AlertService _alertService = AlertService();

  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Critique', 'Avertissement'];

  // ── Marquer toutes lues ───────────────────────────────────────────
  Future<void> _markAllRead(String doctorUid) async {
    try {
      // Sans orderBy pour éviter l'index composite
      final snap = await FirebaseFirestore.instance
          .collection('alerts')
          .where('doctorUid', isEqualTo: doctorUid)
          .where('read', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      if (!mounted) return;
      _showSnack('Toutes les alertes marquées comme lues', error: false);
    } catch (e) {
      _showSnack('Erreur : $e');
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    try {
      await _alertService.deleteAlert(alertId);
    } catch (e) {
      _showSnack('Erreur suppression : $e');
    }
  }

  Future<void> _markRead(String alertId) async {
    await _alertService.markAlertAsRead(alertId);
  }

  void _showSnack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Map<String, dynamic>> _filterAlerts(List<Map<String, dynamic>> alerts) {
    if (_selectedFilter == 'Tous') return alerts;
    final sev = _selectedFilter == 'Critique' ? 'critical' : 'warning';
    return alerts.where((a) => a['severity'] == sev).toList();
  }

  // ── Stream SANS orderBy pour éviter l'index composite ─────────────
  Stream<List<Map<String, dynamic>>> _buildAlertsStream(String doctorUid) {
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('doctorUid', isEqualTo: doctorUid)
        // PAS de .orderBy ici → pas besoin d'index composite
        .limit(100)
        .snapshots()
        .asyncMap((snap) async {
          var alerts = snap.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();

          // Tri côté client par date décroissante
          alerts.sort((a, b) {
            final at = _toDateTime(a['createdAt']);
            final bt = _toDateTime(b['createdAt']);
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          // Enrichir avec le nom du patient
          for (final alert in alerts) {
            final patientId = alert['patientId'] as String?;
            if (patientId != null &&
                patientId.isNotEmpty &&
                alert['patientName'] == null) {
              try {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(patientId)
                    .get();
                alert['patientName'] =
                    (doc.data()?['fullName'] as String?)?.trim() ?? 'Patient';
              } catch (_) {
                alert['patientName'] = 'Patient';
              }
            }
          }
          return alerts;
        });
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static String _formatTimestamp(dynamic value) {
    final date = _toDateTime(value);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Session expirée.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Se reconnecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'markAllRead',
            backgroundColor: AppColors.success,
            onPressed: () => _markAllRead(user.uid),
            tooltip: 'Tout marquer comme lu',
            child: const Icon(Icons.done_all, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          const DoctorChatbotFAB(),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 2),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          _buildHeader(context, photoUrl, isDark),

          // ── Contenu ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _buildAlertsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString(), isDark);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAlerts = snapshot.data ?? [];
                final filtered = _filterAlerts(allAlerts);

                final critical = allAlerts
                    .where((a) => a['severity'] == 'critical')
                    .length;
                final warning = allAlerts
                    .where((a) => a['severity'] == 'warning')
                    .length;
                final unread = allAlerts
                    .where((a) => !(a['read'] as bool? ?? false))
                    .length;

                return Column(
                  children: [
                    // Stats
                    _buildStatsRow(
                      critical,
                      warning,
                      unread,
                      allAlerts.length,
                      isDark,
                    ),
                    // Filtres
                    _buildFilterBar(isDark),
                    // Liste
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState(isDark)
                          : RefreshIndicator(
                              onRefresh: () async => setState(() {}),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildAlertCard(filtered[i], isDark),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header aligné avec les autres screens ─────────────────────────
  Widget _buildHeader(BuildContext context, String? photoUrl, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 24,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Centre d\'Alertes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Surveillance en temps réel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
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
                radius: 22,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 24,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de stats ─────────────────────────────────────────────────
  Widget _buildStatsRow(
    int critical,
    int warning,
    int unread,
    int total,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(
            label: 'Critiques',
            count: critical,
            color: AppColors.error,
            icon: Icons.warning_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Avertiss.',
            count: warning,
            color: AppColors.warning,
            icon: Icons.error_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Non lues',
            count: unread,
            color: AppColors.primary,
            icon: Icons.mark_email_unread_outlined,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Total',
            count: total,
            color: AppColors.textMedium,
            icon: Icons.list_alt_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Filtres ────────────────────────────────────────────────────────
  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: _filters.map((f) {
          final selected = f == _selectedFilter;
          final color = f == 'Critique'
              ? AppColors.error
              : f == 'Avertissement'
              ? AppColors.warning
              : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.surfaceLight),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMedium),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Carte alerte ───────────────────────────────────────────────────
  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final alertId = alert['id'] as String? ?? '';
    final patientId = (alert['patientId'] as String?)?.trim() ?? '';
    final patientName =
        (alert['patientName'] as String?)?.trim() ?? 'Patient inconnu';
    final message = (alert['message'] as String?)?.trim() ?? '';
    final severity = alert['severity'] as String? ?? 'info';
    final isRead = alert['read'] as bool? ?? false;
    final type = alert['type'] as String? ?? '';
    final createdAt = _formatTimestamp(alert['createdAt']);

    Color severityColor;
    IconData severityIcon;
    String severityLabel;

    switch (severity) {
      case 'critical':
        severityColor = AppColors.error;
        severityIcon = Icons.warning_rounded;
        severityLabel = 'Critique';
        break;
      case 'warning':
        severityColor = AppColors.warning;
        severityIcon = Icons.error_outline_rounded;
        severityLabel = 'Avertissement';
        break;
      default:
        severityColor = AppColors.primary;
        severityIcon = Icons.info_outline_rounded;
        severityLabel = 'Information';
    }

    return Dismissible(
      key: Key(alertId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 26,
        ),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Supprimer l\'alerte ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteAlert(alertId),
      child: GestureDetector(
        onTap: () async {
          if (!isRead && alertId.isNotEmpty) {
            await _markRead(alertId);
          }
          if (patientId.isNotEmpty && mounted) {
            context.push(
              RouteNames.doctorPatientProfile(Uri.encodeComponent(patientId)),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: severityColor, width: 4),
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
            boxShadow: [
              BoxShadow(
                color: severityColor.withValues(alpha: isRead ? 0.04 : 0.1),
                blurRadius: isRead ? 4 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ligne 1 ────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(severityIcon, color: severityColor, size: 20),
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
                                  patientName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  severityLabel,
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (type.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '· ${_alertService.getAlertTypeLabel(type)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),

                // ── Message ────────────────────────────────────────
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textBody,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                // ── Actions ────────────────────────────────────────
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isRead) ...[
                      _ActionBtn(
                        icon: Icons.mark_email_read_outlined,
                        label: 'Marquer lu',
                        color: AppColors.success,
                        onTap: () => _markRead(alertId),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (patientId.isNotEmpty) ...[
                      _ActionBtn(
                        icon: Icons.person_search_rounded,
                        label: 'Patient',
                        color: AppColors.primary,
                        onTap: () => context.push(
                          RouteNames.doctorPatientProfile(
                            Uri.encodeComponent(patientId),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: AppColors.textMedium,
                      onTap: () => context.go(RouteNames.doctorMessages),
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

  // ── Empty state ────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'Tous'
                  ? 'Aucune alerte active'
                  : 'Aucune alerte « $_selectedFilter »',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tous vos patients sont surveillés.\n'
              'Vous serez notifié dès qu\'une alerte apparaît.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────
  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                error.contains('failed-precondition')
                    ? 'Index Firestore manquant.\n'
                          'Créez l\'index composite :\n'
                          'alerts → doctorUid (Asc) + createdAt (Desc)\n'
                          'dans Firebase Console → Firestore → Index.'
                    : error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIAIRES
// ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceLight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
