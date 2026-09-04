import 'package:content_models/content_models.dart';

import 'scheduler.dart';
import 'word_state.dart';

/// 一天的学习计划。
class DailyPlan {
  DailyPlan({
    required this.reviews,
    required this.newWords,
    required this.isWeekendMode,
    required this.newWordsThrottled,
  });

  /// 本次会话要复习的词（含次日强制与周末提前量）。
  final List<WordState> reviews;

  /// 本次会话要学的新词（周末或保险阀触发时为空）。
  final List<String> newWords;
  final bool isWeekendMode;

  /// 保险阀是否生效（规则 7）。
  final bool newWordsThrottled;
}

bool _isWeekend(DateTime now) =>
    now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

/// 编排每日任务（spec §4.3 规则 7/8、§4.4）。
DailyPlan planSession({
  required Stage stage,
  required List<WordState> allStates,
  required List<String> pendingNewWords,
  required DateTime now,
  int backlogThreshold = 100,
  int weekendBacklogThreshold = 75,
}) {
  final reviews = dueWords(allStates, now);
  final weekend = _isWeekend(now);

  // 规则 8：周末且积压超阈值 → 提前消化未来 3 天到期的词
  if (weekend && reviews.length > weekendBacklogThreshold) {
    reviews.addAll(weekendExtraWords(allStates, now,
        backlogCount: reviews.length, threshold: weekendBacklogThreshold));
  }

  // 周末不学新词（spec §4.4）
  if (weekend) {
    return DailyPlan(
      reviews: reviews,
      newWords: const [],
      isWeekendMode: true,
      newWordsThrottled: false,
    );
  }

  // 规则 7：积压保险阀 10 → 6 → 0
  final backlog = reviews.length;
  var quota = stage.dailyNewWords;
  var throttled = false;
  if (backlog > backlogThreshold + 50) {
    quota = 0;
    throttled = true;
  } else if (backlog > backlogThreshold) {
    quota = quota > 6 ? 6 : quota;
    throttled = true;
  }

  final newWords = pendingNewWords.take(quota).toList();
  return DailyPlan(
    reviews: reviews,
    newWords: newWords,
    isWeekendMode: false,
    newWordsThrottled: throttled,
  );
}
