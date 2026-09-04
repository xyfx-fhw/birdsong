import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'validator.dart';

/// 生成只读 content.db（spec §3/§5.3）。
void buildContentDb({
  required ValidationResult content,
  required String outputPath,
  required int contentVersion,
}) {
  if (!content.ok) {
    throw StateError('内容校验未通过，拒绝构建: ${content.issues}');
  }
  final file = File(outputPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(outputPath);
  try {
    db.execute('''
      CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE words (
        word TEXT PRIMARY KEY,
        stage TEXT NOT NULL,
        phonetic TEXT NOT NULL,
        pos TEXT NOT NULL,
        meaning_zh TEXT NOT NULL,
        audio TEXT NOT NULL,
        frequency_rank INTEGER NOT NULL
      );
      CREATE TABLE examples (
        word TEXT NOT NULL REFERENCES words(word),
        seq INTEGER NOT NULL,
        en TEXT NOT NULL,
        zh TEXT NOT NULL,
        PRIMARY KEY (word, seq)
      );
      CREATE TABLE units (
        stage TEXT NOT NULL,
        unit INTEGER NOT NULL,
        new_words TEXT NOT NULL,
        sentences TEXT NOT NULL,
        dialogues TEXT NOT NULL,
        readings TEXT NOT NULL,
        writing_prompts TEXT NOT NULL,
        PRIMARY KEY (stage, unit)
      );
      CREATE INDEX idx_words_stage_rank ON words(stage, frequency_rank);
    ''');

    db.execute('BEGIN');
    final insertWord = db.prepare('INSERT INTO words VALUES (?, ?, ?, ?, ?, ?, ?)');
    final insertExample = db.prepare('INSERT INTO examples VALUES (?, ?, ?, ?)');
    final insertUnit = db.prepare('INSERT INTO units VALUES (?, ?, ?, ?, ?, ?, ?)');

    for (final w in content.wordEntries) {
      insertWord.execute([
        w.word,
        w.stage.name,
        w.phonetic,
        w.pos,
        w.meaningZh,
        w.audioPath,
        w.frequencyRank,
      ]);
      for (var i = 0; i < w.examples.length; i++) {
        insertExample.execute([w.word, i, w.examples[i].en, w.examples[i].zh]);
      }
    }
    for (final u in content.units) {
      insertUnit.execute([
        u.stage.name,
        u.unitNumber,
        jsonEncode(u.newWords),
        jsonEncode(u.sentences.map((s) => s.toJson()).toList()),
        jsonEncode(u.dialogues.map((d) => d.toJson()).toList()),
        jsonEncode(u.readings.map((r) => r.toJson()).toList()),
        jsonEncode(u.writingPrompts.map((w) => w.toJson()).toList()),
      ]);
    }
    db.execute("INSERT INTO meta VALUES ('content_version', '$contentVersion')");
    db.execute('COMMIT');
  } finally {
    db.dispose();
  }
}
