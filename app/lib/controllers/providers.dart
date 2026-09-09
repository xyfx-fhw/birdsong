import 'package:content_models/content_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../data/content_repository.dart';
import '../data/user_database.dart';
import '../data/word_state_store.dart';
import '../services/audio_service.dart';
import '../services/reminder_service.dart';
import '../services/tts_service.dart';

/// 以下两个 provider 在 main() 中 override（初始化是异步的）。
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => throw UnimplementedError('在 main 中 override'),
);

final userDatabaseProvider = Provider<UserDatabase>(
  (ref) => throw UnimplementedError('在 main 中 override'),
);

final wordStateStoreProvider = Provider<WordStateStore>(
  (ref) => WordStateStore(ref.watch(userDatabaseProvider)),
);

/// 是否完成 Onboarding。
final onboardedProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  return (await store.setting('onboarded')) == 'true';
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);

/// 今日页视图模型。
class TodayViewModel {
  TodayViewModel({
    required this.reviewCount,
    required this.newWordCount,
    required this.streakDays,
    required this.checkedInToday,
    required this.weekendMode,
    required this.throttled,
  });

  final int reviewCount;
  final int newWordCount;
  final int streakDays;
  final bool checkedInToday;
  final bool weekendMode;
  final bool throttled;

  /// 预计时长（分钟）：复习 15 秒/词 + 新词 60 秒/词 + 巩固 5 分钟。
  int get estimatedMinutes =>
      (reviewCount * 15 + newWordCount * 60) ~/ 60 + (newWordCount > 0 ? 5 : 2);
}

final todayViewModelProvider = FutureProvider<TodayViewModel>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final now = DateTime.now();
  final stage = await store.currentStage();
  final states = await store.allStates();
  final learned = states.map((s) => s.word).toSet();
  final pending = content.pendingNewWords(stage, learned);
  final plan = planSession(
    stage: stage,
    allStates: states,
    pendingNewWords: pending,
    now: now,
  );
  return TodayViewModel(
    reviewCount: plan.reviews.length,
    newWordCount: plan.newWords.length,
    streakDays: await store.streak(now),
    checkedInToday: await store.hasCheckIn(now),
    weekendMode: plan.isWeekendMode,
    throttled: plan.newWordsThrottled,
  );
});

/// 成就视图模型。
class AchievementsView {
  AchievementsView({required this.stats, required this.unlockedIds});

  final LearningStats stats;
  final Set<String> unlockedIds;
}

final achievementsProvider = FutureProvider<AchievementsView>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final now = DateTime.now();
  final stage = await store.currentStage();
  final states = await store.allStates();
  final stageWords = content.wordsOfStage(stage).map((w) => w.word).toSet();
  final stageStates = states.where((s) => stageWords.contains(s.word)).toList();

  final stats = LearningStats(
    totalCheckInDays: await store.checkInCount(),
    consecutiveDays: await store.streak(now),
    totalWordsLearned: states.length,
    graduatedWords: states.where((s) => s.graduated).length,
    stageWordCount: stageWords.length,
    stageGraduatedCount: stageStates.where((s) => s.graduated).length,
  );
  final unlocked = unlockedAchievements(stats, defaultAchievements);
  return AchievementsView(
    stats: stats,
    unlockedIds: unlocked.map((a) => a.id).toSet(),
  );
});

/// 当前阶段晋升检查。
final promotionProvider = FutureProvider<PromotionCheck>((ref) async {
  final store = ref.watch(wordStateStoreProvider);
  final content = ref.watch(contentRepositoryProvider);
  final stage = await store.currentStage();
  final states = await store.allStates();
  final stageWords = content.wordsOfStage(stage).map((w) => w.word).toSet();
  final stageStates = states.where((s) => stageWords.contains(s.word)).toList();
  return checkPromotion(
    stageStates: stageStates,
    stageWordCount: stageWords.length,
  );
});

/// 当前阶段。
final currentStageProvider = FutureProvider<Stage>(
  (ref) => ref.watch(wordStateStoreProvider).currentStage(),
);
