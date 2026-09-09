import 'dart:io';

import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late Directory tmp;
  late ContentRepository content;
  late UserDatabase db;
  late WordStateStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('promo_test');
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

  test('promotionProvider 默认不可晋升（无学习记录）', () async {
    final container = ProviderContainer(
      overrides: [
        wordStateStoreProvider.overrideWithValue(store),
        contentRepositoryProvider.overrideWithValue(content),
      ],
    );
    addTearDown(container.dispose);

    final check = await container.read(promotionProvider.future);
    expect(check.eligible, isFalse);
  });

  test('全部学过且毕业>=80% 时可晋升', () async {
    // 把中级 20 词全部标记为毕业（16 个毕业 = 80%）
    final words = content.wordsOfStage(Stage.intermediate);
    final now = DateTime(2026, 9, 7);
    for (var i = 0; i < words.length; i++) {
      var s = WordState.newWord(words[i].word, now);
      s = applyManualLevel(s, Familiarity.mastered, now);
      if (i >= 16) {
        // 后 4 个只学过未毕业
        s = applyManualLevel(s, Familiarity.vague, now);
      }
      await store.save(s);
    }

    final container = ProviderContainer(
      overrides: [
        wordStateStoreProvider.overrideWithValue(store),
        contentRepositoryProvider.overrideWithValue(content),
      ],
    );
    addTearDown(container.dispose);

    final check = await container.read(promotionProvider.future);
    expect(check.eligible, isTrue);
    expect(check.graduatedRatio, closeTo(0.8, 0.001));
  });
}
