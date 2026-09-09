import 'dart:io';

import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ach_test');
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    content = ContentRepository.open(dbPath);
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() async {
    content.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('achievementsProvider 聚合统计并判定解锁', () async {
    // 打卡日期相对 now，避免 streak(now) 随日期漂移
    final day = DateTime.now();
    await store.checkIn(day);

    final container = ProviderContainer(
      overrides: [
        wordStateStoreProvider.overrideWithValue(store),
        contentRepositoryProvider.overrideWithValue(content),
      ],
    );
    addTearDown(container.dispose);

    final view = await container.read(achievementsProvider.future);
    expect(view.stats.totalCheckInDays, 1);
    expect(view.stats.consecutiveDays, 1);
    // 打卡 1 天不应解锁 streak_7
    expect(view.unlockedIds, isNot(contains('streak_7')));
  });
}
