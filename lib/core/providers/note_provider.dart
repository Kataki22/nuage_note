import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nuage_note/core/models/note.dart';
import 'package:uuid/uuid.dart';

enum SortMode { dateDesc, dateAsc, titleAsc, colorGroup }

class NotesProvider extends ChangeNotifier {
  Box<Note>? _box;
  final _uuid = const Uuid();

  // ─── Filtres & recherche ──────────────────────────────────────────
  String _searchQuery = '';
  List<String> _selectedTags = [];
  SortMode _sortMode = SortMode.dateDesc;
  bool _showFavoritesOnly = false;
  bool _showArchived = false;
  String? _selectedFolderId;

  // ─── Getters ──────────────────────────────────────────────────────
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  SortMode get sortMode => _sortMode;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get showArchived => _showArchived;
  String? get selectedFolderId => _selectedFolderId;

  List<Note> get notes => _filteredNotes();

  // ─── Init ─────────────────────────────────────────────────────────
  Future<void> init() async {
    _box = await Hive.openBox<Note>('notes');
    notifyListeners();
  }

  // ─── Filtre combiné ───────────────────────────────────────────────
  List<Note> _filteredNotes() {
    List<Note> list = _box?.values.toList() ?? [];

    // Archive vs normal
    list = list.where((n) => n.isArchived == _showArchived).toList();

    // Favoris uniquement
    if (_showFavoritesOnly) {
      list = list.where((n) => n.isFavorite).toList();
    }

    // Dossier
    if (_selectedFolderId != null) {
      list = list.where((n) => n.folderId == _selectedFolderId).toList();
    }

    // Tags
    if (_selectedTags.isNotEmpty) {
      list = list
          .where((n) => _selectedTags.any((t) => n.tags.contains(t)))
          .toList();
    }

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (n) =>
                n.title.toLowerCase().contains(q) ||
                n.content.toLowerCase().contains(q),
          )
          .toList();
    }

    // Tri
    switch (_sortMode) {
      case SortMode.dateDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortMode.dateAsc:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SortMode.titleAsc:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SortMode.colorGroup:
        list.sort((a, b) => b.noteColor.compareTo(a.noteColor));
    }

    return list;
  }

  // ─── Setters filtres ──────────────────────────────────────────────
  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortMode(SortMode m) {
    _sortMode = m;
    notifyListeners();
  }

  void setShowFavorites(bool v) {
    _showFavoritesOnly = v;
    _showArchived = false;
    notifyListeners();
  }

  void setShowArchived(bool v) {
    _showArchived = v;
    _showFavoritesOnly = false;
    notifyListeners();
  }

  void setFolder(String? id) {
    _selectedFolderId = id;
    notifyListeners();
  }

  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTags = [];
    _showFavoritesOnly = false;
    _showArchived = false;
    _selectedFolderId = null;
    notifyListeners();
  }

  // ─── CRUD ─────────────────────────────────────────────────────────
  Future<void> addNote(Note note) async {
    await _box!.put(note.id, note);
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await _box!.put(note.id, note);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _box!.delete(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final note = _box!.get(id);
    if (note == null) return;
    await _box!.put(
      id,
      note.copyWith(isFavorite: !note.isFavorite, updatedAt: DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> toggleArchive(String id) async {
    final note = _box!.get(id);
    if (note == null) return;
    await _box!.put(
      id,
      note.copyWith(isArchived: !note.isArchived, updatedAt: DateTime.now()),
    );
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
