import 'stage.dart';

/// 例句。
class ExampleSentence {
  ExampleSentence({required this.en, required this.zh});

  final String en;
  final String zh;

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    final en = json['en'];
    final zh = json['zh'];
    if (en is! String || en.isEmpty || zh is! String || zh.isEmpty) {
      throw const FormatException('例句 en/zh 缺失或为空');
    }
    return ExampleSentence(en: en, zh: zh);
  }

  Map<String, dynamic> toJson() => {'en': en, 'zh': zh};
}

/// 词条（spec §5.1）。
class WordEntry {
  WordEntry({
    required this.word,
    required this.phonetic,
    required this.pos,
    required this.meaningZh,
    required this.audioPath,
    required this.examples,
    required this.stage,
    required this.frequencyRank,
  });

  final String word;
  final String phonetic;
  final String pos;
  final String meaningZh;
  final String audioPath;
  final List<ExampleSentence> examples;
  final Stage stage;
  final int frequencyRank;

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    String requireString(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('词条缺少必填字段: $key');
      }
      return v;
    }

    final examplesJson = json['examples'];
    if (examplesJson is! List || examplesJson.isEmpty) {
      throw const FormatException('词条 examples 缺失或为空');
    }
    final rank = json['frequency_rank'];
    if (rank is! int) {
      throw const FormatException('词条 frequency_rank 缺失或非整数');
    }

    return WordEntry(
      word: requireString('word'),
      phonetic: requireString('phonetic'),
      pos: requireString('pos'),
      meaningZh: requireString('meaning_zh'),
      audioPath: requireString('audio'),
      examples: examplesJson
          .cast<Map<String, dynamic>>()
          .map(ExampleSentence.fromJson)
          .toList(),
      stage: Stage.fromName(requireString('stage')),
      frequencyRank: rank,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'pos': pos,
        'meaning_zh': meaningZh,
        'audio': audioPath,
        'examples': examples.map((e) => e.toJson()).toList(),
        'stage': stage.name,
        'frequency_rank': frequencyRank,
      };
}
