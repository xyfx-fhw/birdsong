import 'familiarity.dart';

/// 单个单词的学习状态（持久化于 user.db，此处为纯数据）。
class WordState {
  WordState({
    required this.word,
    required this.familiarity,
    required this.correctCountInLevel,
    required this.learnedOn,
    this.lastReviewedAt,
    this.nextDueAt,
    this.missedOn,
    this.graduated = false,
  });

  final String word;
  final Familiarity familiarity;

  /// 当前档位内已连续答对次数（0/1/2，到 2 即升档并清零）。
  final int correctCountInLevel;

  /// 首次学习日期（用于次日强制复习判定，规则 6）。
  final DateTime learnedOn;
  final DateTime? lastReviewedAt;

  /// 下次到期时间；毕业词为 null。
  final DateTime? nextDueAt;

  /// 最近一次答错的日期（用于次日强制复习判定，规则 6）。
  final DateTime? missedOn;
  final bool graduated;

  /// 新词：默认模糊，排期到该档间隔 1（spec §4.1/§4.2）。
  factory WordState.newWord(String word, DateTime now) {
    const level = Familiarity.vague;
    return WordState(
      word: word,
      familiarity: level,
      correctCountInLevel: 0,
      learnedOn: now,
      nextDueAt: intervalLadder[level]!.$1.dueFrom(now),
    );
  }

  /// 哨兵：区分「未传参」与「显式传 null」。
  static const Object _unset = Object();

  WordState copyWith({
    Familiarity? familiarity,
    int? correctCountInLevel,
    DateTime? lastReviewedAt,
    Object? nextDueAt = _unset,
    Object? missedOn = _unset,
    bool? graduated,
  }) => WordState(
    word: word,
    familiarity: familiarity ?? this.familiarity,
    correctCountInLevel: correctCountInLevel ?? this.correctCountInLevel,
    learnedOn: learnedOn,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    nextDueAt: identical(nextDueAt, _unset)
        ? this.nextDueAt
        : nextDueAt as DateTime?,
    missedOn: identical(missedOn, _unset)
        ? this.missedOn
        : missedOn as DateTime?,
    graduated: graduated ?? this.graduated,
  );
}
