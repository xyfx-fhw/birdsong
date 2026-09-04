import 'dart:convert';
import 'dart:io';

import 'package:content_models/content_models.dart';
import 'package:path/path.dart' as p;

/// 校验问题。
class ValidationIssue {
  ValidationIssue({required this.level, required this.message});

  /// 'error' 阻断构建；'warning' 仅提示。
  final String level;
  final String message;

  @override
  String toString() => '[$level] $message';
}

/// 校验结果。
class ValidationResult {
  ValidationResult(
      {required this.issues, required this.wordEntries, required this.units});

  final List<ValidationIssue> issues;
  final List<WordEntry> wordEntries;
  final List<DailyUnit> units;

  bool get ok => !issues.any((i) => i.level == 'error');
}

/// 各阶段正式词数（--strict 模式校验）。
const strictStageWordCounts = <Stage, int>{
  Stage.intermediate: 3000,
  Stage.advanced: 2000,
  Stage.professional: 2000,
};

/// 校验 content_src 目录（spec §5.3 校验项）。
ValidationResult validateContent({
  required String contentSrcDir,
  bool strict = false,
}) {
  final issues = <ValidationIssue>[];
  final wordEntries = <WordEntry>[];
  final units = <DailyUnit>[];

  // 1. 词表
  final wordlistDir = Directory(p.join(contentSrcDir, 'wordlists'));
  if (!wordlistDir.existsSync()) {
    issues.add(ValidationIssue(level: 'error', message: '缺少 wordlists 目录'));
    return ValidationResult(issues: issues, wordEntries: [], units: []);
  }
  for (final file in wordlistDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final name = p.basename(file.path);
    try {
      final raw = jsonDecode(file.readAsStringSync()) as List;
      for (final item in raw) {
        wordEntries.add(WordEntry.fromJson(item as Map<String, dynamic>));
      }
    } on FormatException catch (e) {
      issues.add(ValidationIssue(level: 'error', message: '$name: ${e.message}'));
    }
  }

  // 2. 词条唯一性
  final seen = <String>{};
  for (final w in wordEntries) {
    if (!seen.add(w.word)) {
      issues.add(ValidationIssue(level: 'error', message: '词条重复: ${w.word}'));
    }
  }

  // 3. 严格词数
  if (strict) {
    for (final entry in strictStageWordCounts.entries) {
      final count = wordEntries.where((w) => w.stage == entry.key).length;
      if (count != entry.value) {
        issues.add(ValidationIssue(
            level: 'error',
            message: '${entry.key.name} 词数 $count != 期望 ${entry.value}'));
      }
    }
  } else if (wordEntries.isEmpty) {
    issues.add(ValidationIssue(level: 'error', message: '词表为空'));
  }

  // 4. 每日单元
  final dailyDir = Directory(p.join(contentSrcDir, 'daily'));
  if (dailyDir.existsSync()) {
    final unitNumbersByStage = <Stage, Set<int>>{};
    for (final file in dailyDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final name = p.relative(file.path, from: contentSrcDir);
      try {
        final unit = DailyUnit.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        final numbers = unitNumbersByStage.putIfAbsent(unit.stage, () => {});
        if (!numbers.add(unit.unitNumber)) {
          issues.add(ValidationIssue(
              level: 'error',
              message: '$name: ${unit.stage.name} 单元 ${unit.unitNumber} 编号重复'));
        }
        for (final w in unit.newWords) {
          if (!seen.contains(w)) {
            issues.add(ValidationIssue(
                level: 'error', message: '$name: 单元引用了词表中不存在的词: $w'));
          }
        }
        units.add(unit);
      } on FormatException catch (e) {
        issues.add(ValidationIssue(level: 'error', message: '$name: ${e.message}'));
      }
    }
  }

  return ValidationResult(issues: issues, wordEntries: wordEntries, units: units);
}
