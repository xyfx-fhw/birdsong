# 学个鸟语 · 计划 3：激励与完整功能 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补全 app 的激励与完整功能：Onboarding（选阶段 + 可选词汇量测试）、成就页（统计 + 徽章 + 解锁提示）、晋升流程（达标提示 + 手动切换）、每日本地提醒；并清理计划 2 遗留的小问题。

**Architecture:** Onboarding 作为首启门控（读 user.db 设置 `onboarded`）；成就/晋升为纯展示层，判定全部调用 srs_core（`unlockedAchievements`/`checkPromotion`），app 只聚合 `LearningStats`；提醒用 flutter_local_notifications 每日定时。

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2、flutter_riverpod、flutter_local_notifications（+timezone）、drift（已有）。

**Spec:** `docs/superpowers/specs/2026-09-04-xuege-niaoyu-design.md`

## Global Constraints

- 成就判定/晋升判定只调用 srs_core，app 不重写规则
- 成就规则配置驱动：`defaultAchievements`（打卡 7/30/100/365/1000、累计 100/500/1000/3000、毕业 100/500/1000、词表进度 25/50/75/100%）
- 晋升条件：当前阶段词表全部学过 + 毕业比例 ≥ 80%（`checkPromotion`）；达标提示 + 可手动切换/回退
- Onboarding：欢迎 → 选阶段（附描述）→ [可选] 词汇量测试（看词选义）→ 确认 → 进入首页；未完成前不显示主界面
- 提醒：本地通知，用户设定每日提醒时间
- 深色模式跟随系统（已有），新页面不硬编码颜色，用 theme
- 计划 2 遗留清理（Task 5）：删死代码 `sessionControllerProvider`；填空答错文案改为不承诺展示答案；词书调档后 ChoiceChip 选中态即时更新

## 已有接口速查

```dart
// WordStateStore（Task 3 计划2）：allStates() / save / checkIn / hasCheckIn / streak / currentStage / setStage
//   本计划新增：setting(String key) / setSetting(key, value) / checkInCount()
// ContentRepository：wordsOfStage(Stage) / wordOf / pendingNewWords / unitContaining
// srs_core：unlockedAchievements(LearningStats, List<Achievement>) / defaultAchievements
//   LearningStats({totalCheckInDays, consecutiveDays, totalWordsLearned, graduatedWords, stageWordCount, stageGraduatedCount})
//   checkPromotion({required List<WordState> stageStates, double requiredRatio}) → PromotionCheck{eligible, graduatedRatio, requiredRatio}
// providers：contentRepositoryProvider / userDatabaseProvider / wordStateStoreProvider / todayViewModelProvider / audioServiceProvider / ttsServiceProvider
// Stage：intermediate/advanced/professional，.label 中文名；Stage.values 顺序即晋升顺序
```

---

### Task 1: store 通用设置 + Onboarding 首启门控

**Files:**
- Modify: `app/lib/data/word_state_store.dart`
- Create: `app/lib/ui/onboarding/onboarding_page.dart`
- Create: `app/lib/ui/onboarding/placement_test_page.dart`
- Modify: `app/lib/app.dart`（home 门控）
- Modify: `app/lib/controllers/providers.dart`（onboardedProvider）
- Test: `app/test/onboarding_test.dart`

**Interfaces:**
- Produces: `store.setting(String key) → Future<String?>`、`store.setSetting(String key, String value)`、`store.checkInCount() → Future<int>`；`onboardedProvider`（FutureProvider<bool>）；`OnboardingPage`（完成后 setSetting('onboarded','true') + setStage）；`PlacementTestPage`（返回推荐 Stage?）

- [ ] **Step 1: 写失败测试（store 设置 + 门控逻辑）**

`app/test/onboarding_test.dart`：

```dart
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserDatabase db;
  late WordStateStore store;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() => db.close());

  test('setting 默认 null，setSetting 后可读', () async {
    expect(await store.setting('onboarded'), isNull);
    await store.setSetting('onboarded', 'true');
    expect(await store.setting('onboarded'), 'true');
  });

  test('checkInCount 统计打卡天数', () async {
    final day = DateTime(2026, 9, 7);
    await store.checkIn(day);
    await store.checkIn(day.add(const Duration(days: 1)));
    expect(await store.checkInCount(), 2);
  });

  test('Onboarding 完成后 onboarded 持久化且阶段写入', () async {
    await store.setSetting('onboarded', 'true');
    await store.setStage(Stage.advanced);
    expect(await store.setting('onboarded'), 'true');
    expect(await store.currentStage(), Stage.advanced);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `cd app && flutter test test/onboarding_test.dart`
Expected: FAIL（setting/checkInCount 未定义）

- [ ] **Step 3: 给 word_state_store.dart 追加方法**

在 `WordStateStore` 类内追加：

```dart
  // ---- 通用设置 ----

  Future<String?> setting(String key) async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<int> checkInCount() async {
    final rows = await db.select(db.checkIns).get();
    return rows.length;
  }
```

- [ ] **Step 4: providers 追加 onboardedProvider**

```dart
/// 是否完成 Onboarding。
final onboardedProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  return (await store.setting('onboarded')) == 'true';
});
```

- [ ] **Step 5: 实现 onboarding_page.dart**

```dart
import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import 'placement_test_page.dart';

/// 首启引导：选阶段 → [可选]词汇量测试 → 确认。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  Stage _selected = Stage.intermediate;
  Stage? _recommended;

  Future<void> _finish() async {
    final store = ref.read(wordStateStoreProvider);
    await store.setStage(_selected);
    await store.setSetting('onboarded', 'true');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text('欢迎使用学个鸟语', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('每天一小步，坚持 3-5 年。\n选择你的起始阶段：',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              for (final stage in Stage.values) ...[
                RadioListTile<Stage>(
                  title: Text(stage.label),
                  subtitle: Text(_stageDesc(stage)),
                  value: stage,
                  groupValue: _selected,
                  onChanged: (s) => setState(() => _selected = s!),
                ),
                const SizedBox(height: 8),
              ],
              if (_recommended != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('测试推荐：${_recommended!.label}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<Stage?>(
                      MaterialPageRoute(
                          builder: (_) => const PlacementTestPage()));
                  if (result != null) {
                    setState(() {
                      _recommended = result;
                      _selected = result;
                    });
                  }
                },
                child: const Text('不确定？做个小测试'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  await _finish();
                  ref.invalidate(onboardedProvider);
                },
                child: const Text('开始学习'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageDesc(Stage stage) => switch (stage) {
        Stage.intermediate => '3000 词 · 约高中水平，读写流畅',
        Stage.advanced => '5000 词 · 约研究生水平，职场交流',
        Stage.professional => '7000 词 · 可过雅思/托福，留学海外',
      };
}
```

- [ ] **Step 6: 实现 placement_test_page.dart**

```dart
import 'dart:math';

import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';

/// 词汇量快速测试：10 道看词选义，估计起始阶段。
class PlacementTestPage extends ConsumerStatefulWidget {
  const PlacementTestPage({super.key});

  @override
  ConsumerState<PlacementTestPage> createState() => _PlacementTestPageState();
}

class _PlacementTestPageState extends ConsumerState<PlacementTestPage> {
  late final List<_Question> _questions;
  int _index = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final words = ref.read(contentRepositoryProvider).wordsOfStage(Stage.intermediate);
    if (words.length < 4) return [];
    final rng = Random(7);
    final picked = (List.of(words)..shuffle(rng)).take(10).toList();
    return [
      for (final w in picked)
        _Question(
          word: w.word,
          answer: w.meaningZh,
          options: _optionsFor(w, words, rng),
        ),
    ];
  }

  List<String> _optionsFor(WordEntry target, List<WordEntry> all, Random rng) {
    final distractors = (List.of(all)
          ..removeWhere((w) => w.word == target.word)
          ..shuffle(rng))
        .take(3)
        .map((w) => w.meaningZh)
        .toList();
    return (List.of(distractors)..add(target.meaningZh))..shuffle(rng);
  }

  void _answer(String option) {
    setState(() {
      if (option == _questions[_index].answer) _correct++;
      _index++;
    });
    if (_index >= _questions.length) {
      Navigator.of(context).pop(_recommend());
    }
  }

  /// 正确率 >= 80% 推荐高级，否则中级（样例词表为中级，专业级待正式词表）。
  Stage _recommend() {
    final ratio = _questions.isEmpty ? 0.0 : _correct / _questions.length;
    return ratio >= 0.8 ? Stage.advanced : Stage.intermediate;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('词汇量测试')),
        body: const Center(child: Text('词表不足，暂无法测试')),
      );
    }
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('词汇量测试 ${_index + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(q.word,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            for (final opt in q.options) ...[
              OutlinedButton(
                onPressed: () => _answer(opt),
                child: Text(opt),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Question {
  _Question({required this.word, required this.answer, required this.options});

  final String word;
  final String answer;
  final List<String> options;
}
```

- [ ] **Step 7: app.dart 加首启门控**

把 `home: const ShellPage()` 改为：

```dart
home: const StartupGate(),
```

并在 app.dart 追加（需 import riverpod 与 onboarding_page）：

```dart
/// 首启门控：未 Onboarding 显示引导，否则显示主界面。
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardedProvider);
    return onboarded.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (done) => done ? const ShellPage() : const OnboardingPage(),
    );
  }
}
```

app.dart 顶部追加 import：`package:flutter_riverpod/flutter_riverpod.dart` 与 `ui/onboarding/onboarding_page.dart`。

- [ ] **Step 8: 运行测试与既有冒烟测试**

Run: `cd app && flutter test`
Expected: 全绿。注意：既有 `widget_test.dart` 与 `app_smoke_test.dart` 的 `BirdsongApp` 现在会先显示 Onboarding（未 onboarded）。需把这两个测试的断言改为：pump 后 `find.text('欢迎使用学个鸟语')` 可见（或先 `setSetting('onboarded','true')` 再断言 3 Tab）。选择后者：在 pump 前 `await store.setSetting('onboarded', 'true');`，断言不变。

- [ ] **Step 9: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): Onboarding 首启门控（选阶段+词汇量测试）"
```

---

### Task 2: 成就页（统计 + 徽章 + 解锁提示）

**Files:**
- Create: `app/lib/ui/achievements/achievements_page.dart`
- Modify: `app/lib/app.dart`（底部栏加第 4 个 Tab「成就」）
- Modify: `app/lib/controllers/providers.dart`（achievementsProvider）
- Modify: `app/lib/ui/session/consolidation_view.dart`（完成后解锁提示）
- Test: `app/test/achievements_page_test.dart`

**Interfaces:**
- Produces: `achievementsProvider`（FutureProvider<AchievementsView>，含 stats + unlocked ids）；底部 4 Tab；巩固完成后对新增解锁弹 SnackBar

- [ ] **Step 1: 写失败测试**

`app/test/achievements_page_test.dart`：

```dart
import 'dart:io';

import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ach_test');
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    content = ContentRepository.open(dbPath);
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() async {
    content.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('achievementsProvider 聚合统计并判定解锁', () async {
    final day = DateTime(2026, 9, 7);
    await store.checkIn(day);

    final container = ProviderContainer(overrides: [
      wordStateStoreProvider.overrideWithValue(store),
      contentRepositoryProvider.overrideWithValue(content),
    ]);
    addTearDown(container.dispose);

    final view = await container.read(achievementsProvider.future);
    expect(view.stats.totalCheckInDays, 1);
    expect(view.stats.consecutiveDays, 1);
    // 打卡 1 天不应解锁 streak_7
    expect(view.unlockedIds, isNot(contains('streak_7')));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `cd app && flutter test test/achievements_page_test.dart`
Expected: FAIL（achievementsProvider 未定义）

- [ ] **Step 3: providers 追加 achievementsProvider**

```dart
/// 成就视图模型。
class AchievementsView {
  AchievementsView({required this.stats, required this.unlockedIds});

  final LearningStats stats;
  final Set<String> unlockedIds;
}

final achievementsProvider = FutureProvider<AchievementsView>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final now = DateTime.now();
  final stage = await store.currentStage();
  final states = await store.allStates();
  final stageWords = content.wordsOfStage(stage).map((w) => w.word).toSet();
  final stageStates = states.where((s) => stageWords.contains(s.word)).toList();

  final stats = LearningStats(
    totalCheckInDays: await store.checkInCount(),
    consecutiveDays: await store.streak(now),
    totalWordsLearned: states.length,
    graduatedWords: states.where((s) => s.graduated).length,
    stageWordCount: stageWords.length,
    stageGraduatedCount: stageStates.where((s) => s.graduated).length,
  );
  final unlocked = unlockedAchievements(stats, defaultAchievements);
  return AchievementsView(
    stats: stats,
    unlockedIds: unlocked.map((a) => a.id).toSet(),
  );
});
```

providers.dart 顶部追加 `import 'package:srs_core/srs_core.dart';`。

- [ ] **Step 4: 实现 achievements_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 成就页：学习统计 + 徽章列表。
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(achievementsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: viewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (view) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 统计卡
            Row(
              children: [
                _Stat('累计打卡', '${view.stats.totalCheckInDays}天'),
                _Stat('连续打卡', '${view.stats.consecutiveDays}天'),
                _Stat('已学词', '${view.stats.totalWordsLearned}'),
                _Stat('毕业词', '${view.stats.graduatedWords}'),
              ],
            ),
            const SizedBox(height: 16),
            Text('徽章', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final a in defaultAchievements)
              ListTile(
                leading: Icon(
                  view.unlockedIds.contains(a.id)
                      ? Icons.emoji_events
                      : Icons.lock_outline,
                  color: view.unlockedIds.contains(a.id)
                      ? Colors.amber
                      : theme.colorScheme.outline,
                ),
                title: Text(a.name),
                subtitle: Text(view.unlockedIds.contains(a.id) ? '已解锁' : '未解锁'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: app.dart 底部栏加「成就」Tab**

`_ShellPageState` 的 `_pages` 与 `destinations` 改为 4 项（今日/词书/成就/我的），import achievements_page。

- [ ] **Step 6: consolidation_view 完成后解锁提示**

在 `_finish()` 的 `completeConsolidation()` 之后、showDialog 之前：

```dart
    final before = await ref.read(achievementsProvider.future).then((v) => v.unlockedIds);
    ref.invalidate(achievementsProvider);
    final after = await ref.read(achievementsProvider.future).then((v) => v.unlockedIds);
    final newly = after.difference(before);
    if (newly.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('解锁 ${newly.length} 个成就，去成就页看看吧')));
    }
```

- [ ] **Step 7: 运行测试**

Run: `cd app && flutter test`
Expected: 全绿

- [ ] **Step 8: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): 成就页（统计/徽章/解锁提示）+ 第4个Tab"
```

---

### Task 3: 晋升流程（达标提示 + 手动切换）

**Files:**
- Modify: `app/lib/ui/profile_page.dart`（阶段卡片 + 晋升 + 手动切换）
- Modify: `app/lib/controllers/providers.dart`（promotionProvider）
- Test: `app/test/promotion_test.dart`

**Interfaces:**
- Produces: `promotionProvider`（FutureProvider<PromotionCheck>）；我的页显示当前阶段/毕业比例，eligible 时显示「晋升」按钮，确认后 `setStage(next)`；另提供阶段手动切换（3 个选项）

- [ ] **Step 1: 写失败测试**

`app/test/promotion_test.dart`：

```dart
import 'dart:io';

import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('promo_test');
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    content = ContentRepository.open(dbPath);
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() async {
    content.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('promotionProvider 默认不可晋升（无学习记录）', () async {
    final container = ProviderContainer(overrides: [
      wordStateStoreProvider.overrideWithValue(store),
      contentRepositoryProvider.overrideWithValue(content),
    ]);
    addTearDown(container.dispose);

    final check = await container.read(promotionProvider.future);
    expect(check.eligible, isFalse);
  });

  test('全部学过且毕业>=80% 时可晋升', () async {
    // 把中级 20 词全部标记为毕业（16 个毕业 = 80%）
    final words = content.wordsOfStage(Stage.intermediate);
    final now = DateTime(2026, 9, 7);
    for (var i = 0; i < words.length; i++) {
      var s = WordState.newWord(words[i].word, now);
      s = applyManualLevel(s, Familiarity.mastered, now);
      if (i >= 16) {
        // 后 4 个只学过未毕业
        s = applyManualLevel(s, Familiarity.vague, now);
      }
      await store.save(s);
    }

    final container = ProviderContainer(overrides: [
      wordStateStoreProvider.overrideWithValue(store),
      contentRepositoryProvider.overrideWithValue(content),
    ]);
    addTearDown(container.dispose);

    final check = await container.read(promotionProvider.future);
    expect(check.eligible, isTrue);
    expect(check.graduatedRatio, closeTo(0.8, 0.001));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `cd app && flutter test test/promotion_test.dart`
Expected: FAIL（promotionProvider 未定义）

- [ ] **Step 3: providers 追加 promotionProvider**

```dart
/// 当前阶段晋升检查。
final promotionProvider = FutureProvider<PromotionCheck>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final stage = await store.currentStage();
  final states = await store.allStates();
  final stageWords = content.wordsOfStage(stage).map((w) => w.word).toSet();
  final stageStates = states.where((s) => stageWords.contains(s.word)).toList();
  return checkPromotion(stageStates: stageStates);
});
```

- [ ] **Step 4: 重写 profile_page.dart**

```dart
import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers.dart';

/// 我的页：阶段与晋升、手动切换。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _promote(BuildContext context, WidgetRef ref, Stage next) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('晋升阶段'),
        content: Text('进入「${next.label}」阶段？\n新词表与新的学习配比将生效。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('再想想')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认晋升')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(wordStateStoreProvider).setStage(next);
      ref.invalidate(promotionProvider);
      ref.invalidate(todayViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(currentStageProvider);
    final promoAsync = ref.watch(promotionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          stageAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('加载失败: $e'),
            data: (stage) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前阶段：${stage.label}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    promoAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text('晋升检查失败: $e'),
                      data: (check) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '毕业比例：${(check.graduatedRatio * 100).toStringAsFixed(0)}% '
                              '（需 ≥ ${(check.requiredRatio * 100).toStringAsFixed(0)}%）'),
                          if (check.eligible && _next(stage) != null) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  _promote(context, ref, _next(stage)!),
                              icon: const Icon(Icons.celebration),
                              label: Text('晋升到${_next(stage)!.label}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    const Text('手动切换阶段'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in Stage.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: s == stage,
                            onSelected: (_) async {
                              await ref
                                  .read(wordStateStoreProvider)
                                  .setStage(s);
                              ref.invalidate(promotionProvider);
                              ref.invalidate(currentStageProvider);
                              ref.invalidate(todayViewModelProvider);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stage? _next(Stage stage) =>
      stage.index + 1 < Stage.values.length ? Stage.values[stage.index + 1] : null;
}
```

providers 追加：

```dart
/// 当前阶段。
final currentStageProvider = FutureProvider<Stage>((ref) =>
    ref.watch(wordStateStoreProvider).currentStage());
```

- [ ] **Step 5: 运行测试**

Run: `cd app && flutter test`
Expected: 全绿

- [ ] **Step 6: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): 晋升流程（达标提示+确认）与手动切换阶段"
```

---

### Task 4: 每日本地提醒

**Files:**
- Modify: `app/pubspec.yaml`（加 flutter_local_notifications + timezone）
- Create: `app/lib/services/reminder_service.dart`
- Modify: `app/lib/ui/profile_page.dart`（提醒时间设置 UI）
- Modify: `app/lib/controllers/providers.dart`（reminderServiceProvider）
- Test: `app/test/reminder_test.dart`

**Interfaces:**
- Produces: `ReminderService.scheduleDaily(TimeOfDay)` / `cancel()` / `currentSetting()`；我的页时间选择器；设置存 user.db（key `reminder_time`，值 `HH:mm`）

- [ ] **Step 1: 添加依赖**

Run: `cd app && flutter pub add flutter_local_notifications timezone`
Expected: pubspec 更新、解析成功

- [ ] **Step 2: 写失败测试**

`app/test/reminder_test.dart`：

```dart
import 'package:birdsong_app/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTime 解析 HH:mm', () {
    expect(ReminderService.parseTime('08:30'), const TimeOfDay(hour: 8, minute: 30));
    expect(ReminderService.parseTime(null), isNull);
  });

  test('formatTime 往返一致', () {
    const t = TimeOfDay(hour: 21, minute: 5);
    expect(ReminderService.parseTime(ReminderService.formatTime(t)), t);
  });
}
```

- [ ] **Step 3: 运行确认失败**

Run: `cd app && flutter test test/reminder_test.dart`
Expected: FAIL

- [ ] **Step 4: 实现 reminder_service.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 每日学习提醒（本地通知，spec §6.5）。
class ReminderService {
  static const _notificationId = 1;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static TimeOfDay? parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _ensureInit() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(
        android: androidSettings, iOS: darwinSettings, macOS: darwinSettings));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  /// 每天固定时间提醒。
  Future<void> scheduleDaily(TimeOfDay time) async {
    await _ensureInit();
    await _plugin.cancel(_notificationId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _notificationId,
      '学个鸟语',
      '该学鸟语了，每天一小步',
      scheduled,
      const NotificationDetails(
          android: AndroidNotificationDetails('birdsong_daily', '每日提醒'),
          iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await _ensureInit();
    await _plugin.cancel(_notificationId);
  }
}
```

- [ ] **Step 5: providers 追加 reminderServiceProvider**

```dart
final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());
```

- [ ] **Step 6: profile_page 加提醒设置**

在阶段卡片下方追加 Card：

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('每日提醒'),
        const SizedBox(height: 8),
        FutureBuilder<String?>(
          future: ref.read(wordStateStoreProvider).setting('reminder_time'),
          builder: (context, snap) {
            final current = ReminderService.parseTime(snap.data);
            return Row(
              children: [
                Text(current == null ? '未设置' : '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}'),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: current ?? const TimeOfDay(hour: 20, minute: 0),
                    );
                    if (picked != null) {
                      final store = ref.read(wordStateStoreProvider);
                      await store.setSetting('reminder_time', ReminderService.formatTime(picked));
                      await ref.read(reminderServiceProvider).scheduleDaily(picked);
                      if (context.mounted) setState(() {});
                    }
                  },
                  child: const Text('设置时间'),
                ),
              ],
            );
          },
        ),
      ],
    ),
  ),
)
```

注意：ProfilePage 当前是 ConsumerWidget，`setState` 不可用——把提醒卡抽成 `ConsumerStatefulWidget _ReminderCard`，或把 ProfilePage 改为 ConsumerStatefulWidget。实现者取后者更简单。

- [ ] **Step 7: 运行测试**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 无新增告警；测试全绿

- [ ] **Step 8: Commit**

```bash
git add app
git commit -m "feat(app): 每日本地提醒（时间设置+定时通知）"
```

---

### Task 5: 计划 2 遗留清理

**Files:**
- Modify: `app/lib/controllers/providers.dart`（删 `sessionControllerProvider` 死代码）
- Modify: `app/lib/ui/session/consolidation_view.dart`（填空答错文案）
- Modify: `app/lib/ui/wordbook/word_detail_sheet.dart`（调档后选中态即时更新）

**Interfaces:**
- Consumes: 无新增
- Produces: 三处小修，行为更正确

- [ ] **Step 1: 删死代码**

删除 providers.dart 中：

```dart
final sessionControllerProvider = Provider<SessionController>((ref) {
  throw UnimplementedError('会话开始时由 SessionPage override');
});
```

并确认无引用（grep `sessionControllerProvider` 应无其他命中）。

- [ ] **Step 2: 修填空答错文案**

consolidation_view.dart 中：

```dart
result ? '正确' : '再想想（参考答案在完成后可见）',
```

改为：

```dart
result ? '正确' : '再想想',
```

- [ ] **Step 3: 调档后选中态即时更新**

word_detail_sheet.dart 的 `_FamiliarityPicker` 改为 `ConsumerStatefulWidget`，`_applyLevel` 完成后 `setState(() {})` 触发 `_loadState` 重建（把 `future:` 换成在 `didChangeDependencies`/`setState` 后重新读取）。最简实现：`_applyLevel` 末尾 `setState(() {})`，并把 `FutureBuilder` 的 future 存到 state 字段、在 setState 时重新赋值。

- [ ] **Step 4: 运行测试**

Run: `cd app && flutter analyze && flutter test`
Expected: 全绿、无新增告警

- [ ] **Step 5: Commit**

```bash
git add app/lib
git commit -m "chore(app): 清理计划2遗留（死代码/文案/调档选中态）"
```

---

### Task 6: 端到端验证与收尾

**Files:**
- Modify: `docs/superpowers/plans/ROADMAP.md`

**Interfaces:**
- Consumes: 全部前序任务
- Produces: 全仓库验证 + 模拟器构建 + ROADMAP 更新

- [ ] **Step 1: 全仓库验证**

Run: `melos analyze && melos test && melos test_flutter`
Expected: 全部 SUCCESS

- [ ] **Step 2: 模拟器构建验证**

Run: `cd app && flutter build ios --no-codesign`（或 `flutter run` 到已启动模拟器）
Expected: 构建成功

- [ ] **Step 3: 更新 ROADMAP 并提交**

把计划 3 状态改为 `✅ 已完成`，文档路径改为实际文件名。

```bash
git add docs/superpowers/plans/ROADMAP.md
git commit -m "feat(app): 计划3完成 - 激励与完整功能"
```

---

## 计划 4-5 预告（不在本计划范围）

- **计划 4**：付费（StoreKit 2 / Play Billing / 恢复购买）、备份（iCloud / Drive / 手动导出）、上架合规
- **计划 5**：正式 7000 词内容生产 + 单词音频批量生成 + content_version 覆盖安装
