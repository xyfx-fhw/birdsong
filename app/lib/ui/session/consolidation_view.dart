import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';

/// 串词巩固页（Task 7 实现完整内容）。
class ConsolidationView extends StatelessWidget {
  const ConsolidationView({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('串词巩固')),
      body: const Center(child: Text('巩固内容')),
    );
  }
}
