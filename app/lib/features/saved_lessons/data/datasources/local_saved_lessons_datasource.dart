import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/saved_lesson_model.dart';
import 'saved_lessons_datasource.dart';

/// File-backed saved lessons store for the offline demo build.
///
/// Keeping this as a datasource preserves the clean architecture boundary and
/// lets us replace it with Hive/SQLite later without touching presentation code.
class LocalSavedLessonsDatasource implements SavedLessonsDatasource {
  static const String _fileName = 'saved_lessons.json';

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}/$_fileName');
  }

  @override
  Future<List<SavedLessonModel>> all() async {
    final records = await _readAll();
    records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return records;
  }

  @override
  Future<SavedLessonModel?> get(String id) async {
    final records = await _readAll();
    final matches = records.where((record) => record.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> save(SavedLessonModel model) async {
    final records = await _readAll();
    records.removeWhere((record) => record.id == model.id);
    records.add(model);
    await _writeAll(records);
  }

  @override
  Future<void> delete(String id) async {
    final records = await _readAll()
      ..removeWhere((record) => record.id == id);
    await _writeAll(records);
  }

  Future<List<SavedLessonModel>> _readAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return <SavedLessonModel>[];

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return <SavedLessonModel>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Expected a JSON list.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedLessonModel.fromJson)
          .toList();
    } catch (e) {
      throw StorageException('Could not read saved lessons.', cause: e);
    }
  }

  Future<void> _writeAll(List<SavedLessonModel> records) async {
    try {
      final file = await _file();
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final payload = records.map((record) => record.toJson()).toList();
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      throw StorageException('Could not write saved lessons.', cause: e);
    }
  }
}
