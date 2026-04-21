import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../core/models/note.dart';
import '../core/models/tag.dart';
import '../core/providers/tag_provider.dart';

const List<List<Color>> _cardGradients = [
  [Color(0xFF7C5CBF), Color(0xFF5B3FA0)],
  [Color(0xFF3D7FBF), Color(0xFF2A5A8A)],
  [Color(0xFF2EAA82), Color(0xFF1E7A5C)],
  [Color(0xFFBF6E3D), Color(0xFF8A4D28)],
  [Color(0xFFBF3D6E), Color(0xFF8A2A50)],
  [Color(0xFF5C7ABF), Color(0xFF3D5A8A)],
];

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int colorIndex;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.colorIndex,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _extractPlainText() {
    if (note.content.isEmpty) return 'Vide';
    try {
      // Pour l'instant on affiche le raw text ou JSON
      final parsed = jsonDecode(note.content);
      if (parsed is List) {
        String text = '';
        for (var op in parsed) {
          if (op['insert'] is String) text += op['insert'];
        }
        return text.trim().isEmpty ? 'Media' : text.trim();
      }
    } catch (_) {}
    return note.content;
  }

  @override
  Widget build(BuildContext context) {
    // Couleur choisie ou fallback sur le gradient auto
    final hasCustomColor = note.noteColor != 0;
    final List<Color> gradient = hasCustomColor
        ? [Color(note.noteColor), Color(note.noteColor).withValues(alpha: 0.7)]
        : _cardGradients[colorIndex % _cardGradients.length];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header : badges ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (note.isPinned)
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        if (note.isFavorite)
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                        if (note.audioPath != null)
                          const Icon(
                            Icons.mic_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        if (note.drawingPath != null)
                          const Icon(
                            Icons.brush_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        if (note.reminderAt != null &&
                            note.reminderAt!.isAfter(DateTime.now()))
                          const Icon(
                            Icons.notifications_active_rounded,
                            size: 16,
                            color: Colors.amberAccent,
                          ),
                        Text(
                          note.title.isEmpty ? 'Sans titre' : note.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ─── Contenu (Extrapolé du delta) ──────────────────
              Expanded(
                child: Text(
                  _extractPlainText(),
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ─── Tags ──────────────────────────────────────────
              if (note.tags.isNotEmpty)
                Builder(
                  builder: (context) {
                    final allTags = context.watch<TagProvider>().tags;
                    final tagsById = {for (final t in allTags) t.id: t};
                    final resolved = note.tags
                        .map((id) => tagsById[id])
                        .whereType<Tag>()
                        .toList();
                    if (resolved.isEmpty) return const SizedBox.shrink();
                    final extra = resolved.length - 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...resolved.take(3).map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(tag.color).withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${tag.name}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (extra > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+$extra',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              // ─── Date ──────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
