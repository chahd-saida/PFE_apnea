import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';

class RelaxationScreen extends StatefulWidget {
  const RelaxationScreen({super.key});

  @override
  State<RelaxationScreen> createState() => _RelaxationScreenState();
}

class _RelaxationScreenState extends State<RelaxationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  bool _isPlaying = false;
  String _currentlyPlaying = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _playAmbientSound(String title) {
    setState(() {
      _isPlaying = true;
      _currentlyPlaying = title;
    });
    // Here you would integrate with your audio player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('▶️ Lecture de $title'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Arrêter',
          onPressed: () => _stopPlayback(),
        ),
      ),
    );
  }

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
      _currentlyPlaying = '';
    });
  }

  void _navigateToDetail(String type, String title) {
    // Navigate to appropriate detail screen based on type
    switch (type) {
      case 'meditation':
        context.go(RouteNames.meditationDetail(title));
        break;
      case 'video':
        context.go(RouteNames.videoDetail(title));
        break;
      case 'article':
        context.go(RouteNames.articleDetail(title));
        break;
    }
  }

  void _showAddOptions() {
    final themeProvider = context.read<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ajouter du contenu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.music_note, color: Color(0xFFE91E8C)),
                title: const Text('Méditation personnalisée'),
                subtitle: const Text('Créer une séance sur mesure'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteNames.createMeditation);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library,
                  color: Color(0xFFE91E8C),
                ),
                title: const Text('Vidéo relaxante'),
                subtitle: const Text('Ajouter une vidéo apaisante'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteNames.addVideo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article, color: Color(0xFFE91E8C)),
                title: const Text('Article bien-être'),
                subtitle: const Text('Partager des conseils'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteNames.addArticle);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : AppTheme.background,
      appBar: AppBar(title: const Text('🌿 Détente'), centerTitle: true),
      body: Column(
        children: [
          // Mini player at top when something is playing
          if (_isPlaying)
            Container(
              margin: const EdgeInsets.all(AppTheme.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: AppTheme.sm,
              ),
              decoration: AppTheme.getCardDecoration().copyWith(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentlyPlaying,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'En cours de lecture...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Arrêter la lecture',
                    child: IconButton(
                      onPressed: _stopPlayback,
                      icon: const Icon(Icons.stop, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting message
                  FadeTransition(
                    opacity: _fadeController,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.md),
                        decoration: AppTheme.getCardDecoration().copyWith(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.1),
                              AppTheme.secondary.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: AppTheme.sm),
                            const Expanded(
                              child: Text(
                                'Bonne détente, Marie 🌙',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.lg),

                  // Section 1 - Featured Content
                  _buildFeaturedSection(),
                  const SizedBox(height: AppTheme.xl),

                  // Section 2 - Ambiances
                  _buildAmbiancesSection(),
                  const SizedBox(height: AppTheme.xl),

                  // Section 3 - Articles
                  _buildArticlesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Semantics(
          button: true,
          label: 'Ajouter du contenu',
          child: FloatingActionButton.extended(
            onPressed: _showAddOptions,
            backgroundColor: AppTheme.secondary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            elevation: 4,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode
            ? const Color(0xFF1E1E1E)
            : AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: isDarkMode
            ? const Color(0xFF90A4AE)
            : const Color(0xFF90A4AE),
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
        currentIndex: 3, // Highlight 'Détente'
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

  Widget _buildFeaturedSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, color: AppTheme.primary, size: 24),
                const SizedBox(width: AppTheme.sm),
                const Text('Contenu', style: AppTheme.screenTitle),
              ],
            ),
            const SizedBox(height: 16),

            // Featured Card 1
            AnimatedFeaturedCard(
              title: 'Méditation guidée pour s\'endormir',
              duration: '12 min',
              imagePath: 'assets/images/meditation.jpg',
              onTap: () => _navigateToDetail(
                'meditation',
                'Méditation guidée pour s\'endormir',
              ),
              animationDelay: 0,
            ),
            const SizedBox(height: 16),

            // Featured Card 2
            AnimatedFeaturedCard(
              title: 'Respiration relaxante avec musique douce',
              duration: '8 min',
              imagePath: 'assets/images/breathing.jpg',
              onTap: () => _navigateToDetail(
                'meditation',
                'Respiration relaxante avec musique douce',
              ),
              animationDelay: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbiancesSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.surround_sound,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.sm),
                const Text('🎵 Ambiances', style: AppTheme.sectionHeader),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AnimatedAmbientCard(
                    title: 'Forêt enchantée',
                    backgroundColor: const Color(0xFF2E7D5E),
                    icon: Icons.forest,
                    onTap: () => _playAmbientSound('Forêt enchantée'),
                    pulseController: _pulseController,
                    isPlaying: _currentlyPlaying == 'Forêt enchantée',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedAmbientCard(
                    title: 'Pluie en forêt',
                    backgroundColor: const Color(0xFF1A5276),
                    icon: Icons.water_drop,
                    onTap: () => _playAmbientSound('Pluie en forêt'),
                    pulseController: _pulseController,
                    isPlaying: _currentlyPlaying == 'Pluie en forêt',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: AppTheme.primary, size: 24),
                const SizedBox(width: AppTheme.sm),
                const Text(
                  '📚 Articles bien-être',
                  style: AppTheme.sectionHeader,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Article Card 1
            AnimatedCard(
              child: Card(
                elevation: 2,
                child: ListTile(
                  leading: Semantics(
                    label: 'Article sur le sommeil',
                    child: const Icon(Icons.article, color: Colors.blueAccent),
                  ),
                  title: const Text('Améliorer son sommeil naturellement'),
                  subtitle: const Text('Conseils et astuces'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToDetail(
                    'article',
                    'Améliorer son sommeil naturellement',
                  ),
                ),
              ),
              onTap: () => _navigateToDetail(
                'article',
                'Améliorer son sommeil naturellement',
              ),
            ),
            const SizedBox(height: 12),

            // Article Card 2
            AnimatedCard(
              child: Card(
                elevation: 2,
                child: ListTile(
                  leading: Semantics(
                    label: 'Article sur la gestion du stress',
                    child: const Icon(Icons.article, color: Colors.blueAccent),
                  ),
                  title: const Text(
                    'Gestion du stress pour une meilleure nuit',
                  ),
                  subtitle: const Text('Techniques de relaxation'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToDetail(
                    'article',
                    'Gestion du stress pour une meilleure nuit',
                  ),
                ),
              ),
              onTap: () => _navigateToDetail(
                'article',
                'Gestion du stress pour une meilleure nuit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedCard({super.key, required this.child, required this.onTap});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class AnimatedFeaturedCard extends StatefulWidget {
  final String title;
  final String duration;
  final String imagePath;
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
  State<AnimatedFeaturedCard> createState() => _AnimatedFeaturedCardState();
}

class _AnimatedFeaturedCardState extends State<AnimatedFeaturedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Delayed entrance animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(widget.imagePath),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              // Fallback to placeholder if image not found
                            },
                          ),
                        ),
                        child: widget.imagePath.startsWith('assets/')
                            ? null
                            : Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: 40,
                              ),
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

class AnimatedAmbientCard extends StatefulWidget {
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
  State<AnimatedAmbientCard> createState() => _AnimatedAmbientCardState();
}

class _AnimatedAmbientCardState extends State<AnimatedAmbientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, widget.pulseController]),
        builder: (context, child) {
          final pulseValue = widget.isPlaying
              ? 1.0 + (0.05 * widget.pulseController.value)
              : 1.0;

          return Transform.scale(
            scale: _scaleAnimation.value * pulseValue,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.backgroundColor,
                      widget.backgroundColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.3),
                      blurRadius: widget.isPlaying ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background illustration
                    Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 60,
                      ),
                    ),

                    // Title
                    Positioned(
                      bottom: 16,
                      left: 12,
                      right: 12,
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Play button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Semantics(
                        button: true,
                        label: 'Lecture de ${widget.title}',
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.backgroundColor,
                            size: 20,
                          ),
                        ),
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
