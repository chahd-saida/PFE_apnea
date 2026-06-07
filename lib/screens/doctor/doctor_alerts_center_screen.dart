// lib/screens/doctor/doctor_alerts_center_screen.dart
//
// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN CENTRE D'ALERTES — DoctorAlertsCenterScreen
// ═══════════════════════════════════════════════════════════════════════════════
//
// Rôle : Affiche toutes les alertes des patients assignés au médecin connecté,
//         avec filtrage, statistiques et actions rapides.
//
// CORRECTIONS APPORTÉES :
//   1. _stream()      → utilise .map() synchrone (plus de .asyncMap) pour éviter
//                        les délais et les rebuilds excessifs. Tri côté client.
//   2. _stream()      → suppression de .orderBy pour éviter l'index composite
//                        Firestore (cause 'failed-precondition' si absent).
//   3. _alertCard()   → Dismissible avec ValueKey unique garantie (UniqueKey si
//                        rawId vide). Évite les erreurs de clés dupliquées.
//   4. _patientName() → FutureBuilder avec initialData depuis le cache local pour
//                        afficher immédiatement le nom sans flash "Chargement...".
// ═══════════════════════════════════════════════════════════════════════════════

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

  // ─── Services ───────────────────────────────────────────────────────────────
  final AlertService _alertService = AlertService();

  // ─── État local ─────────────────────────────────────────────────────────────
  /// Filtre actuellement sélectionné par le médecin
  String _selectedFilter = 'Tous';

  /// Options de filtre disponibles
  final List<String> _filters = ['Tous', 'Critique', 'Avertissement'];

  /// Cache des noms patients — évite les appels Firestore répétés pour le même patient.
  /// Clé : patientId | Valeur : nom complet
  final Map<String, String> _nameCache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — Stream et filtrage
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream temps réel des alertes du médecin.
  ///
  /// FIX 1 : Utilise .map() synchrone au lieu de .asyncMap().
  ///   - .asyncMap() attendait la résolution du Future à chaque snapshot →
  ///     délai + rebuilds inutiles + risque de concurrence.
  ///   - Le tri et la transformation sont maintenant synchrones (côté client).
  ///
  /// FIX 2 : PAS de .orderBy('createdAt') dans la requête Firestore.
  ///   - .orderBy sur 'doctorUid' + 'createdAt' requiert un index composite
  ///     qui n'est pas créé par défaut → erreur 'failed-precondition'.
  ///   - Le tri est fait côté client dans le .map().
  Stream<List<Map<String, dynamic>>> _stream(String doctorUid) {
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('doctorUid', isEqualTo: doctorUid)
        // ── Pas de .orderBy ici → pas d'index composite nécessaire ──────
        .limit(100)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList();

          // Tri décroissant par date côté client (plus récent en premier)
          list.sort((a, b) {
            final at = _dt(a['createdAt']);
            final bt = _dt(b['createdAt']);
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          return list;
        });
  }

  /// Filtre la liste des alertes selon la sévérité sélectionnée.
  /// Retourne toutes les alertes si 'Tous' est sélectionné.
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    if (_selectedFilter == 'Tous') return all;
    final sev = _selectedFilter == 'Critique' ? 'critical' : 'warning';
    return all.where((a) => a['severity'] == sev).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — Actions sur les alertes
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marque toutes les alertes non lues du médecin comme lues.
  /// Utilise un batch Firestore pour optimiser les writes.
  Future<void> _markAllRead(String doctorUid) async {
    try {
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
      _snack('Toutes les alertes marquées comme lues', ok: true);
    } catch (e) {
      _snack('Erreur : $e');
    }
  }

  /// Supprime une alerte par son ID Firestore.
  Future<void> _deleteAlert(String id) async {
    try {
      await _alertService.deleteAlert(id);
    } catch (e) {
      _snack('Erreur suppression : $e');
    }
  }

  /// Marque une alerte spécifique comme lue.
  Future<void> _markRead(String id) => _alertService.markAlertAsRead(id);

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — Utilitaires
  // ═══════════════════════════════════════════════════════════════════════════

  /// Affiche un SnackBar flottant avec icône succès (vert) ou erreur (rouge).
  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Récupère le nom complet d'un patient avec cache local.
  ///
  /// FIX 3 : Utilisation d'un cache (_nameCache) pour éviter un appel Firestore
  /// par alerte à chaque rebuild. Le nom est affiché immédiatement si déjà en cache.
  Future<String> _patientName(String patientId) async {
    if (patientId.isEmpty) return 'Patient inconnu';

    // Retour immédiat depuis le cache si disponible
    if (_nameCache.containsKey(patientId)) {
      return _nameCache[patientId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      final d = doc.data();
      final name =
          (d?['fullName']     as String?)?.trim() ??
          (d?['displayName']  as String?)?.trim() ??
          '';

      _nameCache[patientId] = name.isEmpty ? 'Patient' : name;
    } catch (_) {
      _nameCache[patientId] = 'Patient';
    }

    return _nameCache[patientId]!;
  }

  /// Convertit différents formats de date en [DateTime].
  /// Supporte : Timestamp Firestore, DateTime natif, String ISO 8601.
  static DateTime? _dt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime)  return v;
    if (v is String)    return DateTime.tryParse(v);
    return null;
  }

  /// Formate une date en texte relatif lisible.
  /// Ex : "Il y a 5 min", "Il y a 2h", "12/06 14:30"
  static String _ts(dynamic v) {
    final d = _dt(v);
    if (d == null) return '';

    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60)  return 'À l\'instant';
    if (diff.inMinutes < 60)  return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)    return 'Il y a ${diff.inHours}h';

    return '${d.day.toString().padLeft(2, '0')}/'
           '${d.month.toString().padLeft(2, '0')} '
           '${d.hour.toString().padLeft(2, '0')}:'
           '${d.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — Build principal
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user          = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl      = doctorProfile?.profileImageUrl;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    // Redirection si session expirée
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

      // ── FABs : Marquer tout lu + Chatbot ───────────────────────────────
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
          // ── En-tête ──────────────────────────────────────────────────
          _header(context, photoUrl, isDark),

          // ── Contenu principal (stream temps réel) ────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream(user.uid),
              builder: (ctx, snap) {

                // ── États de chargement et d'erreur ───────────────────
                if (snap.hasError) {
                  return _errorWidget(snap.error.toString(), isDark);
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all      = snap.data ?? [];
                final filtered = _filter(all);

                // ── Statistiques ──────────────────────────────────────
                final nCrit   = all.where((a) => a['severity'] == 'critical').length;
                final nWarn   = all.where((a) => a['severity'] == 'warning').length;
                final nUnread = all.where((a) => !(a['read'] as bool? ?? false)).length;

                return Column(
                  children: [
                    _statsRow(nCrit, nWarn, nUnread, all.length, isDark),
                    _filterBar(isDark),
                    Expanded(
                      child: filtered.isEmpty
                          ? _emptyState(isDark)
                          : RefreshIndicator(
                              onRefresh: () async => setState(() {}),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _alertCard(filtered[i], isDark),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5 — Widgets de l'interface
  // ═══════════════════════════════════════════════════════════════════════════

  /// En-tête du centre d'alertes.
  /// Affiche : icône + titre + photo de profil du médecin cliquable.
  Widget _header(BuildContext ctx, String? photoUrl, bool isDark) =>
      Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).padding.top + 20,
          left: 24, right: 24, bottom: 24,
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
            // Icône notifications
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white, size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Titre
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

            // Photo profil → navigation vers profil médecin
            GestureDetector(
              onTap: () => ctx.push(RouteNames.doctorProfile),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
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
                          color: AppColors.primary, size: 24,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );

  /// Ligne de statistiques : Critiques | Avertissements | Non lues | Total.
  Widget _statsRow(int c, int w, int u, int t, bool isDark) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            _chip('Critiques',  c, AppColors.error,      Icons.warning_rounded,         isDark),
            const SizedBox(width: 10),
            _chip('Avertiss.',  w, AppColors.warning,    Icons.error_outline_rounded,   isDark),
            const SizedBox(width: 10),
            _chip('Non lues',   u, AppColors.primary,    Icons.mark_email_unread_outlined, isDark),
            const SizedBox(width: 10),
            _chip('Total',      t, AppColors.textMedium, Icons.list_alt_rounded,        isDark),
          ],
        ),
      );

  /// Chip de statistique : icône + nombre + label.
  Widget _chip(
    String label, int count, Color color, IconData icon, bool isDark,
  ) =>
      Expanded(
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
                blurRadius: 8, offset: const Offset(0, 3),
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
                  fontSize: 16, fontWeight: FontWeight.w800, color: color,
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

  /// Barre de filtrage : Tous / Critique / Avertissement.
  Widget _filterBar(bool isDark) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: _filters.map((f) {
            final sel = f == _selectedFilter;
            final col = f == 'Critique'
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
                    horizontal: 16, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? col
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? col
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.surfaceLight),
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: sel
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMedium),
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  /// Carte d'alerte individuelle avec toutes les informations et actions.
  ///
  /// FIX 4 : Dismissible avec ValueKey unique garantie.
  ///   - Si rawId est vide (alerte sans ID), UniqueKey() génère une clé aléatoire
  ///     pour éviter les exceptions "duplicate key" dans l'arbre de widgets.
  ///
  /// FIX 5 : FutureBuilder avec initialData depuis le cache.
  ///   - Le nom est affiché immédiatement si déjà en cache local (_nameCache),
  ///     sans flash "Chargement..." à chaque rebuild.
  Widget _alertCard(Map<String, dynamic> alert, bool isDark) {

    // ── Extraction sécurisée des champs ────────────────────────────────────
    final rawId      = alert['id']         as String? ?? '';
    // FIX 4 : clé unique garantie (UniqueKey si rawId vide)
    final dismissKey = rawId.isNotEmpty
        ? ValueKey<String>(rawId)
        : ValueKey<String>(UniqueKey().toString());

    final patientId = (alert['patientId'] as String?)?.trim() ?? '';
    final message   = (alert['message']   as String?)?.trim() ?? '';
    final severity  = alert['severity']   as String? ?? 'info';
    final isRead    = alert['read']        as bool?   ?? false;
    final type      = alert['type']        as String? ?? '';
    final createdAt = _ts(alert['createdAt']);

    // ── Couleur, icône et label selon la sévérité ─────────────────────────
    final Color   sevColor;
    final IconData sevIcon;
    final String  sevLabel;

    switch (severity) {
      case 'critical':
        sevColor = AppColors.error;
        sevIcon  = Icons.warning_rounded;
        sevLabel = 'Critique';
        break;
      case 'warning':
        sevColor = AppColors.warning;
        sevIcon  = Icons.error_outline_rounded;
        sevLabel = 'Avertissement';
        break;
      default:
        sevColor = AppColors.primary;
        sevIcon  = Icons.info_outline_rounded;
        sevLabel = 'Information';
    }

    return Dismissible(
      key: dismissKey,                          // FIX 4 : clé unique garantie
      direction: DismissDirection.endToStart,   // Glisser vers la gauche

      // Fond rouge avec icône corbeille visible lors du glissement
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
          color: AppColors.error, size: 26,
        ),
      ),

      // Dialog de confirmation avant suppression définitive
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      // Suppression effective après confirmation
      onDismissed: (_) {
        if (rawId.isNotEmpty) _deleteAlert(rawId);
      },

      child: GestureDetector(
        // Tap : marquer comme lu + naviguer vers le profil patient
        onTap: () async {
          if (!isRead && rawId.isNotEmpty) await _markRead(rawId);
          if (patientId.isNotEmpty && mounted) {
            context.push(
              RouteNames.doctorPatientProfile(
                Uri.encodeComponent(patientId),
              ),
            );
          }
        },

        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surfaceLight,
              width: 1,
            ),
            // Accent coloré sur le bord gauche + ombre douce
            boxShadow: [
              BoxShadow(
                color: sevColor,
                blurRadius: 0, spreadRadius: 0,
                offset: const Offset(-4, 0),
              ),
              BoxShadow(
                color: sevColor.withValues(alpha: isRead ? 0.04 : 0.10),
                blurRadius: isRead ? 4 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Ligne 1 : icône + patient + timestamp ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Icône de sévérité
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(sevIcon, color: sevColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Nom du patient avec cache + indicateur non-lu
                        Row(
                          children: [
                            Expanded(
                              child: patientId.isNotEmpty
                                  // FIX 5 : initialData depuis le cache
                                  // → nom affiché immédiatement si connu
                                  ? FutureBuilder<String>(
                                      future: _patientName(patientId),
                                      initialData:
                                          _nameCache[patientId] ??
                                          'Chargement...',
                                      builder: (_, snap) => Text(
                                        snap.data ?? 'Patient',
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
                                    )
                                  : Text(
                                      'Patient inconnu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textDark,
                                      ),
                                    ),
                            ),

                            // Point coloré si alerte non lue
                            if (!isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: sevColor, shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Badge sévérité + type d'alerte
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: sevColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sevLabel,
                                style: TextStyle(
                                  color: sevColor,
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

                  const SizedBox(width: 8),

                  // Timestamp
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

              // ── Message de l'alerte ─────────────────────────────────
              if (message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : sevColor.withValues(alpha: 0.05),
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

              // ── Actions rapides ─────────────────────────────────────
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isRead) ...[
                    _actionBtn(
                      Icons.mark_email_read_outlined, 'Marquer lu',
                      AppColors.success, () => _markRead(rawId),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (patientId.isNotEmpty) ...[
                    _actionBtn(
                      Icons.person_search_rounded, 'Patient',
                      AppColors.primary,
                      () => context.push(
                        RouteNames.doctorPatientProfile(
                          Uri.encodeComponent(patientId),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _actionBtn(
                    Icons.chat_bubble_outline_rounded, 'Message',
                    AppColors.textMedium,
                    () => context.go(RouteNames.doctorMessages),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton d'action compact : icône + label avec fond coloré.
  Widget _actionBtn(
    IconData icon, String label, Color color, VoidCallback onTap,
  ) =>
      GestureDetector(
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
                  color: color, fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  /// État vide : aucune alerte active ou aucun résultat pour le filtre actuel.
  Widget _emptyState(bool isDark) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40, color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _selectedFilter == 'Tous'
                    ? 'Aucune alerte active'
                    : 'Aucune alerte « $_selectedFilter »',
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textDark,
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

  /// État d'erreur : affiché en cas d'erreur Firestore.
  /// Guide l'utilisateur pour créer l'index manquant si nécessaire.
  Widget _errorWidget(String error, bool isDark) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline, size: 36, color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  // Guide spécifique si index Firestore manquant
                  error.contains('failed-precondition')
                      ? 'Index Firestore manquant.\n'
                            'Créez l\'index dans Firebase Console :\n'
                            'Firestore → Index → Créer\n'
                            'Collection : alerts\n'
                            'Champ : doctorUid (Croissant)'
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