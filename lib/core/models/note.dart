import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content; // JSON delta Quill

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5, defaultValue: [])
  List<String> tags;

  @HiveField(6, defaultValue: 0)
  int noteColor; // ARGB int, 0 = auto (basé sur index)

  @HiveField(7, defaultValue: false)
  bool isFavorite;

  @HiveField(8, defaultValue: false)
  bool isArchived;

  @HiveField(9)
  String? folderId;

  @HiveField(10)
  String? audioPath;

  @HiveField(11)
  String? drawingPath;

  @HiveField(12, defaultValue: false)
  bool isPinned;

  @HiveField(13)
  DateTime? reminderAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.noteColor = 0,
    this.isFavorite = false,
    this.isArchived = false,
    this.isPinned = false,
    this.folderId,
    this.audioPath,
    this.drawingPath,
    this.reminderAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? noteColor,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    String? folderId,
    String? audioPath,
    String? drawingPath,
    Object? reminderAt = _sentinel,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      noteColor: noteColor ?? this.noteColor,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      folderId: folderId ?? this.folderId,
      audioPath: audioPath ?? this.audioPath,
      drawingPath: drawingPath ?? this.drawingPath,
      reminderAt: identical(reminderAt, _sentinel)
          ? this.reminderAt
          : reminderAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
