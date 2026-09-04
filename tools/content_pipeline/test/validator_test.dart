import 'dart:convert';
import 'dart:io';

import 'package:content_pipeline/content_pipeline.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('pipeline_test');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void writeWordlist(List<Map<String, dynamic>> words) {
    Directory('${tmp.path}/wordlists').createSync(recursive: true);
    File('${tmp.path}/wordlists/intermediate.json')
        .writeAsStringSync(jsonEncode(words));
  }

  Map<String, dynamic> word(String w, int rank) => {
        'word': w,
        'phonetic': '/x/',
        'pos': 'n.',
        'meaning_zh': '意思',
        'audio': 'intermediate/$w.mp3',
        'examples': [
          {'en': 'a $w b', 'zh': '例句'}
        ],
        'stage': 'intermediate',
        'frequency_rank': rank,
      };

  test('合法内容通过校验', () {
    writeWordlist([word('apple', 1), word('water', 2)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(
        jsonEncode({
          'stage': 'intermediate',
          'unit': 1,
          'new_words': ['apple', 'water'],
          'sentences': [],
          'dialogues': [],
          'readings': [],
          'writing_prompts': []
        }));
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isTrue, reason: result.issues.toString());
    expect(result.wordEntries, hasLength(2));
    expect(result.units, hasLength(1));
  });

  test('单元引用不存在的词 → error', () {
    writeWordlist([word('apple', 1)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(
        jsonEncode({
          'stage': 'intermediate',
          'unit': 1,
          'new_words': ['apple', 'ghost'],
          'sentences': [],
          'dialogues': [],
          'readings': [],
          'writing_prompts': []
        }));
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
    expect(result.issues.any((i) => i.message.contains('ghost')), isTrue);
  });

  test('单元编号重复 → error', () {
    writeWordlist([word('apple', 1)]);
    Directory('${tmp.path}/daily/intermediate').createSync(recursive: true);
    final unit = jsonEncode({
      'stage': 'intermediate',
      'unit': 1,
      'new_words': ['apple'],
      'sentences': [],
      'dialogues': [],
      'readings': [],
      'writing_prompts': []
    });
    File('${tmp.path}/daily/intermediate/unit_001.json').writeAsStringSync(unit);
    File('${tmp.path}/daily/intermediate/unit_002.json').writeAsStringSync(unit);
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
  });

  test('词条 JSON 损坏 → error 并指明文件', () {
    Directory('${tmp.path}/wordlists').createSync(recursive: true);
    File('${tmp.path}/wordlists/intermediate.json')
        .writeAsStringSync('[{"word": "x"}]');
    final result = validateContent(contentSrcDir: tmp.path);
    expect(result.ok, isFalse);
    expect(result.issues.any((i) => i.message.contains('intermediate.json')),
        isTrue);
  });
}
