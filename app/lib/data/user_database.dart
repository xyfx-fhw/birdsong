import 'package:drift/drift.dart';

part 'user_database.g.dart';

/// 单词学习状态，与 srs_core 的 WordState 一一对应。
class LearnedWords extends Table {
  TextColumn get word => text()();
  IntColumn get familiarity => integer()();
  IntColumn get correctCountInLevel =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get learnedOn => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  DateTimeColumn get missedOn => dateTime().nullable()();
  BoolColumn get graduated => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {word};
}

/// 打卡记录，每天一条（存当天零点）。
class CheckIns extends Table {
  DateTimeColumn get day => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

/// 键值设置（当前阶段等）。
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [LearnedWords, CheckIns, AppSettings])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
