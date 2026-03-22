import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../core/models/note.dart';
import '../widgets/tag_picker.dart';
import '../widgets/audio_recorder_widget.dart';
import 'drawing_screen.dart';
import '../core/providers/note_provider.dart';

const List<List<Color>> _cardGradients = [
  [Color(0xFF7C5CBF), Color(0xFF5B3FA0)],
  [Color(0xFF3D7FBF), Color(0xFF2A5A8A)],
  [Color(0xFF2EAA82), Color(0xFF1E7A5C)],
  [Color(0xFFBF6E3D), Color(0xFF8A4D28)],
  [Color(0xFFBF3D6E), Color(0xFF8A2A50)],
  [Color(0xFF5C7ABF), Color(0xFF3D5A8A)],
];

class NoteScreen extends StatefulWidget {
  final Note? note;
  final int colorIndex;

  const NoteScreen({super.key, this.note, this.colorIndex = 0});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late AnimationController _saveAnim;

  bool _saved = false;
  int _noteColor = 0;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isArchived = false;
  bool _isPinned = false;
  String? _audioPath;
  String? _drawingPath;
  String? _folderId;

  bool get isEditing => widget.note != null;
  List<Color> get _gradient {
    if (_noteColor != 0) {
      return [Color(_noteColor), Color(_noteColor).withValues(alpha: 0.7)];
    }
    return _cardGradients[widget.colorIndex % _cardGradients.length];
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // Initialisation Quill
    quill.Document doc;
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        final json = jsonDecode(widget.note!.content);
        doc = quill.Document.fromJson(json);
      } catch (e) {
        // Fallback si c'était du texte brut de l'ancienne version
        doc = quill.Document()..insert(0, widget.note!.content);
      }
    } else {
      doc = quill.Document();
    }

    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    if (widget.note != null) {
      _noteColor = widget.note!.noteColor;
      _tags = List.from(widget.note!.tags);
      _isFavorite = widget.note!.isFavorite;
      _isArchived = widget.note!.isArchived;
      _isPinned = widget.note!.isPinned;
      _audioPath = widget.note!.audioPath;
      _drawingPath = widget.note!.drawingPath;
      _folderId = widget.note!.folderId;
    }

    _saveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _saveAnim.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = jsonEncode(_quillController.document.toDelta().toJson());

    if (title.isEmpty && _quillController.document.isEmpty()) {
      Navigator.pop(context);
      return;
    }

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    if (isEditing) {
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        tags: _tags,
        noteColor: _noteColor,
        isFavorite: _isFavorite,
        isArchived: _isArchived,
        isPinned: _isPinned,
        audioPath: _audioPath,
        drawingPath: _drawingPath,
        folderId: _folderId,
      );
      await notesProvider.updateNote(updatedNote);
    } else {
      final newNote = Note(
        id: notesProvider.generateId(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: _tags,
        noteColor: _noteColor,
        isFavorite: _isFavorite,
        isArchived: _isArchived,
        isPinned: _isPinned,
        audioPath: _audioPath,
        drawingPath: _drawingPath,
        folderId: _folderId,
      );
      await notesProvider.addNote(newNote);
    }

    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) Navigator.pop(context);
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1D2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Couleur',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Sélecteur de couleur rapide
                Wrap(
                  spacing: 12,
                  children: [
                    GestureDetector(
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 20,
                        child: _noteColor == 0
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      onTap: () {
                        setState(() {
                          _noteColor = 0;
                        });
                        setStateSheet(() {});
                      },
                    ),
                    ..._cardGradients.map(
                      (g) => GestureDetector(
                        child: CircleAvatar(
                          backgroundColor: g[0],
                          radius: 20,
                          child: _noteColor == g[0].toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        onTap: () {
                          setState(() {
                            _noteColor = g[0].toARGB32();
                          });
                          setStateSheet(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(
                    _isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Épingler',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _isPinned = !_isPinned;
                    });
                    setStateSheet(() {});
                  },
                ),
                ListTile(
                  leading: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _isFavorite ? Colors.amber : Colors.white,
                  ),
                  title: const Text(
                    'Favori',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                    setStateSheet(() {});
                  },
                ),
                ListTile(
                  leading: Icon(
                    _isArchived
                        ? Icons.archive_rounded
                        : Icons.archive_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Archive',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _isArchived = !_isArchived;
                    });
                    setStateSheet(() {});
                  },
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                TagPicker(
                  initialTags: _tags,
                  onTagsChanged: (tags) {
                    setState(() => _tags = tags);
                    setStateSheet(() {});
                  },
                ),
                const SizedBox(height: 20),
                AudioRecorderWidget(
                  initialAudioPath: _audioPath,
                  onAudioSaved: (path) {
                    setState(() => _audioPath = path);
                    setStateSheet(() {});
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    _drawingPath != null
                        ? Icons.brush_rounded
                        : Icons.brush_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    _drawingPath != null
                        ? 'Modifier le dessin'
                        : 'Dessin libre',
                    style: const TextStyle(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  onTap: () async {
                    final path = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DrawingScreen()),
                    );
                    if (path != null && path is String) {
                      setState(() => _drawingPath = path);
                      setStateSheet(() {});
                    }
                  },
                ),
                if (_drawingPath != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            color: Colors.white,
                            child: Transform.scale(
                              scale: 2.0,
                              child: Image.file(
                                File(_drawingPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dessin joint',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() => _drawingPath = null);
                            setStateSheet(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                if (isEditing) ...[
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Close sheet
                      final p = Provider.of<NotesProvider>(
                        context,
                        listen: false,
                      );
                      final noteToDelete = widget.note!;

                      // On ferme l'écran de la note avant de supprimer
                      Navigator.pop(context);

                      await p.deleteNote(noteToDelete.id);

                      // On pourrait déclencher le snackbar ici si on avait accès au scaffold de l'accueil
                      // Mais on va le faire dans home_screen.dart généralement.
                    },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─── Fond dégradé ────────────────────────────────────────
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [
                  _gradient[0],
                  _gradient[1].withValues(alpha: 0.6),
                  const Color(0xFF12111A).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const Positioned.fill(
            top: 240,
            child: ColoredBox(color: Color(0xFF12111A)),
          ),

          // ─── Contenu ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // AppBar custom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _showOptionsSheet,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: _saved
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _saveNote,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _titleController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Titre',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),
                ),

                const SizedBox(height: 16),

                // Toolbar Quill
                quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                  ),
                ),

                const SizedBox(height: 8),

                // Éditeur Quill
                Expanded(
                  child: Container(
                    color: const Color(0xFF12111A),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;
}
