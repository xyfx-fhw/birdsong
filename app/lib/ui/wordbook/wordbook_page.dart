import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';
import 'word_detail_sheet.dart';

/// 词书状态视图模型。
class WordbookItem {
  WordbookItem({required this.entry, required this.state});

  final WordEntry entry;
  final WordState? state;

  Familiarity? get familiarity => state?.familiarity;
}

final wordbookProvider = FutureProvider<List<WordbookItem>>((ref) async {
  final content = ref.watch(contentRepositoryProvider);
  final store = ref.watch(wordStateStoreProvider);
  final stage = await store.currentStage();
  final states = {for (final s in await store.allStates()) s.word: s};
  return [
    for (final entry in content.wordsOfStage(stage))
      WordbookItem(entry: entry, state: states[entry.word]),
  ];
});

/// 词书页：当前阶段词条 + 熟悉度筛选。
class WordbookPage extends ConsumerStatefulWidget {
  const WordbookPage({super.key});

  @override
  ConsumerState<WordbookPage> createState() => _WordbookPageState();
}

class _WordbookPageState extends ConsumerState<WordbookPage> {
  Familiarity? _filter;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wordbookProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('词书')),
      body: Column(
        children: [
          // 筛选条
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('全部'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final level in Familiarity.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(level.label),
                      selected: _filter == level,
                      onSelected: (_) => setState(() => _filter = level),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (items) {
                final filtered = _filter == null
                    ? items
                    : items.where((i) => i.familiarity == _filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('这个档位暂时没有单词'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(item.entry.word),
                      subtitle: Text(
                        '${item.entry.pos} ${item.entry.meaningZh}',
                      ),
                      trailing: item.familiarity == null
                          ? null
                          : Chip(
                              label: Text(item.familiarity!.label),
                              visualDensity: VisualDensity.compact,
                            ),
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => WordDetailSheet(entry: item.entry),
                        );
                        // 手动调档后刷新列表
                        ref.invalidate(wordbookProvider);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
