import 'dart:io';

import 'package:content_models/content_models.dart';
import 'package:content_pipeline/content_pipeline.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('db_build_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  WordEntry entry(String w, int rank) => WordEntry(
        word: w,
        phonetic: '/x/',
        pos: 'n.',
        meaningZh: '意思',
        audioPath: 'intermediate/$w.mp3',
        examples: [ExampleSentence(en: 'a $w', zh: '例句')],
        stage: Stage.intermediate,
        frequencyRank: rank,
      );

  test('生成的 content.db 包含 meta/words/examples/units', () {
    final result = ValidationResult(
      issues: [],
      wordEntries: [entry('apple', 1), entry('water', 2)],
      units: [
        DailyUnit(
          stage: Stage.intermediate,
          unitNumber: 1,
          newWords: ['apple', 'water'],
          sentences: [
            SentenceItem(en: 'I drink water.', zh: '我喝水。', focusWords: ['water'])
          ],
          dialogues: [],
          readings: [],
          writingPrompts: [],
        )
      ],
    );
    final out = '${tmp.path}/content.db';
    buildContentDb(content: result, outputPath: out, contentVersion: 1);

    final db = sqlite3.open(out);
    addTearDown(db.dispose);

    expect(
        db
            .select('SELECT value FROM meta WHERE key = ?', ['content_version'])
            .single['value'],
        '1');
    expect(db.select('SELECT COUNT(*) AS n FROM words').single['n'], 2);
    expect(db.select('SELECT zh FROM examples WHERE word = ?', ['apple']).single['zh'],
        '例句');
    final unit = db.select('SELECT new_words FROM units WHERE unit = 1').single;
    expect(unit['new_words'], contains('apple'));
  });

  test('重复构建会覆盖旧文件', () {
    final result =
        ValidationResult(issues: [], wordEntries: [entry('apple', 1)], units: []);
    final out = '${tmp.path}/content.db';
    buildContentDb(content: result, outputPath: out, contentVersion: 1);
    buildContentDb(content: result, outputPath: out, contentVersion: 2);
    final db = sqlite3.open(out);
    addTearDown(db.dispose);
    expect(
        db
            .select('SELECT value FROM meta WHERE key = ?', ['content_version'])
            .single['value'],
        '2');
  });
}
