import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../../controllers/providers.dart';

/// 成就页：学习统计 + 徽章列表。
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(achievementsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: viewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (view) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 统计卡
            Row(
              children: [
                _Stat('累计打卡', '${view.stats.totalCheckInDays}天'),
                _Stat('连续打卡', '${view.stats.consecutiveDays}天'),
                _Stat('已学词', '${view.stats.totalWordsLearned}'),
                _Stat('毕业词', '${view.stats.graduatedWords}'),
              ],
            ),
            const SizedBox(height: 16),
            Text('徽章', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final a in defaultAchievements)
              ListTile(
                leading: Icon(
                  view.unlockedIds.contains(a.id)
                      ? Icons.emoji_events
                      : Icons.lock_outline,
                  color: view.unlockedIds.contains(a.id)
                      ? Colors.amber
                      : theme.colorScheme.outline,
                ),
                title: Text(a.name),
                subtitle: Text(view.unlockedIds.contains(a.id) ? '已解锁' : '未解锁'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
