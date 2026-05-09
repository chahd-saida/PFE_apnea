// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/widgets/youtube_player_sheet.dart';
import 'package:apnea_project/widgets/patient_chatbot_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PERSISTENT STORE for custom videos added by user
// ─────────────────────────────────────────────────────────────────────────────
class _VideoStore {
  static final _VideoStore _i = _VideoStore._();
  factory _VideoStore() => _i;
  _VideoStore._();
  final List<_VideoItem> custom = [];
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _VideoItem {
  final String title;
  final String description;
  final String duration;
  final String youtubeId;
  final String thumbnailUrl;
  final String category;
  final bool isCustom;

  _VideoItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.youtubeId,
    required this.thumbnailUrl,
    required this.category,
    this.isCustom = false,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$youtubeId';
}

class _AmbientItem {
  final String title;
  final String emoji;
  final String youtubeId;
  final String thumbnailUrl;
  final Color color1;
  final Color color2;
  final IconData icon;
  final String duration;
  const _AmbientItem({
    required this.title, required this.emoji, required this.youtubeId,
    required this.thumbnailUrl, required this.color1, required this.color2,
    required this.icon, required this.duration,
  });
  String get watchUrl => 'https://www.youtube.com/watch?v=$youtubeId';
}

class _MeditationItem {
  final String title, description, duration;
  final IconData icon;
  final Color color;
  final List<String> steps;
  const _MeditationItem({
    required this.title, required this.description, required this.duration,
    required this.icon, required this.color, required this.steps,
  });
}

class _ArticleItem {
  final String title, category, readTime, summary;
  final List<_ArticleSection> sections;
  final IconData icon;
  final Color color;
  const _ArticleItem({
    required this.title, required this.category, required this.readTime,
    required this.summary, required this.sections, required this.icon, required this.color,
  });
}

class _ArticleSection {
  final String heading, body;
  const _ArticleSection(this.heading, this.body);
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

final List<_VideoItem> _defaultVideos = [
  _VideoItem(title: 'Relaxation guidée — Pleine conscience', description: 'Session de 10 min pour calmer l\'esprit.', duration: '10:24', youtubeId: 'inpok4MKVLM', thumbnailUrl: 'https://img.youtube.com/vi/inpok4MKVLM/hqdefault.jpg', category: 'Mindfulness'),
  _VideoItem(title: 'Sons de la forêt — 3h apaisantes', description: 'Forêt tranquille pour se détendre.', duration: '3:00:00', youtubeId: 'xNN7iTA57jM', thumbnailUrl: 'https://img.youtube.com/vi/xNN7iTA57jM/hqdefault.jpg', category: 'Nature'),
  _VideoItem(title: 'Yoga doux pour mieux dormir', description: 'Séquence yoga pour préparer au sommeil.', duration: '20:15', youtubeId: 'v7AYKMP6rOE', thumbnailUrl: 'https://img.youtube.com/vi/v7AYKMP6rOE/hqdefault.jpg', category: 'Yoga'),
  _VideoItem(title: 'Musique relaxante — Piano & Pluie', description: 'Musique douce pour sommeil et détente.', duration: '3:00:00', youtubeId: '1ZYbU82GVz4', thumbnailUrl: 'https://img.youtube.com/vi/1ZYbU82GVz4/hqdefault.jpg', category: 'Musique'),
  _VideoItem(title: 'Respiration 4-7-8 anti-stress', description: 'Technique pour réduire l\'anxiété.', duration: '5:32', youtubeId: 'YRPh_GaiL8s', thumbnailUrl: 'https://img.youtube.com/vi/YRPh_GaiL8s/hqdefault.jpg', category: 'Respiration'),
  _VideoItem(title: 'ASMR — Sons doux pour s\'endormir', description: 'Sons relaxants pour l\'endormissement.', duration: '1:00:00', youtubeId: 'NT3ej_jKEDs', thumbnailUrl: 'https://img.youtube.com/vi/NT3ej_jKEDs/hqdefault.jpg', category: 'ASMR'),
  _VideoItem(title: 'Méditation guidée du matin', description: 'Commencez avec clarté et sérénité.', duration: '15:00', youtubeId: 'U9YKY7fdwyg', thumbnailUrl: 'https://img.youtube.com/vi/U9YKY7fdwyg/hqdefault.jpg', category: 'Mindfulness'),
  _VideoItem(title: 'Bruit blanc — Sommeil profond 8h', description: 'Son blanc pour masquer les bruits.', duration: '8:00:00', youtubeId: 'nMfPqeZjc2c', thumbnailUrl: 'https://img.youtube.com/vi/nMfPqeZjc2c/hqdefault.jpg', category: 'Sommeil'),
  _VideoItem(title: 'Vagues de l\'océan — 2h relaxation', description: 'Laissez-vous porter par les vagues.', duration: '2:00:00', youtubeId: 'V-_O7nl0Ii0', thumbnailUrl: 'https://img.youtube.com/vi/V-_O7nl0Ii0/hqdefault.jpg', category: 'Nature'),
  _VideoItem(title: 'Stretching doux avant le coucher', description: 'Étirements légers pour relâcher les tensions.', duration: '10:00', youtubeId: 'g_tea8ZNk5A', thumbnailUrl: 'https://img.youtube.com/vi/g_tea8ZNk5A/hqdefault.jpg', category: 'Yoga'),
  _VideoItem(title: 'Méditation zen — Bols tibétains', description: 'Sons de bols tibétains pour la méditation.', duration: '30:00', youtubeId: 'oNkKcMqWkpk', thumbnailUrl: 'https://img.youtube.com/vi/oNkKcMqWkpk/hqdefault.jpg', category: 'Mindfulness'),
  _VideoItem(title: 'Pluie sur les feuilles — Nature', description: 'Son de pluie douce en forêt.', duration: '1:00:00', youtubeId: 'mPZkdNFkNps', thumbnailUrl: 'https://img.youtube.com/vi/mPZkdNFkNps/hqdefault.jpg', category: 'Nature'),
];

const List<_AmbientItem> _ambients = [
  _AmbientItem(title: 'Forêt enchantée', emoji: '🌲', youtubeId: 'xNN7iTA57jM', thumbnailUrl: 'https://img.youtube.com/vi/xNN7iTA57jM/hqdefault.jpg', color1: Color(0xFF1B5E20), color2: Color(0xFF4CAF50), icon: Icons.forest, duration: '3h'),
  _AmbientItem(title: 'Pluie apaisante', emoji: '🌧️', youtubeId: 'mPZkdNFkNps', thumbnailUrl: 'https://img.youtube.com/vi/mPZkdNFkNps/hqdefault.jpg', color1: Color(0xFF0D47A1), color2: Color(0xFF42A5F5), icon: Icons.water_drop, duration: '2h'),
  _AmbientItem(title: 'Vagues de l\'océan', emoji: '🌊', youtubeId: 'V-_O7nl0Ii0', thumbnailUrl: 'https://img.youtube.com/vi/V-_O7nl0Ii0/hqdefault.jpg', color1: Color(0xFF006064), color2: Color(0xFF00BCD4), icon: Icons.waves, duration: '2h'),
  _AmbientItem(title: 'Feu de cheminée', emoji: '🔥', youtubeId: 'L_LUpnjgPso', thumbnailUrl: 'https://img.youtube.com/vi/L_LUpnjgPso/hqdefault.jpg', color1: Color(0xFFBF360C), color2: Color(0xFFFF7043), icon: Icons.local_fire_department, duration: '3h'),
  _AmbientItem(title: 'Bruit blanc', emoji: '🤍', youtubeId: 'nMfPqeZjc2c', thumbnailUrl: 'https://img.youtube.com/vi/nMfPqeZjc2c/hqdefault.jpg', color1: Color(0xFF37474F), color2: Color(0xFF90A4AE), icon: Icons.graphic_eq, duration: '8h'),
  _AmbientItem(title: 'Bols tibétains', emoji: '🔔', youtubeId: 'oNkKcMqWkpk', thumbnailUrl: 'https://img.youtube.com/vi/oNkKcMqWkpk/hqdefault.jpg', color1: Color(0xFF4A148C), color2: Color(0xFF9C27B0), icon: Icons.music_note, duration: '30min'),
];

const List<_MeditationItem> _meditations = [
  _MeditationItem(title: 'Respiration abdominale', description: 'Activez la réponse de relaxation parasympathique.', duration: '5 min', icon: Icons.air, color: Color(0xFF4DBDB8), steps: ['Installez-vous confortablement, dos droit.', 'Posez une main sur le ventre, l\'autre sur la poitrine.', 'Inspirez lentement par le nez pendant 4 secondes.', 'Retenez votre souffle 4 secondes.', 'Expirez doucement par la bouche pendant 6 secondes.', 'Répétez ce cycle 6 fois.']),
  _MeditationItem(title: 'Body Scan complet', description: 'Parcourez votre corps pour libérer les tensions.', duration: '10 min', icon: Icons.self_improvement, color: Color(0xFF7C3AED), steps: ['Allongez-vous sur le dos, yeux fermés.', 'Observez votre respiration naturelle.', 'Portez attention à vos pieds — ressentez les tensions.', 'Remontez jusqu\'aux mollets, genoux, cuisses.', 'Continuez vers l\'abdomen, la poitrine, le dos.', 'Terminez par le cou, la tête et le visage.']),
  _MeditationItem(title: 'Visualisation apaisante', description: 'Voyagez vers un lieu calme et sécurisant.', duration: '8 min', icon: Icons.landscape, color: Color(0xFF059669), steps: ['Fermez les yeux et respirez profondément.', 'Imaginez un lieu qui vous apporte paix.', 'Observez les couleurs, formes, sons de ce lieu.', 'Sentez la chaleur ou la fraîcheur de l\'air.', 'Restez dans cet espace quelques minutes.', 'Revenez doucement en bougeant les doigts.']),
  _MeditationItem(title: 'Cohérence cardiaque 5-5', description: 'Synchronisez votre rythme cardiaque.', duration: '5 min', icon: Icons.favorite, color: Color(0xFFE53E3E), steps: ['Asseyez-vous confortablement et fermez les yeux.', 'Inspirez régulièrement pendant 5 secondes.', 'Expirez pendant 5 secondes sans forcer.', 'Maintenez ce rythme : 6 respirations / minute.', 'Concentrez-vous sur la zone du cœur.', 'Pratiquez 5 min, 3 fois par jour.']),
];

const List<_ArticleItem> _articles = [
  _ArticleItem(title: 'L\'apnée du sommeil : comprendre pour mieux agir', category: 'Santé', readTime: '5 min', summary: 'Tout ce que vous devez savoir sur l\'apnée du sommeil, ses causes et ses traitements.', icon: Icons.medical_information, color: Color(0xFF1E3A8A), sections: [_ArticleSection('Qu\'est-ce que l\'apnée du sommeil ?', 'L\'apnée du sommeil est un trouble caractérisé par des arrêts répétés de la respiration pendant le sommeil, durant au moins 10 secondes. Ces interruptions peuvent survenir des dizaines de fois par heure et perturber profondément la qualité du sommeil.'), _ArticleSection('Les symptômes à reconnaître', 'Les principaux signes incluent : ronflements forts, somnolence diurne excessive, maux de tête matinaux, difficultés de concentration, irritabilité et réveils fréquents la nuit. La somnolence au volant est particulièrement dangereuse.'), _ArticleSection('Les traitements disponibles', 'La PPC (Pression Positive Continue) reste le traitement de référence. Des orthèses d\'avancement mandibulaire, une chirurgie ou des changements de mode de vie peuvent aussi aider selon la sévérité.')]),
  _ArticleItem(title: 'Hygiène du sommeil : 10 règles d\'or', category: 'Bien-être', readTime: '4 min', summary: 'Des habitudes simples pour améliorer durablement la qualité de votre sommeil.', icon: Icons.bedtime, color: Color(0xFF7C3AED), sections: [_ArticleSection('Régularité avant tout', 'Se coucher et se lever à des heures fixes, même le week-end, synchronise votre horloge biologique. Ce rythme est le facteur le plus important pour un sommeil réparateur.'), _ArticleSection('L\'environnement idéal', 'La chambre doit être fraîche (16-19°C), sombre et silencieuse. Investissez dans des rideaux occultants et éliminez les sources lumineuses.'), _ArticleSection('Les ennemis du sommeil', 'Évitez la caféine après 14h, l\'alcool, les écrans 1h avant le coucher, les repas copieux le soir et l\'exercice intense après 19h.')]),
  _ArticleItem(title: 'Stress et sommeil : briser le cercle vicieux', category: 'Psychologie', readTime: '6 min', summary: 'Comment le stress perturbe le sommeil et les stratégies pour retrouver la paix nocturne.', icon: Icons.psychology, color: Color(0xFF059669), sections: [_ArticleSection('Le lien stress-sommeil', 'Le cortisol, hormone du stress, maintient le cerveau en état d\'alerte. En cas de stress chronique, le taux reste élevé le soir, empêchant l\'endormissement et provoquant des réveils nocturnes.'), _ArticleSection('Techniques de gestion du stress', 'La méditation pleine conscience, la cohérence cardiaque, le yoga et la relaxation musculaire progressive ont tous prouvé leur efficacité. Pratiquez 10-20 minutes chaque soir.'), _ArticleSection('Le journal du soir', 'Écrire vos préoccupations avant de dormir "vide" le mental. Notez aussi 3 choses positives — cette pratique de gratitude réduit l\'anxiété nocturne de manière significative.')]),
];

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

class RelaxationContentScreen extends StatelessWidget {
  const RelaxationContentScreen({super.key, required this.title, required this.contentType});
  final String title;
  final String contentType;

  @override
  Widget build(BuildContext context) {
    switch (contentType) {
      case 'video':
      case 'add-video':
        return const _VideoLibraryScreen();
      case 'meditation':
      case 'create-meditation':
        return const _MeditationLibraryScreen();
      case 'article':
      case 'add-article':
        return const _ArticleLibraryScreen();
      default:
        return const _VideoLibraryScreen();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

class _VideoLibraryScreen extends StatefulWidget {
  const _VideoLibraryScreen();
  @override
  State<_VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<_VideoLibraryScreen>
    with SingleTickerProviderStateMixin {
  _VideoItem? _selected;
  String _filter = 'Tous';
  late TabController _tabs;

  static const _cats = ['Tous','Mindfulness','Nature','Yoga','Musique','Respiration','ASMR','Sommeil'];

  List<_VideoItem> get _all => [..._defaultVideos, ..._VideoStore().custom];
  List<_VideoItem> get _filtered => _filter == 'Tous' ? _all : _all.where((v) => v.category == _filter).toList();

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: const Text('🎬 Vidéothèque Bien-être', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.relaxation)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4DBDB8)),
            tooltip: 'Ajouter une vidéo YouTube',
            onPressed: _showAddDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF4DBDB8),
          labelColor: const Color(0xFF4DBDB8),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: '🎬 Vidéos'), Tab(text: '🎵 Ambiances')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_videosTab(), _ambiancesTab()],
      ),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  // ── VIDEOS TAB ─────────────────────────────────────────────────────────────
  Widget _videosTab() {
    return Column(children: [
      if (_selected != null) _player(_selected!),
      _categoryBar(),
      Expanded(
        child: _filtered.isEmpty
            ? _emptyState()
            : GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _videoCard(_filtered[i]),
              ),
      ),
    ]);
  }

  Widget _player(_VideoItem v) {
    return Container(
      color: Colors.black,
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Image.network(v.thumbnailUrl, height: 190, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 190, color: Colors.grey[900],
                  child: const Icon(Icons.video_library, color: Colors.white38, size: 60))),
          Container(height: 190, decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.black54]))),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => YoutubePlayerPage(
                videoId: v.youtubeId,
                title: v.title,
                category: v.category,
              ),
            )),
            child: Container(width: 68, height: 68,
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 25)]),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40)),
          ),
          Positioned(top: 8, right: 8,
            child: GestureDetector(onTap: () => setState(() => _selected = null),
                child: Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18)))),
          Positioned(top: 8, left: 8,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF4DBDB8), borderRadius: BorderRadius.circular(7)),
                child: Text(v.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
        ]),
        Container(
          color: const Color(0xFF0D1117),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.timer, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(v.duration, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (v.isCustom) ...[const SizedBox(width: 8),
                  const Icon(Icons.person, size: 11, color: Color(0xFF4DBDB8)),
                  const SizedBox(width: 2),
                  const Text('Perso', style: TextStyle(color: Color(0xFF4DBDB8), fontSize: 10))],
              ]),
            ])),
            Row(children: [
              if (v.isCustom) IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () { _VideoStore().custom.remove(v); setState(() => _selected = null); },
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => YoutubePlayerPage(
                    videoId: v.youtubeId,
                    title: v.title,
                    category: v.category,
                  ),
                )),
                icon: const Icon(Icons.play_circle_filled, size: 13),
                label: const Text('Lancer', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DBDB8), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _categoryBar() {
    return Container(
      height: 46, color: const Color(0xFF0D1117),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final c = _cats[i]; final sel = c == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = c),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF4DBDB8) : const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFF4DBDB8) : Colors.grey.shade800)),
              child: Center(child: Text(c, style: TextStyle(
                  color: sel ? Colors.white : Colors.grey[400], fontSize: 12,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)))),
          );
        },
      ),
    );
  }

  Widget _videoCard(_VideoItem v) {
    final active = _selected?.youtubeId == v.youtubeId;
    return GestureDetector(
      onTap: () => setState(() => _selected = active ? null : v),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF141824),
          border: Border.all(color: active ? const Color(0xFF4DBDB8) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: active ? const Color(0xFF4DBDB8).withValues(alpha: 0.3) : Colors.black38, blurRadius: active ? 16 : 6)]),
        child: ClipRRect(borderRadius: BorderRadius.circular(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Image.network(v.thumbnailUrl, height: 100, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[900],
                      child: const Icon(Icons.video_library, color: Colors.white38, size: 36))),
              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54])))),
              Positioned(bottom: 5, right: 5,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                    child: Text(v.duration, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
              if (v.isCustom) Positioned(top: 5, left: 5,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF4DBDB8), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Perso', style: TextStyle(color: Colors.white, fontSize: 9)))),
              if (active) Positioned(top: 5, right: 5,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF4DBDB8), borderRadius: BorderRadius.circular(4)),
                    child: const Text('▶ Actif', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
              Positioned.fill(child: Center(child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5)),
                child: Icon(active ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22)))),
            ]),
            Expanded(child: Padding(padding: const EdgeInsets.all(9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF4DBDB8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(v.category, style: const TextStyle(color: Color(0xFF4DBDB8), fontSize: 9, fontWeight: FontWeight.w600))),
              ]))),
          ])),
      ),
    );
  }

  // ── AMBIANCES TAB ──────────────────────────────────────────────────────────
  Widget _ambiancesTab() {
    return Container(color: const Color(0xFF0A0E1A),
      child: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A1F35), Color(0xFF0D1117)]),
              borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4DBDB8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.surround_sound, color: Color(0xFF4DBDB8), size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sons d\'ambiance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 2),
              Text('Tapez une carte → lecture directe dans l\'application', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
          ])),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.88),
          itemCount: _ambients.length,
          itemBuilder: (_, i) => _ambientCard(_ambients[i]),
        )),
        Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Text('Les ambiances se lisent directement dans l\'application',
              style: TextStyle(color: Colors.grey[700], fontSize: 11))),
      ]));
  }

  Widget _ambientCard(_AmbientItem a) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => YoutubeAmbientSheet(
          videoId: a.youtubeId,
          title: a.title,
          emoji: a.emoji,
          color1: a.color1,
          color2: a.color2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: a.color1.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(a.thumbnailUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [a.color1, a.color2], begin: Alignment.topLeft, end: Alignment.bottomRight)))),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [a.color1.withValues(alpha: 0.25), a.color1.withValues(alpha: 0.88)]))),
            Padding(padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 28)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                      child: Text(a.duration, style: const TextStyle(color: Colors.white70, fontSize: 10))),
                ]),
                const Spacer(),
                Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.play_circle_filled, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Écouter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ])),
              ])),
          ])),
      ),
    );
  }

  // ── ADD VIDEO DIALOG ───────────────────────────────────────────────────────
  void _showAddDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final urlC = TextEditingController();
    final durC = TextEditingController();
    String cat = 'Mindfulness';
    final cats = ['Mindfulness','Nature','Yoga','Musique','Respiration','ASMR','Sommeil','Autre'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: const Color(0xFF141824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.add_circle, color: Color(0xFF4DBDB8)),
          SizedBox(width: 8),
          Text('Ajouter une vidéo YouTube', style: TextStyle(color: Colors.white, fontSize: 15)),
        ]),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(titleC, 'Titre *', Icons.title),
          const SizedBox(height: 10),
          _field(descC, 'Description (optionnel)', Icons.description),
          const SizedBox(height: 10),
          _field(urlC, 'Lien YouTube * (youtu.be/... ou youtube.com/watch?v=...)', Icons.link),
          const SizedBox(height: 10),
          _field(durC, 'Durée (ex: 10:30)', Icons.timer),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF1A1F2E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: cat, dropdownColor: const Color(0xFF1A1F2E), isExpanded: true,
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4DBDB8)),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setS(() => cat = v!),
            ))),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1A1F2E), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡 Formats acceptés :', style: TextStyle(color: Color(0xFF4DBDB8), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('• youtu.be/dQw4w9WgXcQ\n• youtube.com/watch?v=dQw4w9WgXcQ\n• ID direct : dQw4w9WgXcQ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ])),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final id = _extractId(urlC.text.trim());
              if (titleC.text.trim().isEmpty || id == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Titre et URL YouTube valide requis.'), backgroundColor: Colors.red));
                return;
              }
              _VideoStore().custom.add(_VideoItem(
                title: titleC.text.trim(),
                description: descC.text.trim().isEmpty ? 'Vidéo personnalisée' : descC.text.trim(),
                duration: durC.text.trim().isEmpty ? '–' : durC.text.trim(),
                youtubeId: id,
                thumbnailUrl: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
                category: cat, isCustom: true,
              ));
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ "${titleC.text.trim()}" ajoutée !'),
                  backgroundColor: const Color(0xFF4DBDB8)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DBDB8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      )));
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF4DBDB8), size: 18),
        filled: true, fillColor: const Color(0xFF1A1F2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)));
  }

  String? _extractId(String url) {
    if (url.isEmpty) return null;
    final r1 = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (r1 != null) return r1.group(1);
    final r2 = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (r2 != null) return r2.group(1);
    final r3 = RegExp(r'embed/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (r3 != null) return r3.group(1);
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) return url;
    return null;
  }


  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.video_library_outlined, size: 60, color: Colors.grey),
    const SizedBox(height: 12),
    const Text('Aucune vidéo dans cette catégorie', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: _showAddDialog,
      icon: const Icon(Icons.add), label: const Text('Ajouter une vidéo'),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DBDB8), foregroundColor: Colors.white)),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDITATION LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

class _MeditationLibraryScreen extends StatefulWidget {
  const _MeditationLibraryScreen();
  @override
  State<_MeditationLibraryScreen> createState() => _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<_MeditationLibraryScreen>
    with TickerProviderStateMixin {
  _MeditationItem? _active;
  bool _playing = false;
  int _phase = 0, _cycles = 0;
  Timer? _timer;
  late AnimationController _breathCtrl, _pulseCtrl;

  static const _labels = ['Inspirez', 'Retenez', 'Expirez'];
  static const _durations = [4, 4, 6];
  static const _colors = [Color(0xFF4DBDB8), Color(0xFF7C3AED), Color(0xFF059669)];

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() { _timer?.cancel(); _breathCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  void _start(_MeditationItem item) {
    setState(() { _active = item; _playing = true; _phase = 0; _cycles = 0; });
    _tick();
  }

  void _tick() {
    final d = _durations[_phase];
    _breathCtrl.duration = Duration(seconds: d);
    _phase == 0 ? _breathCtrl.forward(from: 0) : _breathCtrl.reverse(from: 1);
    _timer = Timer(Duration(seconds: d), () {
      if (!_playing || !mounted) return;
      setState(() { _phase = (_phase + 1) % 3; if (_phase == 0) _cycles++; });
      _tick();
    });
  }

  void _stop() { _timer?.cancel(); _breathCtrl.stop();
    setState(() { _playing = false; _phase = 0; _cycles = 0; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120D24), foregroundColor: Colors.white,
        title: const Text('🧘 Méditations Guidées', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () { _stop(); context.canPop() ? context.pop() : context.go(RouteNames.relaxation); }),
      ),
      body: Column(children: [
        if (_active != null && _playing) _breathPlayer(),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(16),
          itemCount: _meditations.length,
          itemBuilder: (_, i) => _meditationCard(_meditations[i]))),
      ]),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }

  Widget _breathPlayer() {
    final color = _colors[_phase];
    return AnimatedContainer(duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      child: Column(children: [
        Text(_active!.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 18),
        AnimatedBuilder(animation: _breathCtrl, builder: (_, __) {
          final scale = 0.65 + 0.35 * _breathCtrl.value;
          return Transform.scale(scale: scale,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 2.5),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 8)]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_labels[_phase], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
                Text('${_durations[_phase]}s', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13)),
              ])));
        }),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _phase == i ? 24 : 8, height: 8,
            decoration: BoxDecoration(color: _phase == i ? color : Colors.grey[800], borderRadius: BorderRadius.circular(4))))),
        const SizedBox(height: 6),
        Text('Cycle $_cycles', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        TextButton.icon(onPressed: _stop, icon: const Icon(Icons.stop_circle, color: Colors.red),
          label: const Text('Arrêter', style: TextStyle(color: Colors.red))),
      ]));
  }

  Widget _meditationCard(_MeditationItem item) {
    final active = _active?.title == item.title && _playing;
    return AnimatedContainer(duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF141824),
        border: Border.all(color: active ? item.color : Colors.white10, width: active ? 2 : 1),
        boxShadow: [BoxShadow(color: active ? item.color.withValues(alpha: 0.3) : Colors.black38,
            blurRadius: active ? 20 : 6, offset: const Offset(0, 3))]),
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => active ? _stop() : _start(item),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.color.withValues(alpha: 0.3))),
            child: Icon(item.icon, color: item.color, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(item.description, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.timer, size: 12, color: Colors.grey[600]), const SizedBox(width: 4),
              Text(item.duration, style: TextStyle(fontSize: 11, color: Colors.grey[600]))]),
          ])),
          const SizedBox(width: 8),
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Transform.scale(
            scale: active ? 1.0 + 0.08 * _pulseCtrl.value : 1.0,
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: active ? Colors.red : item.color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (active ? Colors.red : item.color).withValues(alpha: 0.4), blurRadius: 12)]),
              child: Icon(active ? Icons.stop : Icons.play_arrow, color: Colors.white, size: 22)))),
        ]))));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARTICLE LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

class _ArticleLibraryScreen extends StatelessWidget {
  const _ArticleLibraryScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white,
        title: const Text('📖 Articles Bien-être', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.relaxation)),
      ),
      body: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (_, i) => _ArticleCard(article: _articles[i])),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final _ArticleItem article;
  const _ArticleCard({required this.article});

  void _open(BuildContext ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => _ArticleDetailPage(article: article)));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))]),
      child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => _open(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, height: 80,
            decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(colors: [article.color, article.color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Stack(children: [
              Positioned(right: -10, top: -10, child: Icon(article.icon, size: 90, color: Colors.white.withValues(alpha: 0.15))),
              Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                  child: Text(article.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(article.readTime, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              ])),
            ])),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(article.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(article.summary, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _open(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Lire l\'article', style: TextStyle(color: article.color, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: article.color),
                ]))),
          ])),
        ])),
    );
  }
}

class _ArticleDetailPage extends StatelessWidget {
  final _ArticleItem article;
  const _ArticleDetailPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(slivers: [
        SliverAppBar(expandedHeight: 180, pinned: true, backgroundColor: article.color, foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(article.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2),
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [article.color, article.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Center(child: Icon(article.icon, size: 80, color: Colors.white.withValues(alpha: 0.25)))))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: article.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(article.category, style: TextStyle(color: article.color, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(width: 10),
            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text('Lecture : ${article.readTime}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: article.color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: article.color, width: 4))),
            child: Text(article.summary, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6, fontStyle: FontStyle.italic))),
          const SizedBox(height: 24),
          ...article.sections.map((s) => Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: article.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Text(s.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
            ]),
            const SizedBox(height: 10),
            Text(s.body, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.7)),
          ]))),
          const SizedBox(height: 30),
        ]))),
      ]),
    );
  }
}