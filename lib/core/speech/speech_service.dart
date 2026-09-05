/// System text-to-speech abstraction used by foreground safety announcements.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// Speaks short phrases through the platform speech engine.
abstract interface class SpeechService {
  /// Stops any current phrase and speaks [text] to completion.
  Future<void> speak(String text, {required String languageTag});

  /// Stops the current phrase, if any.
  Future<void> stop();

  /// Releases transient speech state owned by this service.
  void dispose();
}

/// Android `TextToSpeech` / iOS `AVSpeechSynthesizer`, over an app-owned
/// platform channel.
///
/// A channel rather than a package, like the rest of the native surface: the
/// only TTS package on pub with the API this needs (`flutter_tts`) ships no
/// Swift Package Manager support, and this project builds iOS without
/// CocoaPods (README → 參與開發). Adopting it would have pulled a Podfile back
/// in through a transitive dependency, for two calls whose native side is
/// thirty lines each.
class SystemSpeechService implements SpeechService {
  SystemSpeechService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// The channel `SpeechChannel.kt` and `SpeechPlugin.swift` answer on.
  static const String channelName = 'com.exptech.dpip/speech';

  final MethodChannel _channel;

  /// Speaks [text], completing when the utterance finishes.
  ///
  /// A phrase superseded by a later [speak] — or cut short by [stop] — also
  /// completes normally rather than throwing: latest-report-wins is the
  /// expected path here, not a failure. Only an engine that is absent or
  /// refuses the utterance raises.
  @override
  Future<void> speak(String text, {required String languageTag}) => _channel
      .invokeMethod<void>('speak', {'text': text, 'language': languageTag});

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  void dispose() {
    unawaited(stop());
  }
}
