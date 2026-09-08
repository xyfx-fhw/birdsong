import 'package:flutter/material.dart';

import 'ui/home_page.dart';
import 'ui/profile_page.dart';
import 'ui/wordbook/wordbook_page.dart';

/// 学个鸟语 App 根组件。
class BirdsongApp extends StatelessWidget {
  const BirdsongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学个鸟语',
      debugShowCheckedModeBanner: false,
      // v1 深色模式：跟随系统
      theme: appThemeLight,
      darkTheme: appThemeDark,
      themeMode: ThemeMode.system,
      home: const ShellPage(),
    );
  }
}

final appThemeLight = _buildTheme(Brightness.light);
final appThemeDark = _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: brightness,
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

/// 底部 3 Tab 骨架：今日 / 词书 / 我的。
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  static const _pages = [HomePage(), WordbookPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: '今日'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: '词书'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
