/// The bridge between awesome_notifications' static tap callback and the
/// app's router, which may not exist yet — a tap that launches the app cold
/// arrives before any router has registered [NotificationTaps.onTap].
///
/// Losing a tap in that race is exactly the bug a disaster app cannot afford:
/// the user taps an EEW alert, the app cold-starts, and instead of opening
/// the earthquake it landed on Home because the tap fired before the router
/// was listening. [NotificationTaps.route] stash-or-fire and
/// [NotificationTaps.drainPending]'s replay are what closes that race, so
/// both sides of it are pinned here, along with [onActionReceived]'s job of
/// turning awesome's action into a [NotificationTap] in the first place.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Clean slate: drop any router from a previous test and discard whatever
    // it may have left pending (drainPending clears `_pending` regardless of
    // whether a handler is registered to receive it).
    NotificationTaps.onTap = null;
    NotificationTaps.drainPending();
  });

  tearDown(() {
    NotificationTaps.onTap = null;
  });

  test('routes immediately when a router is already registered', () {
    NotificationTap? routed;
    NotificationTaps.onTap = (tap) => routed = tap;

    const tap = NotificationTap(channelKey: 'eew', data: {'id': '1'});
    NotificationTaps.route(tap);

    expect(routed, same(tap));
  });

  test('stashes the tap when no router is ready yet', () {
    const tap = NotificationTap(channelKey: 'eew', data: {'id': '2'});
    NotificationTaps.route(tap); // onTap is still null

    NotificationTap? routed;
    NotificationTaps.onTap = (t) => routed = t;
    // Registering the router alone must not replay anything by itself.
    expect(routed, isNull);

    NotificationTaps.drainPending();
    expect(routed, same(tap));
  });

  test('a drained tap is not replayed a second time', () {
    const tap = NotificationTap(channelKey: 'eew');
    NotificationTaps.route(tap);

    var calls = 0;
    NotificationTaps.onTap = (_) => calls++;
    NotificationTaps.drainPending();
    NotificationTaps.drainPending();

    expect(calls, 1);
  });

  test('drainPending with nothing pending does not call the router', () {
    var called = false;
    NotificationTaps.onTap = (_) => called = true;

    NotificationTaps.drainPending();

    expect(called, isFalse);
  });

  test('onActionReceived builds a tap from the channel key and payload, '
      'then routes it', () async {
    NotificationTap? routed;
    NotificationTaps.onTap = (tap) => routed = tap;

    final action = ReceivedAction().fromMap({
      'channelKey': 'eew',
      'payload': {'id': '42', 'foo': 'bar'},
    });

    await NotificationTaps.onActionReceived(action);

    expect(routed, isNotNull);
    expect(routed!.channelKey, 'eew');
    expect(routed!.id, '42');
    expect(routed!.data['foo'], 'bar');
  });

  test('onActionReceived stashes when the router is not ready', () async {
    final action = ReceivedAction().fromMap({
      'channelKey': 'rts',
      'payload': {'id': '9'},
    });

    await NotificationTaps.onActionReceived(action);

    NotificationTap? routed;
    NotificationTaps.onTap = (tap) => routed = tap;
    NotificationTaps.drainPending();

    expect(routed?.channelKey, 'rts');
    expect(routed?.id, '9');
  });
}
