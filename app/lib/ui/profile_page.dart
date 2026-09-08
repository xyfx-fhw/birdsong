import 'package:flutter/material.dart';

/// 我的页（占位；Onboarding/备份/购买属计划 3/4）。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: const Center(child: Text('当前阶段：中级（Onboarding 将在后续版本提供）')),
    );
  }
}
