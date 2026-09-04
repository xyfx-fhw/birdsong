/// 复习间隔。用分钟数表示分钟/天级间隔，用 months 表示月级间隔
/// （月长度不固定，必须用日历计算）。
class ReviewInterval {
  const ReviewInterval.minutes(int m) : _minutes = m, months = null;
  const ReviewInterval.days(int d) : _minutes = d * 24 * 60, months = null;
  const ReviewInterval.months(this.months) : _minutes = null;

  final int? _minutes;
  final int? months;

  /// 从 base 推算到期时间。月间隔按日历月计算，日溢出收敛到月末。
  DateTime dueFrom(DateTime base) {
    if (_minutes != null) return base.add(Duration(minutes: _minutes!));
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
      other is ReviewInterval &&
      other._minutes == _minutes &&
      other.months == months;

  @override
  int get hashCode => Object.hash(_minutes, months);

  @override
  String toString() =>
      _minutes != null ? 'Interval($_minutes min)' : 'Interval(${months}mo)';
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
