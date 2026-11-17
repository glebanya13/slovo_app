import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'mock_data.dart' show Verse;

/// Синодальный перевод (общественное достояние), встроен в приложение
/// и работает без сети. Источник — assets/bible_ru.json.gz
/// (73 книги, нумерация псалмов по Септуагинте).
class Bible {
  Bible._(this._books);

  final Map<String, List<List<String>>> _books;

  static Bible _instance = Bible._(const {});
  static Bible get instance => _instance;

  /// Коды книг в файле → коды книг в приложении.
  static const _ids = {
    'gn': 'gen', 'ex': 'exod', 'lv': 'lev', 'nm': 'num', 'dt': 'deut', 'js': 'josh', 'jud': 'judg',
    'rt': 'ruth', '1sm': '1sam', '2sm': '2sam', '1kgs': '1kgs', '2kgs': '2kgs', '1ch': '1chr',
    '2ch': '2chr', 'ezr': 'ezra', 'ne': 'neh', 'tob': 'tob', 'jdt': 'jdt', 'et': 'esth',
    '1mac': '1macc', '2mac': '2macc', 'job': 'job', 'ps': 'ps', 'prv': 'prov', 'ec': 'eccl',
    'so': 'song', 'wis': 'wis', 'sir': 'sir', 'is': 'isa', 'jr': 'jer', 'lm': 'lam', 'bar': 'bar',
    'ez': 'ezek', 'dn': 'dan', 'ho': 'hos', 'jl': 'joel', 'am': 'amos', 'ob': 'obad', 'jn': 'jonah',
    'mi': 'mic', 'na': 'nah', 'hk': 'hab', 'zp': 'zeph', 'hg': 'hag', 'zc': 'zech', 'ml': 'mal',
    'mt': 'matt', 'mk': 'mark', 'lk': 'luke', 'jo': 'john', 'act': 'acts', 'rm': 'rom', '1co': '1cor',
    '2co': '2cor', 'gl': 'gal', 'eph': 'eph', 'ph': 'phil', 'cl': 'col', '1ts': '1thess',
    '2ts': '2thess', '1tm': '1tim', '2tm': '2tim', 'tt': 'titus', 'phm': 'phlm', 'hb': 'heb',
    'jm': 'jas', '1pe': '1pet', '2pe': '2pet', '1jo': '1john', '2jo': '2john', '3jo': '3john',
    'jd': 'jude', 're': 'rev',
  };

  /// Загрузка при старте приложения (распаковка — в фоновом изоляте).
  static Future<void> load() async {
    final data = await rootBundle.load('assets/bible_ru.json.gz');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    _instance = Bible._(await compute(_decode, bytes));
  }

  /// Для тестов: загрузка из байтов файла.
  @visibleForTesting
  static void loadFromBytes(Uint8List bytes) => _instance = Bible._(_decode(bytes));

  bool get isLoaded => _books.isNotEmpty;
  bool hasBook(String id) => _books.containsKey(id);
  int chapterCount(String id) => _books[id]?.length ?? 0;

  List<Verse>? verses(String bookId, int chapter) {
    final chapters = _books[bookId];
    if (chapters == null || chapter < 1 || chapter > chapters.length) return null;
    final list = chapters[chapter - 1];
    return [for (var i = 0; i < list.length; i++) Verse(i + 1, list[i])];
  }

  /// Простой поиск по тексту: до [limit] совпадений.
  List<({String book, int chapter, int verse, String text})> search(String query, {int limit = 100}) {
    final q = query.trim().toLowerCase();
    if (q.length < 3) return const [];
    final result = <({String book, int chapter, int verse, String text})>[];
    for (final e in _books.entries) {
      for (var c = 0; c < e.value.length; c++) {
        final vs = e.value[c];
        for (var v = 0; v < vs.length; v++) {
          if (vs[v].toLowerCase().contains(q)) {
            result.add((book: e.key, chapter: c + 1, verse: v + 1, text: vs[v]));
            if (result.length >= limit) return result;
          }
        }
      }
    }
    return result;
  }
}

Map<String, List<List<String>>> _decode(Uint8List bytes) {
  final json = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  return {
    for (final b in (json['books'] as List).cast<Map<String, dynamic>>())
      if (Bible._ids.containsKey(b['id']))
        Bible._ids[b['id']]!: [
          for (final ch in b['chapters'] as List) [for (final v in ch as List) v.toString()],
        ],
  };
}
