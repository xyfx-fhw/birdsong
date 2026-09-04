import 'dart:io';

import 'package:args/args.dart';
import 'package:content_pipeline/content_pipeline.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('src', mandatory: true, help: 'content_src 目录')
    ..addOption('out', mandatory: true, help: 'content.db 输出路径')
    ..addOption('version', defaultsTo: '1', help: 'content_version')
    ..addFlag('strict', defaultsTo: false, help: '严格校验正式词数');
  final opts = parser.parse(args);

  final src = opts['src'] as String;
  final out = opts['out'] as String;
  final version = int.parse(opts['version'] as String);

  stdout.writeln('校验内容: $src');
  final result = validateContent(
    contentSrcDir: src,
    strict: opts['strict'] as bool,
  );
  for (final issue in result.issues) {
    stdout.writeln('  $issue');
  }
  if (!result.ok) {
    stderr.writeln('校验失败，共 ${result.issues.length} 个问题，中止构建。');
    exit(1);
  }

  buildContentDb(content: result, outputPath: out, contentVersion: version);
  stdout.writeln(
    '构建完成: ${result.wordEntries.length} 词条, ${result.units.length} 单元 → $out',
  );
}
