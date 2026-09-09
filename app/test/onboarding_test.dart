import 'package:birdsong_app/data/user_database.dart';
import 'package:birdsong_app/data/word_state_store.dart';
import 'package:content_models/content_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserDatabase db;
  late WordStateStore store;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = WordStateStore(db);
  });

  tearDown(() => db.close());

  test('setting 默认 null，setSetting 后可读', () async {
    expect(await store.setting('onboarded'), isNull);
    await store.setSetting('onboarded', 'true');
    expect(await store.setting('onboarded'), 'true');
  });

  test('checkInCount 统计打卡天数', () async {
    final day = DateTime(2026, 9, 7);
    await store.checkIn(day);
    await store.checkIn(day.add(const Duration(days: 1)));
    expect(await store.checkInCount(), 2);
  });

  test('Onboarding 完成后 onboarded 持久化且阶段写入', () async {
    await store.setSetting('onboarded', 'true');
    await store.setStage(Stage.advanced);
    expect(await store.setting('onboarded'), 'true');
    expect(await store.currentStage(), Stage.advanced);
  });
}
