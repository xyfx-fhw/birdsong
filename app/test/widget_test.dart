import 'package:birdsong_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app 启动并显示 3 个 Tab', (tester) async {
    await tester.pumpWidget(const BirdsongApp());
    expect(find.text('今日'), findsWidgets);
    expect(find.text('词书'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
