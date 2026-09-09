import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../controllers/session_controller.dart';

/// 串词巩固：用当天新词的素材做听说读写（配比由内容决定，spec §5.2）。
class ConsolidationView extends ConsumerStatefulWidget {
  const ConsolidationView({super.key, required this.controller});

  final SessionController controller;

  @override
  ConsumerState<ConsolidationView> createState() => _ConsolidationViewState();
}

class _ConsolidationViewState extends ConsumerState<ConsolidationView> {
  final Map<int, TextEditingController> _answers = {};
  final Map<int, bool> _fillResults = {};

  SessionController get c => widget.controller;

  void _checkFillBlank(int index, WritingPrompt prompt) {
    final input = (_answers[index]?.text ?? '').trim().toLowerCase();
    setState(() {
      _fillResults[index] = input == prompt.answer.trim().toLowerCase();
    });
  }

  Future<void> _finish() async {
    await c.completeConsolidation();
    final before = await ref
        .read(achievementsProvider.future)
        .then((v) => v.unlockedIds);
    ref.invalidate(achievementsProvider);
    ref.invalidate(promotionProvider);
    final after = await ref
        .read(achievementsProvider.future)
        .then((v) => v.unlockedIds);
    final newly = after.difference(before);
    if (newly.isNotEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('解锁 ${newly.length} 个成就，去成就页看看吧')));
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('今日学习完成'),
        content: Text(
          '复习 ${c.reviewsCompleted} 个词\n'
          '学会 ${c.newWordsLearned} 个新词\n'
          '答错 ${c.wrongCount} 次（已当场纠正）',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关对话框
              Navigator.of(context).pop(); // 回今日页
            },
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = c.unit;
    final tts = ref.read(ttsServiceProvider);
    final theme = Theme.of(context);
    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('串词巩固')),
        body: Center(
          child: FilledButton(onPressed: _finish, child: const Text('完成今日学习')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('串词巩固')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 例句
          if (unit.sentences.isNotEmpty) ...[
            Text('例句跟读', style: theme.textTheme.titleMedium),
            for (final s in unit.sentences)
              ListTile(
                leading: IconButton(
                  onPressed: () => tts.speak(s.en),
                  icon: const Icon(Icons.volume_up),
                ),
                title: Text(s.en),
                subtitle: Text(s.zh),
              ),
          ],
          // 对话
          if (unit.dialogues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('对话', style: theme.textTheme.titleMedium),
            for (final d in unit.dialogues)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final t in d.turns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => tts.speak(t.en),
                              icon: const Icon(Icons.volume_up, size: 18),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t.speaker}: ${t.en}'),
                                  Text(
                                    t.zh,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
          // 阅读
          if (unit.readings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('阅读', style: theme.textTheme.titleMedium),
            for (final r in unit.readings)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            onPressed: () => tts.speak(r.body),
                            icon: const Icon(Icons.volume_up),
                          ),
                        ],
                      ),
                      Text(r.body, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
          ],
          // 写作
          if (unit.writingPrompts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('写作', style: theme.textTheme.titleMedium),
            for (var i = 0; i < unit.writingPrompts.length; i++) ...[
              _buildPrompt(i, unit.writingPrompts[i], theme),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _finish,
            icon: const Icon(Icons.celebration),
            label: const Text('完成今日学习'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(int i, WritingPrompt prompt, ThemeData theme) {
    if (prompt.type == WritingPromptType.fillBlank) {
      final result = _fillResults[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt.question, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answers.putIfAbsent(
                      i,
                      TextEditingController.new,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '填入单词',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _checkFillBlank(i, prompt),
                  child: const Text('检查'),
                ),
              ],
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result ? '正确' : '再想想',
                  style: TextStyle(
                    color: result ? Colors.green : Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // 自由写作：只展示题目与参考
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt.question, style: theme.textTheme.bodyLarge),
          TextField(
            controller: _answers.putIfAbsent(i, TextEditingController.new),
            maxLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '写一句话',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
