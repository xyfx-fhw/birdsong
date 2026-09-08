import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers.dart';
import '../controllers/session_controller.dart';
import 'session/session_page.dart';

/// 今日页：任务概览 + 开始学习入口。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(todayViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('学个鸟语')),
      body: vmAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (vm) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(todayViewModelProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 连续打卡
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '连续打卡 ${vm.streakDays} 天',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 任务概览
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: '待复习',
                      value: '${vm.reviewCount}',
                      icon: Icons.refresh,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: '新单词',
                      value: '${vm.newWordCount}',
                      icon: Icons.fiber_new,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: '预计',
                      value: '${vm.estimatedMinutes}分钟',
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (vm.weekendMode)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '周末轻量模式：只复习、不学新词',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              if (vm.throttled)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '复习积压较多，今日新词已减量',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              // 开始按钮
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: vm.checkedInToday
                    ? null
                    : () => _startSession(context, ref),
                icon: Icon(
                  vm.checkedInToday ? Icons.check_circle : Icons.play_arrow,
                ),
                label: Text(
                  vm.checkedInToday
                      ? '今日已完成'
                      : (vm.reviewCount == 0 && vm.newWordCount == 0
                            ? '暂无任务'
                            : '开始学习'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _startSession(BuildContext context, WidgetRef ref) async {
    final controller = SessionController(
      store: ref.read(wordStateStoreProvider),
      content: ref.read(contentRepositoryProvider),
    );
    final started = await controller.start();
    if (!started) {
      // start() 的恢复路径可能已直接打卡，刷新今日页状态
      ref.invalidate(todayViewModelProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('今天的学习任务都完成啦')));
      }
      return false;
    }
    if (context.mounted) {
      // 会话（含巩固页）结束返回首页时刷新今日页
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => SessionPage(controller: controller),
            ),
          )
          .then((_) => ref.invalidate(todayViewModelProvider));
    }
    return true;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
