import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/session_controller.dart';
import 'consolidation_view.dart';
import 'word_card.dart';

/// 学习会话：复习 → 新词 → 串词巩固 → 完成。
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key, required this.controller});

  final SessionController controller;

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  bool _revealed = false;
  bool _busy = false;

  SessionController get c => widget.controller;

  bool get _isReview => c.phase == SessionPhase.review;

  Future<void> _answer(bool correct) async {
    if (_busy) return;
    if (c.phase != SessionPhase.review && c.phase != SessionPhase.newWords) {
      return;
    }
    setState(() => _busy = true);
    await c.answer(correct: correct);
    if (!mounted) return;
    setState(() {
      _revealed = false;
      _busy = false;
    });
    _syncPhase();
  }

  void _syncPhase() {
    if (c.phase == SessionPhase.consolidation) {
      // 用 push（而非 pushReplacement）保留会话页在栈中：
      // pushReplacement 会让首页 push 的 Future 在进入巩固页时就完成，
      // 导致打卡前的旧数据被刷新。改为巩固页关闭后会话页再自行 pop，
      // 保证首页的刷新发生在整条会话链真正结束之后。
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (_) => ConsolidationView(controller: c)),
          )
          .then((_) {
            if (mounted) Navigator.of(context).pop();
          });
    } else if (c.phase == SessionPhase.done) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReview ? '复习' : '学新词'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _isReview ? '剩余 ${c.reviewsDue}' : '已学 ${c.newWordsLearned}',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WordCard(
                state: c.current,
                revealed: _revealed || !_isReview,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _revealed || !_isReview
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _busy ? null : () => _answer(false),
                            icon: const Icon(Icons.close),
                            label: const Text('不认识'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _busy ? null : () => _answer(true),
                            icon: const Icon(Icons.check),
                            label: const Text('认识'),
                          ),
                        ),
                      ],
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 48,
                        ),
                      ),
                      onPressed: () => setState(() => _revealed = true),
                      child: const Text('想一想，然后点开'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
