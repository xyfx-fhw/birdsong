import 'familiarity.dart';
import 'word_state.dart';

/// 一次答题的结果。
class AnswerOutcome {
  AnswerOutcome({required this.newState, required this.reappearInSession});

  final WordState newState;

  /// 答错时为 true：该词须在本次会话结束前重现（规则 2/5）。
  final bool reappearInSession;
}

Familiarity _shift(Familiarity level, int steps) {
  final idx = (level.index + steps).clamp(0, Familiarity.values.length - 1);
  return Familiarity.values[idx];
}

/// 处理一次答题（spec §4.3 规则 1-3）。
AnswerOutcome applyAnswer(WordState state,
    {required bool correct, required DateTime now}) {
  if (correct) {
    final count = state.correctCountInLevel + 1;
    if (count < correctAnswersToPromote) {
      // 本档未集满：留在原档，按当前进度排到下一个间隔
      final ladder = intervalLadder[state.familiarity]!;
      final next = count == 1 ? ladder.$1 : ladder.$2;
      return AnswerOutcome(
        newState: state.copyWith(
          correctCountInLevel: count,
          lastReviewedAt: now,
          nextDueAt: next.dueFrom(now),
        ),
        reappearInSession: false,
      );
    }
    // 升 1 档（规则 1）
    final promoted = _shift(state.familiarity, 1);
    if (promoted.isMastered) {
      return AnswerOutcome(
        newState: state.copyWith(
          familiarity: promoted,
          correctCountInLevel: 0,
          lastReviewedAt: now,
          nextDueAt: null,
          graduated: true,
        ),
        reappearInSession: false,
      );
    }
    // 变档后从新档间隔 1 重走（规则 3）
    return AnswerOutcome(
      newState: state.copyWith(
        familiarity: promoted,
        correctCountInLevel: 0,
        lastReviewedAt: now,
        nextDueAt: intervalLadder[promoted]!.$1.dueFrom(now),
      ),
      reappearInSession: false,
    );
  }

  // 答错：降 2 档（下限陌生），从新档间隔 1 重走，会话内重现（规则 2/3）
  final demoted = _shift(state.familiarity, -demoteStepsOnWrong);
  return AnswerOutcome(
    newState: state.copyWith(
      familiarity: demoted,
      correctCountInLevel: 0,
      lastReviewedAt: now,
      nextDueAt: intervalLadder[demoted]!.$1.dueFrom(now),
      missedOn: now,
    ),
    reappearInSession: true,
  );
}

/// 手动调档（规则 4）：从目标档间隔 1 开始走；设牢记 = 直接毕业。
WordState applyManualLevel(WordState state, Familiarity level, DateTime now) {
  if (level.isMastered) {
    return state.copyWith(
      familiarity: level,
      correctCountInLevel: 0,
      lastReviewedAt: now,
      nextDueAt: null,
      graduated: true,
    );
  }
  return state.copyWith(
    familiarity: level,
    correctCountInLevel: 0,
    lastReviewedAt: now,
    nextDueAt: intervalLadder[level]!.$1.dueFrom(now),
  );
}
