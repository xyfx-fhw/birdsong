import 'dart:io';

import 'package:birdsong_app/app.dart';
import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app 启动并显示 3 个 Tab', (tester) async {
    // 构建临时 content.db + 内存 user.db
    // （真实文件 I/O 需在 runAsync 中执行，testWidgets 默认 FakeAsync 会挂起）
    late Directory tmp;
    late ContentRepository content;
    late UserDatabase userDb;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('widget');
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
      await WordStateStore(userDb).setSetting('onboarded', 'true');
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

    expect(find.text('今日'), findsWidgets);
    expect(find.text('词书'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
