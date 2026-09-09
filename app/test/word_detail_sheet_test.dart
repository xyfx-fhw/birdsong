import 'package:birdsong_app/controllers/providers.dart';
import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:birdsong_app/ui/wordbook/word_detail_sheet.dart';
import 'package:content_models/content_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs_core/srs_core.dart';

void main() {
  late UserDatabase db;
  late WordStateStore store;

  final entry = WordEntry(
    word: 'abundant',
    phonetic: '/əˈbʌndənt/',
    pos: 'adj.',
    meaningZh: '丰富的',
    audioPath: 'advanced/abundant.mp3',
    examples: const [],
    stage: Stage.advanced,
    frequencyRank: 4200,
  );

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() => db.close());

  testWidgets('调档后 ChoiceChip 选中态即时更新', (tester) async {
    await store.save(WordState.newWord('abundant', DateTime(2026, 9, 9)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [userDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: Scaffold(body: WordDetailSheet(entry: entry))),
      ),
    );
    await tester.pumpAndSettle();

    // 初始状态：新词默认「模糊」档选中
    final vagueChip = find
        .ancestor(of: find.text('模糊'), matching: find.byType(ChoiceChip))
        .first;
    expect(tester.widget<ChoiceChip>(vagueChip).selected, isTrue);

    // 调档到「熟悉」
    await tester.tap(find.text('熟悉'));
    await tester.pumpAndSettle();

    // 选中态即时更新：「熟悉」选中、「模糊」取消
    final familiarChip = find
        .ancestor(of: find.text('熟悉'), matching: find.byType(ChoiceChip))
        .first;
    expect(tester.widget<ChoiceChip>(familiarChip).selected, isTrue);
    expect(tester.widget<ChoiceChip>(vagueChip).selected, isFalse);

    // 落库确认
    final states = await store.allStates();
    expect(states.single.familiarity, Familiarity.familiar);
  });
}
