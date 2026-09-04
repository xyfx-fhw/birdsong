import 'stage.dart';

/// 例句素材。
class SentenceItem {
  SentenceItem({required this.en, required this.zh, required this.focusWords});

  final String en;
  final String zh;
  final List<String> focusWords;

  factory SentenceItem.fromJson(Map<String, dynamic> json) => SentenceItem(
    en: _requireString(json, 'en'),
    zh: _requireString(json, 'zh'),
    focusWords: _stringList(json, 'focus_words'),
  );

  Map<String, dynamic> toJson() => {
    'en': en,
    'zh': zh,
    'focus_words': focusWords,
  };
}

/// 对话轮次。
class DialogueTurn {
  DialogueTurn({required this.speaker, required this.en, required this.zh});

  final String speaker;
  final String en;
  final String zh;

  factory DialogueTurn.fromJson(Map<String, dynamic> json) => DialogueTurn(
    speaker: _requireString(json, 'speaker'),
    en: _requireString(json, 'en'),
    zh: _requireString(json, 'zh'),
  );

  Map<String, dynamic> toJson() => {'speaker': speaker, 'en': en, 'zh': zh};
}

/// 短对话。
class Dialogue {
  Dialogue({required this.turns});

  final List<DialogueTurn> turns;

  factory Dialogue.fromJson(Map<String, dynamic> json) {
    final turns = json['turns'];
    if (turns is! List || turns.isEmpty) {
      throw const FormatException('对话 turns 缺失或为空');
    }
    return Dialogue(
      turns: turns
          .cast<Map<String, dynamic>>()
          .map(DialogueTurn.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'turns': turns.map((t) => t.toJson()).toList(),
  };
}

/// 阅读短文。
class ReadingItem {
  ReadingItem({
    required this.title,
    required this.body,
    required this.focusWords,
  });

  final String title;
  final String body;
  final List<String> focusWords;

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
    title: _requireString(json, 'title'),
    body: _requireString(json, 'body'),
    focusWords: _stringList(json, 'focus_words'),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'focus_words': focusWords,
  };
}

/// 写作练习类型。
enum WritingPromptType {
  fillBlank,
  freeWrite;

  /// JSON 中用 snake_case（fill_blank / free_write）。
  static WritingPromptType fromName(String name) {
    final camel = name.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    return WritingPromptType.values.firstWhere(
      (t) => t.name == camel,
      orElse: () => throw FormatException('未知写作类型: $name'),
    );
  }

  String toJsonName() => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );
}

/// 写作练习。
class WritingPrompt {
  WritingPrompt({
    required this.type,
    required this.question,
    required this.answer,
    required this.focusWords,
  });

  final WritingPromptType type;
  final String question;

  /// 填空参考答案；自由写作为空字符串。
  final String answer;
  final List<String> focusWords;

  factory WritingPrompt.fromJson(Map<String, dynamic> json) => WritingPrompt(
    type: WritingPromptType.fromName(_requireString(json, 'type')),
    question: _requireString(json, 'question'),
    answer: json['answer'] is String ? json['answer'] as String : '',
    focusWords: _stringList(json, 'focus_words'),
  );

  Map<String, dynamic> toJson() => {
    'type': type.toJsonName(),
    'question': question,
    'answer': answer,
    'focus_words': focusWords,
  };
}

/// 每日学习单元（spec §5.2）。按单元组织，不按日期。
class DailyUnit {
  DailyUnit({
    required this.stage,
    required this.unitNumber,
    required this.newWords,
    required this.sentences,
    required this.dialogues,
    required this.readings,
    required this.writingPrompts,
  });

  final Stage stage;
  final int unitNumber;
  final List<String> newWords;
  final List<SentenceItem> sentences;
  final List<Dialogue> dialogues;
  final List<ReadingItem> readings;
  final List<WritingPrompt> writingPrompts;

  factory DailyUnit.fromJson(Map<String, dynamic> json) {
    final newWords = _stringList(json, 'new_words');
    if (newWords.isEmpty) {
      throw const FormatException('单元 new_words 不能为空');
    }
    final unit = json['unit'];
    if (unit is! int || unit < 1) {
      throw const FormatException('单元 unit 必须为正整数');
    }
    return DailyUnit(
      stage: Stage.fromName(_requireString(json, 'stage')),
      unitNumber: unit,
      newWords: newWords,
      sentences: _list(json, 'sentences').map(SentenceItem.fromJson).toList(),
      dialogues: _list(json, 'dialogues').map(Dialogue.fromJson).toList(),
      readings: _list(json, 'readings').map(ReadingItem.fromJson).toList(),
      writingPrompts: _list(
        json,
        'writing_prompts',
      ).map(WritingPrompt.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'unit': unitNumber,
    'new_words': newWords,
    'sentences': sentences.map((s) => s.toJson()).toList(),
    'dialogues': dialogues.map((d) => d.toJson()).toList(),
    'readings': readings.map((r) => r.toJson()).toList(),
    'writing_prompts': writingPrompts.map((w) => w.toJson()).toList(),
  };
}

String _requireString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String || v.isEmpty) {
    throw FormatException('缺少必填字段: $key');
  }
  return v;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! List) {
    throw FormatException('缺少字段: $key');
  }
  return v.cast<String>();
}

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! List) return [];
  return v.cast<Map<String, dynamic>>();
}
