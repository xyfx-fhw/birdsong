import 'dart:io';

import 'package:birdsong_app/app.dart';
import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('完整 app 启动：今日页显示待复习/新单词/开始学习', (tester) async {
    // 构建临时 content.db + 内存 user.db
    // （真实文件 I/O 需在 runAsync 中执行，testWidgets 默认 FakeAsync 会挂起）
    late Directory tmp;
    late ContentRepository content;
    late UserDatabase userDb;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('smoke');
      final src = '${Directory.current.path}/../content_src';
      final validation = validateContent(contentSrcDir: src);
      final dbPath = '${tmp.path}/content.db';
      buildContentDb(
        content: validation,
        outputPath: dbPath,
        contentVersion: 1,
      );
      content = ContentRepository.open(dbPath);
      userDb = UserDatabase(NativeDatabase.memory());
    });
    addTearDown(() => tmp.deleteSync(recursive: true));
    addTearDown(content.dispose);
    addTearDown(() => userDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(content),
          userDatabaseProvider.overrideWithValue(userDb),
        ],
        child: const BirdsongApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('待复习'), findsOneWidget);
    expect(find.text('新单词'), findsOneWidget);
    expect(find.text('开始学习'), findsOneWidget);
  });
}
