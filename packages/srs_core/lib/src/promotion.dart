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
PromotionCheck checkPromotion({
  required List<WordState> stageStates,
  double requiredRatio = 0.8,
}) {
  if (stageStates.isEmpty) {
    return PromotionCheck(
        eligible: false, graduatedRatio: 0, requiredRatio: requiredRatio);
  }
  final graduated = stageStates.where((s) => s.graduated).length;
  final ratio = graduated / stageStates.length;
  return PromotionCheck(
    eligible: ratio >= requiredRatio,
    graduatedRatio: ratio,
    requiredRatio: requiredRatio,
  );
}
