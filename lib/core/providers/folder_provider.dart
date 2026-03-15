import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nuage_note/core/models/folder.dart';
import 'package:uuid/uuid.dart';

class FolderProvider extends ChangeNotifier {
  Box<Folder>? _box;
  final _uuid = const Uuid();

  List<Folder> get folders => _box?.values.toList() ?? [];

  Future<void> init() async {
    _box = await Hive.openBox<Folder>('folders');
    notifyListeners();
  }

  Future<void> addFolder(Folder folder) async {
    await _box!.put(folder.id, folder);
    notifyListeners();
  }

  Future<void> updateFolder(Folder folder) async {
    await _box!.put(folder.id, folder);
    notifyListeners();
  }

  Future<void> deleteFolder(String id) async {
    await _box!.delete(id);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
