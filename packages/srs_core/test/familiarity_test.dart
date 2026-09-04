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
