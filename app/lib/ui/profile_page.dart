import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers.dart';

/// 我的页：阶段与晋升、手动切换。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _promote(BuildContext context, WidgetRef ref, Stage next) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('晋升阶段'),
        content: Text('进入「${next.label}」阶段？\n新词表与新的学习配比将生效。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('再想想'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认晋升'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(wordStateStoreProvider).setStage(next);
      ref.invalidate(promotionProvider);
      ref.invalidate(todayViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(currentStageProvider);
    final promoAsync = ref.watch(promotionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          stageAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('加载失败: $e'),
            data: (stage) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前阶段：${stage.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    promoAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text('晋升检查失败: $e'),
                      data: (check) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '毕业比例：${(check.graduatedRatio * 100).toStringAsFixed(0)}% '
                            '（需 ≥ ${(check.requiredRatio * 100).toStringAsFixed(0)}%）',
                          ),
                          if (check.eligible && _next(stage) != null) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  _promote(context, ref, _next(stage)!),
                              icon: const Icon(Icons.celebration),
                              label: Text('晋升到${_next(stage)!.label}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    const Text('手动切换阶段'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in Stage.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: s == stage,
                            onSelected: (_) async {
                              await ref
                                  .read(wordStateStoreProvider)
                                  .setStage(s);
                              ref.invalidate(promotionProvider);
                              ref.invalidate(currentStageProvider);
                              ref.invalidate(todayViewModelProvider);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stage? _next(Stage stage) => stage.index + 1 < Stage.values.length
      ? Stage.values[stage.index + 1]
      : null;
}
