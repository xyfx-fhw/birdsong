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
      final unlocked =
          unlockedAchievements(stats(consecutive: 7), defaultAchievements);
      expect(unlocked.map((a) => a.id), contains('streak_7'));
    });

    test('累计学词100解锁', () {
      final unlocked =
          unlockedAchievements(stats(learned: 100), defaultAchievements);
      expect(unlocked.map((a) => a.id), contains('words_100'));
    });

    test('未达阈值不解锁', () {
      final unlocked =
          unlockedAchievements(stats(learned: 99), defaultAchievements);
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
    WordState word(String w, {bool graduated = false}) {
      final base = WordState.newWord(w, DateTime(2026, 1, 1));
      return graduated
          ? applyManualLevel(base, Familiarity.mastered, DateTime(2026, 1, 1))
          : base;
    }

    test('全部学过且毕业比例>=80% → 可晋升', () {
      final states = [
        for (var i = 0; i < 8; i++) word('g$i', graduated: true),
        for (var i = 0; i < 2; i++) word('n$i'),
      ];
      final check = checkPromotion(stageStates: states, stageWordCount: states.length);
      expect(check.eligible, isTrue);
      expect(check.graduatedRatio, closeTo(0.8, 0.001));
    });

    test('毕业比例不足 → 不可晋升', () {
      final states = [
        for (var i = 0; i < 7; i++) word('g$i', graduated: true),
        for (var i = 0; i < 3; i++) word('n$i'),
      ];
      expect(
          checkPromotion(stageStates: states, stageWordCount: states.length)
              .eligible,
          isFalse);
    });

    test('未全部学过（词表10词只学8个且全毕业）→ 不可晋升', () {
      final states = [
        for (var i = 0; i < 8; i++) word('g$i', graduated: true),
      ];
      final check = checkPromotion(stageStates: states, stageWordCount: 10);
      expect(check.eligible, isFalse);
    });
  });
}
