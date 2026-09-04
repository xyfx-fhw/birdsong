import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('用仓库样例内容端到端构建 content.db', () {
    // dart test 的工作目录是包根（tools/content_pipeline），仓库根在 ../..
    const repoRoot = '../..';
    final out = '${Directory.systemTemp.path}/e2e_content.db';
    final result = Process.runSync(
      'dart',
      [
        'run',
        'bin/build_content.dart',
        '--src',
        '$repoRoot/content_src',
        '--out',
        out,
        '--version',
        '1'
      ],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final db = sqlite3.open(out);
    addTearDown(() {
      db.dispose();
      File(out).deleteSync();
    });
    expect(db.select('SELECT COUNT(*) AS n FROM words').single['n'], 20);
    expect(db.select('SELECT COUNT(*) AS n FROM units').single['n'], 2);
  });
}
