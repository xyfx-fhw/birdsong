import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'controllers/providers.dart';
import 'data/content_installer.dart';
import 'data/content_repository.dart';
import 'data/user_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // content.db：从 assets 安装后只读打开
  final contentFile = await ContentInstaller.ensureInstalled();
  final content = ContentRepository.open(contentFile.path);

  // user.db：文档目录，读写
  final docs = await getApplicationDocumentsDirectory();
  final userDb = UserDatabase(
    NativeDatabase.createInBackground(File('${docs.path}/user.db')),
  );

  runApp(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        userDatabaseProvider.overrideWithValue(userDb),
      ],
      child: const BirdsongApp(),
    ),
  );
}
