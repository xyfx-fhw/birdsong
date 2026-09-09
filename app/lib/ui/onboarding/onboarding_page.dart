import 'package:content_models/content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import 'placement_test_page.dart';

/// 首启引导：选阶段 → [可选]词汇量测试 → 确认。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  Stage _selected = Stage.intermediate;
  Stage? _recommended;

  Future<void> _finish() async {
    final store = ref.read(wordStateStoreProvider);
    await store.setStage(_selected);
    await store.setSetting('onboarded', 'true');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text('欢迎使用学个鸟语', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '每天一小步，坚持 3-5 年。\n选择你的起始阶段：',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              RadioGroup<Stage>(
                groupValue: _selected,
                onChanged: (s) => setState(() => _selected = s!),
                child: Column(
                  children: [
                    for (final stage in Stage.values) ...[
                      RadioListTile<Stage>(
                        title: Text(stage.label),
                        subtitle: Text(_stageDesc(stage)),
                        value: stage,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              if (_recommended != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '测试推荐：${_recommended!.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<Stage?>(
                    MaterialPageRoute(
                      builder: (_) => const PlacementTestPage(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _recommended = result;
                      _selected = result;
                    });
                  }
                },
                child: const Text('不确定？做个小测试'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await _finish();
                  ref.invalidate(onboardedProvider);
                },
                child: const Text('开始学习'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageDesc(Stage stage) => switch (stage) {
    Stage.intermediate => '3000 词 · 约高中水平，读写流畅',
    Stage.advanced => '5000 词 · 约研究生水平，职场交流',
    Stage.professional => '7000 词 · 可过雅思/托福，留学海外',
  };
}
