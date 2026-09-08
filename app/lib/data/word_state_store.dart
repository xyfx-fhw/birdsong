import 'package:content_models/content_models.dart';
import 'package:drift/drift.dart';
import 'package:srs_core/srs_core.dart';

import 'user_database.dart';

/// user.db 的 DAO：单词状态 / 打卡 / 设置。
class WordStateStore {
  WordStateStore(this.db);

  final UserDatabase db;

  static const _stageKey = 'current_stage';

  // ---- 单词状态 ----

  Future<List<WordState>> allStates() async {
    final rows = await db.select(db.learnedWords).get();
    return rows.map(_toDomain).toList();
  }

  Future<void> save(WordState s) => db
      .into(db.learnedWords)
      .insertOnConflictUpdate(_toCompanion(s));

  // ---- 打卡 ----

  DateTime _dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

  Future<void> checkIn(DateTime day) => db
      .into(db.checkIns)
      .insertOnConflictUpdate(CheckInsCompanion.insert(day: _dayStart(day)));

  Future<bool> hasCheckIn(DateTime day) async {
    final row = await (db.select(db.checkIns)
          ..where((t) => t.day.equals(_dayStart(day))))
        .getSingleOrNull();
    return row != null;
  }

  /// 连续打卡天数：今天已打卡则从今天往回数，否则从昨天往回数。
  Future<int> streak(DateTime today) async {
    final rows = await (db.select(db.checkIns)
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
    final days = rows.map((r) => r.day).toSet();
    var cursor = _dayStart(today);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ---- 设置 ----

  Future<Stage> currentStage() async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(_stageKey)))
        .getSingleOrNull();
    if (row == null) return Stage.intermediate;
    return Stage.fromName(row.value);
  }

  Future<void> setStage(Stage stage) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _stageKey, value: stage.name));

  // ---- 映射 ----

  WordState _toDomain(LearnedWord r) => WordState(
        word: r.word,
        familiarity: Familiarity.values[r.familiarity],
        correctCountInLevel: r.correctCountInLevel,
        learnedOn: r.learnedOn,
        lastReviewedAt: r.lastReviewedAt,
        nextDueAt: r.nextDueAt,
        missedOn: r.missedOn,
        graduated: r.graduated,
      );

  LearnedWordsCompanion _toCompanion(WordState s) => LearnedWordsCompanion.insert(
        word: s.word,
        familiarity: s.familiarity.index,
        correctCountInLevel: Value(s.correctCountInLevel),
        learnedOn: s.learnedOn,
        lastReviewedAt: Value(s.lastReviewedAt),
        nextDueAt: Value(s.nextDueAt),
        missedOn: Value(s.missedOn),
        graduated: Value(s.graduated),
      );
}
