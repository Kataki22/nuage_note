import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../core/models/note.dart';
import '../core/providers/note_provider.dart';

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
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    // Couleur choisie ou fallback sur le gradient auto
    final hasCustomColor = note.noteColor != 0;
    final List<Color> gradient = hasCustomColor
        ? [Color(note.noteColor), Color(note.noteColor).withValues(alpha: 0.7)]
        : _cardGradients[colorIndex % _cardGradients.length];

    return GestureDetector(
      onTap: onTap,
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
              // ─── Header : badges + bouton delete ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: [
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
                        Text(
                          note.title.isEmpty ? 'Sans titre' : note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      notesProvider.toggleFavorite(note.id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        note.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: note.isFavorite ? Colors.amber : Colors.white70,
                      ),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.take(3).map((tId) {
                      // Normalement il faut récupérer le nom du tag depuis le TagProvider
                      // Ici on affiche juste l'ID ou un libellé par défaut si manquant
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'tag',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
