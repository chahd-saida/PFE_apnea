// lib/screens/patient/relaxation_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/widgets/youtube_player_sheet.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
const _night = Color(0xFF070B14);
const _surface = Color(0xFF0F1623);
const _card = Color(0xFF161D2E);
const _teal = Color(0xFF4DBDB8);
const _gold = Color(0xFFD4A843);
const _rose = Color(0xFFE05C7A);
const _lavender = Color(0xFF8B7FD4);

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedItem {
  final String title, subtitle, duration, tag, youtubeId;
  final Color accent;
  final IconData icon;
  const _FeaturedItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.tag,
    required this.youtubeId,
    required this.accent,
    required this.icon,
  });
  String get thumb => 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
}

class _AmbientItem {
  final String title, emoji, youtubeId, duration;
  final Color c1, c2;
  const _AmbientItem({
    required this.title,
    required this.emoji,
    required this.youtubeId,
    required this.duration,
    required this.c1,
    required this.c2,
  });
  String get thumb => 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction({
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
  });
}

class _ArticleData {
  final String title, category, readTime;
  final IconData icon;
  final Color color;
  const _ArticleData({
    required this.title,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

const _featured = [
  _FeaturedItem(
    title: 'Méditation guidée pour s\'endormir',
    subtitle: 'Libérez les tensions et glissez vers le sommeil',
    duration: '10 min',
    tag: 'Mindfulness',
    youtubeId: 'inpok4MKVLM',
    accent: _teal,
    icon: Icons.self_improvement,
  ),
  _FeaturedItem(
    title: 'Yoga doux du soir',
    subtitle: 'Séquence douce pour préparer le corps au repos',
    duration: '20 min',
    tag: 'Yoga',
    youtubeId: 'v7AYKMP6rOE',
    accent: Color(0xFF5B9E7A),
    icon: Icons.spa,
  ),
  _FeaturedItem(
    title: 'Respiration 4-7-8 anti-stress',
    subtitle: 'Réduisez l\'anxiété en quelques minutes',
    duration: '5 min',
    tag: 'Respiration',
    youtubeId: 'YRPh_GaiL8s',
    accent: _rose,
    icon: Icons.favorite,
  ),
];

const _ambients = [
  _AmbientItem(
    title: 'Forêt enchantée',
    emoji: '🌲',
    youtubeId: 'xNN7iTA57jM',
    duration: '3h',
    c1: Color(0xFF0D3B1F),
    c2: Color(0xFF2E7D52),
  ),
  _AmbientItem(
    title: 'Pluie apaisante',
    emoji: '🌧️',
    youtubeId: 'mPZkdNFkNps',
    duration: '2h',
    c1: Color(0xFF0A1E3D),
    c2: Color(0xFF1565C0),
  ),
  _AmbientItem(
    title: 'Vagues de l\'océan',
    emoji: '🌊',
    youtubeId: 'V-_O7nl0Ii0',
    duration: '2h',
    c1: Color(0xFF003338),
    c2: Color(0xFF00838F),
  ),
  _AmbientItem(
    title: 'Feu de cheminée',
    emoji: '🔥',
    youtubeId: 'L_LUpnjgPso',
    duration: '3h',
    c1: Color(0xFF3E0C00),
    c2: Color(0xFFBF360C),
  ),
  _AmbientItem(
    title: 'Bols tibétains',
    emoji: '🔔',
    youtubeId: 'oNkKcMqWkpk',
    duration: '30min',
    c1: Color(0xFF1A0A35),
    c2: Color(0xFF6A1B9A),
  ),
  _AmbientItem(
    title: 'Bruit blanc',
    emoji: '🤍',
    youtubeId: 'nMfPqeZjc2c',
    duration: '8h',
    c1: Color(0xFF1C2129),
    c2: Color(0xFF37474F),
  ),
];

const _quickActions = [
  _QuickAction(
    label: 'Vidéos',
    route: 'video',
    icon: Icons.video_library_rounded,
    color: _teal,
  ),
  _QuickAction(
    label: 'Méditation',
    route: 'meditation',
    icon: Icons.self_improvement,
    color: _lavender,
  ),
  _QuickAction(
    label: 'Articles',
    route: 'article',
    icon: Icons.menu_book_rounded,
    color: _gold,
  ),
];

const _articleData = [
  _ArticleData(
    title: 'L\'apnée du sommeil : comprendre pour agir',
    category: 'Santé',
    readTime: '5 min',
    icon: Icons.medical_information,
    color: _teal,
  ),
  _ArticleData(
    title: 'Hygiène du sommeil : 10 règles d\'or',
    category: 'Bien-être',
    readTime: '4 min',
    icon: Icons.bedtime,
    color: _lavender,
  ),
  _ArticleData(
    title: 'Stress et sommeil : briser le cercle',
    category: 'Psychologie',
    readTime: '6 min',
    icon: Icons.psychology,
    color: _rose,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RelaxationScreen extends StatefulWidget {
  const RelaxationScreen({super.key});

  @override
  State<RelaxationScreen> createState() => _RelaxationScreenState();
}

class _RelaxationScreenState extends State<RelaxationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _orbitCtrl;
  final _scroll = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _scroll.addListener(() => setState(() => _scrollOffset = _scroll.offset));
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _playVideo(
    String videoId,
    String title, {
    String? category,
    Color accent = _teal,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YoutubePlayerPage(
          videoId: videoId,
          title: title,
          category: category,
          accentColor: accent,
        ),
      ),
    );
  }

  void _playAmbient(_AmbientItem a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => YoutubeAmbientSheet(
        videoId: a.youtubeId,
        title: a.title,
        emoji: a.emoji,
        color1: a.c1,
        color2: a.c2,
      ),
    );
  }

  void _navigateToLibrary(String type) {
    switch (type) {
      case 'video':
        context.go(RouteNames.videoDetail('library'));
        break;
      case 'meditation':
        context.go(RouteNames.meditationDetail('library'));
        break;
      case 'article':
        context.go(RouteNames.articleDetail('library'));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _BackgroundOrbs(
            orbitCtrl: _orbitCtrl,
            pulseCtrl: _pulseCtrl,
            scrollOffset: _scrollOffset,
          ),
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              SliverToBoxAdapter(
                child: _HeroSection(
                  introCtrl: _introCtrl,
                  pulseCtrl: _pulseCtrl,
                ),
              ),
              SliverToBoxAdapter(
                child: _QuickActionsRow(
                  introCtrl: _introCtrl,
                  onTap: _navigateToLibrary,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '✨ À la une',
                  subtitle: 'Tapez pour lancer directement',
                ),
              ),
              SliverToBoxAdapter(
                child: _FeaturedCarousel(
                  featured: _featured,
                  onPlay: _playVideo,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '🎵 Ambiances sonores',
                  subtitle: 'Son réel · Lecture instantanée dans l\'app',
                ),
              ),
              SliverToBoxAdapter(
                child: _AmbiancesGrid(
                  ambients: _ambients,
                  onPlay: _playAmbient,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '📖 Bien-être & Santé',
                  subtitle: 'Articles pour mieux dormir',
                ),
              ),
              SliverToBoxAdapter(
                child: _ArticlesTeaser(articles: _articleData),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.nightlight_round, color: _teal, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Détente',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddSheet(),
        ),
        backgroundColor: _teal,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: _teal,
        unselectedItemColor: Colors.grey[600],
        elevation: 0,
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_rounded),
            label: 'Surveil.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_rounded),
            label: 'Détente',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Param.',
          ),
        ],
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND ORBS
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundOrbs extends StatelessWidget {
  final AnimationController orbitCtrl, pulseCtrl;
  final double scrollOffset;
  const _BackgroundOrbs({
    required this.orbitCtrl,
    required this.pulseCtrl,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: Listenable.merge([orbitCtrl, pulseCtrl]),
      builder: (_, __) {
        final t = orbitCtrl.value * 2 * math.pi;
        final p = pulseCtrl.value;
        return Stack(
          children: [
            Positioned(
              top: -80 - scrollOffset * 0.3,
              left: -60 + math.sin(t) * 20,
              child: _Orb(280, _teal.withValues(alpha: 0.06 + p * 0.03)),
            ),
            Positioned(
              top: 100 - scrollOffset * 0.1,
              right: -80 + math.cos(t) * 15,
              child: _Orb(220, _rose.withValues(alpha: 0.04 + p * 0.02)),
            ),
            Positioned(
              top: 350,
              left: w * 0.3,
              child: _Orb(160, _gold.withValues(alpha: 0.03)),
            ),
            Positioned(
              top: 600,
              left: -40,
              child: _Orb(200, _lavender.withValues(alpha: 0.04)),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AnimationController introCtrl, pulseCtrl;
  const _HeroSection({required this.introCtrl, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
        ? 'Bonne après-midi'
        : 'Bonne nuit';
    final sub = hour < 18
        ? 'Prenez un moment pour vous ressourcer'
        : 'Préparez votre corps au sommeil';

    return AnimatedBuilder(
      animation: Listenable.merge([introCtrl, pulseCtrl]),
      builder: (_, __) {
        final f = CurvedAnimation(
          parent: introCtrl,
          curve: Curves.easeOut,
        ).value.clamp(0.0, 1.0);
        return Opacity(
          opacity: f,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - f)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _teal.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: pulseCtrl,
                          builder: (_, __) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _teal,
                              boxShadow: [
                                BoxShadow(
                                  color: _teal.withValues(
                                    alpha: 0.5 + 0.3 * pulseCtrl.value,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Votre espace\nde sérénité',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _statChip('🌙', 'Sommeil', '7.2h'),
                      const SizedBox(width: 10),
                      _statChip('💆', 'Détente', '3 séances'),
                      const SizedBox(width: 10),
                      _statChip('🧘', 'Streak', '5 jours'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final AnimationController introCtrl;
  final void Function(String) onTap;
  const _QuickActionsRow({required this.introCtrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: introCtrl,
      builder: (_, __) {
        final f = CurvedAnimation(
          parent: introCtrl,
          curve: const Interval(0.3, 1, curve: Curves.easeOut),
        ).value;
        return Opacity(
          opacity: f,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Row(
              children: _quickActions.asMap().entries.map((e) {
                final q = e.value;
                final isLast = e.key == _quickActions.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 10),
                    child: _QBtn(action: q, onTap: () => onTap(q.route)),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _QBtn extends StatefulWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _QBtn({required this.action, required this.onTap});

  @override
  State<_QBtn> createState() => _QBtnState();
}

class _QBtnState extends State<_QBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: 1 - 0.04 * _c.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: a.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: a.color, size: 24),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  style: TextStyle(
                    color: a.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED CAROUSEL
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedCarousel extends StatefulWidget {
  final List<_FeaturedItem> featured;
  final void Function(
    String videoId,
    String title, {
    String? category,
    Color accent,
  })
  onPlay;
  const _FeaturedCarousel({required this.featured, required this.onPlay});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            onPageChanged: (i) => setState(() => _active = i),
            itemCount: widget.featured.length,
            itemBuilder: (_, i) {
              final f = widget.featured[i];
              return _FeaturedCard(
                item: f,
                isActive: i == _active,
                onTap: () => widget.onPlay(
                  f.youtubeId,
                  f.title,
                  category: f.tag,
                  accent: f.accent,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.featured.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _active == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _active == i ? _teal : Colors.grey[700],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FeaturedCard extends StatefulWidget {
  final _FeaturedItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _FeaturedCard({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard>
    with SingleTickerProviderStateMixin {
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
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: (widget.isActive ? 1.0 : 0.93) - 0.02 * _c.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: item.accent.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _card,
                      child: Icon(
                        item.icon,
                        color: item.accent.withValues(alpha: 0.4),
                        size: 60,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _night.withValues(alpha: 0.96),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              color: item.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: item.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Lancer · ${item.duration}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIANCES GRID
// ─────────────────────────────────────────────────────────────────────────────

class _AmbiancesGrid extends StatelessWidget {
  final List<_AmbientItem> ambients;
  final void Function(_AmbientItem) onPlay;
  const _AmbiancesGrid({required this.ambients, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AmbientTile(
                  item: ambients[0],
                  tall: true,
                  onPlay: onPlay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AmbientTile(
                  item: ambients[1],
                  tall: true,
                  onPlay: onPlay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AmbientTile(
                  item: ambients[2],
                  tall: false,
                  onPlay: onPlay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmbientTile(
                  item: ambients[3],
                  tall: false,
                  onPlay: onPlay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmbientTile(
                  item: ambients[4],
                  tall: false,
                  onPlay: onPlay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AmbientTile extends StatefulWidget {
  final _AmbientItem item;
  final bool tall;
  final void Function(_AmbientItem) onPlay;
  const _AmbientTile({
    required this.item,
    required this.tall,
    required this.onPlay,
  });

  @override
  State<_AmbientTile> createState() => _AmbientTileState();
}

class _AmbientTileState extends State<_AmbientTile>
    with SingleTickerProviderStateMixin {
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
    final a = widget.item;
    final h = widget.tall ? 140.0 : 100.0;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onPlay(a);
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Transform.scale(
            scale: 1 - 0.04 * _c.value,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: a.c1.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      a.thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [a.c1, a.c2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            a.c1.withValues(alpha: 0.15),
                            a.c1.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                a.emoji,
                                style: TextStyle(
                                  fontSize: widget.tall ? 22 : 18,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  a.duration,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.tall ? 13 : 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Écouter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARTICLES TEASER
// ─────────────────────────────────────────────────────────────────────────────

class _ArticlesTeaser extends StatelessWidget {
  final List<_ArticleData> articles;
  const _ArticlesTeaser({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: articles.map((a) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: a.color, size: 20),
              ),
              title: Text(
                a.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.category,
                      style: TextStyle(
                        color: a.color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    a.readTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey,
              ),
              onTap: () => context.go(RouteNames.articleDetail(a.title)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddSheet extends StatelessWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajouter du contenu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enrichissez votre espace détente',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _sheetBtn(
                  context,
                  '🧘',
                  'Méditation',
                  'Créer une séance',
                  _lavender,
                  RouteNames.createMeditation,
                ),
                const SizedBox(width: 12),
                _sheetBtn(
                  context,
                  '🎬',
                  'Vidéo YouTube',
                  'Ajouter depuis YouTube',
                  _teal,
                  RouteNames.addVideo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sheetBtnWide(
              context,
              '📖',
              'Article bien-être',
              'Partager des conseils santé',
              _gold,
              RouteNames.addArticle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(
    BuildContext ctx,
    String emoji,
    String title,
    String sub,
    Color color,
    String route,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          ctx.go(route);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetBtnWide(
    BuildContext ctx,
    String emoji,
    String title,
    String sub,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        ctx.go(route);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 13),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKWARD-COMPAT STUBS (used in relaxation_screen imports elsewhere)
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const AnimatedCard({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: onTap, child: child);
}

class AnimatedFeaturedCard extends StatelessWidget {
  final String title, duration, imagePath;
  final VoidCallback onTap;
  final int animationDelay;
  const AnimatedFeaturedCard({
    super.key,
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 90,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
}

class AnimatedAmbientCard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onTap;
  final AnimationController pulseController;
  final bool isPlaying;
  const AnimatedAmbientCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
    required this.pulseController,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
