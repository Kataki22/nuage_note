import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/models/folder.dart';
import '../core/providers/folder_provider.dart';
import '../core/providers/note_provider.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Dossiers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: folderProvider.folders.length,
        itemBuilder: (context, index) {
          final folder = folderProvider.folders[index];
          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.folder_rounded, color: Color(folder.color)),
              title: Text(
                folder.name,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                notesProvider.setFolder(folder.id);
                Navigator.pop(context); // Retour à l'accueil filtré
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                onPressed: () => _confirmDelete(context, folder.id),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFolderDialog(context),
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Nouveau dossier'),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    var name = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2A),
        title: Text(
          'Nouveau dossier',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom du dossier',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.trim().isEmpty) return;
              final p = Provider.of<FolderProvider>(context, listen: false);
              p.addFolder(
                Folder(
                  id: p.generateId(),
                  name: name.trim(),
                  color: Colors.blueAccent.toARGB32(),
                  createdAt: DateTime.now(),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String folderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2A),
        title: const Text('Supprimer ?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce dossier ? Les notes à l\'intérieur ne seront pas supprimées.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Provider.of<FolderProvider>(
                context,
                listen: false,
              ).deleteFolder(folderId);
              Navigator.pop(context);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
