import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/alert_service.dart';

class PatientAlertsScreen extends StatefulWidget {
  const PatientAlertsScreen({super.key});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  final AlertService _alertService = AlertService();

  Future<void> _markAllRead(String patientId) async {
    await _alertService.markAllAlertsAsRead(patientId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les alertes marquées comme lues.')),
    );
  }

  Future<void> _deleteAlert(String alertId) async {
    try {
      await _alertService.deleteAlert(alertId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Centre d\'Alertes')),
        body: const Center(child: Text('Session expirée.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'Alertes'),
        actions: [
          TextButton.icon(
            onPressed: () => _markAllRead(user.uid),
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Tout lire',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _alertService.streamPatientAlerts(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger les alertes.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return _buildEmptyState();
          }

          final criticals = alerts
              .where((a) => a['severity'] == 'critical')
              .toList();
          final warnings = alerts
              .where((a) => a['severity'] == 'warning')
              .toList();
          final infos = alerts
              .where(
                (a) =>
                    a['severity'] != 'critical' && a['severity'] != 'warning',
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (criticals.isNotEmpty) ...[
                _buildSectionHeader(
                  '🚨 Critiques (${criticals.length})',
                  Colors.red,
                ),
                const SizedBox(height: 8),
                ...criticals.map(
                  (a) => _buildAlertCard(a, context),
                ),
                const SizedBox(height: 20),
              ],
              if (warnings.isNotEmpty) ...[
                _buildSectionHeader(
                  '⚠️ Avertissements (${warnings.length})',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                ...warnings.map(
                  (a) => _buildAlertCard(a, context),
                ),
                const SizedBox(height: 20),
              ],
              if (infos.isNotEmpty) ...[
                _buildSectionHeader(
                  'ℹ️ Informations (${infos.length})',
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                ...infos.map((a) => _buildAlertCard(a, context)),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Surveil.',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Détente'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.patientDashboard);
              break;
            case 1:
              context.go(RouteNames.patientHistory);
              break;
            case 2:
              context.go(RouteNames.realtimeMonitoring);
              break;
            case 3:
              context.go(RouteNames.relaxation);
              break;
            case 4:
              context.go(RouteNames.patientSettings);
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune alerte active',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tout va bien ! Vos paramètres vitaux sont dans les limites normales.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildAlertCard(
    Map<String, dynamic> alert,
    BuildContext context,
  ) {
    final severity = alert['severity'] as String? ?? 'info';
    final message = alert['message'] as String? ?? 'Alerte';
    final isRead = alert['read'] as bool? ?? false;
    final alertId = alert['id'] as String?;
    final createdAt = _formatTimestamp(alert['createdAt']);
    final type = alert['type'] as String?;

    Color severityColor;
    IconData severityIcon;
    Color bgColor;

    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.warning_rounded;
        bgColor = Colors.red.shade50;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.error_outline_rounded;
        bgColor = Colors.orange.shade50;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info_outline_rounded;
        bgColor = Colors.blue.shade50;
    }

    return Dismissible(
      key: Key(alertId ?? message),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer l\'alerte'),
            content: const Text('Voulez-vous supprimer cette alerte ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (alertId != null) _deleteAlert(alertId);
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead && alertId != null) {
            await _alertService.markAlertAsRead(alertId);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.3),
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
                color: severityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(severityIcon, color: severityColor, size: 22),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _alertService.getAlertTypeLabel(type ?? ''),
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severityColor,
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Timestamp) {
      date = value.toDate();
    }
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} à $hour:$minute';
  }
}