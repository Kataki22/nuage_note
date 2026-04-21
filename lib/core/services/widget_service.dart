import 'package:home_widget/home_widget.dart';

import '../models/note.dart';

class WidgetService {
  const WidgetService._();

  static const String _androidProvider =
      'com.example.nuage_note.NoteWidgetProvider';

  static const int _maxPinned = 2;
  static const int _maxRecent = 3;

  static String _displayTitle(Note note) {
    final t = note.title.trim();
    return t.isEmpty ? 'Sans titre' : t;
  }

  static Future<void> sync(Iterable<Note> allNotes) async {
    final active = allNotes.where((n) => !n.isArchived).toList();

    final pinned = active.where((n) => n.isPinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = active.where((n) => !n.isPinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (var i = 0; i < _maxPinned; i++) {
      final note = i < pinned.length ? pinned[i] : null;
      await HomeWidget.saveWidgetData<String>(
        'pinned_${i + 1}_id',
        note?.id ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'pinned_${i + 1}_title',
        note != null ? _displayTitle(note) : '',
      );
    }

    for (var i = 0; i < _maxRecent; i++) {
      final note = i < recent.length ? recent[i] : null;
      await HomeWidget.saveWidgetData<String>(
        'recent_${i + 1}_id',
        note?.id ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'recent_${i + 1}_title',
        note != null ? _displayTitle(note) : '',
      );
    }

    try {
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
    } catch (_) {
      // Pas de widget installé sur l'écran d'accueil — pas grave
    }
  }
}
