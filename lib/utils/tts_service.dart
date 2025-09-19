// lib/utils/tts_service.dart

import 'dart:ui';

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("ml-IN");
    await _flutterTts.setVoice({"name": "ml-in-x-mle-local", "locale": "ml-IN"});
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    print("TTS Service Initialized for ANDROID with Malayalam voice.");
    _isInitialized = true;
  }

  // --- THIS IS THE NEWLY ADDED METHOD ---
  // It allows any screen to listen for when speech is complete.
  void setCompletionHandler(VoidCallback handler) {
    _flutterTts.setCompletionHandler(handler);
  }
  // ------------------------------------

  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
  }
}
