import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 词详情：释义/例句/音频 + 手动调整熟悉度（规则 4）。
class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({super.key, required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = ref.read(audioServiceProvider);
    final tts = ref.read(ttsServiceProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.word, style: theme.textTheme.headlineSmall),
                    Text(
                      entry.phonetic,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => audio.playWord(entry.audioPath),
                icon: const Icon(Icons.volume_up),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${entry.pos} ${entry.meaningZh}',
            style: theme.textTheme.titleMedium,
          ),
          const Divider(height: 24),
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
                      Text(ex.en),
                      Text(
                        ex.zh,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 24),
          Text('调整熟悉度', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _FamiliarityPicker(entry: entry),
        ],
      ),
    );
  }
}

class _FamiliarityPicker extends ConsumerStatefulWidget {
  const _FamiliarityPicker({required this.entry});

  final WordEntry entry;

  @override
  ConsumerState<_FamiliarityPicker> createState() => _FamiliarityPickerState();
}

class _FamiliarityPickerState extends ConsumerState<_FamiliarityPicker> {
  Future<WordState?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WordState?>(
      future: _future,
      builder: (context, snapshot) {
        final current = snapshot.data?.familiarity;
        return Wrap(
          spacing: 8,
          children: [
            for (final level in Familiarity.values)
              ChoiceChip(
                label: Text(level.label),
                selected: current == level,
                onSelected: (_) async {
                  await _applyLevel(level);
                },
              ),
          ],
        );
      },
    );
  }

  Future<WordState?> _loadState() async {
    final states = await ref.read(wordStateStoreProvider).allStates();
    for (final s in states) {
      if (s.word == widget.entry.word) return s;
    }
    return null;
  }

  Future<void> _applyLevel(Familiarity level) async {
    final store = ref.read(wordStateStoreProvider);
    final states = await store.allStates();
    WordState? state;
    for (final s in states) {
      if (s.word == widget.entry.word) state = s;
    }
    // 未学过的词手动调档 = 以当前时间为 learnedOn 建状态
    state ??= WordState.newWord(widget.entry.word, DateTime.now());
    await store.save(applyManualLevel(state, level, DateTime.now()));
    if (!mounted) return;
    setState(() {
      _future = _loadState();
    });
  }
}
