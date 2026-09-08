import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 学习卡片：正面单词+音标，翻开后显示释义与例句。
class WordCard extends ConsumerStatefulWidget {
  const WordCard({super.key, required this.state, required this.revealed});

  final WordState state;
  final bool revealed;

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  @override
  Widget build(BuildContext context) {
    final audio = ref.read(audioServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final entry = ref.read(contentRepositoryProvider).wordOf(widget.state.word);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.state.word,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (entry != null)
              Text(entry.phonetic,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 16),
            IconButton.filledTonal(
              iconSize: 32,
              onPressed: () {
                if (entry != null) audio.playWord(entry.audioPath);
              },
              icon: const Icon(Icons.volume_up),
            ),
            if (widget.revealed && entry != null) ...[
              const Divider(height: 32),
              Text('${entry.pos} ${entry.meaningZh}',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final ex in entry.examples) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      iconSize: 18,
                      onPressed: () => tts.speak(ex.en),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.en, style: theme.textTheme.bodyLarge),
                          Text(ex.zh,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
