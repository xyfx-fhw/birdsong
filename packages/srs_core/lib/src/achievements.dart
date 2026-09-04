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
    Achievement(
        id: 'streak_$d',
        name: '连续打卡 $d 天',
        condition: AchievementCondition.streakDays,
        threshold: d),
  for (final n in [100, 500, 1000, 3000])
    Achievement(
        id: 'words_$n',
        name: '累计学会 $n 词',
        condition: AchievementCondition.totalWords,
        threshold: n),
  for (final n in [100, 500, 1000])
    Achievement(
        id: 'graduated_$n',
        name: '$n 个词毕业',
        condition: AchievementCondition.graduatedWords,
        threshold: n),
  for (final p in [25, 50, 75, 100])
    Achievement(
        id: 'stage_progress_$p',
        name: '当前词表完成 $p%',
        condition: AchievementCondition.stageProgressPercent,
        threshold: p),
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
