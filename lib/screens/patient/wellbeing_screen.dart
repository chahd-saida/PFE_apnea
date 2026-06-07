import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

// ── Palette ───────────────────────────────────────────────────────
const _teal = Color(0xFF1B9C95);
const _navy = Color(0xFF0F1F3A);
const _coral = Color(0xFFE05C7A);
const _violet = Color(0xFF7C3AED);
const _green = Color(0xFF5B9E7A);

// ═══════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned:
                true, // Reste visible quand scrollé (collapse en appbar classique)
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, _teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.self_improvement_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bien-être & Santé',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Articles, exercices et conseils pour mieux dormir',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Catégories rapides ───────────────────────────
                _QuickCategories(isDark: isDark),
                const SizedBox(height: 24),

                // ── Articles ─────────────────────────────────────
                _SectionHeader(
                  title: '📚 Articles & Santé',
                  subtitle: 'Comprendre, prévenir, mieux dormir',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                ..._articles.map(
                  (a) => _ArticleCard(
                    article: a,
                    isDark: isDark,
                    onTap: () => _openArticle(context, a, isDark),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Exercices interactifs ─────────────────────────
                _SectionHeader(
                  title: '🧘 Exercices de respiration',
                  subtitle: 'Appuyez pour démarrer le minuteur guidé',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                ..._exercises.map(
                  (e) => _ExerciseCard(
                    exercise: e,
                    isDark: isDark,
                    onTap: () => _openExercise(context, e, isDark),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Plan nuit ────────────────────────────────────
                _SectionHeader(
                  title: '🌙 Plan nuit sans apnée',
                  subtitle: 'Les étapes essentielles avant le coucher',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _NightPlanCard(isDark: isDark),
                const SizedBox(height: 24),

                // ── Bonus ────────────────────────────────────────
                _SectionHeader(
                  title: '💡 Idées bonus',
                  subtitle: 'Aller plus loin',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _BonusChips(isDark: isDark),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: const PatientChatbotFAB(),
      bottomNavigationBar: _buildBottomNav(context, l10n),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      onTap: (i) {
        switch (i) {
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
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: l10n.homeLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_rounded),
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
    );
  }
}

// ── Catégories rapides ────────────────────────────────────────────

class _QuickCategories extends StatelessWidget {
  const _QuickCategories({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cats = [
      (icon: Icons.bedtime_rounded, label: 'Sommeil', color: _teal),
      (icon: Icons.air_rounded, label: 'Respiration', color: _coral),
      (
        icon: Icons.self_improvement_rounded,
        label: 'Méditation',
        color: _violet,
      ),
      (icon: Icons.favorite_rounded, label: 'Bien-être', color: _green),
    ];
    return Row(
      children: cats.map((c) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? c.color.withValues(alpha: 0.12)
                  : c.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(c.icon, color: c.color, size: 22),
                const SizedBox(height: 6),
                Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Section header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });
  final String title, subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ── Article card ──────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.isDark,
    required this.onTap,
  });
  final _ArticleItem article;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // → _openArticle() (bottom sheet)
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: article.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(article.icon, color: article.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: article.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: article.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        article.readTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// Exercise card
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
  });
  final _ExerciseItem exercise;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              exercise.color.withValues(alpha: isDark ? 0.18 : 0.06),
              exercise.color.withValues(alpha: isDark ? 0.08 : 0.02),
            ], // Dégradé de gauche à droite, s'estompant vers la transparence
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: exercise.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: exercise.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(exercise.icon, color: exercise.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 13,
                        color: exercise.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.duration,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: exercise.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: exercise.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          exercise.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: exercise.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: exercise.color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Night plan card ───────────────────────────────────────────────

class _NightPlanCard extends StatefulWidget {
  const _NightPlanCard({required this.isDark});
  final bool isDark;

  @override
  State<_NightPlanCard> createState() => _NightPlanCardState();
}

class _NightPlanCardState extends State<_NightPlanCard> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF121826) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: _teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routine du soir',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_checked.length}/${_nightPlan.length} complétées',
                      style: TextStyle(
                        fontSize: 11,
                        color: _checked.length == _nightPlan.length
                            ? AppColors.success
                            : (widget.isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
              if (_checked.length == _nightPlan.length)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ Complet',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _checked.length / _nightPlan.length,
              backgroundColor: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                _checked.length == _nightPlan.length
                    ? AppColors.success
                    : _teal,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          ..._nightPlan.asMap().entries.map((e) {
            final checked = _checked.contains(e.key);
            return GestureDetector(
              onTap: () => setState(() {
                checked ? _checked.remove(e.key) : _checked.add(e.key);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: checked
                      ? AppColors.success.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: checked
                        ? AppColors.success.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: checked ? AppColors.success : Colors.transparent,
                        border: Border.all(
                          color: checked
                              ? AppColors.success
                              : (widget.isDark
                                    ? Colors.white30
                                    : Colors.grey.shade400),
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: checked
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: checked
                              ? AppColors.success
                              : (widget.isDark
                                    ? Colors.white70
                                    : Colors.black87),
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Bonus chips ───────────────────────────────────────────────────

class _BonusChips extends StatelessWidget {
  const _BonusChips({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = [_teal, _coral, _violet, _green, _navy, _teal];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bonusIdeas.asMap().entries.map((e) {
        final color = colors[e.key % colors.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            e.value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BOTTOM SHEET ARTICLE
// ═══════════════════════════════════════════════════════════════════

void _openArticle(BuildContext context, _ArticleItem article, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: article.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(article.icon, color: article.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: article.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: article.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            article.readTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Résumé
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: article.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: article.color.withValues(alpha: 0.2)),
              ),
              child: Text(
                article.summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Points clés',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...article.points.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: article.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: article.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// BOTTOM SHEET EXERCICE — MINUTEUR GUIDÉ INTERACTIF
// ═══════════════════════════════════════════════════════════════════

void _openExercise(BuildContext context, _ExerciseItem exercise, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ExerciseSheet(exercise: exercise, isDark: isDark),
  );
}

class _ExerciseSheet extends StatefulWidget {
  const _ExerciseSheet({required this.exercise, required this.isDark});
  final _ExerciseItem exercise;
  final bool isDark;

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isRunning = false;
  bool _isFinished = false;
  int _secondsLeft = 0;
  Timer? _timer;
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // Durée fixe par étape (secondes)
  int get _stepDuration {
    const durations = [4, 4, 6, 4, 4, 6];
    if (_currentStep < durations.length) return durations[_currentStep];
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
    _breathCtrl.addStatusListener((status) {
      if (!mounted || !_isRunning) return;
      if (status == AnimationStatus.completed) _breathCtrl.reverse();
      if (status == AnimationStatus.dismissed) _breathCtrl.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathCtrl.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _isFinished = false;
      _currentStep = 0;
      _secondsLeft = _stepDuration;
    });
    _breathCtrl.forward();
    _scheduleTick();
  }

  void _stopExercise() {
    _timer?.cancel();
    _breathCtrl.stop();
    _breathCtrl.reset();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _currentStep = 0;
      _secondsLeft = 0;
    });
  }

  // ── UN SEUL timer périodique, toujours le même ─────────────────
  void _scheduleTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          // Décrémenter normalement
          _secondsLeft--;
        } else {
          // Étape terminée
          final nextStep = _currentStep + 1;
          if (nextStep < widget.exercise.steps.length) {
            // Passer à l'étape suivante
            _currentStep = nextStep;
            _secondsLeft = _stepDuration;
          } else {
            // Tout terminé
            _timer?.cancel();
            _isRunning = false;
            _isFinished = true;
            _breathCtrl.stop();
            _breathCtrl.reset();
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle + Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: exercise.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        exercise.icon,
                        color: exercise.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${exercise.duration} · ${exercise.tag}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Corps scrollable ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Cercle animé
                  SizedBox(
                    height: 170,
                    child: Center(
                      child: _isFinished
                          ? Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppColors.success,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.success,
                                size: 48,
                              ),
                            )
                          : _isRunning
                          ? AnimatedBuilder(
                              animation: _breathAnim,
                              builder: (_, __) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: _breathAnim.value * 1.3,
                                    child: Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: exercise.color.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: _breathAnim.value,
                                    child: Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: exercise.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: exercise.color.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$_secondsLeft',
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              color: exercise.color,
                                            ),
                                          ),
                                          Text(
                                            'sec',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: exercise.color.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: exercise.color.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: exercise.color.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                exercise.icon,
                                color: exercise.color.withValues(alpha: 0.6),
                                size: 40,
                              ),
                            ),
                    ),
                  ),

                  // Message terminé
                  if (_isFinished)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.celebration_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Exercice terminé ! Bravo 🎉',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Étape courante (si en cours)
                  if (_isRunning && !_isFinished)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Étape ${_currentStep + 1} / ${exercise.steps.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: exercise.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: exercise.color.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: exercise.color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              exercise.steps[_currentStep],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Liste de toutes les étapes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: exercise.steps.asMap().entries.map((e) {
                        final isActive = _isRunning && e.key == _currentStep;
                        final isDone = e.key < _currentStep || _isFinished;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? exercise.color.withValues(alpha: 0.08)
                                : isDone
                                ? AppColors.success.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? exercise.color.withValues(alpha: 0.3)
                                  : isDone
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? exercise.color
                                      : isDone
                                      ? AppColors.success
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                            : Colors.grey.shade100),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : Text(
                                          '${e.key + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isActive
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade500),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isActive
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                        : isDone
                                        ? AppColors.success
                                        : (isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Bouton ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? _stopExercise : _startExercise,
                icon: Icon(
                  _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  _isRunning
                      ? 'Arrêter'
                      : (_isFinished ? 'Recommencer' : 'Démarrer l\'exercice'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning
                      ? Colors.red.shade400
                      : exercise.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DONNÉES
// ═══════════════════════════════════════════════════════════════════

class _ArticleItem {
  final String title, category, readTime, summary;
  final List<String> points;
  final IconData icon;
  final Color color;
  const _ArticleItem({
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.points, // Points clés de l'article
    required this.icon,
    required this.color,
  });
}

class _ExerciseItem {
  final String title, duration, tag;
  final List<String> steps; // Étapes séquentielles de l'exercice
  final IconData icon;
  final Color color;
  const _ExerciseItem({
    required this.title,
    required this.duration,
    required this.tag,
    required this.steps,
    required this.icon,
    required this.color,
  });
}

const _articles = [
  // 4 articles de santé du sommeil
  _ArticleItem(
    title: 'Comprendre l\'apnée du sommeil',
    category: 'Apnée',
    readTime: '5 min',
    summary:
        'L\'apnée du sommeil correspond à des pauses respiratoires répétitives. Elle provoque des micro-réveils, une fatigue diurne et des risques cardiométaboliques si elle n\'est pas prise en charge.',
    points: [
      'Reconnaissez les signes : ronflement fort, fatigue, somnolence.',
      'Un diagnostic médical repose sur un examen du sommeil.',
      'Le traitement peut inclure PPC, orthèses ou hygiéno-diététique.',
    ],
    icon: Icons.bedtime_rounded,
    color: _teal,
  ),
  _ArticleItem(
    title: 'Passer une nuit plus calme',
    category: 'Conseils',
    readTime: '4 min',
    summary:
        'La régularité et l\'environnement sont vos meilleurs alliés. Des ajustements simples peuvent réduire les épisodes d\'apnée.',
    points: [
      'Dormez sur le côté et surélevez légèrement la tête.',
      'Évitez alcool et repas lourds en soirée.',
      'Gardez une température fraîche et une chambre sombre.',
    ],
    icon: Icons.nights_stay_rounded,
    color: _green,
  ),
  _ArticleItem(
    title: 'Mieux respirer avant le coucher',
    category: 'Respiration',
    readTime: '3 min',
    summary:
        'La respiration lente diminue le stress et facilite l\'endormissement.',
    points: [
      'Respiration 4-7-8 pendant 4 cycles.',
      'Cohérence cardiaque : 5 minutes, 6 respirations par minute.',
      'Garder un rythme doux et confortable.',
    ],
    icon: Icons.air_rounded,
    color: _coral,
  ),
  _ArticleItem(
    title: 'Hygiène du sommeil : les bases',
    category: 'Bien-être',
    readTime: '6 min',
    summary:
        'Une routine stable renforce l\'horloge biologique et diminue la dette de sommeil.',
    points: [
      'Heure de coucher et de réveil régulières.',
      'Limiter les écrans 60 minutes avant de dormir.',
      'Activité physique modérée en journée.',
    ],
    icon: Icons.self_improvement,
    color: _violet,
  ),
];

const _exercises = [
  // 3 exercices de respiration
  _ExerciseItem(
    title: 'Respiration abdominale',
    duration: '5 min',
    tag: 'Relaxation',
    steps: [
      'Installez-vous confortablement, dos droit.',
      'Posez une main sur le ventre, l\'autre sur la poitrine.',
      'Inspirez lentement par le nez pendant 4 secondes.',
      'Retenez votre souffle 4 secondes.',
      'Expirez doucement par la bouche pendant 6 secondes.',
      'Répétez ce cycle 6 fois.',
    ],
    icon: Icons.air_rounded,
    color: _teal,
  ),
  _ExerciseItem(
    title: 'Cohérence cardiaque 5-5',
    duration: '5 min',
    tag: 'Calme',
    steps: [
      'Asseyez-vous confortablement et fermez les yeux.',
      'Inspirez régulièrement pendant 5 secondes.',
      'Expirez pendant 5 secondes sans forcer.',
      'Maintenez ce rythme : 6 respirations / minute.',
      'Concentrez-vous sur la zone du cœur.',
      'Pratiquez 5 min, 3 fois par jour.',
    ],
    icon: Icons.favorite_rounded,
    color: _coral,
  ),
  _ExerciseItem(
    title: 'Body Scan complet',
    duration: '10 min',
    tag: 'Méditation',
    steps: [
      'Allongez-vous sur le dos, yeux fermés.',
      'Observez votre respiration naturelle.',
      'Portez attention à vos pieds — ressentez les tensions.',
      'Remontez jusqu\'aux mollets, genoux, cuisses.',
      'Continuez vers l\'abdomen, la poitrine, le dos.',
      'Terminez par le cou, la tête et le visage.',
    ],
    icon: Icons.self_improvement_rounded,
    color: _violet,
  ),
];

const _nightPlan = [
  // 5 étapes de la routine du soir
  'Arrêtez les écrans 60 minutes avant de dormir.',
  'Évitez alcool et café après 16h.',
  'Surélevez légèrement la tête ou dormez sur le côté.',
  'Ventilez la chambre et gardez 18 à 20 degrés.',
  'Pratiquez 5 minutes de respiration lente.',
];

const _bonusIdeas = [
  // 6 idées bonus
  '📖 Journal du sommeil',
  '🧘 Étirements doux',
  '💧 Hydratation en journée',
  '😌 Gestion du stress',
  '⚖️ Suivi du poids',
  '🎵 Bruits blancs légers',
];
