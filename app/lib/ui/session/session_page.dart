import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';

/// 学习会话页（Task 6 实现完整内容）。
class SessionPage extends StatelessWidget {
  const SessionPage({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习中')),
      body: Center(child: Text('当前卡片: ${controller.current.word}')),
    );
  }
}
