import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 1)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int color; // ARGB

  @HiveField(3)
  DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });
}
