import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// 把打包在 assets 里的 content.db 安装到应用文档目录。
/// 已存在则跳过（内容更新随 app 版本发布，见 spec §3）。
class ContentInstaller {
  static Future<File> ensureInstalled() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/content.db');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/content.db');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file;
  }
}
