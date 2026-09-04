/// 学习阶段。词汇量为累计值：中级 3000 / 高级 5000 / 专业级 7000。
enum Stage {
  intermediate('中级', 10),
  advanced('高级', 6),
  professional('专业级', 6);

  const Stage(this.label, this.dailyNewWords);

  final String label;

  /// 每日新词量（spec §1）。
  final int dailyNewWords;

  static Stage fromName(String name) =>
      Stage.values.firstWhere((s) => s.name == name,
          orElse: () => throw FormatException('未知阶段: $name'));
}
