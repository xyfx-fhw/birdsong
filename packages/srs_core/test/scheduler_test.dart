import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  final day0 = DateTime(2026, 9, 1, 20); // 周二
  final day1 = day0.add(const Duration(days: 1));

  group('isDue 基础到期判定', () {
    test('未到期的词不算到期', () {
      // learnedOn 在 10 天前（避开规则 6），到期日在未来
      final s = WordState(
        word: 'a',
        familiarity: Familiarity.recognize,
        correctCountInLevel: 0,
        learnedOn: day0.subtract(const Duration(days: 10)),
        nextDueAt: day1.add(const Duration(days: 5)),
      );
      expect(isDue(s, day1), isFalse);
    });

    test('到期时间已过的词算到期', () {
      final s = WordState.newWord('a', day0);
      expect(isDue(s, DateTime(2026, 9, 3, 21)), isTrue);
    });

    test('毕业词永不到期', () {
      final s = applyManualLevel(
        WordState.newWord('a', day0),
        Familiarity.mastered,
        day0,
      );
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
      s = applyAnswer(
        s,
        correct: false,
        now: day0,
      ).newState; // 降档，missedOn=day0
      // 模拟当天 10 分钟后已复习过（排期推进），但 missedOn 仍是 day0
      expect(needsNextDayReview(s, day1), isTrue);
    });

    test('前天学的词不再强制（阶梯照常）', () {
      final s = WordState.newWord('a', day0);
      expect(needsNextDayReview(s, day0.add(const Duration(days: 2))), isFalse);
    });
  });

  group('规则8：周末消耗兜底', () {
    // 构造 learnedOn 久远（避开规则 6）、到期日在未来的词
    WordState upcoming(String w, int dueInDays) => WordState(
      word: w,
      familiarity: Familiarity.recognize,
      correctCountInLevel: 0,
      learnedOn: day0.subtract(const Duration(days: 10)),
      nextDueAt: day1.add(Duration(days: dueInDays)),
    );

    test('积压>75 时返回未来3天内到期的词', () {
      final words = [upcoming('a', 1), upcoming('b', 2), upcoming('c', 10)];
      final extra = weekendExtraWords(words, day1, backlogCount: 80);
      expect(extra.map((w) => w.word), containsAll(['a', 'b']));
      expect(extra.map((w) => w.word), isNot(contains('c')));
    });

    test('积压<=75 时不额外加量', () {
      final words = [upcoming('a', 1)];
      expect(weekendExtraWords(words, day1, backlogCount: 75), isEmpty);
    });
  });
}
