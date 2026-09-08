import 'package:content_models/content_models.dart';
import 'package:srs_core/srs_core.dart';

import '../data/content_repository.dart';
import '../data/word_state_store.dart';

/// 会话阶段。
enum SessionPhase { review, newWords, consolidation, done, empty }

/// 学习会话编排器（UI 无关）。
///
/// 流程：复习到期词 → 学新词 → 串词巩固 → 打卡完成。
/// 规则 5（当日必过/会话内重现）：新词答错进入重学队列（排在本批新词之后），
/// 复习答错回到复习队尾，直到答对。
class SessionController {
  SessionController({
    required this.store,
    required this.content,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WordStateStore store;
  final ContentRepository content;
  final DateTime Function() _clock;

  SessionPhase phase = SessionPhase.done;
  DailyUnit? unit;
  int reviewsCompleted = 0;
  int wrongCount = 0;
  bool throttled = false;
  bool weekendMode = false;

  final List<WordState> _reviewQueue = [];
  final List<String> _newWordQueue = [];
  final List<WordState> _relearnQueue = []; // 新词答错后的重现队列
  final List<String> _learnedToday = [];
  WordState? _current;
  late Stage _stage;
  late DateTime _sessionStart;

  /// 当前卡片（复习词或新词）。
  WordState get current => _current!;

  /// 当前复习队列长度（UI 展示进度用）。
  int get reviewsDue => _reviewQueue.length + (phase == SessionPhase.review ? 1 : 0);

  /// 今天已学新词数。
  int get newWordsLearned => _learnedToday.length;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 开始会话。返回 false 表示今天没有可学内容（phase = empty）。
  Future<bool> start() async {
    final now = _clock();
    _sessionStart = now;
    _stage = await store.currentStage();
    final states = await store.allStates();
    final learned = states.map((s) => s.word).toSet();

    // 每日新词配额扣减：同一天重开会话不能重复学新词
    final learnedTodayCount =
        states.where((s) => _sameDay(s.learnedOn, now)).length;
    final remainingQuota = _stage.dailyNewWords - learnedTodayCount;
    final pending = remainingQuota <= 0
        ? <String>[]
        : content.pendingNewWords(_stage, learned).take(remainingQuota).toList();

    final plan = planSession(
      stage: _stage,
      allStates: states,
      pendingNewWords: pending,
      now: now,
    );

    _reviewQueue
      ..clear()
      ..addAll(plan.reviews);
    _newWordQueue
      ..clear()
      ..addAll(plan.newWords);
    _relearnQueue.clear();
    _learnedToday.clear();
    reviewsCompleted = 0;
    wrongCount = 0;
    throttled = plan.newWordsThrottled;
    weekendMode = plan.isWeekendMode;
    unit = null;

    if (_reviewQueue.isEmpty && _newWordQueue.isEmpty) {
      phase = SessionPhase.empty;
      return false;
    }
    await _advance();
    return true;
  }

  /// 回答当前卡片。答错的词重新入队（规则 2/5）。
  Future<void> answer({required bool correct}) async {
    final now = _clock();
    final outcome = applyAnswer(_current!, correct: correct, now: now);
    await store.save(outcome.newState);
    if (!correct) {
      wrongCount++;
      if (phase == SessionPhase.newWords) {
        _relearnQueue.add(outcome.newState); // 本批新词学完后重现
      } else {
        _reviewQueue.add(outcome.newState); // 复习队尾重现
      }
    } else if (phase == SessionPhase.review) {
      reviewsCompleted++;
    } else if (phase == SessionPhase.newWords) {
      _learnedToday.add(_current!.word); // 答对才算学会（抽出未答不计）
    }
    await _advance();
  }

  /// 串词巩固完成 → 打卡，会话结束。
  Future<void> completeConsolidation() async {
    await store.checkIn(_sessionStart);
    phase = SessionPhase.done;
  }

  Future<void> _advance() async {
    if (_reviewQueue.isNotEmpty) {
      phase = SessionPhase.review;
      _current = _reviewQueue.removeAt(0);
      return;
    }
    if (_newWordQueue.isNotEmpty) {
      phase = SessionPhase.newWords;
      final word = _newWordQueue.removeAt(0);
      final state = WordState.newWord(word, _clock());
      await store.save(state); // 立即持久化：即使中途退出也记录 learnedOn
      _current = state;
      return;
    }
    if (_relearnQueue.isNotEmpty) {
      phase = SessionPhase.newWords; // 重学仍属今日新词环节
      _current = _relearnQueue.removeAt(0);
      return;
    }
    // 队列清空 → 串词巩固或直接完成
    unit = _learnedToday.isEmpty
        ? null
        : content.unitContaining(_stage, _learnedToday);
    if (unit == null) {
      await store.checkIn(_sessionStart);
      phase = SessionPhase.done;
    } else {
      phase = SessionPhase.consolidation;
    }
  }
}
