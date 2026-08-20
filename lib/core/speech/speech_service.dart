/// System text-to-speech abstraction used by foreground safety announcements.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks short phrases through the platform speech engine.
abstract interface class SpeechService {
  /// Stops any current phrase and speaks [text] to completion.
  Future<void> speak(String text, {required String languageTag});

  /// Stops the current phrase, if any.
  Future<void> stop();

  /// Releases transient speech state owned by this service.
  void dispose();
}

/// Android `TextToSpeech` / iOS `AVSpeechSynthesizer` implementation.
class SystemSpeechService implements SpeechService {
  SystemSpeechService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _engine.awaitSpeakCompletion(true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // The plugin's default iOS category follows the Silent switch. A
      // foreground disaster announcement must remain audible there as well;
      // voicePrompt + duckOthers keeps it intelligible without permanently
      // taking ownership of another app's audio session.
      await _engine.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ], IosTextToSpeechAudioMode.voicePrompt);
    }
    // Maximise the utterance within the user's selected media-volume level.
    // Changing the device's stream volume would be intrusive and would persist
    // after the warning, so that remains under the user's control.
    await _engine.setVolume(1.0);
    _configured = true;
  }

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    await _configure();
    await _engine.stop();
    await _engine.setLanguage(languageTag);
    final result = await _engine.speak(text);
    if (result != 1) throw StateError('System TTS rejected speech');
  }

  @override
  Future<void> stop() async {
    await _engine.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
  }
}
