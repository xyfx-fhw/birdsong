import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:srs_core/srs_core.dart';

import '../data/content_repository.dart';
import '../data/user_database.dart';
import '../data/word_state_store.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import 'session_controller.dart';

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

final sessionControllerProvider = Provider<SessionController>((ref) {
  throw UnimplementedError('会话开始时由 SessionPage override');
});

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
