import 'dart:async';

import 'package:dpip/core/platform/live_activity_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<LiveActivityState>> parse(List<Object?> reports) =>
      LiveActivityTokens.statesOf(Stream.fromIterable(reports)).toList();

  test('a token and the switch are passed through', () async {
    expect(
      await parse([
        {'token': 'abcd', 'enabled': true},
        {'token': null, 'enabled': false},
      ]),
      [(token: 'abcd', enabled: true), (token: null, enabled: false)],
    );
  });

  test(
    'a malformed report is skipped, the ones after it still count',
    () async {
      expect(
        await parse([
          'not a map',
          {'token': 'abcd'},
          {'token': 42, 'enabled': true},
          {'token': '', 'enabled': true},
          {'token': 'abcd', 'enabled': 'yes'},
          {'token': 'ef01', 'enabled': true},
        ]),
        [(token: 'ef01', enabled: true)],
      );
    },
  );

  test('an error from the platform is skipped', () async {
    final reports = StreamController<Object?>();
    final states = LiveActivityTokens.statesOf(reports.stream).toList();
    reports
      ..addError(StateError('channel'))
      ..add({'token': 'abcd', 'enabled': true});
    await reports.close();
    expect(await states, [(token: 'abcd', enabled: true)]);
  });
}
