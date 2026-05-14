import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

const _headerNavy = Color(0xFF0F1F3A);
const _headerTeal = Color(0xFF1B9C95);
const _cardBg = Color(0xFFF6F8FF);

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : AppColors.background,
      appBar: AppBar(
        title: const Text('Bien-etre & sante'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0D1117) : _headerNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _HeroHeader(isDark: isDark),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Articles sante & apnee du sommeil',
            subtitle: 'Comprendre, prevenir, mieux dormir',
          ),
          const SizedBox(height: 10),
          ..._articles.map(
            (article) => _ArticleCard(
              article: article,
              isDark: isDark,
              onTap: () => _openArticle(context, article, isDark),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Meditation & respiration guidee',
            subtitle: 'Routines courtes pour se detendre',
          ),
          const SizedBox(height: 10),
          ..._exercises.map(
            (exercise) => _ExerciseCard(
              exercise: exercise,
              isDark: isDark,
              onTap: () => _openExercise(context, exercise, isDark),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Plan pour une nuit sans apnee',
            subtitle: 'Les etapes essentielles avant le coucher',
          ),
          const SizedBox(height: 10),
          _PlanCard(isDark: isDark),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Idees bonus',
            subtitle: 'Aller plus loin sur la sante du sommeil',
          ),
          const SizedBox(height: 10),
          _BonusIdeas(isDark: isDark),
        ],
      ),
      floatingActionButton: const PatientChatbotFAB(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.homeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l10n.historyLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monitor_heart),
            label: l10n.monitoringShortLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.spa),
            label: l10n.relaxationLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsShortLabel,
          ),
        ],
        currentIndex: 3,
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
}

class _HeroHeader extends StatelessWidget {
  final bool isDark;
  const _HeroHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF101828), Color(0xFF0B3A3A)]
              : const [_headerNavy, _headerTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bien-etre & sante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Articles pratiques, conseils et routines pour mieux dormir.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final _ArticleItem article;
  final bool isDark;
  final VoidCallback onTap;
  const _ArticleCard({
    required this.article,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2B) : _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: article.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(article.icon, color: article.color),
        ),
        title: Text(
          article.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${article.category} · ${article.readTime}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _ExerciseItem exercise;
  final bool isDark;
  final VoidCallback onTap;
  const _ExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: exercise.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(exercise.icon, color: exercise.color),
        ),
        title: Text(
          exercise.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${exercise.duration} · ${exercise.tag}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: const Icon(Icons.play_arrow_rounded),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool isDark;
  const _PlanCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: _nightPlan.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BonusIdeas extends StatelessWidget {
  final bool isDark;
  const _BonusIdeas({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bonusIdeas.map((idea) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            idea,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
}

void _openArticle(BuildContext context, _ArticleItem article, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${article.category} · ${article.readTime}',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                article.summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Points cles',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...article.points.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _openExercise(BuildContext context, _ExerciseItem exercise, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${exercise.duration} · ${exercise.tag}',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 12),
            ...exercise.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}

class _ArticleItem {
  final String title;
  final String category;
  final String readTime;
  final String summary;
  final List<String> points;
  final IconData icon;
  final Color color;
  const _ArticleItem({
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.points,
    required this.icon,
    required this.color,
  });
}

class _ExerciseItem {
  final String title;
  final String duration;
  final String tag;
  final List<String> steps;
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
  _ArticleItem(
    title: 'Comprendre l\'apnee du sommeil',
    category: 'Apnee',
    readTime: '5 min',
    summary:
        'L\'apnee du sommeil correspond a des pauses respiratoires repetitives. '
        'Elle provoque des micro-reveils, une fatigue diurne et des risques '
        'cardiometaboliques si elle n\'est pas prise en charge.',
    points: [
      'Reconnaissez les signes: ronflement fort, fatigue, somnolence.',
      'Un diagnostic medical repose sur un examen du sommeil.',
      'Le traitement peut inclure PPC, ortheses ou hygieno-dietetique.',
    ],
    icon: Icons.bedtime_rounded,
    color: Color(0xFF4DBDB8),
  ),
  _ArticleItem(
    title: 'Passer une nuit plus calme',
    category: 'Conseils',
    readTime: '4 min',
    summary:
        'La regularite et l\'environnement sont vos meilleurs allies. '
        'Des ajustements simples peuvent reduire les episodes d\'apnee.',
    points: [
      'Dormez sur le cote et sur-elevez legerement la tete.',
      'Evitez alcool et repas lourds en soiree.',
      'Gardez une temperature fraiche et une chambre sombre.',
    ],
    icon: Icons.nights_stay_rounded,
    color: Color(0xFF5B9E7A),
  ),
  _ArticleItem(
    title: 'Mieux respirer avant le coucher',
    category: 'Respiration',
    readTime: '3 min',
    summary:
        'La respiration lente diminue le stress et facilite l\'endormissement.',
    points: [
      'Respiration 4-7-8 pendant 4 cycles.',
      'Cohérence cardiaque: 5 minutes, 6 respirations par minute.',
      'Garder un rythme doux et confortable.',
    ],
    icon: Icons.air_rounded,
    color: Color(0xFFE05C7A),
  ),
  _ArticleItem(
    title: 'Hygiene du sommeil: les bases',
    category: 'Bien-etre',
    readTime: '6 min',
    summary:
        'Une routine stable renforce l\'horloge biologique et diminue la dette de sommeil.',
    points: [
      'Heure de coucher et de reveil regulieres.',
      'Limiter les ecrans 60 minutes avant de dormir.',
      'Activite physique moderee en journee.',
    ],
    icon: Icons.self_improvement,
    color: Color(0xFF8B7FD4),
  ),
];

const _exercises = [
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
    color: Color(0xFF4DBDB8),
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
    icon: Icons.favorite,
    color: Color(0xFFE53E3E),
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
    icon: Icons.self_improvement,
    color: Color(0xFF7C3AED),
  ),
];

const _nightPlan = [
  'Arretez les ecrans 60 minutes avant de dormir.',
  'Evitez alcool et cafe apres 16h.',
  'Sur-elevez legerement la tete ou dormez sur le cote.',
  'Ventilez la chambre et gardez 18 a 20 degres.',
  'Pratiquez 5 minutes de respiration lente.',
];

const _bonusIdeas = [
  'Journal du sommeil',
  'Etirements doux',
  'Hydratation en journee',
  'Gestion du stress',
  'Suivi du poids',
  'Bruits blancs legers',
];
