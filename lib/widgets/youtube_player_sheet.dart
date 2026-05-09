// lib/widgets/youtube_player_sheet.dart
// Requires: youtube_player_iframe: ^4.0.0
// ignore_for_file: use_build_context_synchronously
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FULL PAGE PLAYER
// ─────────────────────────────────────────────────────────────────────────────

class YoutubePlayerPage extends StatefulWidget {
  final String videoId;
  final String title;
  final String? category;
  final Color accentColor;

  const YoutubePlayerPage({
    super.key,
    required this.videoId,
    required this.title,
    this.category,
    this.accentColor = const Color(0xFF4DBDB8),
  });

  @override
  State<YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  late final YoutubePlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // ✅ FIX: autoPlay param is deprecated — use loadVideoById + playVideo() on ready
    _ctrl = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        enableCaption: false,
        playsInline: true,
      ),
    );

    // Load the video — this queues it but doesn't auto-play
    _ctrl.loadVideoById(videoId: widget.videoId);

    // ✅ Trigger play as soon as the player is ready
    _ctrl.listen((value) {
      if (!_ready && value.playerState == PlayerState.unStarted) {
        _ready = true;
        Future.microtask(() => _ctrl.playVideo());
      }
      // Also trigger play when buffering starts (player is ready)
      if (!_ready && value.playerState == PlayerState.buffering) {
        _ready = true;
      }
    });
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _ctrl,
      aspectRatio: 16 / 9,
      builder: (context, player) => Scaffold(
        backgroundColor: const Color(0xFF070B14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1117),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.category != null)
                Text(
                  widget.category!,
                  style: TextStyle(fontSize: 10, color: widget.accentColor),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Inline player ─────────────────────────────────────────────
            player,

            // ── Info + controls ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.category!,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Manual play/pause/seek controls
                    YoutubeValueBuilder(
                      controller: _ctrl,
                      builder: (context, value) {
                        final isPlaying =
                            value.playerState == PlayerState.playing;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ctrlBtn(
                              Icons.replay_10_rounded,
                              Colors.grey,
                              () async {
                                final pos = await _ctrl.currentTime;
                                _ctrl.seekTo(
                                  seconds: math.max(0, pos - 10).toDouble(),
                                  allowSeekAhead: true,
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => isPlaying
                                  ? _ctrl.pauseVideo()
                                  : _ctrl.playVideo(),
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accentColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            _ctrlBtn(
                              Icons.forward_10_rounded,
                              Colors.grey,
                              () async {
                                final pos = await _ctrl.currentTime;
                                _ctrl.seekTo(
                                  seconds: pos + 10,
                                  allowSeekAhead: true,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141824),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          _tip(
                            Icons.fullscreen_rounded,
                            'Plein écran',
                            'Tapez ⛶ dans le lecteur',
                            widget.accentColor,
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          _tip(
                            Icons.speed_rounded,
                            'Vitesse',
                            'Contrôles disponibles dans le player',
                            Colors.grey,
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          _tip(
                            Icons.replay_10_rounded,
                            'Navigation',
                            'Utilisez les boutons ±10s ci-dessus',
                            Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _ctrlBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class YoutubeAmbientSheet extends StatefulWidget {
  final String videoId;
  final String title;
  final String emoji;
  final Color color1;
  final Color color2;

  const YoutubeAmbientSheet({
    super.key,
    required this.videoId,
    required this.title,
    required this.emoji,
    required this.color1,
    required this.color2,
  });

  @override
  State<YoutubeAmbientSheet> createState() => _YoutubeAmbientSheetState();
}

class _YoutubeAmbientSheetState extends State<YoutubeAmbientSheet> {
  late final YoutubePlayerController _ctrl;
  bool _showVideo = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _ctrl = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false, // We use our own controls in audio mode
        mute: false,
        loop: true,
        enableCaption: false,
        playsInline: true,
        showFullscreenButton: false,
      ),
    );

    _ctrl.loadVideoById(videoId: widget.videoId);

    // ✅ Play as soon as player is ready
    _ctrl.listen((value) {
      if (!_ready && value.playerState == PlayerState.unStarted) {
        _ready = true;
        Future.microtask(() => _ctrl.playVideo());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1623),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color1, widget.color2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Lecture en cours',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle video/audio
                GestureDetector(
                  onTap: () => setState(() => _showVideo = !_showVideo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showVideo
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _showVideo ? 'Audio' : 'Vidéo',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Player zone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _showVideo
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: YoutubePlayer(
                      controller: _ctrl,
                      aspectRatio: 16 / 9,
                    ),
                  )
                : Column(
                    children: [
                      _Waveform(color: widget.color2),
                      const SizedBox(height: 16),
                      YoutubeValueBuilder(
                        controller: _ctrl,
                        builder: (context, value) {
                          final isPlaying =
                              value.playerState == PlayerState.playing;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _miniBtn(Icons.replay_10_rounded, () async {
                                final p = await _ctrl.currentTime;
                                _ctrl.seekTo(
                                  seconds: math.max(0, p - 10).toDouble(),
                                  allowSeekAhead: true,
                                );
                              }),
                              const SizedBox(width: 18),
                              GestureDetector(
                                onTap: () => isPlaying
                                    ? _ctrl.pauseVideo()
                                    : _ctrl.playVideo(),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.color1, widget.color2],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.color2.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              _miniBtn(Icons.forward_10_rounded, () async {
                                final p = await _ctrl.currentTime;
                                _ctrl.seekTo(
                                  seconds: p + 10,
                                  allowSeekAhead: true,
                                );
                              }),
                            ],
                          );
                        },
                      ),
                      // Hidden player to keep audio running in audio mode
                      SizedBox(
                        height: 1,
                        child: YoutubePlayer(
                          controller: _ctrl,
                          aspectRatio: 16 / 9,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _ctrl.pauseVideo();
              Navigator.pop(context);
            },
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED WAVEFORM
// ─────────────────────────────────────────────────────────────────────────────

class _Waveform extends StatefulWidget {
  final Color color;
  const _Waveform({required this.color});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(24, (i) {
            final phase = (i / 24 * math.pi * 2) + _c.value * math.pi;
            final h = 6.0 + 30.0 * ((math.sin(phase) + 1) / 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 4,
              height: h,
              decoration: BoxDecoration(
                color: widget.color.withValues(
                  alpha: 0.4 + 0.6 * ((math.sin(phase) + 1) / 2),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}
