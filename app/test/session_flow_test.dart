import 'dart:io';

import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/controllers/session_controller.dart';
import 'package:birdsong_app/data/content_repository.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:birdsong_app/ui/home_page.dart';
import 'package:birdsong_app/ui/session/consolidation_view.dart';
import 'package:birdsong_app/ui/session/session_page.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 会话链导航与刷新的端到端 widget 测试。
///
/// 覆盖三条结束路径：
/// 1. 完整会话（新词 → 巩固 → 完成）→ 回首页且今日页刷新；
/// 2. 恢复路径（巩固打断后重进）→ 直接进巩固页，不崩溃，完成后回首页刷新；
/// 3. 无巩固直接 done（unit 为 null）→ 回首页且刷新。
void main() {
  // 真实文件 I/O 需在 runAsync 中执行（testWidgets 默认 FakeAsync 会挂起）
  Future<ContentRepository> buildContent(
    WidgetTester tester,
    String srcDir,
  ) async {
    late ContentRepository content;
    late Directory tmp;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('session_flow');
      final validation = validateContent(contentSrcDir: srcDir);
      final dbPath = '${tmp.path}/content.db';
      buildContentDb(
        content: validation,
        outputPath: dbPath,
        contentVersion: 1,
      );
      content = ContentRepository.open(dbPath);
    });
    addTearDown(() => tmp.deleteSync(recursive: true));
    addTearDown(content.dispose);
    return content;
  }

  Widget app(ContentRepository content, UserDatabase db) => ProviderScope(
    overrides: [
      contentRepositoryProvider.overrideWithValue(content),
      userDatabaseProvider.overrideWithValue(db),
    ],
    child: const MaterialApp(home: HomePage()),
  );

  testWidgets('完整会话：巩固期间首页仍在栈中，完成后回到首页且今日页显示已完成', (tester) async {
    final content = await buildContent(tester, '../content_src');
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    await tester.pumpWidget(app(content, db));
    await tester.pumpAndSettle();
    expect(find.text('开始学习'), findsOneWidget);

    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsOneWidget);

    // 10 个新词全部答对
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('认识'));
      await tester.pumpAndSettle();
    }

    // 进入巩固页。此时尚未打卡：若首页 push 的 Future 此刻就完成
    // （pushReplacement 的 bug），invalidate 会重算出旧数据。
    expect(find.byType(ConsolidationView), findsOneWidget);
    expect(
      find.byType(HomePage, skipOffstage: false),
      findsOneWidget,
      reason: '巩固期间首页路由应仍在导航栈中（会话链未结束）',
    );
    expect(
      find.text('今日已完成', skipOffstage: false),
      findsNothing,
      reason: '尚未打卡，今日页不应提前显示已完成',
    );

    // 巩固页是懒加载 ListView，完成按钮在底部，先滚动到可见
    await tester.scrollUntilVisible(
      find.text('完成今日学习'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('完成今日学习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好的'));
    await tester.pumpAndSettle();

    // 整条会话链结束：回到首页，且刷新发生在打卡之后
    expect(find.byType(ConsolidationView), findsNothing);
    expect(find.byType(SessionPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('今日已完成'), findsOneWidget);
  });

  testWidgets('恢复路径：巩固打断后重进直接进巩固页，完成打卡后回首页', (tester) async {
    final content = await buildContent(tester, '../content_src');
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final store = WordStateStore(db);

    // 预置：学完 10 个新词进入巩固后被打断（未打卡）
    final c1 = SessionController(store: store, content: content);
    await c1.start();
    for (var i = 0; i < 10; i++) {
      await c1.answer(correct: true);
    }
    expect(c1.phase, SessionPhase.consolidation);
    expect(await store.hasCheckIn(DateTime.now()), isFalse);

    await tester.pumpWidget(app(content, db));
    await tester.pumpAndSettle();
    expect(find.text('开始学习'), findsOneWidget);

    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();

    // 分流：直接进巩固页，而不是读 current 崩溃的会话页
    expect(find.byType(ConsolidationView), findsOneWidget);
    expect(find.byType(SessionPage), findsNothing);

    await tester.scrollUntilVisible(
      find.text('完成今日学习'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('完成今日学习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好的'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('今日已完成'), findsOneWidget);
    expect(await store.hasCheckIn(DateTime.now()), isTrue);
  });

  testWidgets('无巩固直接完成：学完即打卡回首页并刷新', (tester) async {
    // 最小内容：1 个词、无单元 → 学完无巩固素材，直接打卡
    final content = await buildContent(tester, 'test/content_no_unit');
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final store = WordStateStore(db);

    await tester.pumpWidget(app(content, db));
    await tester.pumpAndSettle();
    expect(find.text('开始学习'), findsOneWidget);

    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('今日已完成'), findsOneWidget);
    expect(await store.hasCheckIn(DateTime.now()), isTrue);
  });
}
