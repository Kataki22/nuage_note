// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      tags: fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      noteColor: fields[6] == null ? 0 : fields[6] as int,
      isFavorite: fields[7] == null ? false : fields[7] as bool,
      isArchived: fields[8] == null ? false : fields[8] as bool,
      isPinned: fields[12] == null ? false : fields[12] as bool,
      folderId: fields[9] as String?,
      audioPath: fields[10] as String?,
      drawingPath: fields[11] as String?,
      reminderAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.noteColor)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.folderId)
      ..writeByte(10)
      ..write(obj.audioPath)
      ..writeByte(11)
      ..write(obj.drawingPath)
      ..writeByte(12)
      ..write(obj.isPinned)
      ..writeByte(13)
      ..write(obj.reminderAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
