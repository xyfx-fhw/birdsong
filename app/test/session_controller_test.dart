import 'dart:io';

import 'package:birdsong_app/controllers/session_controller.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;
  // 模拟「今天是 2026-09-08 周二 20:00」，可随测试推进
  late DateTime fakeNow;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('session_test');
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    content = ContentRepository.open(dbPath);
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
    fakeNow = DateTime(2026, 9, 8, 20);
  });

  tearDown(() async {
    content.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  SessionController controller() => SessionController(
        store: store,
        content: content,
        clock: () => fakeNow,
      );

  test('首次开始：10 个新词，无复习', () async {
    final c = controller();
    final started = await c.start();
    expect(started, isTrue);
    expect(c.phase, SessionPhase.newWords);
    expect(c.newWordsLearned, 0);
    expect(c.current.word, 'water'); // 词频第 1
  });

  test('新词答错会重现，当日必过', () async {
    final c = controller();
    await c.start();
    await c.answer(correct: false); // water 答错
    expect(c.wrongCount, 1);
    // 队列里还有 9 个新词 + 重现的 water
    for (var i = 0; i < 9; i++) {
      await c.answer(correct: true);
    }
    // 最后应轮到重现的 water
    expect(c.current.word, 'water');
    expect(c.phase, SessionPhase.newWords);
    await c.answer(correct: true);
    expect(c.newWordsLearned, 10);
  });

  test('学完新词进入串词巩固，完成后打卡', () async {
    final c = controller();
    await c.start();
    for (var i = 0; i < 10; i++) {
      await c.answer(correct: true);
    }
    expect(c.phase, SessionPhase.consolidation);
    expect(c.unit, isNotNull);
    expect(c.unit!.unitNumber, 1);
    expect(await store.hasCheckIn(fakeNow), isFalse);
    await c.completeConsolidation();
    expect(c.phase, SessionPhase.done);
    expect(await store.hasCheckIn(fakeNow), isTrue);
  });

  test('次日开始：昨日新词因规则6强制复习', () async {
    final c1 = controller();
    await c1.start();
    for (var i = 0; i < 10; i++) {
      await c1.answer(correct: true);
    }
    await c1.completeConsolidation();

    fakeNow = DateTime(2026, 9, 9, 20); // 周三
    final c2 = controller();
    await c2.start();
    expect(c2.phase, SessionPhase.review);
    expect(c2.reviewsDue, 10); // 昨日 10 个新词全部次日强制复习
  });

  test('周末开始：只复习不学新词', () async {
    // 先学一天
    final c1 = controller();
    await c1.start();
    for (var i = 0; i < 10; i++) {
      await c1.answer(correct: true);
    }
    await c1.completeConsolidation();

    fakeNow = DateTime(2026, 9, 12, 10); // 周六
    final c2 = controller();
    await c2.start();
    expect(c2.weekendMode, isTrue);
    expect(c2.phase, SessionPhase.review);
  });

  test('无任务可学时返回 empty', () async {
    fakeNow = DateTime(2026, 9, 8, 20);
    final c = controller();
    await c.start();
    for (var i = 0; i < 10; i++) {
      await c.answer(correct: true);
    }
    await c.completeConsolidation();

    // 同一天再次开始：复习都未到期、新词当天已学
    final c2 = controller();
    final started = await c2.start();
    expect(started, isFalse);
    expect(c2.phase, SessionPhase.empty);
  });
}
