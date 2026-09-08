import 'word_state.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

/// 规则 6：昨天新学或昨天答错的词，今天必须强制复习一次。
bool needsNextDayReview(WordState s, DateTime now) {
  if (s.graduated) return false;
  final yesterday = _dayStart(now).subtract(const Duration(days: 1));
  final learnedYesterday = _sameDay(s.learnedOn, yesterday);
  final missedYesterday = s.missedOn != null && _sameDay(s.missedOn!, yesterday);
  return learnedYesterday || missedYesterday;
}

/// 到期判定：常规到期 或 次日强制复习命中。
/// 按天粒度：到期日当天任意时刻均算到期（每日会话开始时间不固定）。
bool isDue(WordState s, DateTime now) {
  if (s.graduated) return false;
  if (needsNextDayReview(s, now)) return true;
  final due = s.nextDueAt;
  return due != null && !_dayStart(due).isAfter(_dayStart(now));
}

/// 当前所有到期词，按到期时间升序（最久的排最前）。
List<WordState> dueWords(Iterable<WordState> all, DateTime now) {
  final due = all.where((s) => isDue(s, now)).toList()
    ..sort((a, b) {
      final da = a.nextDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.nextDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
  return due;
}

/// 规则 8：周末消耗兜底。积压超过 threshold 时，
/// 把未来 lookaheadDays 天内到期的词提前到周末复习。
List<WordState> weekendExtraWords(
  Iterable<WordState> all,
  DateTime now, {
  required int backlogCount,
  int threshold = 75,
  int lookaheadDays = 3,
}) {
  if (backlogCount <= threshold) return const [];
  final horizon = _dayStart(now).add(Duration(days: lookaheadDays + 1));
  return all
      .where((s) =>
          !s.graduated &&
          !isDue(s, now) &&
          s.nextDueAt != null &&
          s.nextDueAt!.isBefore(horizon))
      .toList()
    ..sort((a, b) => a.nextDueAt!.compareTo(b.nextDueAt!));
}
