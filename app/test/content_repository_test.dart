import 'dart:io';

import 'package:birdsong_app/data/content_repository.dart';
import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late ContentRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('repo_test');
    // 用仓库样例内容构建一个临时 content.db
    final src = '${Directory.current.path}/../content_src';
    final validation = validateContent(contentSrcDir: src);
    expect(validation.ok, isTrue, reason: validation.issues.toString());
    final dbPath = '${tmp.path}/content.db';
    buildContentDb(content: validation, outputPath: dbPath, contentVersion: 1);
    repo = ContentRepository.open(dbPath);
  });

  tearDown(() async {
    repo.dispose();
    await tmp.delete(recursive: true);
  });

  test('wordsOfStage 返回该阶段全部词条（含例句）', () {
    final words = repo.wordsOfStage(Stage.intermediate);
    expect(words, hasLength(20));
    final water = words.firstWhere((w) => w.word == 'water');
    expect(water.meaningZh, '水');
    expect(water.examples, isNotEmpty);
  });

  test('wordOf 查单词，未找到返回 null', () {
    expect(repo.wordOf('apple')?.meaningZh, '苹果');
    expect(repo.wordOf('ghost'), isNull);
  });

  test('pendingNewWords 排除已学词，按词频排序', () {
    final pending = repo.pendingNewWords(Stage.intermediate, {'water', 'apple'});
    expect(pending, hasLength(18));
    expect(pending.first, 'book'); // frequency_rank 3，剩余中最高频
    expect(pending, isNot(contains('water')));
  });

  test('unitContaining 找到包含今日新词的单元', () {
    final unit = repo.unitContaining(Stage.intermediate, ['water', 'apple']);
    expect(unit, isNotNull);
    expect(unit!.unitNumber, 1);
  });

  test('unitsOfStage 按单元号排序', () {
    final units = repo.unitsOfStage(Stage.intermediate);
    expect(units.map((u) => u.unitNumber), [1, 2]);
  });
}
