// lib/screens/shared/help_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:apnea_project/theme/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _faqItems = [


    // ── Surveillance ─────────────────────────────────────────────────────────
    {
      'category': 'Surveillance',
      'icon': Icons.monitor_heart_rounded,
      'color': 0xFFEF5350,
      'question': 'Comment interpréter mon score de sommeil ?',
      'answer':
          'Le score est calculé sur 100 points selon :\n\n'
          '🟢 80–100 : Excellent — sommeil réparateur, peu ou pas d\'apnées.\n'
          '🟡 50–79  : Moyen — quelques perturbations, consultez votre médecin.\n'
          '🔴 0–49   : Mauvais — apnées fréquentes, consultation recommandée.\n\n'
          'Les facteurs pris en compte : durée, SpO₂ moyenne, fréquence cardiaque, nombre d\'apnées.',
    },
    {
      'category': 'Surveillance',
      'icon': Icons.monitor_heart_rounded,
      'color': 0xFFEF5350,
      'question': 'Comment démarrer une session de surveillance ?',
      'answer':
          '1. Portez le capteur correctement (doigt sur MAX30102, électrodes ECG collées).\n'
          '2. Ouvrez l\'écran "Surveillance" depuis le menu bas.\n'
          '3. Appuyez sur le bouton bleu "Démarrer la surveillance".\n'
          '4. En l\'absence de capteur, le mode simulation démarre automatiquement.\n'
          '5. Appuyez sur "Arrêter" pour terminer et sauvegarder la session.',
    },

    // ── Alertes ───────────────────────────────────────────────────────────────
    {
      'category': 'Alertes',
      'icon': Icons.notifications_active_rounded,
      'color': 0xFFF57C00,
      'question': 'Que faire en cas d\'alerte critique ?',
      'answer':
          '⚠️ En cas d\'alerte CRITIQUE (SpO₂ < 90% ou apnées sévères) :\n\n'
          '1. Ne paniquez pas — réveillez la personne surveillée.\n'
          '2. Contactez immédiatement votre médecin traitant.\n'
          '3. Si la personne est inconsciente ou en détresse respiratoire, '
          'appelez le 190 (SAMU Tunisie) ou les services d\'urgence locaux.\n'
          '4. Conservez l\'historique des alertes pour montrer au médecin.',
    },
    {
      'category': 'Alertes',
      'icon': Icons.notifications_active_rounded,
      'color': 0xFFF57C00,
      'question': 'Comment configurer les notifications d\'alertes ?',
      'answer':
          'Allez dans Paramètres > Notifications :\n\n'
          '• Activez/désactivez les alertes apnée.\n'
          '• Configurez les rappels de surveillance.\n'
          '• Assurez-vous que l\'application a la permission d\'envoyer des notifications '
          'dans les paramètres système de votre téléphone.',
    },

    // ── Données ───────────────────────────────────────────────────────────────
    {
      'category': 'Données',
      'icon': Icons.bar_chart_rounded,
      'color': 0xFF1E3A8A,
      'question': 'Comment accéder à mon historique ?',
      'answer':
          'Appuyez sur "Historique" dans la barre de navigation du bas.\n\n'
          '• Onglet "Historique des nuits" : liste de toutes vos sessions avec score et apnées.\n'
          '• Onglet "Statistiques" : vue d\'ensemble (score moyen, total apnées, évolution).\n'
          '• Appuyez sur une nuit pour voir le détail complet.',
    },
    {
      'category': 'Données',
      'icon': Icons.bar_chart_rounded,
      'color': 0xFF1E3A8A,
      'question': 'Mes données sont-elles sécurisées ?',
      'answer':
          'Oui. Toutes vos données médicales sont :\n\n'
          '🔒 Chiffrées en transit (HTTPS/TLS).\n'
          '🔒 Stockées sur Firebase (Google Cloud), certifié ISO 27001.\n'
          '🔒 Accessibles uniquement par vous et votre médecin assigné.\n'
          '🔒 Jamais vendues à des tiers.\n\n'
          'Consultez notre politique de confidentialité pour plus de détails.',
    },

    // ── Médecin ───────────────────────────────────────────────────────────────
    {
      'category': 'Médecin',
      'icon': Icons.medical_services_rounded,
      'color': 0xFF7C3AED,
      'question': 'Comment contacter mon médecin via l\'application ?',
      'answer':
          'Depuis votre tableau de bord :\n\n'
          '1. Appuyez sur "Messages" dans les actions rapides.\n'
          '2. Votre médecin assigné apparaît dans la liste des conversations.\n'
          '3. Envoyez un message texte ou partagez un rapport de nuit directement.',
    },
    {
      'category': 'Médecin',
      'icon': Icons.medical_services_rounded,
      'color': 0xFF7C3AED,
      'question': 'Comment partager mes données avec mon médecin ?',
      'answer':
          'Vos données sont automatiquement visibles par votre médecin assigné.\n\n'
          'Pour partager un rapport PDF :\n'
          '1. Allez dans Historique > sélectionnez une nuit.\n'
          '2. Appuyez sur l\'icône de partage en haut à droite.\n'
          '3. Choisissez "Envoyer au médecin" ou exportez le PDF.',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaq {
    if (_searchQuery.isEmpty) return _faqItems;
    final q = _searchQuery.toLowerCase();
    return _faqItems.where((item) =>
        (item['question'] as String).toLowerCase().contains(q) ||
        (item['answer'] as String).toLowerCase().contains(q) ||
        (item['category'] as String).toLowerCase().contains(q)).toList();
  }

  List<String> get _categories {
    final seen = <String>{};
    return _faqItems
        .map((e) => e['category'] as String)
        .where((c) => seen.add(c))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: _buildSearchBar(isDark),
            ),
          ),
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _buildCategoryChips(isDark),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: _buildFaqList(isDark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _buildContactSection(isDark),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── AppBar personnalisé ────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1A4FA8), Color(0xFF4DBDB8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Aide & FAQ',
                        style: TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text('Trouvez rapidement une réponse',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Barre de recherche ────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _expandedIndex = null;
        }),
        style: TextStyle(fontSize: 14,
            color: isDark ? Colors.white : AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Rechercher dans l\'aide...',
          hintStyle: TextStyle(fontSize: 13,
              color: isDark ? Colors.white38 : AppColors.textLight),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textMedium),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textMedium),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Chips catégories ──────────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    final categoryColors = {
      'Surveillance': const Color(0xFFEF5350),
      'Alertes':      const Color(0xFFF57C00),
      'Données':      const Color(0xFF1E3A8A),
      'Médecin':      const Color(0xFF7C3AED),
    };
    final categoryIcons = {
      'Surveillance': Icons.monitor_heart_rounded,
      'Alertes':      Icons.notifications_active_rounded,
      'Données':      Icons.bar_chart_rounded,
      'Médecin':      Icons.medical_services_rounded,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _categories.map((cat) {
        final color = categoryColors[cat] ?? AppColors.primary;
        final icon  = categoryIcons[cat] ?? Icons.help_outline;
        final count = _faqItems.where((e) => e['category'] == cat).length;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: color)),
            const SizedBox(width: 6),
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(child: Text('$count',
                  style: const TextStyle(fontSize: 9, color: Colors.white,
                      fontWeight: FontWeight.w800))),
            ),
          ]),
        );
      }).toList()),
    );
  }

  // ── Liste FAQ ─────────────────────────────────────────────────────────────
  Widget _buildFaqList(bool isDark) {
    final items = _filteredFaq;

    if (items.isEmpty) {
      return SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.search_off_rounded, size: 48,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 12),
          Text('Aucun résultat pour "$_searchQuery"',
              style: TextStyle(fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textMedium)),
        ]),
      ));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item     = items[index];
          final color    = Color(item['color'] as int);
          final isExpanded = _expandedIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161D2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded
                    ? color.withValues(alpha: 0.4)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06)),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpanded
                      ? color.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isExpanded ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(children: [
                // En-tête
                InkWell(
                  onTap: () => setState(() =>
                      _expandedIndex = isExpanded ? null : index),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item['category'] as String,
                                  style: TextStyle(fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ),
                            const SizedBox(height: 4),
                            Text(item['question'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.textDark)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: isExpanded ? color : AppColors.textMedium,
                            size: 22),
                      ),
                    ]),
                  ),
                ),

                // Contenu déroulé
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                            color: color.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.08 : 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(item['answer'] as String,
                              style: TextStyle(
                                  fontSize: 13, height: 1.7,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textBody)),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ]),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  // ── Section contact ───────────────────────────────────────────────────────
  Widget _buildContactSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Contact Support',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A365D))),
        ]),
        const SizedBox(height: 6),
        Text('Notre équipe est disponible du lundi au vendredi, 9h–18h.',
            style: TextStyle(fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textMedium)),
        const SizedBox(height: 16),

        _buildContactTile(
          icon: Icons.email_outlined,
          color: AppColors.primary,
          label: 'Email',
          value: 'support@sleepapneadetect.com',
          isDark: isDark,
          onTap: () => _launchUrl('mailto:support@sleepapneadetect.com'),
        ),
        const SizedBox(height: 10),
        _buildContactTile(
          icon: Icons.phone_outlined,
          color: AppColors.success,
          label: 'Téléphone',
          value: '+216 XX XX XX XX',
          isDark: isDark,
          onTap: () => _launchUrl('tel:+21600000000'),
        ),
        const SizedBox(height: 10),
        _buildContactTile(
          icon: Icons.language_rounded,
          color: const Color(0xFF7C3AED),
          label: 'Site web',
          value: 'www.sleepapneadetect.com',
          isDark: isDark,
          onTap: () => _launchUrl('https://www.sleepapneadetect.com'),
        ),
      ]),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600, color: color)),
              Text(value, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textDark)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, size: 13,
              color: isDark ? Colors.white24 : Colors.black26),
        ]),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}