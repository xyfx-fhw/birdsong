import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 单词音频播放。样例阶段音频文件尚未生成，缺失时静默跳过（不报错）。
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWord(String audioPath) async {
    try {
      await _player.setAsset('assets/audio/$audioPath');
      await _player.play();
    } catch (e) {
      debugPrint('音频不可用，跳过: $audioPath ($e)');
    }
  }

  void dispose() => _player.dispose();
}
