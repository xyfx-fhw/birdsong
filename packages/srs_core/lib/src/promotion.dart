import 'word_state.dart';

/// 晋升检查结果（spec §6.4）。
class PromotionCheck {
  PromotionCheck({
    required this.eligible,
    required this.graduatedRatio,
    required this.requiredRatio,
  });

  final bool eligible;
  final double graduatedRatio;
  final double requiredRatio;
}

/// 晋升条件：当前阶段词表全部学过 + 毕业词比例 >= requiredRatio。
///
/// [stageStates] 为该阶段已学过的词的状态；[stageWordCount] 为该阶段词表
/// 总词数。只有全部学过（[stageStates] 数量 >= [stageWordCount]）且毕业词
/// 占词表总数的比例达标时才允许晋升。
PromotionCheck checkPromotion({
  required List<WordState> stageStates,
  required int stageWordCount,
  double requiredRatio = 0.8,
}) {
  if (stageWordCount <= 0 || stageStates.length < stageWordCount) {
    final ratio = stageWordCount <= 0
        ? 0.0
        : stageStates.where((s) => s.graduated).length / stageWordCount;
    return PromotionCheck(
        eligible: false, graduatedRatio: ratio, requiredRatio: requiredRatio);
  }
  final graduated = stageStates.where((s) => s.graduated).length;
  final ratio = graduated / stageWordCount;
  return PromotionCheck(
    eligible: ratio >= requiredRatio,
    graduatedRatio: ratio,
    requiredRatio: requiredRatio,
  );
}
