import 'package:content_models/content_models.dart';
import 'package:test/test.dart';

void main() {
  group('Stage', () {
    test('每日新词量：中级10，高级/专业级6', () {
      expect(Stage.intermediate.dailyNewWords, 10);
      expect(Stage.advanced.dailyNewWords, 6);
      expect(Stage.professional.dailyNewWords, 6);
    });
  });

  group('WordEntry', () {
    final json = {
      'word': 'abundant',
      'phonetic': '/əˈbʌndənt/',
      'pos': 'adj.',
      'meaning_zh': '丰富的，充裕的',
      'audio': 'advanced/abundant.mp3',
      'examples': [
        {'en': 'The region has abundant natural resources.', 'zh': '该地区自然资源丰富。'}
      ],
      'stage': 'advanced',
      'frequency_rank': 4200,
    };

    test('fromJson 解析完整词条', () {
      final entry = WordEntry.fromJson(json);
      expect(entry.word, 'abundant');
      expect(entry.phonetic, '/əˈbʌndənt/');
      expect(entry.pos, 'adj.');
      expect(entry.meaningZh, '丰富的，充裕的');
      expect(entry.audioPath, 'advanced/abundant.mp3');
      expect(entry.examples, hasLength(1));
      expect(entry.examples.first.en, contains('abundant'));
      expect(entry.stage, Stage.advanced);
      expect(entry.frequencyRank, 4200);
    });

    test('toJson 与 fromJson 往返一致', () {
      final entry = WordEntry.fromJson(json);
      expect(WordEntry.fromJson(entry.toJson()).word, entry.word);
      expect(WordEntry.fromJson(entry.toJson()).frequencyRank, 4200);
    });

    test('缺少必填字段时抛 FormatException', () {
      final bad = Map<String, dynamic>.from(json)..remove('meaning_zh');
      expect(() => WordEntry.fromJson(bad), throwsFormatException);
    });
  });
}
