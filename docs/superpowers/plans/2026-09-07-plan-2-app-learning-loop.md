# 学个鸟语 · 计划 2：App 骨架与学习闭环 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建可运行的 Flutter app：接入 content.db 与 user.db，实现今日页、学习会话（复习/新词/串词巩固）、词书（手动调档），在模拟器上完成完整学习闭环。

**Architecture:** `app/` 为 Flutter 工程（加入现有 pub workspace）。数据层：content.db 用 sqlite3 包只读访问（启动时从 assets 安装）；user.db 用 drift（代码生成）存储学习状态/打卡/设置。`SessionController` 是 UI 无关的会话编排器，调用计划 1 的 `srs_core` 引擎；Riverpod 负责依赖注入与状态管理。

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2、drift（+drift_dev/build_runner 代码生成）、sqlite3、path_provider、flutter_riverpod、just_audio（单词音频）、flutter_tts（句子朗读）。

**Spec:** `docs/superpowers/specs/2026-09-04-xuege-niaoyu-design.md`

## Global Constraints

- 熟悉度 5 档：陌生 / 模糊 / 认识 / 熟悉 / 牢记；新词默认「模糊」
- 调档 8 条规则全部由 `srs_core` 已实现，app 层只调用不重写：`applyAnswer`（规则 1-3）、`applyManualLevel`（规则 4）、当日必过与会话内重现（规则 5，由 `AnswerOutcome.reappearInSession` 驱动）、`planSession`（规则 7/8）、次日强制复习（规则 6，由排期引擎自动处理）
- 每日新词：中级 10；高级/专业级 6（`Stage.dailyNewWords`）
- 周末只复习不学新词（`DailyPlan.isWeekendMode`）
- content.db 只读、含 `content_version`；user.db 读写；两库严格分离
- 口语为纯跟读无评测；写作填空精确匹配（忽略大小写与首尾空格），自由写作仅展示参考
- 本计划默认阶段为中级（intermediate），Onboarding 选阶段属计划 3；当前阶段存 user.db 设置表
- 样例内容无真实音频文件：音频播放缺失时必须静默跳过，不得报错崩溃
- v1 支持深色模式：跟随系统（亮/暗双主题）
- app 显示名：学个鸟语

## 计划 1 已有接口速查（本计划大量调用）

```dart
// srs_core
enum Familiarity { unknown, vague, recognize, familiar, mastered } // .label 中文名, .isMastered
class WordState { word, familiarity, correctCountInLevel, learnedOn, lastReviewedAt, nextDueAt, missedOn, graduated }
WordState.newWord(String word, DateTime now)
AnswerOutcome applyAnswer(WordState state, {required bool correct, required DateTime now})
  // AnswerOutcome { WordState newState; bool reappearInSession }
WordState applyManualLevel(WordState state, Familiarity level, DateTime now)
DailyPlan planSession({required Stage stage, required List<WordState> allStates,
    required List<String> pendingNewWords, required DateTime now})
  // DailyPlan { List<WordState> reviews; List<String> newWords; bool isWeekendMode; bool newWordsThrottled }

// content_models
enum Stage { intermediate, advanced, professional } // .label, .dailyNewWords, Stage.fromName
class WordEntry { word, phonetic, pos, meaningZh, audioPath, examples(List<ExampleSentence>), stage, frequencyRank }
class ExampleSentence { en, zh }
class DailyUnit { stage, unitNumber, newWords, sentences(List<SentenceItem>), dialogues(List<Dialogue>),
    readings(List<ReadingItem>), writingPrompts(List<WritingPrompt>) }
class SentenceItem { en, zh, focusWords }
class Dialogue { turns(List<DialogueTurn>) } / class DialogueTurn { speaker, en, zh }
class ReadingItem { title, body, focusWords }
class WritingPrompt { type(WritingPromptType.fillBlank/freeWrite), question, answer, focusWords }

// content.db 表结构（计划 1 Task 11 生成）
// meta(key, value) / words(word, stage, phonetic, pos, meaning_zh, audio, frequency_rank)
// examples(word, seq, en, zh) / units(stage, unit, new_words, sentences, dialogues, readings, writing_prompts)
// units 的 5 个素材列均为 JSON 字符串
```

---

## File Structure

```
app/
├── pubspec.yaml                        # flutter 依赖 + workspace resolution
├── assets/content.db                   # 已存在（计划 1 产物）
├── lib/
│   ├── main.dart                       # 入口：初始化两库，ProviderScope
│   ├── app.dart                        # MaterialApp + 双主题 + Tab 骨架
│   ├── data/
│   │   ├── content_installer.dart      # assets/content.db → documents 安装
│   │   ├── content_repository.dart     # content.db 只读查询（sqlite3）
│   │   ├── user_database.dart          # drift 表定义（+生成的 .g.dart）
│   │   └── word_state_store.dart       # user.db DAO：状态/打卡/设置
│   ├── controllers/
│   │   ├── session_controller.dart     # 学习会话编排（UI 无关，可单测）
│   │   └── providers.dart              # Riverpod providers
│   ├── services/
│   │   ├── audio_service.dart          # just_audio 单词音频（缺失静默跳过）
│   │   └── tts_service.dart            # flutter_tts 句子朗读
│   └── ui/
│       ├── home_page.dart              # 今日页
│       ├── session/
│       │   ├── session_page.dart       # 学习会话（复习卡/新词卡）
│       │   └── consolidation_view.dart # 串词巩固 + 完成总结
│       ├── wordbook/
│       │   ├── wordbook_page.dart      # 词书列表 + 熟悉度筛选
│       │   └── word_detail_sheet.dart  # 词详情 + 手动调档
│       └── profile_page.dart           # 我的（占位：当前阶段）
└── test/
    ├── content_repository_test.dart
    ├── word_state_store_test.dart
    ├── session_controller_test.dart
    └── app_smoke_test.dart
```

---

### Task 1: Flutter 工程骨架与 workspace 接入

**Files:**
- Create: `app/`（flutter create 生成）
- Modify: `pubspec.yaml`（根，workspace 增加 app）
- Modify: `app/pubspec.yaml`（依赖 + assets 声明）
- Modify: `app/lib/main.dart`、`app/lib/app.dart`、`app/test/widget_test.dart`
- Modify: `app/ios/Runner/Info.plist`、`app/android/app/src/main/AndroidManifest.xml`（显示名）

**Interfaces:**
- Produces: 可 `flutter run` 的空壳 app（3 个 Tab：今日/词书/我的）；`BirdsongApp` widget；`appThemeLight`/`appThemeDark`

- [ ] **Step 1: 生成 Flutter 工程**

```bash
cd app
flutter create . --project-name birdsong_app --org guru.xuegeniaoyu --platforms ios,android
```

Expected: 生成 lib/main.dart、ios/、android/ 等，保留已有 assets/content.db

- [ ] **Step 2: 根 workspace 纳入 app**

根 `pubspec.yaml` 的 workspace 列表追加一行：

```yaml
workspace:
  - packages/content_models
  - packages/srs_core
  - tools/content_pipeline
  - app
```

- [ ] **Step 3: 改写 app/pubspec.yaml**

```yaml
name: birdsong_app
description: 学个鸟语 - 每天一小步的英语学习 app
publish_to: none
version: 0.1.0+1
resolution: workspace

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
  content_models:
    path: ../packages/content_models
  srs_core:
    path: ../packages/srs_core
  flutter_riverpod: ^2.5.1
  drift: ^2.20.0
  sqlite3: ^2.4.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  just_audio: ^0.9.40
  flutter_tts: ^4.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  drift_dev: ^2.20.0
  build_runner: ^2.4.13
  content_pipeline:
    path: ../tools/content_pipeline

flutter:
  uses-material-design: true
  assets:
    - assets/
```

- [ ] **Step 4: 修复 melos test 脚本（Flutter 包不能用 dart test）**

根 `pubspec.yaml` 的 `melos: scripts:` 改为：

```yaml
melos:
  scripts:
    analyze:
      run: melos exec -- dart analyze --fatal-infos
    test:
      run: melos exec --dir-exists=test --no-flutter -- dart test
    test_flutter:
      run: melos exec --dir-exists=test --flutter -- flutter test
```

- [ ] **Step 5: 安装依赖**

Run: `flutter pub get && melos bootstrap`
Expected: 成功，无解析错误

- [ ] **Step 6: 写 app.dart（双主题 + Tab 骨架）**

`app/lib/app.dart`：

```dart
import 'package:flutter/material.dart';

import 'ui/home_page.dart';
import 'ui/profile_page.dart';
import 'ui/wordbook/wordbook_page.dart';

/// 学个鸟语 App 根组件。
class BirdsongApp extends StatelessWidget {
  const BirdsongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学个鸟语',
      debugShowCheckedModeBanner: false,
      // v1 深色模式：跟随系统
      theme: appThemeLight,
      darkTheme: appThemeDark,
      themeMode: ThemeMode.system,
      home: const ShellPage(),
    );
  }
}

final appThemeLight = _buildTheme(Brightness.light);
final appThemeDark = _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: brightness,
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

/// 底部 3 Tab 骨架：今日 / 词书 / 我的。
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  static const _pages = [HomePage(), WordbookPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: '今日'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: '词书'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: 写三个占位页与 main.dart**

`app/lib/ui/home_page.dart`：

```dart
import 'package:flutter/material.dart';

/// 今日页（Task 5 实现完整内容）。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('今日')),
    );
  }
}
```

`app/lib/ui/wordbook/wordbook_page.dart`：

```dart
import 'package:flutter/material.dart';

/// 词书页（Task 8 实现完整内容）。
class WordbookPage extends StatelessWidget {
  const WordbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('词书')),
    );
  }
}
```

`app/lib/ui/profile_page.dart`：

```dart
import 'package:flutter/material.dart';

/// 我的页（占位；Onboarding/备份/购买属计划 3/4）。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: const Center(child: Text('当前阶段：中级（Onboarding 将在后续版本提供）')),
    );
  }
}
```

`app/lib/main.dart`：

```dart
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(const BirdsongApp());
}
```

- [ ] **Step 8: 替换默认 widget 测试**

`app/test/widget_test.dart`：

```dart
import 'package:birdsong_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app 启动并显示 3 个 Tab', (tester) async {
    await tester.pumpWidget(const BirdsongApp());
    expect(find.text('今日'), findsWidgets);
    expect(find.text('词书'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
```

- [ ] **Step 9: 设置显示名「学个鸟语」**

`app/ios/Runner/Info.plist` 中 `CFBundleDisplayName` 的值改为 `学个鸟语`。
`app/android/app/src/main/AndroidManifest.xml` 中 `android:label` 改为 `学个鸟语`。

- [ ] **Step 10: 验证**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 无 error；widget 测试 PASS

- [ ] **Step 11: Commit**

```bash
git add app pubspec.yaml pubspec.lock
git commit -m "feat(app): Flutter 工程骨架（双主题/3Tab/显示名）"
```

---

### Task 2: content.db 安装与只读访问层

**Files:**
- Create: `app/lib/data/content_installer.dart`
- Create: `app/lib/data/content_repository.dart`
- Test: `app/test/content_repository_test.dart`

**Interfaces:**
- Consumes: 计划 1 的 `content_pipeline.buildContentDb`（仅测试用）、`WordEntry.fromJson`、`DailyUnit.fromJson`、`Stage`
- Produces: `ContentRepository.open(String path)`；`List<WordEntry> wordsOfStage(Stage)`；`WordEntry? wordOf(String)`；`List<DailyUnit> unitsOfStage(Stage)`；`DailyUnit? unitContaining(Stage, List<String> newWords)`；`List<String> pendingNewWords(Stage, Set<String> learned)`；`Future<File> ContentInstaller.ensureInstalled()`

- [ ] **Step 1: 写失败测试**

`app/test/content_repository_test.dart`：

```dart
import 'dart:io';

import 'package:birdsong_app/data/content_repository.dart';
import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late ContentRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('repo_test');
    // 用仓库样例内容构建一个临时 content.db
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    expect(validation.ok, isTrue, reason: validation.issues.toString());
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    repo = ContentRepository.open(dbPath);
  });

  tearDown(() async {
    repo.dispose();
    await tmp.delete(recursive: true);
  });

  test('wordsOfStage 返回该阶段全部词条（含例句）', () {
    final words = repo.wordsOfStage(Stage.intermediate);
    expect(words, hasLength(20));
    final water = words.firstWhere((w) => w.word == 'water');
    expect(water.meaningZh, '水');
    expect(water.examples, isNotEmpty);
  });

  test('wordOf 查单词，未找到返回 null', () {
    expect(repo.wordOf('apple')?.meaningZh, '苹果');
    expect(repo.wordOf('ghost'), isNull);
  });

  test('pendingNewWords 排除已学词，按词频排序', () {
    final pending = repo.pendingNewWords(Stage.intermediate, {'water', 'apple'});
    expect(pending, hasLength(18));
    expect(pending.first, 'book'); // frequency_rank 3，剩余中最高频
    expect(pending, isNot(contains('water')));
  });

  test('unitContaining 找到包含今日新词的单元', () {
    final unit = repo.unitContaining(Stage.intermediate, ['water', 'apple']);
    expect(unit, isNotNull);
    expect(unit!.unitNumber, 1);
  });

  test('unitsOfStage 按单元号排序', () {
    final units = repo.unitsOfStage(Stage.intermediate);
    expect(units.map((u) => u.unitNumber), [1, 2]);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd app && flutter test test/content_repository_test.dart`
Expected: FAIL（ContentRepository 未定义）

- [ ] **Step 3: 实现 content_repository.dart**

```dart
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
```

- [ ] **Step 4: 实现 content_installer.dart**

```dart
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// 把打包在 assets 里的 content.db 安装到应用文档目录。
/// 已存在则跳过（内容更新随 app 版本发布，见 spec §3）。
class ContentInstaller {
  static Future<File> ensureInstalled() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/content.db');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/content.db');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file;
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd app && flutter test test/content_repository_test.dart`
Expected: PASS（5 tests）

- [ ] **Step 6: Commit**

```bash
git add app/lib/data app/test/content_repository_test.dart
git commit -m "feat(app): content.db 安装与只读访问层"
```

---

### Task 3: user.db（drift）与 WordStateStore

**Files:**
- Create: `app/lib/data/user_database.dart`（+ build_runner 生成 `user_database.g.dart`）
- Create: `app/lib/data/word_state_store.dart`
- Test: `app/test/word_state_store_test.dart`

**Interfaces:**
- Consumes: srs_core 的 `WordState`、`Familiarity`；content_models 的 `Stage`
- Produces: `UserDatabase`（drift，表 `LearnedWords`/`CheckIns`/`AppSettings`）；`WordStateStore.allStates()`、`save(WordState)`、`checkIn(DateTime)`、`hasCheckIn(DateTime)`、`streak(DateTime)`、`currentStage()`、`setStage(Stage)`

- [ ] **Step 1: 写失败测试**

`app/test/word_state_store_test.dart`：

```dart
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late UserDatabase db;
  late WordStateStore store;
  final day = DateTime(2026, 9, 7, 20);

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() => db.close());

  group('单词状态持久化', () {
    test('save 后 allStates 往返一致', () async {
      final s = WordState.newWord('apple', day);
      await store.save(s);
      final loaded = await store.allStates();
      expect(loaded, hasLength(1));
      final got = loaded.single;
      expect(got.word, 'apple');
      expect(got.familiarity, Familiarity.vague);
      expect(got.nextDueAt, s.nextDueAt);
      expect(got.graduated, isFalse);
    });

    test('重复 save 同一词为更新而非插入', () async {
      await store.save(WordState.newWord('apple', day));
      final updated = applyAnswer(
        WordState.newWord('apple', day),
        correct: true,
        now: day,
      ).newState;
      await store.save(updated);
      final loaded = await store.allStates();
      expect(loaded, hasLength(1));
      expect(loaded.single.correctCountInLevel, 1);
    });
  });

  group('打卡与连续天数', () {
    test('checkIn 幂等，hasCheckIn 正确', () async {
      expect(await store.hasCheckIn(day), isFalse);
      await store.checkIn(day);
      await store.checkIn(day); // 重复打卡不报错
      expect(await store.hasCheckIn(day), isTrue);
    });

    test('streak 统计连续天数（今天已打卡）', () async {
      await store.checkIn(day.subtract(const Duration(days: 2)));
      await store.checkIn(day.subtract(const Duration(days: 1)));
      await store.checkIn(day);
      expect(await store.streak(day), 3);
    });

    test('streak 今天未打卡时从昨天数', () async {
      await store.checkIn(day.subtract(const Duration(days: 1)));
      await store.checkIn(day.subtract(const Duration(days: 2)));
      expect(await store.streak(day), 2);
    });

    test('streak 中断后归零', () async {
      await store.checkIn(day.subtract(const Duration(days: 3)));
      expect(await store.streak(day), 0);
    });
  });

  group('阶段设置', () {
    test('默认中级', () async {
      expect(await store.currentStage(), Stage.intermediate);
    });

    test('setStage 持久化', () async {
      await store.setStage(Stage.advanced);
      expect(await store.currentStage(), Stage.advanced);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd app && flutter test test/word_state_store_test.dart`
Expected: FAIL（UserDatabase 未定义）

- [ ] **Step 3: 实现 user_database.dart**

```dart
import 'package:drift/drift.dart';

part 'user_database.g.dart';

/// 单词学习状态，与 srs_core 的 WordState 一一对应。
class LearnedWords extends Table {
  TextColumn get word => text()();
  IntColumn get familiarity => integer()();
  IntColumn get correctCountInLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get learnedOn => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  DateTimeColumn get missedOn => dateTime().nullable()();
  BoolColumn get graduated => boolean().withDefault(const Constant(false))();

  @override
  Set<String> get primaryKey => {word};
}

/// 打卡记录，每天一条（存当天零点）。
class CheckIns extends Table {
  DateTimeColumn get day => dateTime()();

  @override
  Set<String> get primaryKey => {day};
}

/// 键值设置（当前阶段等）。
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<String> get primaryKey => {key};
}

@DriftDatabase(tables: [LearnedWords, CheckIns, AppSettings])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 4: 运行代码生成**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `lib/data/user_database.g.dart`，无错误

- [ ] **Step 5: 实现 word_state_store.dart**

```dart
import 'package:content_models/content_models.dart';
import 'package:drift/drift.dart';
import 'package:srs_core/srs_core.dart';

import 'user_database.dart';

/// user.db 的 DAO：单词状态 / 打卡 / 设置。
class WordStateStore {
  WordStateStore(this.db);

  final UserDatabase db;

  static const _stageKey = 'current_stage';

  // ---- 单词状态 ----

  Future<List<WordState>> allStates() async {
    final rows = await db.select(db.learnedWords).get();
    return rows.map(_toDomain).toList();
  }

  Future<void> save(WordState s) => db
      .into(db.learnedWords)
      .insertOnConflictUpdate(_toCompanion(s));

  // ---- 打卡 ----

  DateTime _dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

  Future<void> checkIn(DateTime day) => db
      .into(db.checkIns)
      .insertOnConflictUpdate(CheckInsCompanion.insert(day: _dayStart(day)));

  Future<bool> hasCheckIn(DateTime day) async {
    final row = await (db.select(db.checkIns)
          ..where((t) => t.day.equals(_dayStart(day))))
        .getSingleOrNull();
    return row != null;
  }

  /// 连续打卡天数：今天已打卡则从今天往回数，否则从昨天往回数。
  Future<int> streak(DateTime today) async {
    final rows = await (db.select(db.checkIns)
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
    final days = rows.map((r) => r.day).toSet();
    var cursor = _dayStart(today);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ---- 设置 ----

  Future<Stage> currentStage() async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(_stageKey)))
        .getSingleOrNull();
    if (row == null) return Stage.intermediate;
    return Stage.fromName(row.value);
  }

  Future<void> setStage(Stage stage) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _stageKey, value: stage.name));

  // ---- 映射 ----

  WordState _toDomain(LearnedWord r) => WordState(
        word: r.word,
        familiarity: Familiarity.values[r.familiarity],
        correctCountInLevel: r.correctCountInLevel,
        learnedOn: r.learnedOn,
        lastReviewedAt: r.lastReviewedAt,
        nextDueAt: r.nextDueAt,
        missedOn: r.missedOn,
        graduated: r.graduated,
      );

  LearnedWordsCompanion _toCompanion(WordState s) => LearnedWordsCompanion.insert(
        word: s.word,
        familiarity: s.familiarity.index,
        correctCountInLevel: Value(s.correctCountInLevel),
        learnedOn: s.learnedOn,
        lastReviewedAt: Value(s.lastReviewedAt),
        nextDueAt: Value(s.nextDueAt),
        missedOn: Value(s.missedOn),
        graduated: Value(s.graduated),
      );
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd app && flutter test test/word_state_store_test.dart`
Expected: PASS（9 tests）

- [ ] **Step 7: Commit**

```bash
git add app/lib/data app/test/word_state_store_test.dart
git commit -m "feat(app): user.db（drift）与 WordStateStore"
```

---

### Task 4: SessionController 会话编排

**Files:**
- Create: `app/lib/controllers/session_controller.dart`
- Test: `app/test/session_controller_test.dart`

**Interfaces:**
- Consumes: Task 2 的 `ContentRepository`；Task 3 的 `WordStateStore`；srs_core 的 `planSession`/`applyAnswer`/`WordState.newWord`
- Produces: `enum SessionPhase { review, newWords, consolidation, done, empty }`；`SessionController({store, content, clock})`；`Future<bool> start()`；`WordState get current`；`SessionPhase get phase`；`Future<void> answer({required bool correct})`；`DailyUnit? get unit`；`Future<void> completeConsolidation()`；`int get reviewsCompleted`、`int get newWordsLearned`、`int get wrongCount`、`bool get throttled`、`bool get weekendMode`

- [ ] **Step 1: 写失败测试**

`app/test/session_controller_test.dart`：

```dart
import 'dart:io';

import 'package:birdsong_app/controllers/session_controller.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;
  // 模拟「今天是 2026-09-08 周二 20:00」，可随测试推进
  late DateTime fakeNow;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('session_test');
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    content = ContentRepository.open(dbPath);
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
    fakeNow = DateTime(2026, 9, 8, 20);
  });

  tearDown(() async {
    content.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  SessionController controller() => SessionController(
        store: store,
        content: content,
        clock: () => fakeNow,
      );

  test('首次开始：10 个新词，无复习', () async {
    final c = controller();
    final started = await c.start();
    expect(started, isTrue);
    expect(c.phase, SessionPhase.newWords);
    expect(c.newWordsLearned, 0);
    expect(c.current.word, 'water'); // 词频第 1
  });

  test('新词答错会重现，当日必过', () async {
    final c = controller();
    await c.start();
    await c.answer(correct: false); // water 答错
    expect(c.wrongCount, 1);
    // 队列里还有 9 个新词 + 重现的 water
    for (var i = 0; i < 9; i++) {
      await c.answer(correct: true);
    }
    // 最后应轮到重现的 water
    expect(c.current.word, 'water');
    expect(c.phase, SessionPhase.newWords);
    await c.answer(correct: true);
    expect(c.newWordsLearned, 10);
  });

  test('学完新词进入串词巩固，完成后打卡', () async {
    final c = controller();
    await c.start();
    for (var i = 0; i < 10; i++) {
      await c.answer(correct: true);
    }
    expect(c.phase, SessionPhase.consolidation);
    expect(c.unit, isNotNull);
    expect(c.unit!.unitNumber, 1);
    expect(await store.hasCheckIn(fakeNow), isFalse);
    await c.completeConsolidation();
    expect(c.phase, SessionPhase.done);
    expect(await store.hasCheckIn(fakeNow), isTrue);
  });

  test('次日开始：昨日新词因规则6强制复习', () async {
    final c1 = controller();
    await c1.start();
    for (var i = 0; i < 10; i++) {
      await c1.answer(correct: true);
    }
    await c1.completeConsolidation();

    fakeNow = DateTime(2026, 9, 9, 20); // 周三
    final c2 = controller();
    await c2.start();
    expect(c2.phase, SessionPhase.review);
    expect(c2.reviewsDue, 10); // 昨日 10 个新词全部次日强制复习
  });

  test('周末开始：只复习不学新词', () async {
    // 先学一天
    final c1 = controller();
    await c1.start();
    for (var i = 0; i < 10; i++) {
      await c1.answer(correct: true);
    }
    await c1.completeConsolidation();

    fakeNow = DateTime(2026, 9, 12, 10); // 周六
    final c2 = controller();
    await c2.start();
    expect(c2.weekendMode, isTrue);
    expect(c2.phase, SessionPhase.review);
  });

  test('无任务可学时返回 empty', () async {
    fakeNow = DateTime(2026, 9, 8, 20);
    final c = controller();
    await c.start();
    for (var i = 0; i < 10; i++) {
      await c.answer(correct: true);
    }
    await c.completeConsolidation();

    // 同一天再次开始：复习都未到期、新词当天已学
    final c2 = controller();
    final started = await c2.start();
    expect(started, isFalse);
    expect(c2.phase, SessionPhase.empty);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd app && flutter test test/session_controller_test.dart`
Expected: FAIL（SessionController 未定义）

- [ ] **Step 3: 实现 session_controller.dart**

```dart
import 'package:content_models/content_models.dart';
import 'package:srs_core/srs_core.dart';

import '../data/content_repository.dart';
import '../data/word_state_store.dart';

/// 会话阶段。
enum SessionPhase { review, newWords, consolidation, done, empty }

/// 学习会话编排器（UI 无关）。
///
/// 流程：复习到期词 → 学新词 → 串词巩固 → 打卡完成。
/// 规则 5（当日必过/会话内重现）：新词答错进入重学队列（排在本批新词之后），
/// 复习答错回到复习队尾，直到答对。
class SessionController {
  SessionController({
    required this.store,
    required this.content,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WordStateStore store;
  final ContentRepository content;
  final DateTime Function() _clock;

  SessionPhase phase = SessionPhase.done;
  DailyUnit? unit;
  int reviewsCompleted = 0;
  int wrongCount = 0;
  bool throttled = false;
  bool weekendMode = false;

  final List<WordState> _reviewQueue = [];
  final List<String> _newWordQueue = [];
  final List<WordState> _relearnQueue = []; // 新词答错后的重现队列
  final List<String> _learnedToday = [];
  WordState? _current;
  late Stage _stage;
  late DateTime _sessionStart;

  /// 当前卡片（复习词或新词）。
  WordState get current => _current!;

  /// 当前复习队列长度（UI 展示进度用）。
  int get reviewsDue => _reviewQueue.length + (phase == SessionPhase.review ? 1 : 0);

  /// 今天已学新词数。
  int get newWordsLearned => _learnedToday.length;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 开始会话。返回 false 表示今天没有可学内容（phase = empty）。
  Future<bool> start() async {
    final now = _clock();
    _sessionStart = now;
    _stage = await store.currentStage();
    final states = await store.allStates();
    final learned = states.map((s) => s.word).toSet();

    // 每日新词配额扣减：同一天重开会话不能重复学新词
    final learnedTodayCount =
        states.where((s) => _sameDay(s.learnedOn, now)).length;
    final remainingQuota = _stage.dailyNewWords - learnedTodayCount;
    final pending = remainingQuota <= 0
        ? <String>[]
        : content.pendingNewWords(_stage, learned).take(remainingQuota).toList();

    final plan = planSession(
      stage: _stage,
      allStates: states,
      pendingNewWords: pending,
      now: now,
    );

    _reviewQueue
      ..clear()
      ..addAll(plan.reviews);
    _newWordQueue
      ..clear()
      ..addAll(plan.newWords);
    _relearnQueue.clear();
    _learnedToday.clear();
    reviewsCompleted = 0;
    wrongCount = 0;
    throttled = plan.newWordsThrottled;
    weekendMode = plan.isWeekendMode;
    unit = null;

    if (_reviewQueue.isEmpty && _newWordQueue.isEmpty) {
      phase = SessionPhase.empty;
      return false;
    }
    await _advance();
    return true;
  }

  /// 回答当前卡片。答错的词重新入队（规则 2/5）。
  Future<void> answer({required bool correct}) async {
    final now = _clock();
    final outcome = applyAnswer(_current!, correct: correct, now: now);
    await store.save(outcome.newState);
    if (!correct) {
      wrongCount++;
      if (phase == SessionPhase.newWords) {
        _relearnQueue.add(outcome.newState); // 本批新词学完后重现
      } else {
        _reviewQueue.add(outcome.newState); // 复习队尾重现
      }
    } else if (phase == SessionPhase.review) {
      reviewsCompleted++;
    }
    await _advance();
  }

  /// 串词巩固完成 → 打卡，会话结束。
  Future<void> completeConsolidation() async {
    await store.checkIn(_sessionStart);
    phase = SessionPhase.done;
  }

  Future<void> _advance() async {
    if (_reviewQueue.isNotEmpty) {
      phase = SessionPhase.review;
      _current = _reviewQueue.removeAt(0);
      return;
    }
    if (_newWordQueue.isNotEmpty) {
      phase = SessionPhase.newWords;
      final word = _newWordQueue.removeAt(0);
      final state = WordState.newWord(word, _clock());
      await store.save(state); // 立即持久化：即使中途退出也记录 learnedOn
      _learnedToday.add(word);
      _current = state;
      return;
    }
    if (_relearnQueue.isNotEmpty) {
      phase = SessionPhase.newWords; // 重学仍属今日新词环节
      _current = _relearnQueue.removeAt(0);
      return;
    }
    // 队列清空 → 串词巩固或直接完成
    unit = _learnedToday.isEmpty
        ? null
        : content.unitContaining(_stage, _learnedToday);
    if (unit == null) {
      await store.checkIn(_sessionStart);
      phase = SessionPhase.done;
    } else {
      phase = SessionPhase.consolidation;
    }
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd app && flutter test test/session_controller_test.dart`
Expected: PASS（6 tests）

- [ ] **Step 5: Commit**

```bash
git add app/lib/controllers app/test/session_controller_test.dart
git commit -m "feat(app): SessionController 会话编排（复习/新词/巩固/打卡）"
```

---

### Task 5: providers、音频/TTS 服务与今日页

**Files:**
- Create: `app/lib/controllers/providers.dart`
- Create: `app/lib/services/audio_service.dart`
- Create: `app/lib/services/tts_service.dart`
- Modify: `app/lib/main.dart`
- Modify: `app/lib/ui/home_page.dart`
- Test: `app/test/app_smoke_test.dart`

**Interfaces:**
- Consumes: Task 2/3/4 全部产物
- Produces: providers：`contentRepositoryProvider`、`userDatabaseProvider`、`wordStateStoreProvider`、`sessionControllerProvider`、`todayViewModelProvider`（FutureProvider）、`audioServiceProvider`、`ttsServiceProvider`；`TodayViewModel { reviewCount, newWordCount, streakDays, checkedInToday, weekendMode, throttled, estimatedMinutes }`；`AudioService.playWord(String audioPath)`；`TtsService.speak(String)`、`stop()`

- [ ] **Step 1: 实现音频与 TTS 服务**

`app/lib/services/audio_service.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 单词音频播放。样例阶段音频文件尚未生成，缺失时静默跳过（不报错）。
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWord(String audioPath) async {
    try {
      await _player.setAsset('assets/audio/$audioPath');
      await _player.play();
    } catch (e) {
      debugPrint('音频不可用，跳过: $audioPath ($e)');
    }
  }

  void dispose() => _player.dispose();
}
```

`app/lib/services/tts_service.dart`：

```dart
import 'package:flutter_tts/flutter_tts.dart';

/// 句子/对话/短文朗读（系统 TTS，离线可用，spec §2 决策）。
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _ensureReady();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
```

- [ ] **Step 2: 实现 providers.dart**

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../data/content_repository.dart';
import '../data/user_database.dart';
import '../data/word_state_store.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import 'session_controller.dart';

/// 以下两个 provider 在 main() 中 override（初始化是异步的）。
final contentRepositoryProvider = Provider<ContentRepository>(
    (ref) => throw UnimplementedError('在 main 中 override'));

final userDatabaseProvider =
    Provider<UserDatabase>((ref) => throw UnimplementedError('在 main 中 override'));

final wordStateStoreProvider = Provider<WordStateStore>(
    (ref) => WordStateStore(ref.watch(userDatabaseProvider)));

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

final sessionControllerProvider = Provider<SessionController>((ref) {
  throw UnimplementedError('会话开始时由 SessionPage override');
});

/// 今日页视图模型。
class TodayViewModel {
  TodayViewModel({
    required this.reviewCount,
    required this.newWordCount,
    required this.streakDays,
    required this.checkedInToday,
    required this.weekendMode,
    required this.throttled,
  });

  final int reviewCount;
  final int newWordCount;
  final int streakDays;
  final bool checkedInToday;
  final bool weekendMode;
  final bool throttled;

  /// 预计时长（分钟）：复习 15 秒/词 + 新词 60 秒/词 + 巩固 5 分钟。
  int get estimatedMinutes =>
      (reviewCount * 15 + newWordCount * 60) ~/ 60 + (newWordCount > 0 ? 5 : 2);
}

final todayViewModelProvider = FutureProvider<TodayViewModel>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final now = DateTime.now();
  final stage = await store.currentStage();
  final states = await store.allStates();
  final learned = states.map((s) => s.word).toSet();
  final pending = content.pendingNewWords(stage, learned);
  final plan = planSession(
      stage: stage, allStates: states, pendingNewWords: pending, now: now);
  return TodayViewModel(
    reviewCount: plan.reviews.length,
    newWordCount: plan.newWords.length,
    streakDays: await store.streak(now),
    checkedInToday: await store.hasCheckIn(now),
    weekendMode: plan.isWeekendMode,
    throttled: plan.newWordsThrottled,
  );
});
```

- [ ] **Step 3: 改写 main.dart（异步初始化两库）**

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'controllers/providers.dart';
import 'data/content_installer.dart';
import 'data/content_repository.dart';
import 'data/user_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // content.db：从 assets 安装后只读打开
  final contentFile = await ContentInstaller.ensureInstalled();
  final content = ContentRepository.open(contentFile.path);

  // user.db：文档目录，读写
  final docs = await getApplicationDocumentsDirectory();
  final userDb = UserDatabase(
      NativeDatabase.createInBackground(File('${docs.path}/user.db')));

  runApp(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        userDatabaseProvider.overrideWithValue(userDb),
      ],
      child: const BirdsongApp(),
    ),
  );
}
```

- [ ] **Step 4: 实现今日页**

`app/lib/ui/home_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers.dart';
import '../controllers/session_controller.dart';
import 'session/session_page.dart';

/// 今日页：任务概览 + 开始学习入口。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(todayViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('学个鸟语')),
      body: vmAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (vm) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(todayViewModelProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 连续打卡
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 32),
                      const SizedBox(width: 12),
                      Text('连续打卡 ${vm.streakDays} 天',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 任务概览
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                        label: '待复习', value: '${vm.reviewCount}', icon: Icons.refresh),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                        label: '新单词', value: '${vm.newWordCount}', icon: Icons.fiber_new),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                        label: '预计', value: '${vm.estimatedMinutes}分钟', icon: Icons.timer),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (vm.weekendMode)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('周末轻量模式：只复习、不学新词',
                      style: TextStyle(fontSize: 13)),
                ),
              if (vm.throttled)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('复习积压较多，今日新词已减量',
                      style: TextStyle(fontSize: 13, color: Colors.orange)),
                ),
              // 开始按钮
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: vm.checkedInToday
                    ? null
                    : () => _startSession(context, ref),
                icon: Icon(
                    vm.checkedInToday ? Icons.check_circle : Icons.play_arrow),
                label: Text(vm.checkedInToday
                    ? '今日已完成'
                    : (vm.reviewCount == 0 && vm.newWordCount == 0
                        ? '暂无任务'
                        : '开始学习')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _startSession(BuildContext context, WidgetRef ref) async {
    final controller = SessionController(
      store: ref.read(wordStateStoreProvider),
      content: ref.read(contentRepositoryProvider),
    );
    final started = await controller.start();
    if (!started) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('今天的学习任务都完成啦')));
      }
      return false;
    }
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SessionPage(controller: controller)));
    }
    return true;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 创建 SessionPage 占位（Task 6 实现完整内容）**

`app/lib/ui/session/session_page.dart`：

```dart
import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';

/// 学习会话页（Task 6 实现完整内容）。
class SessionPage extends StatelessWidget {
  const SessionPage({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习中')),
      body: Center(child: Text('当前卡片: ${controller.current.word}')),
    );
  }
}
```

- [ ] **Step 6: 写 app 冒烟测试**

`app/test/app_smoke_test.dart`：

```dart
import 'dart:io';

import 'package:birdsong_app/app.dart';
import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('完整 app 启动：今日页显示待复习/新单词/开始学习', (tester) async {
    // 构建临时 content.db + 内存 user.db
    final tmp = await Directory.systemTemp.createTemp('smoke');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);

    final content = ContentRepository.open(dbPath);
    addTearDown(content.dispose);
    final userDb = UserDatabase(NativeDatabase.memory());
    addTearDown(() => userDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(content),
          userDatabaseProvider.overrideWithValue(userDb),
        ],
        child: const BirdsongApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('待复习'), findsOneWidget);
    expect(find.text('新单词'), findsOneWidget);
    expect(find.text('开始学习'), findsOneWidget);
  });
}
```

- [ ] **Step 7: 运行全部测试确认通过**

Run: `cd app && flutter test`
Expected: 全部 PASS（widget 1 + repository 5 + store 9 + controller 6 + smoke 1）

- [ ] **Step 8: Commit**

```bash
git add app/lib app/test/app_smoke_test.dart
git commit -m "feat(app): providers/音频TTS服务/今日页"
```

---

### Task 6: 学习会话页（复习卡/新词卡）

**Files:**
- Modify: `app/lib/ui/session/session_page.dart`（完整实现）
- Create: `app/lib/ui/session/word_card.dart`

**Interfaces:**
- Consumes: Task 4 的 `SessionController`；Task 5 的 `audioServiceProvider`、`ttsServiceProvider`
- Produces: 完整学习会话界面：进度条、卡片正反面、认识/不认识按钮、答错提示、阶段标签（复习/新词）

- [ ] **Step 1: 实现单词卡片组件**

`app/lib/ui/session/word_card.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 学习卡片：正面单词+音标，翻开后显示释义与例句。
class WordCard extends ConsumerStatefulWidget {
  const WordCard({super.key, required this.state, required this.revealed});

  final WordState state;
  final bool revealed;

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  @override
  Widget build(BuildContext context) {
    final audio = ref.read(audioServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final entry = ref.read(contentRepositoryProvider).wordOf(widget.state.word);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.state.word,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (entry != null)
              Text(entry.phonetic,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 16),
            IconButton.filledTonal(
              iconSize: 32,
              onPressed: () {
                if (entry != null) audio.playWord(entry.audioPath);
              },
              icon: const Icon(Icons.volume_up),
            ),
            if (widget.revealed && entry != null) ...[
              const Divider(height: 32),
              Text('${entry.pos} ${entry.meaningZh}',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final ex in entry.examples) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      iconSize: 18,
                      onPressed: () => tts.speak(ex.en),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.en, style: theme.textTheme.bodyLarge),
                          Text(ex.zh,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 完整实现 session_page.dart**

新词卡与复习卡的交互差异：复习卡先回想再翻开（`_revealed` 控制）；新词卡一上来
就展示释义（先学后测），所以卡片 `revealed` 传 `_revealed || !isReview`，
按钮区同样在 `!isReview` 时直接显示认识/不认识。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/session_controller.dart';
import 'consolidation_view.dart';
import 'word_card.dart';

/// 学习会话：复习 → 新词 → 串词巩固 → 完成。
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key, required this.controller});

  final SessionController controller;

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  bool _revealed = false;
  bool _busy = false;

  SessionController get c => widget.controller;

  bool get _isReview => c.phase == SessionPhase.review;

  Future<void> _answer(bool correct) async {
    if (_busy) return;
    setState(() => _busy = true);
    await c.answer(correct: correct);
    if (!mounted) return;
    setState(() {
      _revealed = false;
      _busy = false;
    });
    _syncPhase();
  }

  void _syncPhase() {
    if (c.phase == SessionPhase.consolidation) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ConsolidationView(controller: c)));
    } else if (c.phase == SessionPhase.done) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReview ? '复习' : '学新词'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
                child: Text(_isReview
                    ? '剩余 ${c.reviewsDue}'
                    : '已学 ${c.newWordsLearned}')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WordCard(
                state: c.current,
                revealed: _revealed || !_isReview,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _revealed || !_isReview
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _busy ? null : () => _answer(false),
                            icon: const Icon(Icons.close),
                            label: const Text('不认识'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _busy ? null : () => _answer(true),
                            icon: const Icon(Icons.check),
                            label: const Text('认识'),
                          ),
                        ),
                      ],
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 48)),
                      onPressed: () => setState(() => _revealed = true),
                      child: const Text('想一想，然后点开'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 ConsolidationView 占位（Task 7 实现）**

`app/lib/ui/session/consolidation_view.dart`：

```dart
import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';

/// 串词巩固页（Task 7 实现完整内容）。
class ConsolidationView extends StatelessWidget {
  const ConsolidationView({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('串词巩固')),
      body: const Center(child: Text('巩固内容')),
    );
  }
}
```

- [ ] **Step 4: 验证编译与既有测试**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 无 error；既有测试全部 PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/ui/session
git commit -m "feat(app): 学习会话页（复习卡/新词卡/认识-不认识）"
```

---

### Task 7: 串词巩固与完成总结

**Files:**
- Modify: `app/lib/ui/session/consolidation_view.dart`（完整实现）

**Interfaces:**
- Consumes: Task 4 的 `SessionController.unit`（DailyUnit）；Task 5 的 `ttsServiceProvider`
- Produces: 巩固页（例句朗读/对话/阅读/写作填空判题）+ 完成打卡 + 总结页

- [ ] **Step 1: 完整实现 consolidation_view.dart**

```dart
import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../controllers/session_controller.dart';

/// 串词巩固：用当天新词的素材做听说读写（配比由内容决定，spec §5.2）。
class ConsolidationView extends ConsumerStatefulWidget {
  const ConsolidationView({super.key, required this.controller});

  final SessionController controller;

  @override
  ConsumerState<ConsolidationView> createState() => _ConsolidationViewState();
}

class _ConsolidationViewState extends ConsumerState<ConsolidationView> {
  final Map<int, TextEditingController> _answers = {};
  final Map<int, bool> _fillResults = {};

  SessionController get c => widget.controller;

  void _checkFillBlank(int index, WritingPrompt prompt) {
    final input = (_answers[index]?.text ?? '').trim().toLowerCase();
    setState(() {
      _fillResults[index] = input == prompt.answer.trim().toLowerCase();
    });
  }

  Future<void> _finish() async {
    await c.completeConsolidation();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('今日学习完成'),
        content: Text(
          '复习 ${c.reviewsCompleted} 个词\n'
          '学会 ${c.newWordsLearned} 个新词\n'
          '答错 ${c.wrongCount} 次（已当场纠正）',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关对话框
              Navigator.of(context).pop(); // 回今日页
            },
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = c.unit;
    final tts = ref.read(ttsServiceProvider);
    final theme = Theme.of(context);
    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('串词巩固')),
        body: Center(
          child: FilledButton(
              onPressed: _finish, child: const Text('完成今日学习')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('串词巩固')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 例句
          if (unit.sentences.isNotEmpty) ...[
            Text('例句跟读', style: theme.textTheme.titleMedium),
            for (final s in unit.sentences)
              ListTile(
                leading: IconButton(
                    onPressed: () => tts.speak(s.en),
                    icon: const Icon(Icons.volume_up)),
                title: Text(s.en),
                subtitle: Text(s.zh),
              ),
          ],
          // 对话
          if (unit.dialogues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('对话', style: theme.textTheme.titleMedium),
            for (final d in unit.dialogues)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final t in d.turns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                                onPressed: () => tts.speak(t.en),
                                icon: const Icon(Icons.volume_up, size: 18)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t.speaker}: ${t.en}'),
                                  Text(t.zh,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.outline)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
          // 阅读
          if (unit.readings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('阅读', style: theme.textTheme.titleMedium),
            for (final r in unit.readings)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(r.title,
                                  style: theme.textTheme.titleSmall)),
                          IconButton(
                              onPressed: () => tts.speak(r.body),
                              icon: const Icon(Icons.volume_up)),
                        ],
                      ),
                      Text(r.body, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
          ],
          // 写作
          if (unit.writingPrompts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('写作', style: theme.textTheme.titleMedium),
            for (var i = 0; i < unit.writingPrompts.length; i++) ...[
              _buildPrompt(i, unit.writingPrompts[i], theme),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style:
                FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _finish,
            icon: const Icon(Icons.celebration),
            label: const Text('完成今日学习'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(int i, WritingPrompt prompt, ThemeData theme) {
    if (prompt.type == WritingPromptType.fillBlank) {
      final result = _fillResults[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt.question, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answers.putIfAbsent(i, TextEditingController.new),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: '填入单词'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: () => _checkFillBlank(i, prompt),
                    child: const Text('检查')),
              ],
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result ? '正确' : '再想想（参考答案在完成后可见）',
                  style: TextStyle(color: result ? Colors.green : Colors.orange),
                ),
              ),
          ],
        ),
      );
    }
    // 自由写作：只展示题目与参考
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt.question, style: theme.textTheme.bodyLarge),
          TextField(
            controller: _answers.putIfAbsent(i, TextEditingController.new),
            maxLines: 2,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: '写一句话'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
```

- [ ] **Step 2: 验证编译与既有测试**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 无 error；全部测试 PASS

- [ ] **Step 3: Commit**

```bash
git add app/lib/ui/session/consolidation_view.dart
git commit -m "feat(app): 串词巩固（例句/对话/阅读/写作）与完成总结"
```

---

### Task 8: 词书（列表/筛选/详情/手动调档）

**Files:**
- Modify: `app/lib/ui/wordbook/wordbook_page.dart`（完整实现）
- Create: `app/lib/ui/wordbook/word_detail_sheet.dart`

**Interfaces:**
- Consumes: Task 2 的 `ContentRepository`；Task 3 的 `WordStateStore`；srs_core 的 `applyManualLevel`、`Familiarity`
- Produces: 词书页（当前阶段词条列表 + 熟悉度徽章 + 筛选）；词详情底部弹层（释义/例句/音频 + 5 档手动调档按钮）

- [ ] **Step 1: 实现词详情底部弹层**

`app/lib/ui/wordbook/word_detail_sheet.dart`：

```dart
import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 词详情：释义/例句/音频 + 手动调整熟悉度（规则 4）。
class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({super.key, required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = ref.read(audioServiceProvider);
    final tts = ref.read(ttsServiceProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.word, style: theme.textTheme.headlineSmall),
                    Text(entry.phonetic,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => audio.playWord(entry.audioPath),
                icon: const Icon(Icons.volume_up),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${entry.pos} ${entry.meaningZh}',
              style: theme.textTheme.titleMedium),
          const Divider(height: 24),
          for (final ex in entry.examples) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  iconSize: 18,
                  onPressed: () => tts.speak(ex.en),
                  icon: const Icon(Icons.volume_up_outlined),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.en),
                      Text(ex.zh,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 24),
          Text('调整熟悉度', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _FamiliarityPicker(entry: entry),
        ],
      ),
    );
  }
}

class _FamiliarityPicker extends ConsumerWidget {
  const _FamiliarityPicker({required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WordState?>(
      future: _loadState(ref),
      builder: (context, snapshot) {
        final current = snapshot.data?.familiarity;
        return Wrap(
          spacing: 8,
          children: [
            for (final level in Familiarity.values)
              ChoiceChip(
                label: Text(level.label),
                selected: current == level,
                onSelected: (_) async {
                  await _applyLevel(ref, level);
                },
              ),
          ],
        );
      },
    );
  }

  Future<WordState?> _loadState(WidgetRef ref) async {
    final states = await ref.read(wordStateStoreProvider).allStates();
    for (final s in states) {
      if (s.word == entry.word) return s;
    }
    return null;
  }

  Future<void> _applyLevel(WidgetRef ref, Familiarity level) async {
    final store = ref.read(wordStateStoreProvider);
    final states = await store.allStates();
    WordState? state;
    for (final s in states) {
      if (s.word == entry.word) state = s;
    }
    // 未学过的词手动调档 = 以当前时间为 learnedOn 建状态
    state ??= WordState.newWord(entry.word, DateTime.now());
    await store.save(applyManualLevel(state, level, DateTime.now()));
  }
}
```

- [ ] **Step 2: 完整实现词书页**

`app/lib/ui/wordbook/wordbook_page.dart`：

```dart
import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';
import 'word_detail_sheet.dart';

/// 词书状态视图模型。
class WordbookItem {
  WordbookItem({required this.entry, required this.state});

  final WordEntry entry;
  final WordState? state;

  Familiarity? get familiarity => state?.familiarity;
}

final wordbookProvider = FutureProvider<List<WordbookItem>>((ref) async {
  final content = ref.watch(contentRepositoryProvider);
  final store = ref.watch(wordStateStoreProvider);
  final stage = await store.currentStage();
  final states = {for (final s in await store.allStates()) s.word: s};
  return [
    for (final entry in content.wordsOfStage(stage))
      WordbookItem(entry: entry, state: states[entry.word]),
  ];
});

/// 词书页：当前阶段词条 + 熟悉度筛选。
class WordbookPage extends ConsumerStatefulWidget {
  const WordbookPage({super.key});

  @override
  ConsumerState<WordbookPage> createState() => _WordbookPageState();
}

class _WordbookPageState extends ConsumerState<WordbookPage> {
  Familiarity? _filter;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wordbookProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('词书')),
      body: Column(
        children: [
          // 筛选条
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('全部'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final level in Familiarity.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(level.label),
                      selected: _filter == level,
                      onSelected: (_) => setState(() => _filter = level),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (items) {
                final filtered = _filter == null
                    ? items
                    : items.where((i) => i.familiarity == _filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('这个档位暂时没有单词'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(item.entry.word),
                      subtitle: Text(
                          '${item.entry.pos} ${item.entry.meaningZh}'),
                      trailing: item.familiarity == null
                          ? null
                          : Chip(
                              label: Text(item.familiarity!.label),
                              visualDensity: VisualDensity.compact,
                            ),
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => WordDetailSheet(entry: item.entry),
                        );
                        // 手动调档后刷新列表
                        ref.invalidate(wordbookProvider);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 验证编译与既有测试**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 无 error；全部测试 PASS

- [ ] **Step 4: Commit**

```bash
git add app/lib/ui/wordbook
git commit -m "feat(app): 词书（列表/熟悉度筛选/详情/手动调档）"
```

---

### Task 9: 模拟器端到端验证与收尾

**Files:**
- Modify: `docs/superpowers/plans/ROADMAP.md`（状态更新）

**Interfaces:**
- Consumes: 全部前序任务
- Produces: 模拟器上可完整走通的学习闭环；ROADMAP 更新

- [ ] **Step 1: 全仓库静态分析与测试**

Run: `melos analyze && melos test && melos test_flutter`
Expected: 全部 SUCCESS；app 测试 21+ 个全绿

- [ ] **Step 2: 启动 iOS 模拟器**

Run: `open -a Simulator && flutter devices`
Expected: 设备列表中出现 iPhone 模拟器（如 `iPhone 16 (mobile)`）

- [ ] **Step 3: 运行 app**

Run: `cd app && flutter run -d <模拟器设备ID>`
Expected: app 启动，显示「学个鸟语」，底部 3 个 Tab

- [ ] **Step 4: 手工验证清单（逐项操作并确认）**

1. 今日页：显示「待复习 0」「新单词 10」「预计 15 分钟」「连续打卡 0 天」
2. 点「开始学习」→ 进入学新词，第一张卡是 `water`，展示单词/音标
3. 点「记住了，看下一个」→ 卡片显示释义与例句；点喇叭按钮不崩溃（音频缺失静默跳过）
4. 点「认识」→ 进入下一个词；任选一词点「不认识」→ 该词在 10 个词学完后重现（当日必过）
5. 10 个新词学完 → 自动进入串词巩固：例句/对话/阅读/写作填空都在，点句子喇叭有 TTS 朗读
6. 写作填空输入 `water` 点检查 → 显示「正确」
7. 点「完成今日学习」→ 弹出总结对话框（学会 10 个新词）→ 返回今日页显示「今日已完成」
8. 词书 Tab：20 个词，刚学的 10 个带熟悉度徽章；筛选「模糊」显示 10 个
9. 点任一词 → 详情弹层；手动把某词调为「牢记」→ 徽章变为牢记
10. 系统切深色模式 → app 整体变暗，文字可读

- [ ] **Step 5: 修复验证中发现的问题并重跑测试**

如有问题：修复 → `flutter analyze && flutter test` → 重新运行验证。

- [ ] **Step 6: 更新 ROADMAP 并收尾提交**

将 `docs/superpowers/plans/ROADMAP.md` 中计划 2 的状态改为
`✅ 已完成（模拟器验证通过）`，文档路径更新为实际文件名。

```bash
git add -A
git commit -m "feat(app): 计划2完成 - 学习闭环可在模拟器运行"
```

---

## 计划 3-5 预告（不在本计划范围）

- **计划 3**：成就展示页、晋升流程 UI、本地提醒、Onboarding（选阶段 + 词汇量测试）
- **计划 4**：付费（StoreKit 2 / Play Billing）、备份（iCloud / Drive / 手动导出）、上架合规
- **计划 5**：正式 7000 词内容生产 + 单词音频批量生成
