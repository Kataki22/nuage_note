import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/note_provider.dart';
import '../core/providers/tag_provider.dart';
import '../widgets/note_card.dart';
import 'note_screen.dart';
import 'folder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final tagProvider = Provider.of<TagProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar avec Recherche et Tri ──────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF12111A),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Nuage Note',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              PopupMenuButton<SortMode>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: notesProvider.setSortMode,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortMode.dateDesc,
                    child: Text('Récent d\'abord'),
                  ),
                  PopupMenuItem(
                    value: SortMode.dateAsc,
                    child: Text('Ancien d\'abord'),
                  ),
                  PopupMenuItem(
                    value: SortMode.titleAsc,
                    child: Text('Titre (A-Z)'),
                  ),
                  PopupMenuItem(
                    value: SortMode.colorGroup,
                    child: Text('Couleur'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      onChanged: notesProvider.setSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une note...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),

                  // Filtres (Tags, Favoris)
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip(
                          label: 'Tout',
                          selected:
                              !notesProvider.showFavoritesOnly &&
                              !notesProvider.showArchived &&
                              notesProvider.selectedTags.isEmpty,
                          onSelected: (_) => notesProvider.clearFilters(),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '⭐ Favoris',
                          selected: notesProvider.showFavoritesOnly,
                          onSelected: (val) =>
                              notesProvider.setShowFavorites(val),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        // Tags personnalisés
                        ...tagProvider.tags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: '#${tag.name}',
                              selected: notesProvider.selectedTags.contains(
                                tag.id,
                              ),
                              onSelected: (_) =>
                                  notesProvider.toggleTagFilter(tag.id),
                              colorScheme: colorScheme,
                              chipColor: Color(tag.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ─── Compteur de notes ─────────────────────────────────────
          if (notesProvider.notes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '${notesProvider.notes.length} note${notesProvider.notes.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ─── Contenu principal ─────────────────────────────────────
          notesProvider.notes.isEmpty
              ? SliverFillRemaining(child: _EmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final note = notesProvider.notes[index];
                      return NoteCard(
                        note: note,
                        colorIndex: index,
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(NoteScreen(note: note)),
                        ),
                        onDelete: () => _confirmDelete(
                          context,
                          () => notesProvider.deleteNote(note.id),
                        ),
                      );
                    }, childCount: notesProvider.notes.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                  ),
                ),
        ],
      ),

      // ─── FAB avec menu ───────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simplifié pour l'instant : ouvre juste une note texte
          Navigator.push(context, _slideRoute(const NoteScreen()));
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    return Drawer(
      backgroundColor: const Color(0xFF1E1D2A),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.centerLeft,
              child: Text(
                'Nuage Note',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.white),
              title: const Text(
                'Accueil',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                notesProvider.clearFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_rounded, color: Colors.white),
              title: const Text(
                'Archive',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                notesProvider.setShowArchived(true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded, color: Colors.white),
              title: const Text(
                'Dossiers',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FolderScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required ColorScheme colorScheme,
    Color? chipColor,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: (chipColor ?? colorScheme.primary).withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, a1, a2) => page,
      transitionsBuilder: (context, animation, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1D2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              'Supprimer cette note ?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune note trouvée',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
