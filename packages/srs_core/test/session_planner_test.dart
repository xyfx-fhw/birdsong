import 'package:content_models/content_models.dart';
import 'package:srs_core/srs_core.dart';
import 'package:test/test.dart';

void main() {
  final monday = DateTime(2026, 9, 7, 20); // 周一
  final saturday = DateTime(2026, 9, 12, 10); // 周六
  final pending = List.generate(30, (i) => 'word$i');

  // 构造 learnedOn 久远、已逾期的词（避开规则 6）
  WordState overdue(String w, DateTime now) => WordState(
        word: w,
        familiarity: Familiarity.recognize,
        correctCountInLevel: 0,
        learnedOn: now.subtract(const Duration(days: 20)),
        nextDueAt: now.subtract(const Duration(days: 2)),
      );

  group('平日模式', () {
    test('中级平日：10 个新词 + 到期复习', () {
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [overdue('old', monday)],
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
    List<WordState> makeBacklog(int n, DateTime now) =>
        List.generate(n, (i) => overdue('b$i', now));

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
      final overdueList = List.generate(80, (i) => overdue('o$i', saturday));
      final upcoming = WordState(
        word: 'soon',
        familiarity: Familiarity.recognize,
        correctCountInLevel: 0,
        learnedOn: saturday.subtract(const Duration(days: 20)),
        nextDueAt: saturday.add(const Duration(days: 2)),
      );
      final plan = planSession(
        stage: Stage.intermediate,
        allStates: [...overdueList, upcoming],
        pendingNewWords: pending,
        now: saturday,
      );
      expect(plan.reviews.map((w) => w.word), contains('soon'));
    });
  });
}
