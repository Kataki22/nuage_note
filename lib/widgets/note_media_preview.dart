import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteMediaPreview extends StatelessWidget {
  final String? audioPath;
  final String? drawingPath;
  final VoidCallback onDrawingTap;
  final VoidCallback onDrawingDelete;
  final VoidCallback onAudioDelete;

  const NoteMediaPreview({
    super.key,
    required this.audioPath,
    required this.drawingPath,
    required this.onDrawingTap,
    required this.onDrawingDelete,
    required this.onAudioDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (audioPath == null && drawingPath == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drawingPath != null)
            _DrawingPreviewCard(
              path: drawingPath!,
              onTap: onDrawingTap,
              onDelete: onDrawingDelete,
            ),
          if (drawingPath != null && audioPath != null)
            const SizedBox(height: 12),
          if (audioPath != null)
            InlineAudioPlayer(
              path: audioPath!,
              onDelete: onAudioDelete,
            ),
        ],
      ),
    );
  }
}

class _DrawingPreviewCard extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DrawingPreviewCard({
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.white,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                cacheWidth: 1080,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.brush_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dessin',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Modifier',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}

class InlineAudioPlayer extends StatefulWidget {
  final String path;
  final VoidCallback onDelete;

  const InlineAudioPlayer({
    super.key,
    required this.path,
    required this.onDelete,
  });

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadSource(widget.path);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void didUpdateWidget(covariant InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadSource(widget.path);
    }
  }

  Future<void> _loadSource(String path) async {
    try {
      await _player.setSourceDeviceFile(path);
    } catch (_) {
      // Le fichier n'est pas lisible — on laisse l'UI sans durée
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture impossible.')),
      );
    }
  }

  Future<void> _seek(double value) async {
    final ms = (_duration.inMilliseconds * value).round();
    await _player.seek(Duration(milliseconds: ms));
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CBF), Color(0xFF5B3FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CBF).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _toggle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Note vocale',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: Colors.greenAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.greenAccent,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: _duration.inMilliseconds > 0 ? _seek : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(_position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _format(_duration),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
