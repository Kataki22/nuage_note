import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nuage_note/core/models/tag.dart';
import 'package:uuid/uuid.dart';

class TagProvider extends ChangeNotifier {
  Box<Tag>? _box;
  final _uuid = const Uuid();

  List<Tag> get tags => _box?.values.toList() ?? [];

  Future<void> init() async {
    _box = await Hive.openBox<Tag>('tags');
    notifyListeners();
  }

  Future<void> addTag(Tag tag) async {
    await _box!.put(tag.id, tag);
    notifyListeners();
  }

  Future<void> updateTag(Tag tag) async {
    await _box!.put(tag.id, tag);
    notifyListeners();
  }

  Future<void> deleteTag(String id) async {
    await _box!.delete(id);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
