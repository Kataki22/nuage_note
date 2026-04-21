import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../models/tag.dart';

class NoteShareService {
  const NoteShareService._();

  static String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final parsed = jsonDecode(content);
      if (parsed is List) {
        final buffer = StringBuffer();
        for (final op in parsed) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {
      // Contenu non-Delta : on renvoie tel quel
    }
    return content.trim();
  }

  static String buildShareText(Note note, {List<Tag> resolvedTags = const []}) {
    final buffer = StringBuffer();
    final title = note.title.trim();
    if (title.isNotEmpty) {
      buffer.writeln(title);
      buffer.writeln('─' * (title.length.clamp(3, 40)));
      buffer.writeln();
    }
    final body = _extractPlainText(note.content);
    if (body.isNotEmpty) {
      buffer.writeln(body);
      buffer.writeln();
    }
    if (resolvedTags.isNotEmpty) {
      buffer.writeln(resolvedTags.map((t) => '#${t.name}').join(' '));
    }
    return buffer.toString().trim();
  }

  static String _sanitize(String input, {int maxLength = 40}) {
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) return 'note';
    return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
  }

  static Future<XFile?> _prepareAttachment({
    required String? sourcePath,
    required String baseName,
    required String extension,
    required String mimeType,
  }) async {
    if (sourcePath == null) return null;
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    try {
      final tmp = await getTemporaryDirectory();
      final cleanName = '${_sanitize(baseName)}.$extension';
      final destPath = '${tmp.path}/$cleanName';
      final dest = await source.copy(destPath);
      return XFile(dest.path, mimeType: mimeType);
    } catch (_) {
      return XFile(sourcePath, mimeType: mimeType);
    }
  }

  static Future<void> shareTextOnly(
    Note note, {
    List<Tag> resolvedTags = const [],
  }) async {
    final text = buildShareText(note, resolvedTags: resolvedTags);
    if (text.isEmpty) return;
    final subject = note.title.isEmpty ? 'Note' : note.title;
    await Share.share(text, subject: subject);
  }

  static Future<void> shareDrawingOnly(
    Note note, {
    bool includeText = false,
    List<Tag> resolvedTags = const [],
  }) async {
    final attachment = await _prepareAttachment(
      sourcePath: note.drawingPath,
      baseName: '${_sanitize(note.title.isEmpty ? "dessin" : note.title)}_dessin',
      extension: 'png',
      mimeType: 'image/png',
    );
    if (attachment == null) return;
    final subject = note.title.isEmpty ? 'Dessin' : note.title;
    await Share.shareXFiles(
      [attachment],
      text: includeText ? buildShareText(note, resolvedTags: resolvedTags) : null,
      subject: subject,
    );
  }

  static Future<void> shareAudioOnly(
    Note note, {
    bool includeText = false,
    List<Tag> resolvedTags = const [],
  }) async {
    final attachment = await _prepareAttachment(
      sourcePath: note.audioPath,
      baseName: '${_sanitize(note.title.isEmpty ? "audio" : note.title)}_audio',
      extension: 'm4a',
      mimeType: 'audio/mp4',
    );
    if (attachment == null) return;
    final subject = note.title.isEmpty ? 'Note vocale' : note.title;
    await Share.shareXFiles(
      [attachment],
      text: includeText ? buildShareText(note, resolvedTags: resolvedTags) : null,
      subject: subject,
    );
  }

  static Future<void> shareAll(
    Note note, {
    List<Tag> resolvedTags = const [],
  }) async {
    final text = buildShareText(note, resolvedTags: resolvedTags);
    final subject = note.title.isEmpty ? 'Note' : note.title;
    final attachments = <XFile>[];

    final drawing = await _prepareAttachment(
      sourcePath: note.drawingPath,
      baseName: '${_sanitize(note.title.isEmpty ? "note" : note.title)}_dessin',
      extension: 'png',
      mimeType: 'image/png',
    );
    if (drawing != null) attachments.add(drawing);

    final audio = await _prepareAttachment(
      sourcePath: note.audioPath,
      baseName: '${_sanitize(note.title.isEmpty ? "note" : note.title)}_audio',
      extension: 'm4a',
      mimeType: 'audio/mp4',
    );
    if (audio != null) attachments.add(audio);

    if (attachments.isEmpty) {
      if (text.isEmpty) return;
      await Share.share(text, subject: subject);
    } else {
      await Share.shareXFiles(attachments, text: text, subject: subject);
    }
  }

  static Future<void> copyToClipboard(
    Note note, {
    List<Tag> resolvedTags = const [],
  }) async {
    final text = buildShareText(note, resolvedTags: resolvedTags);
    await Clipboard.setData(ClipboardData(text: text));
  }
}
