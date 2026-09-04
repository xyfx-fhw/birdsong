// 学个鸟语 - SRS 引擎模拟器
// 模拟一名中级用户连续学习，验证 8 条调档规则的真实运转：
// 复习量曲线、升降档、次日强制复习、保险阀、周末消耗、毕业机制。
//
// 运行：cd packages/srs_core && dart run example/simulate.dart
import 'dart:math';

import 'package:content_models/content_models.dart';
import 'package:srs_core/srs_core.dart';

void main(List<String> args) {
  final rng = Random(42); // 固定种子，结果可复现
  // 用法：dart run example/simulate.dart [天数]，默认 120
  final totalDays = args.isNotEmpty ? int.parse(args[0]) : 120;
  const accuracy = 0.90; // 模拟用户整体答对率 90%
  final start = DateTime(2026, 9, 7, 20); // 从某个周一晚 8 点开始

  final states = <String, WordState>{};
  // 引擎只关心词的标识，用合成词即可（正式内容由 content.db 提供）
  final pending = List.generate(
    1200,
    (i) => 'word_${(i + 1).toString().padLeft(3, '0')}',
  );
  var pendingIndex = 0;

  print(
    '模拟 ${totalDays} 天中级学习：每天 10 新词，答对率 '
    '${(accuracy * 100).toInt()}%（种子 42）',
  );
  print('');
  print(
    '${'天'.padLeft(3)} ${'星期'.padRight(3)} ${'复习'.padLeft(4)} '
    '${'新词'.padLeft(3)} ${'答错'.padLeft(3)} ${'累计毕业'.padLeft(6)}  备注',
  );
  print('-' * 52);

  const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

  for (var d = 0; d < totalDays; d++) {
    final now = start.add(Duration(days: d));
    final plan = planSession(
      stage: Stage.intermediate,
      allStates: states.values.toList(),
      pendingNewWords: pending.sublist(pendingIndex),
      now: now,
    );

    var wrongCount = 0;

    // 复习队列：答错的词按规则 2/5 在会话内重现，直到答对（当日必过）
    final queue = [...plan.reviews];
    while (queue.isNotEmpty) {
      final w = queue.removeAt(0);
      final correct = rng.nextDouble() < accuracy;
      final outcome = applyAnswer(w, correct: correct, now: now);
      states[w.word] = outcome.newState;
      if (!correct) {
        wrongCount++;
        queue.add(outcome.newState);
      }
    }

    // 新词学习：首次学习同样必须答对才算完成
    for (final word in plan.newWords) {
      var s = WordState.newWord(word, now);
      while (true) {
        final correct = rng.nextDouble() < accuracy;
        final outcome = applyAnswer(s, correct: correct, now: now);
        s = outcome.newState;
        if (correct) break;
        wrongCount++;
      }
      states[word] = s;
    }
    pendingIndex += plan.newWords.length;

    final graduated = states.values.where((s) => s.graduated).length;
    final notes = <String>[
      if (plan.isWeekendMode) '周末',
      if (plan.newWordsThrottled) '保险阀(新词限流)',
      if (plan.isWeekendMode && plan.reviews.length > 75) '周末消耗',
    ];
    print(
      '${(d + 1).toString().padLeft(3)} '
      '周${weekdayNames[now.weekday - 1]}  '
      '${plan.reviews.length.toString().padLeft(4)} '
      '${plan.newWords.length.toString().padLeft(3)} '
      '${wrongCount.toString().padLeft(3)} '
      '${graduated.toString().padLeft(6)}  ${notes.join('，')}',
    );
  }

  // 最终熟悉度分布
  print('');
  print('=== 120 天后状态 ===');
  print('已学词数: ${states.length}');
  final byLevel = <Familiarity, int>{};
  for (final s in states.values) {
    byLevel[s.familiarity] = (byLevel[s.familiarity] ?? 0) + 1;
  }
  for (final level in Familiarity.values) {
    print('  ${level.label}: ${byLevel[level] ?? 0}');
  }
}
