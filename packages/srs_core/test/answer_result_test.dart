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
