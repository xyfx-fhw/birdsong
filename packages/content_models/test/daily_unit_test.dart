import 'package:content_models/content_models.dart';
import 'package:test/test.dart';

void main() {
  final json = {
    'stage': 'intermediate',
    'unit': 1,
    'new_words': ['apple', 'water'],
    'sentences': [
      {'en': 'I drink water every day.', 'zh': '我每天喝水。', 'focus_words': ['water']}
    ],
    'dialogues': [
      {
        'turns': [
          {'speaker': 'A', 'en': 'Do you want an apple?', 'zh': '你想要一个苹果吗？'},
          {'speaker': 'B', 'en': 'Yes, please.', 'zh': '好的，谢谢。'},
        ]
      }
    ],
    'readings': [
      {'title': 'A Healthy Day', 'body': 'I eat an apple and drink water.', 'focus_words': ['apple', 'water']}
    ],
    'writing_prompts': [
      {'type': 'fill_blank', 'question': 'I drink ___ every day.', 'answer': 'water', 'focus_words': ['water']}
    ],
  };

  test('fromJson 解析完整单元', () {
    final unit = DailyUnit.fromJson(json);
    expect(unit.stage, Stage.intermediate);
    expect(unit.unitNumber, 1);
    expect(unit.newWords, ['apple', 'water']);
    expect(unit.sentences.single.focusWords, ['water']);
    expect(unit.dialogues.single.turns, hasLength(2));
    expect(unit.readings.single.title, 'A Healthy Day');
    expect(unit.writingPrompts.single.type, WritingPromptType.fillBlank);
  });

  test('new_words 为空时抛 FormatException', () {
    final bad = Map<String, dynamic>.from(json)..['new_words'] = <String>[];
    expect(() => DailyUnit.fromJson(bad), throwsFormatException);
  });

  test('toJson 往返一致', () {
    final unit = DailyUnit.fromJson(json);
    final roundTrip = DailyUnit.fromJson(unit.toJson());
    expect(roundTrip.newWords, unit.newWords);
    expect(roundTrip.dialogues.single.turns.length, 2);
  });
}
