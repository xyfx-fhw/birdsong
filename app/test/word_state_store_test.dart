import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late UserDatabase db;
  late WordStateStore store;
  final day = DateTime(2026, 9, 7, 20);

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() => db.close());

  group('单词状态持久化', () {
    test('save 后 allStates 往返一致', () async {
      final s = WordState.newWord('apple', day);
      await store.save(s);
      final loaded = await store.allStates();
      expect(loaded, hasLength(1));
      final got = loaded.single;
      expect(got.word, 'apple');
      expect(got.familiarity, Familiarity.vague);
      expect(got.nextDueAt, s.nextDueAt);
      expect(got.graduated, isFalse);
    });

    test('重复 save 同一词为更新而非插入', () async {
      await store.save(WordState.newWord('apple', day));
      final updated = applyAnswer(
        WordState.newWord('apple', day),
        correct: true,
        now: day,
      ).newState;
      await store.save(updated);
      final loaded = await store.allStates();
      expect(loaded, hasLength(1));
      expect(loaded.single.correctCountInLevel, 1);
    });
  });

  group('打卡与连续天数', () {
    test('checkIn 幂等，hasCheckIn 正确', () async {
      expect(await store.hasCheckIn(day), isFalse);
      await store.checkIn(day);
      await store.checkIn(day); // 重复打卡不报错
      expect(await store.hasCheckIn(day), isTrue);
    });

    test('streak 统计连续天数（今天已打卡）', () async {
      await store.checkIn(day.subtract(const Duration(days: 2)));
      await store.checkIn(day.subtract(const Duration(days: 1)));
      await store.checkIn(day);
      expect(await store.streak(day), 3);
    });

    test('streak 今天未打卡时从昨天数', () async {
      await store.checkIn(day.subtract(const Duration(days: 1)));
      await store.checkIn(day.subtract(const Duration(days: 2)));
      expect(await store.streak(day), 2);
    });

    test('streak 中断后归零', () async {
      await store.checkIn(day.subtract(const Duration(days: 3)));
      expect(await store.streak(day), 0);
    });
  });

  group('阶段设置', () {
    test('默认中级', () async {
      expect(await store.currentStage(), Stage.intermediate);
    });

    test('setStage 持久化', () async {
      await store.setStage(Stage.advanced);
      expect(await store.currentStage(), Stage.advanced);
    });
  });
}
