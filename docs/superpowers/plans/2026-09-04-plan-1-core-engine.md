# 学个鸟语 · 计划 1：核心引擎与内容管线 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建 Flutter monorepo 骨架，实现可 100% 单测覆盖的 SRS 学习引擎（srs_core）、共享内容模型（content_models）和内容构建管线（tools/content_pipeline），并用样例内容产出可集成的 content.db。

**Architecture:** 纯 Dart 包优先（无 Flutter 依赖，直接 `dart test`）。srs_core 实现熟悉度状态机、艾宾浩斯排期、每日任务编排与成就判定；content_models 定义词条/单元素材模型；管线读取 content_src/ JSON，校验后生成只读 content.db（SQLite）。

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2（stable）；drift（SQLite，user.db 与 content.db 共用）；melos 管理 monorepo；content_pipeline 用纯 Dart + sqlite3 包。

**Spec:** `docs/superpowers/specs/2026-09-04-xuege-niaoyu-design.md`

## Global Constraints

- 词汇量为累计值：中级 3000 / 高级累计 5000（新增 2000）/ 专业级累计 7000（新增 2000），全 app 去重总量 7000
- 熟悉度 5 档：陌生(L0) / 模糊(L1) / 认识(L2) / 熟悉(L3) / 牢记(L4)；新词默认「模糊」
- 艾宾浩斯阶梯（每档 2 个间隔，本档答对 2 次升档）：陌生 10分钟/1天；模糊 2天/4天；认识 7天/15天；熟悉 1个月/3个月；牢记=毕业不再复习
- 调档规则 8 条（spec §4.3）：答对 2 次升 1 档；答错降 2 档（下限 L0）且会话内重现；变档后从新档间隔 1 重走（答对计数清零）；手动调档从该档间隔 1 开始、手动设牢记=毕业；当日必过（答错持续重现直到答对）；新词/错词次日强制复习一次后阶梯照常；积压 >100 暂停新词（10→6→0）；待复习 >75 时周末提前消化未来 3 天到期的复习
- 每日新词：中级 10 个；高级/专业级 6 个
- 周末/节假日：只复习 + 轻量串词，不学新词（积压 >75 除外）
- 晋升条件：当前阶段词表学完 + 毕业词比例 ≥ 80%（可配置）
- content.db 只读、含 content_version；user.db 读写；两库严格分离
- content_src/ 与 tools/ 不随 app 发布
- 所有时间计算必须可注入"当前时间"（测试友好），禁止在核心逻辑里直接调用 DateTime.now()

---

## File Structure

```
birdsong/
├── melos.yaml                          # monorepo 工作区配置
├── pubspec.yaml                        # 根 workspace pubspec
├── packages/
│   ├── content_models/
│   │   ├── pubspec.yaml
│   │   ├── lib/content_models.dart     # 导出
│   │   ├── lib/src/stage.dart          # Stage 枚举（中级/高级/专业级）
│   │   ├── lib/src/word_entry.dart     # 词条模型 + JSON 序列化
│   │   ├── lib/src/daily_unit.dart     # 每日单元素材模型 + JSON 序列化
│   │   └── test/                       # 模型与序列化测试
│   └── srs_core/
│       ├── pubspec.yaml
│       ├── lib/srs_core.dart           # 导出
│       ├── lib/src/familiarity.dart    # Familiarity 枚举 + 间隔表
│       ├── lib/src/word_state.dart     # 单词学习状态（档位/计数/日期）
│       ├── lib/src/scheduler.dart      # 排期引擎：到期判定、次日强制、周末消耗
│       ├── lib/src/answer_result.dart  # 答题结果处理：升降档状态机
│       ├── lib/src/session_planner.dart# 每日任务编排：复习队列+新词+保险阀
│       ├── lib/src/achievements.dart   # 成就判定（配置驱动）
│       ├── lib/src/promotion.dart      # 晋升条件判定
│       └── test/                       # 各模块单测
├── tools/
│   └── content_pipeline/
│       ├── pubspec.yaml
│       ├── bin/build_content.dart      # 入口：校验 + 生成 content.db + 复制音频
│       ├── lib/src/validator.dart      # JSON schema/词数/音频齐全性校验
│       ├── lib/src/db_builder.dart     # 写 content.db（sqlite3）
│       └── test/                       # 校验与构建测试
├── content_src/
│   ├── wordlists/intermediate.json     # 样例词表（计划内用 20 词样例）
│   └── daily/intermediate/unit_001.json# 样例单元
└── app/                                # 计划 2 创建，本计划仅预留
```

---

### Task 1: Monorepo 骨架与 workspace 配置

**Files:**
- Create: `melos.yaml`
- Create: `pubspec.yaml`（根）
- Create: `packages/content_models/pubspec.yaml`
- Create: `packages/srs_core/pubspec.yaml`
- Create: `tools/content_pipeline/pubspec.yaml`
- Modify: `.gitignore`

**Interfaces:**
- Produces: 可运行的 `melos bootstrap`、`dart test` 基础设施；后续所有任务依赖此骨架

- [ ] **Step 1: 创建根 pubspec.yaml（workspace 声明）**

```yaml
name: birdsong_workspace
publish_to: none
environment:
  sdk: ^3.13.0
workspace:
  - packages/content_models
  - packages/srs_core
  - tools/content_pipeline
```

- [ ] **Step 2: 创建 melos.yaml**

```yaml
name: birdsong
packages:
  - packages/*
  - tools/*
  - app

scripts:
  analyze:
    run: melos exec -- dart analyze --fatal-infos
  test:
    run: melos exec --dir-exists=test -- dart test
```

- [ ] **Step 3: 创建 packages/content_models/pubspec.yaml**

```yaml
name: content_models
description: 学个鸟语 - 词表与每日内容共享数据模型
version: 0.1.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.13.0
dev_dependencies:
  test: ^1.25.0
```

- [ ] **Step 4: 创建 packages/srs_core/pubspec.yaml**

```yaml
name: srs_core
description: 学个鸟语 - SRS 学习引擎（熟悉度/艾宾浩斯/任务编排/成就）
version: 0.1.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.13.0
dependencies:
  content_models:
    path: ../content_models
dev_dependencies:
  test: ^1.25.0
```

- [ ] **Step 5: 创建 tools/content_pipeline/pubspec.yaml**

```yaml
name: content_pipeline
description: 学个鸟语 - 内容构建管线（content_src → content.db）
version: 0.1.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.13.0
dependencies:
  content_models:
    path: ../../packages/content_models
  sqlite3: ^2.4.0
  args: ^2.5.0
  path: ^1.9.0
dev_dependencies:
  test: ^1.25.0
```

- [ ] **Step 6: 为每个包创建占位入口文件**

`packages/content_models/lib/content_models.dart`：

```dart
/// 学个鸟语 - 词表与每日内容共享数据模型。
library content_models;
```

`packages/srs_core/lib/srs_core.dart`：

```dart
/// 学个鸟语 - SRS 学习引擎。
library srs_core;
```

`tools/content_pipeline/bin/build_content.dart`：

```dart
void main(List<String> args) {
  throw UnimplementedError('Task 12 实现');
}
```

- [ ] **Step 7: .gitignore 追加 Dart/Flutter 规则**

在现有 `.gitignore` 末尾追加：

```
# Dart/Flutter
.dart_tool/
build/
pubspec.lock
.flutter-plugins
.flutter-plugins-dependencies
```

- [ ] **Step 8: 安装依赖并验证**

Run: `flutter pub get && melos bootstrap`
Expected: 三个包解析成功，无错误

Run: `melos analyze`
Expected: 无 error（info/warning 允许为空包提示）

- [ ] **Step 9: Commit**

```bash
git add melos.yaml pubspec.yaml packages tools .gitignore
git commit -m "chore: 搭建 monorepo 骨架（content_models/srs_core/content_pipeline）"
```

---

### Task 2: content_models — Stage 枚举与词条模型

**Files:**
- Create: `packages/content_models/lib/src/stage.dart`
- Create: `packages/content_models/lib/src/word_entry.dart`
- Modify: `packages/content_models/lib/content_models.dart`
- Test: `packages/content_models/test/word_entry_test.dart`

**Interfaces:**
- Produces: `enum Stage { intermediate, advanced, professional }`（含 `dailyNewWords` getter：10/6/6、`label` 中文名）；`class WordEntry { word, phonetic, pos, meaningZh, audioPath, examples, stage, frequencyRank }` 与 `WordEntry.fromJson(Map<String, dynamic>)` / `toJson()`；`class ExampleSentence { en, zh }`

- [ ] **Step 1: 写失败测试**

`packages/content_models/test/word_entry_test.dart`：

```dart
import 'package:content_models/content_models.dart';
import 'package:test/test.dart';

void main() {
  group('Stage', () {
    test('每日新词量：中级10，高级/专业级6', () {
      expect(Stage.intermediate.dailyNewWords, 10);
      expect(Stage.advanced.dailyNewWords, 6);
      expect(Stage.professional.dailyNewWords, 6);
    });
  });

  group('WordEntry', () {
    final json = {
      'word': 'abundant',
      'phonetic': '/əˈbʌndənt/',
      'pos': 'adj.',
      'meaning_zh': '丰富的，充裕的',
      'audio': 'advanced/abundant.mp3',
      'examples': [
        {'en': 'The region has abundant natural resources.', 'zh': '该地区自然资源丰富。'}
      ],
      'stage': 'advanced',
      'frequency_rank': 4200,
    };

    test('fromJson 解析完整词条', () {
      final entry = WordEntry.fromJson(json);
      expect(entry.word, 'abundant');
      expect(entry.phonetic, '/əˈbʌndənt/');
      expect(entry.pos, 'adj.');
      expect(entry.meaningZh, '丰富的，充裕的');
      expect(entry.audioPath, 'advanced/abundant.mp3');
      expect(entry.examples, hasLength(1));
      expect(entry.examples.first.en, contains('abundant'));
      expect(entry.stage, Stage.advanced);
      expect(entry.frequencyRank, 4200);
    });

    test('toJson 与 fromJson 往返一致', () {
      final entry = WordEntry.fromJson(json);
      expect(WordEntry.fromJson(entry.toJson()).word, entry.word);
      expect(WordEntry.fromJson(entry.toJson()).frequencyRank, 4200);
    });

    test('缺少必填字段时抛 FormatException', () {
      final bad = Map<String, dynamic>.from(json)..remove('meaning_zh');
      expect(() => WordEntry.fromJson(bad), throwsFormatException);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/content_models && dart test`
Expected: FAIL（Stage/WordEntry 未定义）

- [ ] **Step 3: 实现 stage.dart**

```dart
/// 学习阶段。词汇量为累计值：中级 3000 / 高级 5000 / 专业级 7000。
enum Stage {
  intermediate('中级', 10),
  advanced('高级', 6),
  professional('专业级', 6);

  const Stage(this.label, this.dailyNewWords);

  final String label;

  /// 每日新词量（spec §1）。
  final int dailyNewWords;

  static Stage fromName(String name) =>
      Stage.values.firstWhere((s) => s.name == name,
          orElse: () => throw FormatException('未知阶段: $name'));
}
```

- [ ] **Step 4: 实现 word_entry.dart**

```dart
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
```

- [ ] **Step 5: 更新导出文件 content_models.dart**

```dart
/// 学个鸟语 - 词表与每日内容共享数据模型。
library content_models;

export 'src/stage.dart';
export 'src/word_entry.dart';
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd packages/content_models && dart test`
Expected: PASS（4 tests）

- [ ] **Step 7: Commit**

```bash
git add packages/content_models
git commit -m "feat(content_models): Stage 枚举与 WordEntry 词条模型"
```

---

### Task 3: content_models — 每日单元素材模型

**Files:**
- Create: `packages/content_models/lib/src/daily_unit.dart`
- Modify: `packages/content_models/lib/content_models.dart`
- Test: `packages/content_models/test/daily_unit_test.dart`

**Interfaces:**
- Consumes: Task 2 的 `Stage`
- Produces: `class DailyUnit { stage, unitNumber, newWords (List<String>), sentences, dialogues, readings, writingPrompts }` 与 `fromJson`/`toJson`；`class SentenceItem { en, zh, focusWords }`；`class Dialogue { turns: List<DialogueTurn> }`、`class DialogueTurn { speaker, en, zh }`；`class ReadingItem { title, body, focusWords }`；`class WritingPrompt { type (fillBlank/freeWrite), question, answer, focusWords }`

- [ ] **Step 1: 写失败测试**

`packages/content_models/test/daily_unit_test.dart`：

```dart
import 'package:content_models/content_models.dart';
import 'package:test/test.dart';

void main() {
  final json = {
    'stage': 'intermediate',
    'unit': 1,
    'new_words': ['apple', 'water'],
    'sentences': [
      {'en': 'I drink water every day.', 'zh': '我每天喝水。', 'focus_words': ['water']}
    ],
    'dialogues': [
      {
        'turns': [
          {'speaker': 'A', 'en': 'Do you want an apple?', 'zh': '你想要一个苹果吗？'},
          {'speaker': 'B', 'en': 'Yes, please.', 'zh': '好的，谢谢。'},
        ]
      }
    ],
    'readings': [
      {'title': 'A Healthy Day', 'body': 'I eat an apple and drink water.', 'focus_words': ['apple', 'water']}
    ],
    'writing_prompts': [
      {'type': 'fill_blank', 'question': 'I drink ___ every day.', 'answer': 'water', 'focus_words': ['water']}
    ],
  };

  test('fromJson 解析完整单元', () {
    final unit = DailyUnit.fromJson(json);
    expect(unit.stage, Stage.intermediate);
    expect(unit.unitNumber, 1);
    expect(unit.newWords, ['apple', 'water']);
    expect(unit.sentences.single.focusWords, ['water']);
    expect(unit.dialogues.single.turns, hasLength(2));
    expect(unit.readings.single.title, 'A Healthy Day');
    expect(unit.writingPrompts.single.type, WritingPromptType.fillBlank);
  });

  test('new_words 为空时抛 FormatException', () {
    final bad = Map<String, dynamic>.from(json)..['new_words'] = <String>[];
    expect(() => DailyUnit.fromJson(bad), throwsFormatException);
  });

  test('toJson 往返一致', () {
    final unit = DailyUnit.fromJson(json);
    final roundTrip = DailyUnit.fromJson(unit.toJson());
    expect(roundTrip.newWords, unit.newWords);
    expect(roundTrip.dialogues.single.turns.length, 2);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/content_models && dart test test/daily_unit_test.dart`
Expected: FAIL（DailyUnit 未定义）

- [ ] **Step 3: 实现 daily_unit.dart**

```dart
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

  Map<String, dynamic> toJson() =>
      {'en': en, 'zh': zh, 'focus_words': focusWords};
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
      turns: turns.cast<Map<String, dynamic>>().map(DialogueTurn.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'turns': turns.map((t) => t.toJson()).toList()};
}

/// 阅读短文。
class ReadingItem {
  ReadingItem({required this.title, required this.body, required this.focusWords});

  final String title;
  final String body;
  final List<String> focusWords;

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
        title: _requireString(json, 'title'),
        body: _requireString(json, 'body'),
        focusWords: _stringList(json, 'focus_words'),
      );

  Map<String, dynamic> toJson() =>
      {'title': title, 'body': body, 'focus_words': focusWords};
}

/// 写作练习类型。
enum WritingPromptType {
  fillBlank,
  freeWrite;

  static WritingPromptType fromName(String name) =>
      WritingPromptType.values.firstWhere((t) => t.name == name,
          orElse: () => throw FormatException('未知写作类型: $name'));
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
        'type': type.name,
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
      writingPrompts:
          _list(json, 'writing_prompts').map(WritingPrompt.fromJson).toList(),
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
```

- [ ] **Step 4: 导出追加到 content_models.dart**

```dart
export 'src/daily_unit.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd packages/content_models && dart test`
Expected: PASS（7 tests 全绿）

- [ ] **Step 6: Commit**

```bash
git add packages/content_models
git commit -m "feat(content_models): DailyUnit 每日单元素材模型"
```

---

### Task 4: srs_core — 熟悉度枚举与间隔表

**Files:**
- Create: `packages/srs_core/lib/src/familiarity.dart`
- Modify: `packages/srs_core/lib/srs_core.dart`
- Test: `packages/srs_core/test/familiarity_test.dart`

**Interfaces:**
- Produces: `enum Familiarity { unknown(L0陌生), vague(L1模糊), recognize(L2认识), familiar(L3熟悉), mastered(L4牢记) }`；`class ReviewInterval`（`Duration? duration` 与 `int? months`，`DateTime dueFrom(DateTime base)`）；常量 `intervalLadder`：`Map<Familiarity, (ReviewInterval, ReviewInterval)>` = 陌生(10分钟,1天)、模糊(2天,4天)、认识(7天,15天)、熟悉(1月,3月)；`correctAnswersToPromote = 2`

- [ ] **Step 1: 写失败测试**

`packages/srs_core/test/familiarity_test.dart`：

```dart
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  test('5 档顺序：陌生<模糊<认识<熟悉<牢记', () {
    expect(Familiarity.values, [
      Familiarity.unknown,
      Familiarity.vague,
      Familiarity.recognize,
      Familiarity.familiar,
      Familiarity.mastered,
    ]);
  });

  test('间隔表符合 spec §4.2', () {
    final ladder = intervalLadder;
    expect(ladder[Familiarity.unknown]!.$1, ReviewInterval.minutes(10));
    expect(ladder[Familiarity.unknown]!.$2, ReviewInterval.days(1));
    expect(ladder[Familiarity.vague]!.$1, ReviewInterval.days(2));
    expect(ladder[Familiarity.vague]!.$2, ReviewInterval.days(4));
    expect(ladder[Familiarity.recognize]!.$1, ReviewInterval.days(7));
    expect(ladder[Familiarity.recognize]!.$2, ReviewInterval.days(15));
    expect(ladder[Familiarity.familiar]!.$1, ReviewInterval.months(1));
    expect(ladder[Familiarity.familiar]!.$2, ReviewInterval.months(3));
    expect(ladder.containsKey(Familiarity.mastered), isFalse);
  });

  test('dueFrom 按天计算', () {
    final base = DateTime(2026, 9, 1, 8);
    expect(ReviewInterval.days(2).dueFrom(base), DateTime(2026, 9, 3, 8));
    expect(ReviewInterval.minutes(10).dueFrom(base), DateTime(2026, 9, 1, 8, 10));
  });

  test('dueFrom 按月计算（月末收敛）', () {
    expect(ReviewInterval.months(1).dueFrom(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28));
    expect(ReviewInterval.months(3).dueFrom(DateTime(2026, 9, 4)),
        DateTime(2026, 12, 4));
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/srs_core && dart test`
Expected: FAIL（Familiarity 未定义）

- [ ] **Step 3: 实现 familiarity.dart**

```dart
/// 复习间隔。用 duration 表示分钟/天级间隔，用 months 表示月级间隔
/// （月长度不固定，必须用日历计算）。
class ReviewInterval {
  const ReviewInterval.minutes(int m) : duration = Duration(minutes: m), months = null;
  const ReviewInterval.days(int d) : duration = Duration(days: d), months = null;
  const ReviewInterval.months(this.months) : duration = null;

  final Duration? duration;
  final int? months;

  /// 从 base 推算到期时间。月间隔按日历月计算，日溢出收敛到月末。
  DateTime dueFrom(DateTime base) {
    if (duration != null) return base.add(duration!);
    final m = months!;
    final totalMonths = base.year * 12 + (base.month - 1) + m;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = base.day > maxDay ? maxDay : base.day;
    return DateTime(year, month, day, base.hour, base.minute);
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewInterval && other.duration == duration && other.months == months;

  @override
  int get hashCode => Object.hash(duration, months);

  @override
  String toString() =>
      duration != null ? 'Interval(${duration!.inMinutes}min)' : 'Interval(${months}mo)';
}

/// 熟悉度 5 档（spec §4.1）。新词默认 [vague]。
enum Familiarity {
  unknown('陌生'),
  vague('模糊'),
  recognize('认识'),
  familiar('熟悉'),
  mastered('牢记');

  const Familiarity(this.label);

  final String label;

  bool get isMastered => this == mastered;
}

/// 艾宾浩斯间隔阶梯（spec §4.2）。每档两个间隔，本档答对 2 次升档。
/// mastered 无间隔（毕业，不再安排复习）。
const intervalLadder = <Familiarity, (ReviewInterval, ReviewInterval)>{
  Familiarity.unknown: (ReviewInterval.minutes(10), ReviewInterval.days(1)),
  Familiarity.vague: (ReviewInterval.days(2), ReviewInterval.days(4)),
  Familiarity.recognize: (ReviewInterval.days(7), ReviewInterval.days(15)),
  Familiarity.familiar: (ReviewInterval.months(1), ReviewInterval.months(3)),
};

/// 每档需要连续答对次数才能升档（spec §4.3 规则 1）。
const correctAnswersToPromote = 2;

/// 答错降档数（spec §4.3 规则 2）。
const demoteStepsOnWrong = 2;
```

- [ ] **Step 4: 导出 srs_core.dart**

```dart
/// 学个鸟语 - SRS 学习引擎。
library srs_core;

export 'src/familiarity.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd packages/srs_core && dart test`
Expected: PASS（4 tests）

- [ ] **Step 6: Commit**

```bash
git add packages/srs_core
git commit -m "feat(srs_core): 熟悉度 5 档与艾宾浩斯间隔表"
```

---

### Task 5: srs_core — 单词学习状态与答题状态机

**Files:**
- Create: `packages/srs_core/lib/src/word_state.dart`
- Create: `packages/srs_core/lib/src/answer_result.dart`
- Modify: `packages/srs_core/lib/srs_core.dart`
- Test: `packages/srs_core/test/answer_result_test.dart`

**Interfaces:**
- Consumes: Task 4 的 `Familiarity`、`intervalLadder`、`correctAnswersToPromote`、`demoteStepsOnWrong`
- Produces: `class WordState { word, familiarity, correctCountInLevel, learnedOn, lastReviewedAt, nextDueAt, missedOn (DateTime? 最近答错日), graduated }` 与 `WordState.newWord(word, now)`（默认模糊、排期到间隔 1）；`class AnswerOutcome { newState, reappearInSession (bool) }`；`AnswerOutcome applyAnswer(WordState state, {required bool correct, required DateTime now})`；`WordState applyManualLevel(WordState state, Familiarity level, DateTime now)`

- [ ] **Step 1: 写失败测试**

`packages/srs_core/test/answer_result_test.dart`：

```dart
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  final day0 = DateTime(2026, 9, 1, 20);

  group('新词', () {
    test('默认模糊，排期到间隔1（2天后）', () {
      final s = WordState.newWord('apple', day0);
      expect(s.familiarity, Familiarity.vague);
      expect(s.correctCountInLevel, 0);
      expect(s.graduated, isFalse);
      expect(s.nextDueAt, DateTime(2026, 9, 3, 20));
    });
  });

  group('答对升档（规则1：本档答对2次升1档）', () {
    test('模糊档答对2次 → 认识，从间隔1（7天）重走', () {
      var s = WordState.newWord('apple', day0);
      s = applyAnswer(s, correct: true, now: day0).newState;
      expect(s.familiarity, Familiarity.vague);
      expect(s.correctCountInLevel, 1);
      s = applyAnswer(s, correct: true, now: day0).newState;
      expect(s.familiarity, Familiarity.recognize);
      expect(s.correctCountInLevel, 0);
      expect(s.nextDueAt, DateTime(2026, 9, 8, 20));
    });

    test('熟悉档答对2次 → 牢记（毕业），无下次到期', () {
      var s = WordState.newWord('apple', day0);
      // 爬到熟悉档：模糊2次 + 认识2次
      for (var i = 0; i < 4; i++) {
        s = applyAnswer(s, correct: true, now: day0).newState;
      }
      expect(s.familiarity, Familiarity.familiar);
      s = applyAnswer(s, correct: true, now: day0).newState;
      s = applyAnswer(s, correct: true, now: day0).newState;
      expect(s.familiarity, Familiarity.mastered);
      expect(s.graduated, isTrue);
      expect(s.nextDueAt, isNull);
    });
  });

  group('答错降档（规则2/3）', () {
    test('认识档答错 → 降2档到陌生，从间隔1（10分钟）重走，会话内重现', () {
      var s = WordState.newWord('apple', day0);
      s = applyAnswer(s, correct: true, now: day0).newState;
      s = applyAnswer(s, correct: true, now: day0).newState;
      expect(s.familiarity, Familiarity.recognize);
      final outcome = applyAnswer(s, correct: false, now: day0);
      expect(outcome.newState.familiarity, Familiarity.unknown);
      expect(outcome.newState.correctCountInLevel, 0);
      expect(outcome.newState.nextDueAt, day0.add(const Duration(minutes: 10)));
      expect(outcome.reappearInSession, isTrue);
      expect(outcome.newState.missedOn, day0);
    });

    test('模糊档答错 → 降到下限陌生（不再往下）', () {
      final s = WordState.newWord('apple', day0);
      final outcome = applyAnswer(s, correct: false, now: day0);
      expect(outcome.newState.familiarity, Familiarity.unknown);
    });
  });

  group('手动调档（规则4）', () {
    test('手动设为认识 → 从间隔1（7天）开始走', () {
      final s = WordState.newWord('apple', day0);
      final manual = applyManualLevel(s, Familiarity.recognize, day0);
      expect(manual.familiarity, Familiarity.recognize);
      expect(manual.correctCountInLevel, 0);
      expect(manual.nextDueAt, DateTime(2026, 9, 8, 20));
    });

    test('手动设为牢记 → 直接毕业', () {
      final s = WordState.newWord('apple', day0);
      final manual = applyManualLevel(s, Familiarity.mastered, day0);
      expect(manual.graduated, isTrue);
      expect(manual.nextDueAt, isNull);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/srs_core && dart test test/answer_result_test.dart`
Expected: FAIL（WordState 未定义）

- [ ] **Step 3: 实现 word_state.dart**

```dart
import 'familiarity.dart';

/// 单个单词的学习状态（持久化于 user.db，此处为纯数据）。
class WordState {
  WordState({
    required this.word,
    required this.familiarity,
    required this.correctCountInLevel,
    required this.learnedOn,
    this.lastReviewedAt,
    this.nextDueAt,
    this.missedOn,
    this.graduated = false,
  });

  final String word;
  final Familiarity familiarity;

  /// 当前档位内已连续答对次数（0/1/2，到 2 即升档并清零）。
  final int correctCountInLevel;

  /// 首次学习日期（用于次日强制复习判定，规则 6）。
  final DateTime learnedOn;
  final DateTime? lastReviewedAt;

  /// 下次到期时间；毕业词为 null。
  final DateTime? nextDueAt;

  /// 最近一次答错的日期（用于次日强制复习判定，规则 6）。
  final DateTime? missedOn;
  final bool graduated;

  /// 新词：默认模糊，排期到该档间隔 1（spec §4.1/§4.2）。
  factory WordState.newWord(String word, DateTime now) {
    const level = Familiarity.vague;
    return WordState(
      word: word,
      familiarity: level,
      correctCountInLevel: 0,
      learnedOn: now,
      nextDueAt: intervalLadder[level]!.$1.dueFrom(now),
    );
  }

  WordState copyWith({
    Familiarity? familiarity,
    int? correctCountInLevel,
    DateTime? lastReviewedAt,
    DateTime? nextDueAt,
    DateTime? missedOn,
    bool? graduated,
  }) =>
      WordState(
        word: word,
        familiarity: familiarity ?? this.familiarity,
        correctCountInLevel: correctCountInLevel ?? this.correctCountInLevel,
        learnedOn: learnedOn,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        nextDueAt: nextDueAt ?? this.nextDueAt,
        missedOn: missedOn ?? this.missedOn,
        graduated: graduated ?? this.graduated,
      );
}
```

- [ ] **Step 4: 实现 answer_result.dart**

```dart
import 'familiarity.dart';
import 'word_state.dart';

/// 一次答题的结果。
class AnswerOutcome {
  AnswerOutcome({required this.newState, required this.reappearInSession});

  final WordState newState;

  /// 答错时为 true：该词须在本次会话结束前重现（规则 2/5）。
  final bool reappearInSession;
}

Familiarity _shift(Familiarity level, int steps) {
  final idx = (level.index + steps).clamp(0, Familiarity.values.length - 1);
  return Familiarity.values[idx];
}

/// 处理一次答题（spec §4.3 规则 1-3）。
AnswerOutcome applyAnswer(WordState state, {required bool correct, required DateTime now}) {
  if (correct) {
    final count = state.correctCountInLevel + 1;
    if (count < correctAnswersToPromote) {
      // 本档未集满：留在原档，按当前进度排到下一个间隔
      final ladder = intervalLadder[state.familiarity]!;
      final next = count == 1 ? ladder.$1 : ladder.$2;
      return AnswerOutcome(
        newState: state.copyWith(
          correctCountInLevel: count,
          lastReviewedAt: now,
          nextDueAt: next.dueFrom(now),
        ),
        reappearInSession: false,
      );
    }
    // 升 1 档（规则 1）
    final promoted = _shift(state.familiarity, 1);
    if (promoted.isMastered) {
      return AnswerOutcome(
        newState: state.copyWith(
          familiarity: promoted,
          correctCountInLevel: 0,
          lastReviewedAt: now,
          nextDueAt: null,
          graduated: true,
        ),
        reappearInSession: false,
      );
    }
    // 变档后从新档间隔 1 重走（规则 3）
    return AnswerOutcome(
      newState: state.copyWith(
        familiarity: promoted,
        correctCountInLevel: 0,
        lastReviewedAt: now,
        nextDueAt: intervalLadder[promoted]!.$1.dueFrom(now),
      ),
      reappearInSession: false,
    );
  }

  // 答错：降 2 档（下限陌生），从新档间隔 1 重走，会话内重现（规则 2/3）
  final demoted = _shift(state.familiarity, -demoteStepsOnWrong);
  return AnswerOutcome(
    newState: state.copyWith(
      familiarity: demoted,
      correctCountInLevel: 0,
      lastReviewedAt: now,
      nextDueAt: intervalLadder[demoted]!.$1.dueFrom(now),
      missedOn: now,
    ),
    reappearInSession: true,
  );
}

/// 手动调档（规则 4）：从目标档间隔 1 开始走；设牢记 = 直接毕业。
WordState applyManualLevel(WordState state, Familiarity level, DateTime now) {
  if (level.isMastered) {
    return state.copyWith(
      familiarity: level,
      correctCountInLevel: 0,
      lastReviewedAt: now,
      nextDueAt: null,
      graduated: true,
    );
  }
  return state.copyWith(
    familiarity: level,
    correctCountInLevel: 0,
    lastReviewedAt: now,
    nextDueAt: intervalLadder[level]!.$1.dueFrom(now),
  );
}
```

- [ ] **Step 5: 导出追加到 srs_core.dart**

```dart
export 'src/word_state.dart';
export 'src/answer_result.dart';
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd packages/srs_core && dart test`
Expected: PASS（11 tests 全绿）

- [ ] **Step 7: Commit**

```bash
git add packages/srs_core
git commit -m "feat(srs_core): WordState 与答题升降档状态机"
```

---

### Task 6: srs_core — 排期引擎（到期判定 + 次日强制 + 周末消耗）

**Files:**
- Create: `packages/srs_core/lib/src/scheduler.dart`
- Modify: `packages/srs_core/lib/srs_core.dart`
- Test: `packages/srs_core/test/scheduler_test.dart`

**Interfaces:**
- Consumes: Task 5 的 `WordState`
- Produces: `bool isDue(WordState s, DateTime now)`（到期 或 次日强制规则命中）；`bool needsNextDayReview(WordState s, DateTime now)`（规则 6：learnedOn 或 missedOn 为昨天且未毕业）；`List<WordState> dueWords(Iterable<WordState> all, DateTime now)`（按到期时间排序）；`List<WordState> weekendExtraWords(Iterable<WordState> all, DateTime now, {required int backlogCount, int threshold = 75, int lookaheadDays = 3})`（规则 8：backlogCount > threshold 时返回未来 lookaheadDays 天内到期的词）

- [ ] **Step 1: 写失败测试**

`packages/srs_core/test/scheduler_test.dart`：

```dart
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  final day0 = DateTime(2026, 9, 1, 20); // 周二
  final day1 = day0.add(const Duration(days: 1));

  group('isDue 基础到期判定', () {
    test('未到期的词不算到期', () {
      final s = WordState.newWord('a', day0); // 到期日 9/3
      expect(isDue(s, day1), isFalse);
    });

    test('到期时间已过的词算到期', () {
      final s = WordState.newWord('a', day0);
      expect(isDue(s, DateTime(2026, 9, 3, 21)), isTrue);
    });

    test('毕业词永不到期', () {
      final s = applyManualLevel(WordState.newWord('a', day0), Familiarity.mastered, day0);
      expect(isDue(s, DateTime(2027, 1, 1)), isFalse);
    });
  });

  group('规则6：次日强制复习', () {
    test('昨天新学的词今天强制到期', () {
      final s = WordState.newWord('a', day0); // nextDueAt 本是 9/3
      expect(needsNextDayReview(s, day1), isTrue);
      expect(isDue(s, day1), isTrue);
    });

    test('昨天答错的词今天强制到期', () {
      var s = WordState.newWord('a', day0);
      s = applyAnswer(s, correct: true, now: day0).newState;
      s = applyAnswer(s, correct: true, now: day0).newState; // 认识档，到期 9/8
      s = applyAnswer(s, correct: false, now: day0).newState; // 降档，missedOn=day0
      // 模拟当天 10 分钟后已复习过（排期推进），但 missedOn 仍是 day0
      expect(needsNextDayReview(s, day1), isTrue);
    });

    test('前天学的词不再强制（阶梯照常）', () {
      final s = WordState.newWord('a', day0);
      expect(needsNextDayReview(s, day0.add(const Duration(days: 2))), isFalse);
    });
  });

  group('规则8：周末消耗兜底', () {
    test('积压>75 时返回未来3天内到期的词', () {
      final words = [
        WordState.newWord('a', day0).copyWith(nextDueAt: day1.add(const Duration(days: 1))),
        WordState.newWord('b', day0).copyWith(nextDueAt: day1.add(const Duration(days: 2))),
        WordState.newWord('c', day0).copyWith(nextDueAt: day1.add(const Duration(days: 10))),
      ];
      final extra = weekendExtraWords(words, day1, backlogCount: 80);
      expect(extra.map((w) => w.word), containsAll(['a', 'b']));
      expect(extra.map((w) => w.word), isNot(contains('c')));
    });

    test('积压<=75 时不额外加量', () {
      final words = [WordState.newWord('a', day0)];
      expect(weekendExtraWords(words, day1, backlogCount: 75), isEmpty);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/srs_core && dart test test/scheduler_test.dart`
Expected: FAIL（isDue 未定义）

- [ ] **Step 3: 实现 scheduler.dart**

```dart
import 'word_state.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

/// 规则 6：昨天新学或昨天答错的词，今天必须强制复习一次。
bool needsNextDayReview(WordState s, DateTime now) {
  if (s.graduated) return false;
  final yesterday = _dayStart(now).subtract(const Duration(days: 1));
  final learnedYesterday = _sameDay(s.learnedOn, yesterday);
  final missedYesterday = s.missedOn != null && _sameDay(s.missedOn!, yesterday);
  return learnedYesterday || missedYesterday;
}

/// 到期判定：常规到期 或 次日强制复习命中。
bool isDue(WordState s, DateTime now) {
  if (s.graduated) return false;
  if (needsNextDayReview(s, now)) return true;
  final due = s.nextDueAt;
  return due != null && !due.isAfter(now);
}

/// 当前所有到期词，按到期时间升序（最久的排最前）。
List<WordState> dueWords(Iterable<WordState> all, DateTime now) {
  final due = all.where((s) => isDue(s, now)).toList()
    ..sort((a, b) {
      final da = a.nextDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.nextDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
  return due;
}

/// 规则 8：周末消耗兜底。积压超过 threshold 时，
/// 把未来 lookaheadDays 天内到期的词提前到周末复习。
List<WordState> weekendExtraWords(
  Iterable<WordState> all,
  DateTime now, {
  required int backlogCount,
  int threshold = 75,
  int lookaheadDays = 3,
}) {
  if (backlogCount <= threshold) return const [];
  final horizon = _dayStart(now).add(Duration(days: lookaheadDays + 1));
  return all
      .where((s) =>
          !s.graduated &&
          !isDue(s, now) &&
          s.nextDueAt != null &&
          s.nextDueAt!.isBefore(horizon))
      .toList()
    ..sort((a, b) => a.nextDueAt!.compareTo(b.nextDueAt!));
}
```

- [ ] **Step 4: 导出追加到 srs_core.dart**

```dart
export 'src/scheduler.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd packages/srs_core && dart test`
Expected: PASS（18 tests 全绿）

- [ ] **Step 6: Commit**

```bash
git add packages/srs_core
git commit -m "feat(srs_core): 排期引擎（到期/次日强制/周末消耗）"
```

---

### Task 7: srs_core — 每日任务编排（新词 + 保险阀 + 周末模式）

**Files:**
- Create: `packages/srs_core/lib/src/session_planner.dart`
- Modify: `packages/srs_core/lib/srs_core.dart`
- Test: `packages/srs_core/test/session_planner_test.dart`

**Interfaces:**
- Consumes: Task 2 的 `Stage`；Task 5 的 `WordState`；Task 6 的 `dueWords`、`weekendExtraWords`
- Produces: `class DailyPlan { reviews (List<WordState>), newWords (List<String>), isWeekendMode, newWordsThrottled }`；`DailyPlan planSession({required Stage stage, required List<WordState> allStates, required List<String> pendingNewWords, required DateTime now, int backlogThreshold = 100, int weekendBacklogThreshold = 75})`。规则：周末（周六/日）不排新词；积压 > backlogThreshold 时新词 10→6→0（>100 取 6，>150 取 0）；周末且积压 > weekendBacklogThreshold 时并入 weekendExtraWords

- [ ] **Step 1: 写失败测试**

`packages/srs_core/test/session_planner_test.dart`：

```dart
import 'package:content_models/content_models.dart';
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  final monday = DateTime(2026, 9, 7, 20); // 周一
  final saturday = DateTime(2026, 9, 12, 10); // 周六
  final pending = List.generate(30, (i) => 'word$i');

  group('平日模式', () {
    test('中级平日：10 个新词 + 到期复习', () {
      final due = WordState.newWord('old', monday.subtract(const Duration(days: 3)));
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [due],
        pendingNewWords: pending,
        now: monday,
      );
      expect(plan.newWords, hasLength(10));
      expect(plan.reviews.map((w) => w.word), contains('old'));
      expect(plan.isWeekendMode, isFalse);
    });

    test('高级平日：6 个新词', () {
      final plan = planSession(
        stage: Stage.advanced,
        allStates: [],
        pendingNewWords: pending,
        now: monday,
      );
      expect(plan.newWords, hasLength(6));
    });

    test('待学新词不足时全量取出', () {
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [],
        pendingNewWords: ['a', 'b'],
        now: monday,
      );
      expect(plan.newWords, ['a', 'b']);
    });
  });

  group('规则7：积压保险阀', () {
    List<WordState> makeBacklog(int n, DateTime now) => List.generate(
        n,
        (i) => WordState.newWord('b$i', now.subtract(const Duration(days: 5))));

    test('积压>100：新词降到6', () {
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: makeBacklog(101, monday),
        pendingNewWords: pending,
        now: monday,
      );
      expect(plan.newWords, hasLength(6));
      expect(plan.newWordsThrottled, isTrue);
    });

    test('积压>150：新词暂停', () {
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: makeBacklog(151, monday),
        pendingNewWords: pending,
        now: monday,
      );
      expect(plan.newWords, isEmpty);
    });
  });

  group('周末模式', () {
    test('周末不学新词，只复习', () {
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [],
        pendingNewWords: pending,
        now: saturday,
      );
      expect(plan.newWords, isEmpty);
      expect(plan.isWeekendMode, isTrue);
    });

    test('周末积压>75：并入未来3天到期的词', () {
      final overdue = List.generate(
          80, (i) => WordState.newWord('o$i', saturday.subtract(const Duration(days: 5))));
      final upcoming = WordState.newWord('soon', saturday)
          .copyWith(nextDueAt: saturday.add(const Duration(days: 2)));
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [...overdue, upcoming],
        pendingNewWords: pending,
        now: saturday,
      );
      expect(plan.reviews.map((w) => w.word), contains('soon'));
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/srs_core && dart test test/session_planner_test.dart`
Expected: FAIL（planSession 未定义）

- [ ] **Step 3: 实现 session_planner.dart**

```dart
import 'package:content_models/content_models.dart';

import 'scheduler.dart';
import 'word_state.dart';

/// 一天的学习计划。
class DailyPlan {
  DailyPlan({
    required this.reviews,
    required this.newWords,
    required this.isWeekendMode,
    required this.newWordsThrottled,
  });

  /// 本次会话要复习的词（含次日强制与周末提前量）。
  final List<WordState> reviews;

  /// 本次会话要学的新词（周末或保险阀触发时为空）。
  final List<String> newWords;
  final bool isWeekendMode;

  /// 保险阀是否生效（规则 7）。
  final bool newWordsThrottled;
}

bool _isWeekend(DateTime now) =>
    now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

/// 编排每日任务（spec §4.3 规则 7/8、§4.4）。
DailyPlan planSession({
  required Stage stage,
  required List<WordState> allStates,
  required List<String> pendingNewWords,
  required DateTime now,
  int backlogThreshold = 100,
  int weekendBacklogThreshold = 75,
}) {
  final reviews = dueWords(allStates, now);
  final weekend = _isWeekend(now);

  // 规则 8：周末且积压超阈值 → 提前消化未来 3 天到期的词
  if (weekend && reviews.length > weekendBacklogThreshold) {
    reviews.addAll(weekendExtraWords(allStates, now,
        backlogCount: reviews.length, threshold: weekendBacklogThreshold));
  }

  // 周末不学新词（spec §4.4）
  if (weekend) {
    return DailyPlan(
      reviews: reviews,
      newWords: const [],
      isWeekendMode: true,
      newWordsThrottled: false,
    );
  }

  // 规则 7：积压保险阀 10 → 6 → 0
  final backlog = reviews.length;
  int quota = stage.dailyNewWords;
  var throttled = false;
  if (backlog > backlogThreshold + 50) {
    quota = 0;
    throttled = true;
  } else if (backlog > backlogThreshold) {
    quota = quota > 6 ? 6 : quota;
    throttled = true;
  }

  final newWords = pendingNewWords.take(quota).toList();
  return DailyPlan(
    reviews: reviews,
    newWords: newWords,
    isWeekendMode: false,
    newWordsThrottled: throttled,
  );
}
```

- [ ] **Step 4: 导出追加到 srs_core.dart**

```dart
export 'src/session_planner.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd packages/srs_core && dart test`
Expected: PASS（25 tests 全绿）

- [ ] **Step 6: Commit**

```bash
git add packages/srs_core
git commit -m "feat(srs_core): 每日任务编排（新词配额/保险阀/周末模式）"
```

---

### Task 8: srs_core — 成就判定与晋升条件

**Files:**
- Create: `packages/srs_core/lib/src/achievements.dart`
- Create: `packages/srs_core/lib/src/promotion.dart`
- Modify: `packages/srs_core/lib/srs_core.dart`
- Test: `packages/srs_core/test/achievements_test.dart`

**Interfaces:**
- Consumes: Task 2 的 `Stage`；Task 5 的 `WordState`
- Produces: `class LearningStats { totalCheckInDays, consecutiveDays, totalWordsLearned, graduatedWords, stageWordCount, stageGraduatedCount }`；`class Achievement { id, name, conditionType, threshold }` 与 `List<Achievement> defaultAchievements`（打卡里程碑 7/30/100/365/1000、累计学词 100/500/1000/3000、毕业词 100/500/1000、晋升×2、词表进度 25/50/75/100%）；`List<Achievement> unlockedAchievements(LearningStats stats, List<Achievement> defs)`；`class PromotionCheck { eligible, graduatedRatio, requiredRatio }`；`PromotionCheck checkPromotion({required List<WordState> stageStates, double requiredRatio = 0.8})`（词表全部学过 + 毕业比例达标）

- [ ] **Step 1: 写失败测试**

`packages/srs_core/test/achievements_test.dart`：

```dart
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

LearningStats stats({
  int checkIn = 0,
  int consecutive = 0,
  int learned = 0,
  int graduated = 0,
  int stageWords = 0,
  int stageGraduated = 0,
}) =>
    LearningStats(
      totalCheckInDays: checkIn,
      consecutiveDays: consecutive,
      totalWordsLearned: learned,
      graduatedWords: graduated,
      stageWordCount: stageWords,
      stageGraduatedCount: stageGraduated,
    );

void main() {
  group('成就判定', () {
    test('连续打卡7天解锁里程碑', () {
      final unlocked = unlockedAchievements(
          stats(consecutive: 7), defaultAchievements);
      expect(unlocked.map((a) => a.id), contains('streak_7'));
    });

    test('累计学词100解锁', () {
      final unlocked = unlockedAchievements(stats(learned: 100), defaultAchievements);
      expect(unlocked.map((a) => a.id), contains('words_100'));
    });

    test('未达阈值不解锁', () {
      final unlocked = unlockedAchievements(stats(learned: 99), defaultAchievements);
      expect(unlocked.map((a) => a.id), isNot(contains('words_100')));
    });

    test('词表进度50%解锁', () {
      final unlocked = unlockedAchievements(
          stats(learned: 1500, stageWords: 3000, stageGraduated: 0),
          defaultAchievements);
      expect(unlocked.map((a) => a.id), contains('stage_progress_50'));
    });
  });

  group('晋升判定', () {
    WordState word(String w, {bool graduated = false, bool learned = true}) {
      final base = WordState.newWord(w, DateTime(2026, 1, 1));
      if (!learned) return base.copyWith(nextDueAt: null);
      return graduated
          ? applyManualLevel(base, Familiarity.mastered, DateTime(2026, 1, 1))
          : base;
    }

    test('全部学过且毕业比例>=80% → 可晋升', () {
      final states = [
        for (var i = 0; i < 8; i++) word('g$i', graduated: true),
        for (var i = 0; i < 2; i++) word('n$i'),
      ];
      final check = checkPromotion(stageStates: states);
      expect(check.eligible, isTrue);
      expect(check.graduatedRatio, closeTo(0.8, 0.001));
    });

    test('毕业比例不足 → 不可晋升', () {
      final states = [
        for (var i = 0; i < 7; i++) word('g$i', graduated: true),
        for (var i = 0; i < 3; i++) word('n$i'),
      ];
      expect(checkPromotion(stageStates: states).eligible, isFalse);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/srs_core && dart test test/achievements_test.dart`
Expected: FAIL（LearningStats 未定义）

- [ ] **Step 3: 实现 achievements.dart**

```dart
/// 学习统计快照（由 app 层从 user.db 聚合后传入）。
class LearningStats {
  LearningStats({
    required this.totalCheckInDays,
    required this.consecutiveDays,
    required this.totalWordsLearned,
    required this.graduatedWords,
    required this.stageWordCount,
    required this.stageGraduatedCount,
  });

  final int totalCheckInDays;
  final int consecutiveDays;
  final int totalWordsLearned;
  final int graduatedWords;

  /// 当前阶段词表总词数。
  final int stageWordCount;

  /// 当前阶段已毕业词数。
  final int stageGraduatedCount;
}

/// 成就条件类型。
enum AchievementCondition {
  streakDays,
  totalWords,
  graduatedWords,
  stageProgressPercent,
  promoted,
}

/// 成就定义（配置驱动，加成就不改判定代码，spec §7）。
class Achievement {
  Achievement({
    required this.id,
    required this.name,
    required this.condition,
    required this.threshold,
  });

  final String id;
  final String name;
  final AchievementCondition condition;
  final int threshold;
}

final List<Achievement> defaultAchievements = [
  for (final d in [7, 30, 100, 365, 1000])
    Achievement(id: 'streak_$d', name: '连续打卡 $d 天',
        condition: AchievementCondition.streakDays, threshold: d),
  for (final n in [100, 500, 1000, 3000])
    Achievement(id: 'words_$n', name: '累计学会 $n 词',
        condition: AchievementCondition.totalWords, threshold: n),
  for (final n in [100, 500, 1000])
    Achievement(id: 'graduated_$n', name: '$n 个词毕业',
        condition: AchievementCondition.graduatedWords, threshold: n),
  for (final p in [25, 50, 75, 100])
    Achievement(id: 'stage_progress_$p', name: '当前词表完成 $p%',
        condition: AchievementCondition.stageProgressPercent, threshold: p),
];

/// 返回当前统计已满足的成就列表。
List<Achievement> unlockedAchievements(
    LearningStats stats, List<Achievement> defs) {
  return defs.where((a) {
    switch (a.condition) {
      case AchievementCondition.streakDays:
        return stats.consecutiveDays >= a.threshold;
      case AchievementCondition.totalWords:
        return stats.totalWordsLearned >= a.threshold;
      case AchievementCondition.graduatedWords:
        return stats.graduatedWords >= a.threshold;
      case AchievementCondition.stageProgressPercent:
        if (stats.stageWordCount == 0) return false;
        final learnedPercent =
            (stats.totalWordsLearned * 100) ~/ stats.stageWordCount;
        return learnedPercent >= a.threshold;
      case AchievementCondition.promoted:
        return false; // 晋升成就由 app 层在晋升事件时单独触发
    }
  }).toList();
}
```

- [ ] **Step 4: 实现 promotion.dart**

```dart
import 'word_state.dart';

/// 晋升检查结果（spec §6.4）。
class PromotionCheck {
  PromotionCheck({
    required this.eligible,
    required this.graduatedRatio,
    required this.requiredRatio,
  });

  final bool eligible;
  final double graduatedRatio;
  final double requiredRatio;
}

/// 晋升条件：当前阶段词表全部学过 + 毕业词比例 >= requiredRatio。
PromotionCheck checkPromotion({
  required List<WordState> stageStates,
  double requiredRatio = 0.8,
}) {
  if (stageStates.isEmpty) {
    return PromotionCheck(
        eligible: false, graduatedRatio: 0, requiredRatio: requiredRatio);
  }
  final graduated = stageStates.where((s) => s.graduated).length;
  final ratio = graduated / stageStates.length;
  return PromotionCheck(
    eligible: ratio >= requiredRatio,
    graduatedRatio: ratio,
    requiredRatio: requiredRatio,
  );
}
```

- [ ] **Step 5: 导出追加到 srs_core.dart**

```dart
export 'src/achievements.dart';
export 'src/promotion.dart';
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd packages/srs_core && dart test`
Expected: PASS（31 tests 全绿）

- [ ] **Step 7: Commit**

```bash
git add packages/srs_core
git commit -m "feat(srs_core): 成就判定与晋升条件"
```

---

### Task 9: 样例内容（20 词 + 2 个单元）

**Files:**
- Create: `content_src/wordlists/intermediate.json`
- Create: `content_src/daily/intermediate/unit_001.json`
- Create: `content_src/daily/intermediate/unit_002.json`

**Interfaces:**
- Consumes: Task 2/3 定义的 JSON schema
- Produces: 供 Task 10 校验与 Task 12 构建使用的样例数据；`app/assets/` 集成测试的输入

- [ ] **Step 1: 创建样例词表（20 词，frequency_rank 1-20）**

`content_src/wordlists/intermediate.json`（数组，20 个词条，结构严格遵循 spec §5.1）：

```json
[
  {"word": "water", "phonetic": "/ˈwɔːtər/", "pos": "n.", "meaning_zh": "水", "audio": "intermediate/water.mp3", "examples": [{"en": "I drink water every day.", "zh": "我每天喝水。"}], "stage": "intermediate", "frequency_rank": 1},
  {"word": "apple", "phonetic": "/ˈæpl/", "pos": "n.", "meaning_zh": "苹果", "audio": "intermediate/apple.mp3", "examples": [{"en": "She eats an apple every morning.", "zh": "她每天早上吃一个苹果。"}], "stage": "intermediate", "frequency_rank": 2},
  {"word": "book", "phonetic": "/bʊk/", "pos": "n.", "meaning_zh": "书", "audio": "intermediate/book.mp3", "examples": [{"en": "This book is very interesting.", "zh": "这本书很有趣。"}], "stage": "intermediate", "frequency_rank": 3},
  {"word": "house", "phonetic": "/haʊs/", "pos": "n.", "meaning_zh": "房子", "audio": "intermediate/house.mp3", "examples": [{"en": "They bought a new house.", "zh": "他们买了一栋新房子。"}], "stage": "intermediate", "frequency_rank": 4},
  {"word": "friend", "phonetic": "/frend/", "pos": "n.", "meaning_zh": "朋友", "audio": "intermediate/friend.mp3", "examples": [{"en": "He is my best friend.", "zh": "他是我最好的朋友。"}], "stage": "intermediate", "frequency_rank": 5},
  {"word": "morning", "phonetic": "/ˈmɔːrnɪŋ/", "pos": "n.", "meaning_zh": "早晨", "audio": "intermediate/morning.mp3", "examples": [{"en": "I run in the morning.", "zh": "我早晨跑步。"}], "stage": "intermediate", "frequency_rank": 6},
  {"word": "food", "phonetic": "/fuːd/", "pos": "n.", "meaning_zh": "食物", "audio": "intermediate/food.mp3", "examples": [{"en": "The food here is delicious.", "zh": "这里的食物很好吃。"}], "stage": "intermediate", "frequency_rank": 7},
  {"word": "work", "phonetic": "/wɜːrk/", "pos": "v.", "meaning_zh": "工作", "audio": "intermediate/work.mp3", "examples": [{"en": "I work in a hospital.", "zh": "我在医院工作。"}], "stage": "intermediate", "frequency_rank": 8},
  {"word": "school", "phonetic": "/skuːl/", "pos": "n.", "meaning_zh": "学校", "audio": "intermediate/school.mp3", "examples": [{"en": "The school is near my house.", "zh": "学校在我家附近。"}], "stage": "intermediate", "frequency_rank": 9},
  {"word": "family", "phonetic": "/ˈfæməli/", "pos": "n.", "meaning_zh": "家庭", "audio": "intermediate/family.mp3", "examples": [{"en": "My family has four people.", "zh": "我家有四口人。"}], "stage": "intermediate", "frequency_rank": 10},
  {"word": "happy", "phonetic": "/ˈhæpi/", "pos": "adj.", "meaning_zh": "快乐的", "audio": "intermediate/happy.mp3", "examples": [{"en": "She looks very happy today.", "zh": "她今天看起来很开心。"}], "stage": "intermediate", "frequency_rank": 11},
  {"word": "read", "phonetic": "/riːd/", "pos": "v.", "meaning_zh": "阅读", "audio": "intermediate/read.mp3", "examples": [{"en": "I read books before bed.", "zh": "我睡前读书。"}], "stage": "intermediate", "frequency_rank": 12},
  {"word": "write", "phonetic": "/raɪt/", "pos": "v.", "meaning_zh": "写", "audio": "intermediate/write.mp3", "examples": [{"en": "Please write your name here.", "zh": "请在这里写下你的名字。"}], "stage": "intermediate", "frequency_rank": 13},
  {"word": "listen", "phonetic": "/ˈlɪsn/", "pos": "v.", "meaning_zh": "听", "audio": "intermediate/listen.mp3", "examples": [{"en": "Listen to the teacher carefully.", "zh": "认真听老师讲。"}], "stage": "intermediate", "frequency_rank": 14},
  {"word": "speak", "phonetic": "/spiːk/", "pos": "v.", "meaning_zh": "说", "audio": "intermediate/speak.mp3", "examples": [{"en": "Can you speak English?", "zh": "你会说英语吗？"}], "stage": "intermediate", "frequency_rank": 15},
  {"word": "city", "phonetic": "/ˈsɪti/", "pos": "n.", "meaning_zh": "城市", "audio": "intermediate/city.mp3", "examples": [{"en": "Beijing is a big city.", "zh": "北京是一座大城市。"}], "stage": "intermediate", "frequency_rank": 16},
  {"word": "weather", "phonetic": "/ˈweðər/", "pos": "n.", "meaning_zh": "天气", "audio": "intermediate/weather.mp3", "examples": [{"en": "The weather is nice today.", "zh": "今天天气很好。"}], "stage": "intermediate", "frequency_rank": 17},
  {"word": "music", "phonetic": "/ˈmjuːzɪk/", "pos": "n.", "meaning_zh": "音乐", "audio": "intermediate/music.mp3", "examples": [{"en": "I enjoy listening to music.", "zh": "我喜欢听音乐。"}], "stage": "intermediate", "frequency_rank": 18},
  {"word": "travel", "phonetic": "/ˈtrævl/", "pos": "v.", "meaning_zh": "旅行", "audio": "intermediate/travel.mp3", "examples": [{"en": "We travel by train.", "zh": "我们坐火车旅行。"}], "stage": "intermediate", "frequency_rank": 19},
  {"word": "dream", "phonetic": "/driːm/", "pos": "n.", "meaning_zh": "梦想", "audio": "intermediate/dream.mp3", "examples": [{"en": "Her dream is to travel the world.", "zh": "她的梦想是环游世界。"}], "stage": "intermediate", "frequency_rank": 20}
]
```

- [ ] **Step 2: 创建 unit_001（绑定前 10 词）**

`content_src/daily/intermediate/unit_001.json`：

```json
{
  "stage": "intermediate",
  "unit": 1,
  "new_words": ["water", "apple", "book", "house", "friend", "morning", "food", "work", "school", "family"],
  "sentences": [
    {"en": "I drink water and eat an apple every morning.", "zh": "我每天早上喝水、吃苹果。", "focus_words": ["water", "apple", "morning"]},
    {"en": "My friend reads a book at school.", "zh": "我的朋友在学校看书。", "focus_words": ["friend", "read", "book", "school"]},
    {"en": "My family enjoys the food at home.", "zh": "我的家人喜欢家里的食物。", "focus_words": ["family", "food", "house"]}
  ],
  "dialogues": [
    {
      "turns": [
        {"speaker": "A", "en": "Do you want some water?", "zh": "你想喝点水吗？"},
        {"speaker": "B", "en": "Yes, please. I also want an apple.", "zh": "好的。我还想要一个苹果。"},
        {"speaker": "A", "en": "The food here is great.", "zh": "这里的食物很棒。"}
      ]
    }
  ],
  "readings": [
    {
      "title": "My Morning",
      "body": "Every morning, I drink water and eat an apple. Then I go to school with my friend. We read books and talk about our family. I like my school life. It makes me happy. After school, I go home and help my family with the food. In the evening, I write in my book and dream about tomorrow.",
      "focus_words": ["morning", "water", "apple", "school", "friend", "book", "family", "food", "write", "dream"]
    }
  ],
  "writing_prompts": [
    {"type": "fill_blank", "question": "I drink ___ every morning.", "answer": "water", "focus_words": ["water"]},
    {"type": "fill_blank", "question": "My ___ reads a book at school.", "answer": "friend", "focus_words": ["friend"]}
  ]
}
```

- [ ] **Step 3: 创建 unit_002（绑定后 10 词）**

`content_src/daily/intermediate/unit_002.json`：

```json
{
  "stage": "intermediate",
  "unit": 2,
  "new_words": ["happy", "read", "write", "listen", "speak", "city", "weather", "music", "travel", "dream"],
  "sentences": [
    {"en": "I am happy to read and write every day.", "zh": "我每天读写都很开心。", "focus_words": ["happy", "read", "write"]},
    {"en": "We listen to music and speak about travel.", "zh": "我们听音乐，聊旅行。", "focus_words": ["listen", "music", "speak", "travel"]},
    {"en": "The weather in this city is nice.", "zh": "这个城市的天气很好。", "focus_words": ["weather", "city"]}
  ],
  "dialogues": [
    {
      "turns": [
        {"speaker": "A", "en": "What is your dream?", "zh": "你的梦想是什么？"},
        {"speaker": "B", "en": "I want to travel to a big city.", "zh": "我想去一座大城市旅行。"},
        {"speaker": "A", "en": "That sounds happy. The weather there is nice too.", "zh": "听起来很开心。那里天气也不错。"}
      ]
    }
  ],
  "readings": [
    {
      "title": "A Happy Trip",
      "body": "Last summer, I traveled to a big city. The weather was nice. I listened to music on the train and read a book. In the city, I spoke with new friends. We talked about dreams and music. I wrote about the trip in my book. It was a happy journey, and I want to travel again.",
      "focus_words": ["travel", "city", "weather", "listen", "music", "read", "speak", "friend", "dream", "write", "happy"]
    }
  ],
  "writing_prompts": [
    {"type": "fill_blank", "question": "The ___ in this city is nice.", "answer": "weather", "focus_words": ["weather"]},
    {"type": "free_write", "question": "用 dream 和 travel 写一句话。", "answer": "", "focus_words": ["dream", "travel"]}
  ]
}
```

- [ ] **Step 4: 手工验证 JSON 合法性**

Run: `python3 -c "import json; [json.load(open(f)) for f in ['content_src/wordlists/intermediate.json','content_src/daily/intermediate/unit_001.json','content_src/daily/intermediate/unit_002.json']]; print('OK')"`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add content_src
git commit -m "feat(content): 样例词表（20词）与两个每日单元"
```

---

### Task 10: content_pipeline — 校验器

**Files:**
- Create: `tools/content_pipeline/lib/src/validator.dart`
- Create: `tools/content_pipeline/lib/content_pipeline.dart`
- Test: `tools/content_pipeline/test/validator_test.dart`

**Interfaces:**
- Consumes: Task 2/3 的 `WordEntry.fromJson`、`DailyUnit.fromJson`
- Produces: `class ValidationIssue { level (error/warning), message }`；`class ValidationResult { issues, wordEntries, units, get ok }`；`ValidationResult validateContent({required String contentSrcDir})`。校验项（spec §5.3）：JSON 可解析、模型可反序列化、各阶段词数（计划 1 样例模式：>0 即可；正式模式校验 3000/2000/2000，由 `--strict` 参数开启）、音频路径在词条中唯一、单元 new_words 全部存在于词表、单元编号连续不重复

- [ ] **Step 1: 写失败测试**

`tools/content_pipeline/test/validator_test.dart`：

```dart
import 'dart:convert';
import 'dart:io';

import 'package:content_pipeline/content_pipeline.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('pipeline_test');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void writeWordlist(List<Map<String, dynamic>> words) {
    Directory('${tmp.path}/wordlists').createSync(recursive: true);
    File('${tmp.path}/wordlists/intermediate.json')
        .writeAsStringSync(jsonEncode(words));
  }

  Map<String, dynamic> word(String w, int rank) => {
        'word': w,
        'phonetic': '/x/',
        'pos': 'n.',
        'meaning_zh': '意思',
        'audio': 'intermediate/$w.mp3',
        'examples': [
          {'en': 'a $w b', 'zh': '例句'}
        ],
        'stage': 'intermediate',
        'frequency_rank': rank,
      };

  test('合法内容通过校验', () {
    writeWordlist([word('apple', 1), word('water', 2)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(
        jsonEncode({
          'stage': 'intermediate',
          'unit': 1,
          'new_words': ['apple', 'water'],
          'sentences': [],
          'dialogues': [],
          'readings': [],
          'writing_prompts': []
        }));
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isTrue, reason: result.issues.toString());
    expect(result.wordEntries, hasLength(2));
    expect(result.units, hasLength(1));
  });

  test('单元引用不存在的词 → error', () {
    writeWordlist([word('apple', 1)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(
        jsonEncode({
          'stage': 'intermediate',
          'unit': 1,
          'new_words': ['apple', 'ghost'],
          'sentences': [],
          'dialogues': [],
          'readings': [],
          'writing_prompts': []
        }));
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
    expect(result.issues.any((i) => i.message.contains('ghost')), isTrue);
  });

  test('单元编号重复 → error', () {
    writeWordlist([word('apple', 1)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    final unit = jsonEncode({
      'stage': 'intermediate',
      'unit': 1,
      'new_words': ['apple'],
      'sentences': [],
      'dialogues': [],
      'readings': [],
      'writing_prompts': []
    });
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(unit);
    File('${tmp.path}/daily/intermediate/unit_002.json').writeAsStringSync(unit);
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
  });

  test('词条 JSON 损坏 → error 并指明文件', () {
    Directory('${tmp.path}/wordlists').createSync(recursive: true);
    File('${tmp.path}/wordlists/intermediate.json')
        .writeAsStringSync('[{"word": "x"}]');
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
    expect(
        result.issues.any((i) => i.message.contains('intermediate.json')), isTrue);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd tools/content_pipeline && dart test`
Expected: FAIL（validateContent 未定义）

- [ ] **Step 3: 实现 validator.dart**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:content_models/content_models.dart';
import 'package:path/path.dart' as p;

/// 校验问题。
class ValidationIssue {
  ValidationIssue({required this.level, required this.message});

  /// 'error' 阻断构建；'warning' 仅提示。
  final String level;
  final String message;

  @override
  String toString() => '[$level] $message';
}

/// 校验结果。
class ValidationResult {
  ValidationResult({required this.issues, required this.wordEntries, required this.units});

  final List<ValidationIssue> issues;
  final List<WordEntry> wordEntries;
  final List<DailyUnit> units;

  bool get ok => !issues.any((i) => i.level == 'error');
}

/// 各阶段正式词数（--strict 模式校验）。
const strictStageWordCounts = <Stage, int>{
  Stage.intermediate: 3000,
  Stage.advanced: 2000,
  Stage.professional: 2000,
};

/// 校验 content_src 目录（spec §5.3 校验项）。
ValidationResult validateContent({
  required String contentSrcDir,
  bool strict = false,
}) {
  final issues = <ValidationIssue>[];
  final wordEntries = <WordEntry>[];
  final units = <DailyUnit>[];

  // 1. 词表
  final wordlistDir = Directory(p.join(contentSrcDir, 'wordlists'));
  if (!wordlistDir.existsSync()) {
    issues.add(ValidationIssue(level: 'error', message: '缺少 wordlists 目录'));
    return ValidationResult(issues: issues, wordEntries: [], units: []);
  }
  for (final file in wordlistDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final name = p.basename(file.path);
    try {
      final raw = jsonDecode(file.readAsStringSync()) as List;
      for (final item in raw) {
        wordEntries.add(WordEntry.fromJson(item as Map<String, dynamic>));
      }
    } on FormatException catch (e) {
      issues.add(ValidationIssue(level: 'error', message: '$name: ${e.message}'));
    }
  }

  // 2. 词条唯一性
  final seen = <String>{};
  for (final w in wordEntries) {
    if (!seen.add(w.word)) {
      issues.add(ValidationIssue(level: 'error', message: '词条重复: ${w.word}'));
    }
  }

  // 3. 严格词数
  if (strict) {
    for (final entry in strictStageWordCounts.entries) {
      final count = wordEntries.where((w) => w.stage == entry.key).length;
      if (count != entry.value) {
        issues.add(ValidationIssue(
            level: 'error',
            message: '${entry.key.name} 词数 $count != 期望 ${entry.value}'));
      }
    }
  } else if (wordEntries.isEmpty) {
    issues.add(ValidationIssue(level: 'error', message: '词表为空'));
  }

  // 4. 每日单元
  final dailyDir = Directory(p.join(contentSrcDir, 'daily'));
  final wordSet = seen;
  if (dailyDir.existsSync()) {
    final unitNumbersByStage = <Stage, Set<int>>{};
    for (final file in dailyDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final name = p.relative(file.path, from: contentSrcDir);
      try {
        final unit = DailyUnit.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        final numbers = unitNumbersByStage.putIfAbsent(unit.stage, () => {});
        if (!numbers.add(unit.unitNumber)) {
          issues.add(ValidationIssue(
              level: 'error',
              message: '$name: ${unit.stage.name} 单元 ${unit.unitNumber} 编号重复'));
        }
        for (final w in unit.newWords) {
          if (!wordSet.contains(w)) {
            issues.add(ValidationIssue(
                level: 'error', message: '$name: 单元引用了词表中不存在的词: $w'));
          }
        }
        units.add(unit);
      } on FormatException catch (e) {
        issues.add(ValidationIssue(level: 'error', message: '$name: ${e.message}'));
      }
    }
  }

  return ValidationResult(issues: issues, wordEntries: wordEntries, units: units);
}
```

- [ ] **Step 4: 创建导出文件 content_pipeline.dart**

本任务只导出 validator（`db_builder.dart` 在 Task 11 创建后再追加导出）：

```dart
/// 学个鸟语 - 内容构建管线。
library content_pipeline;

export 'src/validator.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd tools/content_pipeline && dart test`
Expected: PASS（4 tests）

- [ ] **Step 6: Commit**

```bash
git add tools/content_pipeline
git commit -m "feat(pipeline): 内容校验器（schema/词数/引用/编号）"
```

---

### Task 11: content_pipeline — content.db 构建器

**Files:**
- Create: `tools/content_pipeline/lib/src/db_builder.dart`
- Modify: `tools/content_pipeline/lib/content_pipeline.dart`（追加导出）
- Test: `tools/content_pipeline/test/db_builder_test.dart`

**Interfaces:**
- Consumes: Task 10 的 `ValidationResult`；Task 2/3 的模型
- Produces: `void buildContentDb({required ValidationResult content, required String outputPath, required int contentVersion})`。表结构：`meta(key TEXT PRIMARY KEY, value TEXT)`（含 content_version）；`words(word TEXT PRIMARY KEY, stage TEXT, phonetic TEXT, pos TEXT, meaning_zh TEXT, audio TEXT, frequency_rank INTEGER)`；`examples(word TEXT, seq INTEGER, en TEXT, zh TEXT)`；`units(stage TEXT, unit INTEGER, new_words TEXT(JSON), sentences TEXT(JSON), dialogues TEXT(JSON), readings TEXT(JSON), writing_prompts TEXT(JSON), PRIMARY KEY(stage, unit))`

- [ ] **Step 1: 写失败测试**

`tools/content_pipeline/test/db_builder_test.dart`：

```dart
import 'dart:io';

import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('db_build_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  WordEntry entry(String w, int rank) => WordEntry(
        word: w,
        phonetic: '/x/',
        pos: 'n.',
        meaningZh: '意思',
        audioPath: 'intermediate/$w.mp3',
        examples: [ExampleSentence(en: 'a $w', zh: '例句')],
        stage: Stage.intermediate,
        frequencyRank: rank,
      );

  test('生成的 content.db 包含 meta/words/examples/units', () {
    final result = ValidationResult(
      issues: [],
      wordEntries: [entry('apple', 1), entry('water', 2)],
      units: [
        DailyUnit(
          stage: Stage.intermediate,
          unitNumber: 1,
          newWords: ['apple', 'water'],
          sentences: [SentenceItem(en: 'I drink water.', zh: '我喝水。', focusWords: ['water'])],
          dialogues: [],
          readings: [],
          writingPrompts: [],
        )
      ],
    );
    final out = '${tmp.path}/content.db';
    buildContentDb(content: result, outputPath: out, contentVersion: 1);

    final db = sqlite3.open(out);
    addTearDown(db.dispose);

    expect(db.select('SELECT value FROM meta WHERE key = ?', ['content_version']).single['value'], '1');
    expect(db.select('SELECT COUNT(*) AS n FROM words').single['n'], 2);
    expect(db.select('SELECT zh FROM examples WHERE word = ?', ['apple']).single['zh'], '例句');
    final unit = db.select('SELECT new_words FROM units WHERE unit = 1').single;
    expect(unit['new_words'], contains('apple'));
  });

  test('重复构建会覆盖旧文件', () {
    final result = ValidationResult(issues: [], wordEntries: [entry('apple', 1)], units: []);
    final out = '${tmp.path}/content.db';
    buildContentDb(content: result, outputPath: out, contentVersion: 1);
    buildContentDb(content: result, outputPath: out, contentVersion: 2);
    final db = sqlite3.open(out);
    addTearDown(db.dispose);
    expect(db.select('SELECT value FROM meta WHERE key = ?', ['content_version']).single['value'], '2');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd tools/content_pipeline && dart test test/db_builder_test.dart`
Expected: FAIL（buildContentDb 未定义）

- [ ] **Step 3: 实现 db_builder.dart**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'validator.dart';

/// 生成只读 content.db（spec §3/§5.3）。
void buildContentDb({
  required ValidationResult content,
  required String outputPath,
  required int contentVersion,
}) {
  if (!content.ok) {
    throw StateError('内容校验未通过，拒绝构建: ${content.issues}');
  }
  final file = File(outputPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(outputPath);
  try {
    db.execute('''
      CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE words (
        word TEXT PRIMARY KEY,
        stage TEXT NOT NULL,
        phonetic TEXT NOT NULL,
        pos TEXT NOT NULL,
        meaning_zh TEXT NOT NULL,
        audio TEXT NOT NULL,
        frequency_rank INTEGER NOT NULL
      );
      CREATE TABLE examples (
        word TEXT NOT NULL REFERENCES words(word),
        seq INTEGER NOT NULL,
        en TEXT NOT NULL,
        zh TEXT NOT NULL,
        PRIMARY KEY (word, seq)
      );
      CREATE TABLE units (
        stage TEXT NOT NULL,
        unit INTEGER NOT NULL,
        new_words TEXT NOT NULL,
        sentences TEXT NOT NULL,
        dialogues TEXT NOT NULL,
        readings TEXT NOT NULL,
        writing_prompts TEXT NOT NULL,
        PRIMARY KEY (stage, unit)
      );
      CREATE INDEX idx_words_stage_rank ON words(stage, frequency_rank);
    ''');

    db.execute('BEGIN');
    final insertWord = db.prepare(
        'INSERT INTO words VALUES (?, ?, ?, ?, ?, ?, ?)');
    final insertExample = db.prepare('INSERT INTO examples VALUES (?, ?, ?, ?)');
    final insertUnit = db.prepare('INSERT INTO units VALUES (?, ?, ?, ?, ?, ?, ?)');

    for (final w in content.wordEntries) {
      insertWord.execute([
        w.word, w.stage.name, w.phonetic, w.pos,
        w.meaningZh, w.audioPath, w.frequencyRank,
      ]);
      for (var i = 0; i < w.examples.length; i++) {
        insertExample.execute([w.word, i, w.examples[i].en, w.examples[i].zh]);
      }
    }
    for (final u in content.units) {
      insertUnit.execute([
        u.stage.name,
        u.unitNumber,
        jsonEncode(u.newWords),
        jsonEncode(u.sentences.map((s) => s.toJson()).toList()),
        jsonEncode(u.dialogues.map((d) => d.toJson()).toList()),
        jsonEncode(u.readings.map((r) => r.toJson()).toList()),
        jsonEncode(u.writingPrompts.map((w) => w.toJson()).toList()),
      ]);
    }
    db.execute(
        "INSERT INTO meta VALUES ('content_version', '$contentVersion')");
    db.execute('COMMIT');
  } finally {
    db.dispose();
  }
}
```

- [ ] **Step 4: 追加导出到 content_pipeline.dart**

```dart
export 'src/db_builder.dart';
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd tools/content_pipeline && dart test`
Expected: PASS（6 tests 全绿）

- [ ] **Step 6: Commit**

```bash
git add tools/content_pipeline
git commit -m "feat(pipeline): content.db 构建器（meta/words/examples/units）"
```

---

### Task 12: content_pipeline — CLI 入口与端到端构建

**Files:**
- Modify: `tools/content_pipeline/bin/build_content.dart`
- Test: `tools/content_pipeline/test/e2e_test.dart`

**Interfaces:**
- Consumes: Task 10 的 `validateContent`；Task 11 的 `buildContentDb`；Task 9 的样例内容
- Produces: CLI `dart run content_pipeline:build_content --src <dir> --out <db> [--audio-out <dir>] [--strict] [--version N]`；校验失败时退出码 1 并打印问题清单；成功时打印统计（词数/单元数/输出路径）

- [ ] **Step 1: 写端到端测试**

`tools/content_pipeline/test/e2e_test.dart`：

```dart
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('用仓库样例内容端到端构建 content.db', () {
    // dart test 的工作目录是包根（tools/content_pipeline），仓库根在 ../..
    const repoRoot = '../..';
    final out = '${Directory.systemTemp.path}/e2e_content.db';
    final result = Process.runSync(
      'dart',
      ['run', 'bin/build_content.dart', '--src', '$repoRoot/content_src', '--out', out, '--version', '1'],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final db = sqlite3.open(out);
    addTearDown(() {
      db.dispose();
      File(out).deleteSync();
    });
    expect(db.select('SELECT COUNT(*) AS n FROM words').single['n'], 20);
    expect(db.select('SELECT COUNT(*) AS n FROM units').single['n'], 2);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd tools/content_pipeline && dart test test/e2e_test.dart`
Expected: FAIL（UnimplementedError）

- [ ] **Step 3: 实现 CLI 入口**

`tools/content_pipeline/bin/build_content.dart`：

```dart
import 'dart:io';

import 'package:args/args.dart';
import 'package:content_pipeline/content_pipeline.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('src', mandatory: true, help: 'content_src 目录')
    ..addOption('out', mandatory: true, help: 'content.db 输出路径')
    ..addOption('version', defaultsTo: '1', help: 'content_version')
    ..addFlag('strict', defaultsTo: false, help: '严格校验正式词数');
  final opts = parser.parse(args);

  final src = opts['src'] as String;
  final out = opts['out'] as String;
  final version = int.parse(opts['version'] as String);

  stdout.writeln('校验内容: $src');
  final result = validateContent(contentSrcDir: src, strict: opts['strict'] as bool);
  for (final issue in result.issues) {
    stdout.writeln('  $issue');
  }
  if (!result.ok) {
    stderr.writeln('校验失败，共 ${result.issues.length} 个问题，中止构建。');
    exit(1);
  }

  buildContentDb(content: result, outputPath: out, contentVersion: version);
  stdout.writeln('构建完成: ${result.wordEntries.length} 词条, '
      '${result.units.length} 单元 → $out');
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd tools/content_pipeline && dart test`
Expected: PASS（7 tests 全绿）

- [ ] **Step 5: 手工运行一次真实构建**

Run: `cd tools/content_pipeline && dart run bin/build_content.dart --src ../../content_src --out ../../app/assets/content.db --version 1`
Expected: 输出"构建完成: 20 词条, 2 单元"（首次运行会自动创建 app/assets/ 目录——若未自动创建，先 `mkdir -p ../../app/assets`）

- [ ] **Step 6: Commit**

```bash
git add tools/content_pipeline app/assets/content.db
git commit -m "feat(pipeline): CLI 入口，端到端构建样例 content.db"
```

---

### Task 13: 全量验证与收尾

**Files:**
- Modify: `.gitignore`（如需排除构建中间产物）

**Interfaces:**
- Consumes: 全部前序任务
- Produces: 全仓库测试/分析通过的基线，供计划 2（app 层）使用

- [ ] **Step 1: 全仓库静态分析**

Run: `melos analyze`
Expected: 无 error

- [ ] **Step 2: 全仓库测试**

Run: `melos test`
Expected: content_models 7 tests + srs_core 31 tests + content_pipeline 7 tests，全部 PASS

- [ ] **Step 3: 确认 content.db 可被重新生成（幂等）**

Run: `cd tools/content_pipeline && dart run bin/build_content.dart --src ../../content_src --out ../../app/assets/content.db --version 1`
Expected: 构建完成，无报错

- [ ] **Step 4: Commit 收尾改动（如有）**

```bash
git add -A
git commit -m "chore: 计划1收尾（分析/测试基线通过）"
```

---

## 计划 2-4 预告（不在本计划范围）

- **计划 2**：Flutter app 骨架 + drift user.db + content.db 接入 + 今日页 + 学习会话（复习/新词/串词）+ 词书（手动调档）
- **计划 3**：成就页 + 晋升流程 + 本地提醒 + 深色模式
- **计划 4**：付费（StoreKit 2 / Play Billing）+ 备份（iCloud / Drive / 手动导出）+ 上架准备
