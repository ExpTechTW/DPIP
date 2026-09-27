/// [SystemSpeechService] wraps `flutter_tts`'s `MethodChannel` with a
/// configure-once guard, a hard failure when the platform declines to speak,
/// and (on iOS only) an audio-category request so a safety announcement stays
/// audible under the Silent switch.
///
/// A regression here is invisible in the UI: the call returns, the phrase
/// queue advances, and the user simply never hears the alert. This pins the
/// invoke order (`awaitSpeakCompletion` → `setVolume` → `stop` →
/// `setLanguage` → `speak`), that configuration runs only once across
/// repeated calls, the `StateError` thrown when the platform's `speak` result
/// is not `1`, and that `stop()`/`dispose()` reach the engine directly
/// without requiring a prior `speak()`.
///
/// Coverage gap, stated rather than worked around: `flutter_tts`'s own
/// `setIosAudioCategory` gates its channel call behind `dart:io`'s
/// `Platform.isIOS`, which is false on this macOS/Linux test host no matter
/// what `debugDefaultTargetPlatformOverride` is set to — that override only
/// changes Flutter's `defaultTargetPlatform`, a separate signal `dart:io`
/// never sees. So the test below for the iOS branch can prove
/// [SystemSpeechService._configure]'s own `if (defaultTargetPlatform ==
/// TargetPlatform.iOS)` check is entered and does not throw, and that
/// execution still reaches the following `setVolume` call, but it cannot
/// observe a `setIosAudioCategory` invocation actually reaching the channel.
library;

import 'package:dpip/core/speech/speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Map<String, Object?> responses;

  setUp(() {
    calls = [];
    responses = {'speak': 1};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return responses[call.method];
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'speak configures once, then stops, sets language and speaks in order',
    () async {
      final service = SystemSpeechService(engine: FlutterTts());

      await service.speak('hello', languageTag: 'en-US');

      expect(calls.map((c) => c.method).toList(), [
        'awaitSpeakCompletion',
        'setVolume',
        'stop',
        'setLanguage',
        'speak',
      ]);
      expect(calls[0].arguments, isTrue);
      expect(calls[1].arguments, 1.0);
      expect(calls[3].arguments, 'en-US');
      expect(calls[4].arguments, 'hello');
    },
  );

  test('a second speak call does not repeat configuration', () async {
    final service = SystemSpeechService(engine: FlutterTts());

    await service.speak('one', languageTag: 'en-US');
    await service.speak('two', languageTag: 'fr-FR');

    expect(
      calls.where((c) => c.method == 'awaitSpeakCompletion'),
      hasLength(1),
    );
    expect(calls.where((c) => c.method == 'setVolume'), hasLength(1));
    expect(calls.where((c) => c.method == 'speak'), hasLength(2));
  });

  test('throws StateError when the platform declines to speak', () async {
    responses['speak'] = 0;
    final service = SystemSpeechService(engine: FlutterTts());

    await expectLater(
      () => service.speak('hello', languageTag: 'en-US'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'a null speak result (e.g. no engine installed) also throws StateError',
    () async {
      responses['speak'] = null;
      final service = SystemSpeechService(engine: FlutterTts());

      await expectLater(
        () => service.speak('hello', languageTag: 'en-US'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('stop reaches the engine directly without configuring first', () async {
    // Default-constructed, exercising the `engine ?? FlutterTts()` branch.
    final service = SystemSpeechService();

    await service.stop();

    expect(calls.single.method, 'stop');
  });

  test('dispose stops the engine without awaiting', () async {
    final service = SystemSpeechService(engine: FlutterTts());

    service.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.method, 'stop');
  });

  test('the iOS configure branch runs without throwing and still reaches '
      'setVolume', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = SystemSpeechService(engine: FlutterTts());

    await expectLater(service.speak('hello', languageTag: 'en-US'), completes);

    expect(calls.map((c) => c.method), contains('setVolume'));
  });
}
