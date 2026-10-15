/// Each event out of [NetworkChanges] tears down and rebuilds every realtime
/// connection, so what counts as a change is the whole contract: the network
/// the app starts on is not one, a repeat of the same network is not one
/// (iOS re-reports a path whenever any property of it moves), and a failed
/// report must not end the watch.
library;

import 'dart:async';

import 'package:dpip/core/platform/network_changes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first report is a baseline, not a change', () async {
    final changes = await NetworkChanges.changesOf(
      Stream.fromIterable(['wifi:100']),
    ).toList();
    expect(changes, isEmpty);
  });

  test('only a different network is a change', () async {
    final changes = await NetworkChanges.changesOf(
      Stream.fromIterable([
        'wifi:100',
        'wifi:100', // the same path, re-reported
        'cellular:200', // Wi-Fi gone, on cellular
        'none', // offline
        'none',
        'cellular:201', // back on a new cellular network
        'wifi:300', // a different Wi-Fi
      ]),
    ).toList();
    expect(changes, ['cellular:200', 'none', 'cellular:201', 'wifi:300']);
  });

  test('a failed report is skipped, not the end of the stream', () async {
    final reports = StreamController<Object?>();
    final done = NetworkChanges.changesOf(reports.stream).toList();
    reports
      ..add('wifi:1')
      ..addError(PlatformException(code: 'UNAVAILABLE'))
      ..add('cellular:2');
    await reports.close();
    expect(await done, ['cellular:2']);
  });

  test('cancelling reaches the platform at once', () async {
    // The reports may never come again; the listener must still be able to
    // let go of the platform callback.
    final reports = StreamController<Object?>();
    final subscription = NetworkChanges.changesOf(reports.stream).listen(null);
    reports.add('wifi:1');
    await pumpEventQueue();
    expect(reports.hasListener, isTrue);
    await subscription.cancel();
    expect(reports.hasListener, isFalse);
  });

  test('the channel reports reach the stream', () async {
    const channel = EventChannel('com.exptech.dpip/network');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final events = StreamController<Object?>();
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, sink) => events.stream.listen(sink.success),
      ),
    );
    addTearDown(() => messenger.setMockStreamHandler(channel, null));

    final seen = <String>[];
    final subscription = NetworkChanges.stream.listen(seen.add);
    events
      ..add('wifi:1')
      ..add('cellular:2');
    await pumpEventQueue();
    expect(seen, ['cellular:2']);
    await subscription.cancel();
    await events.close();
  });
}
