import 'package:flutter_tts/flutter_tts.dart';

/// 句子/对话/短文朗读（系统 TTS，离线可用，spec §2 决策）。
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _ensureReady();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
