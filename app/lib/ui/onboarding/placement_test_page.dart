import 'dart:math';

import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';

/// 词汇量快速测试：10 道看词选义，估计起始阶段。
class PlacementTestPage extends ConsumerStatefulWidget {
  const PlacementTestPage({super.key});

  @override
  ConsumerState<PlacementTestPage> createState() => _PlacementTestPageState();
}

class _PlacementTestPageState extends ConsumerState<PlacementTestPage> {
  late final List<_Question> _questions;
  int _index = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final words = ref.read(contentRepositoryProvider).wordsOfStage(Stage.intermediate);
    if (words.length < 4) return [];
    final rng = Random(7);
    final picked = (List.of(words)..shuffle(rng)).take(10).toList();
    return [
      for (final w in picked)
        _Question(
          word: w.word,
          answer: w.meaningZh,
          options: _optionsFor(w, words, rng),
        ),
    ];
  }

  List<String> _optionsFor(WordEntry target, List<WordEntry> all, Random rng) {
    final distractors = (List.of(all)
          ..removeWhere((w) => w.word == target.word)
          ..shuffle(rng))
        .take(3)
        .map((w) => w.meaningZh)
        .toList();
    return (List.of(distractors)..add(target.meaningZh))..shuffle(rng);
  }

  void _answer(String option) {
    setState(() {
      if (option == _questions[_index].answer) _correct++;
      _index++;
    });
    if (_index >= _questions.length) {
      Navigator.of(context).pop(_recommend());
    }
  }

  /// 正确率 >= 80% 推荐高级，否则中级（样例词表为中级，专业级待正式词表）。
  Stage _recommend() {
    final ratio = _questions.isEmpty ? 0.0 : _correct / _questions.length;
    return ratio >= 0.8 ? Stage.advanced : Stage.intermediate;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('词汇量测试')),
        body: const Center(child: Text('词表不足，暂无法测试')),
      );
    }
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('词汇量测试 ${_index + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(q.word,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            for (final opt in q.options) ...[
              OutlinedButton(
                onPressed: () => _answer(opt),
                child: Text(opt),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Question {
  _Question({required this.word, required this.answer, required this.options});

  final String word;
  final String answer;
  final List<String> options;
}
