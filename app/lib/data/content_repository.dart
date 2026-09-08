import 'dart:convert';

import 'package:content_models/content_models.dart';
import 'package:sqlite3/sqlite3.dart';

/// content.db 只读访问层。
/// 表结构由 tools/content_pipeline 生成，见 spec §5。
class ContentRepository {
  ContentRepository._(this._db);

  final Database _db;

  /// 以只读模式打开 content.db。
  static ContentRepository open(String path) =>
      ContentRepository._(sqlite3.open(path, mode: OpenMode.readOnly));

  void dispose() => _db.dispose();

  /// 某阶段全部词条（含例句），按词频升序。
  List<WordEntry> wordsOfStage(Stage stage) {
    final rows = _db.select(
      'SELECT word, phonetic, pos, meaning_zh, audio, frequency_rank '
      'FROM words WHERE stage = ? ORDER BY frequency_rank',
      [stage.name],
    );
    return rows.map((r) {
      final word = r['word'] as String;
      final examples = _db.select(
        'SELECT en, zh FROM examples WHERE word = ? ORDER BY seq',
        [word],
      );
      return WordEntry(
        word: word,
        phonetic: r['phonetic'] as String,
        pos: r['pos'] as String,
        meaningZh: r['meaning_zh'] as String,
        audioPath: r['audio'] as String,
        frequencyRank: r['frequency_rank'] as int,
        stage: stage,
        examples: [
          for (final e in examples)
            ExampleSentence(en: e['en'] as String, zh: e['zh'] as String),
        ],
      );
    }).toList();
  }

  /// 按词查词条；不存在返回 null。
  WordEntry? wordOf(String word) {
    final rows = _db.select(
      'SELECT stage, phonetic, pos, meaning_zh, audio, frequency_rank '
      'FROM words WHERE word = ?',
      [word],
    );
    if (rows.isEmpty) return null;
    final r = rows.single;
    final examples = _db.select(
      'SELECT en, zh FROM examples WHERE word = ? ORDER BY seq',
      [word],
    );
    return WordEntry(
      word: word,
      phonetic: r['phonetic'] as String,
      pos: r['pos'] as String,
      meaningZh: r['meaning_zh'] as String,
      audioPath: r['audio'] as String,
      frequencyRank: r['frequency_rank'] as int,
      stage: Stage.fromName(r['stage'] as String),
      examples: [
        for (final e in examples)
          ExampleSentence(en: e['en'] as String, zh: e['zh'] as String),
      ],
    );
  }

  /// 某阶段全部单元，按单元号升序。
  List<DailyUnit> unitsOfStage(Stage stage) {
    final rows = _db.select(
      'SELECT unit, new_words, sentences, dialogues, readings, writing_prompts '
      'FROM units WHERE stage = ? ORDER BY unit',
      [stage.name],
    );
    return rows.map((r) {
      return DailyUnit(
        stage: stage,
        unitNumber: r['unit'] as int,
        newWords: (jsonDecode(r['new_words'] as String) as List).cast<String>(),
        sentences: _decodeList(r['sentences'] as String, SentenceItem.fromJson),
        dialogues: _decodeList(r['dialogues'] as String, Dialogue.fromJson),
        readings: _decodeList(r['readings'] as String, ReadingItem.fromJson),
        writingPrompts:
            _decodeList(r['writing_prompts'] as String, WritingPrompt.fromJson),
      );
    }).toList();
  }

  /// 找到 new_words 与今日新词有交集的单元（串词巩固用）；无则 null。
  DailyUnit? unitContaining(Stage stage, List<String> newWords) {
    final set = newWords.toSet();
    for (final unit in unitsOfStage(stage)) {
      if (unit.newWords.any(set.contains)) return unit;
    }
    return null;
  }

  /// 该阶段尚未学习的词，按词频升序。
  List<String> pendingNewWords(Stage stage, Set<String> learned) =>
      wordsOfStage(stage)
          .map((w) => w.word)
          .where((w) => !learned.contains(w))
          .toList();

  List<T> _decodeList<T>(
      String json, T Function(Map<String, dynamic>) fromJson) =>
      (jsonDecode(json) as List)
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
}
