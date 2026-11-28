/// The lane every request to the notify backend's per-IP-limited routes goes
/// through: one at a time, spaced to the server's one-a-second limit, no wait
/// when nothing came before, and device requests ahead of deferred ones.
library;

import 'dart:async';

import 'package:dpip/core/network/notify_request_lane.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs requests through a lane on the fake clock and records when each one
/// started and ended.
class _Bench {
  _Bench(this.async) : lane = NotifyRequestLane(elapsed: () => async.elapsed);

  final FakeAsync async;
  final NotifyRequestLane lane;
  final starts = <String, Duration>{};
  final ends = <String, Duration>{};
  final order = <String>[];

  Future<String> send(
    String name, {
    Duration takes = const Duration(milliseconds: 200),
    Object? error,
    NotifyRequestPriority priority = NotifyRequestPriority.device,
  }) => lane.run(() async {
    starts[name] = async.elapsed;
    order.add(name);
    await Future<void>.delayed(takes);
    ends[name] = async.elapsed;
    if (error != null) throw error;
    return name;
  }, priority: priority);
}

void main() {
  test('the spacing is the server limit plus margin', () {
    expect(NotifyRequestLane.minSpacing, const Duration(milliseconds: 1100));
    expect(NotifyRequestLane().spacing, NotifyRequestLane.minSpacing);
  });

  test('an idle lane starts a request at once', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      bench.send('location');
      async.flushMicrotasks();
      expect(bench.starts['location'], Duration.zero);
    });
  });

  test('two requests queued together start at least 1.1 s apart and never '
      'overlap', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      final results = <String>[];
      bench.send('location').then(results.add);
      bench.send('settings').then(results.add);
      async.elapse(const Duration(seconds: 5));

      expect(bench.order, ['location', 'settings']);
      expect(results, ['location', 'settings']);
      // Not overlapping: the second starts after the first has ended …
      expect(bench.starts['settings']! >= bench.ends['location']!, isTrue);
      // … and a full spacing after it, so after its start as well.
      expect(
        bench.starts['settings']! - bench.ends['location']!,
        greaterThanOrEqualTo(NotifyRequestLane.minSpacing),
      );
      expect(
        bench.starts['settings']! - bench.starts['location']!,
        greaterThanOrEqualTo(NotifyRequestLane.minSpacing),
      );
    });
  });

  test('a slow request pushes the next one back by its whole length', () {
    // The server counts arrivals: timed from the first one's end, it has
    // certainly arrived before the second leaves.
    fakeAsync((async) {
      final bench = _Bench(async);
      bench.send('slow', takes: const Duration(seconds: 3));
      bench.send('next');
      async.elapse(const Duration(seconds: 10));
      expect(bench.starts['next'], const Duration(milliseconds: 4100));
    });
  });

  test('a request long after the last one starts at once', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      bench.send('first');
      async.elapse(const Duration(seconds: 5));
      bench.send('second');
      async.flushMicrotasks();
      expect(bench.starts['second'], const Duration(seconds: 5));
    });
  });

  test('a request soon after the last one waits out the rest', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      bench.send('first');
      async.elapse(const Duration(milliseconds: 700));
      bench.send('second');
      async.elapse(const Duration(seconds: 5));
      // 200 ms request + 1100 ms spacing.
      expect(bench.starts['second'], const Duration(milliseconds: 1300));
    });
  });

  test('a failure goes to its caller and the lane carries on', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      Object? caught;
      bench.send('failing', error: StateError('429')).catchError((Object e) {
        caught = e;
        return '';
      });
      String? next;
      bench.send('next').then((value) => next = value);
      async.elapse(const Duration(seconds: 5));
      expect(caught, isA<StateError>());
      expect(next, 'next');
      expect(
        bench.starts['next']! - bench.ends['failing']!,
        greaterThanOrEqualTo(NotifyRequestLane.minSpacing),
      );
    });
  });

  test('ten queued at once stay one at a time, each spaced', () {
    fakeAsync((async) {
      final bench = _Bench(async);
      for (var i = 0; i < 10; i++) {
        bench.send('r$i');
      }
      async.elapse(const Duration(minutes: 1));
      expect(bench.order, [for (var i = 0; i < 10; i++) 'r$i']);
      for (var i = 1; i < 10; i++) {
        expect(
          bench.starts['r$i']! - bench.ends['r${i - 1}']!,
          greaterThanOrEqualTo(NotifyRequestLane.minSpacing),
        );
      }
    });
  });

  group('priority', () {
    const deferred = NotifyRequestPriority.deferred;

    test('queued together, the location report goes first', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        // The deferred one even arrives first; the lane is busy, so both wait.
        bench.send('settings');
        bench.send('live activity', priority: deferred);
        bench.send('location');
        async.elapse(const Duration(seconds: 10));
        expect(bench.order, ['settings', 'location', 'live activity']);
        expect(
          bench.starts['live activity']! - bench.ends['location']!,
          greaterThanOrEqualTo(NotifyRequestLane.minSpacing),
        );
      });
    });

    test('a device request that arrives during the spacing still goes '
        'first', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        bench.send('settings');
        bench.send('live activity', priority: deferred);
        // The settings request has ended; the Live Activity is waiting out
        // the spacing when the location report arrives.
        async.elapse(const Duration(milliseconds: 600));
        bench.send('location');
        async.elapse(const Duration(seconds: 10));
        expect(bench.order, ['settings', 'location', 'live activity']);
      });
    });

    test('an idle lane starts a deferred request at once too', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        bench.send('live activity', priority: deferred);
        async.flushMicrotasks();
        expect(bench.starts['live activity'], Duration.zero);
      });
    });

    test('a hold keeps deferred requests back, never device ones', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        final fix = Completer<void>();
        bench.lane.holdDeferred(() async {
          await fix.future;
          await bench.send('location');
        });
        bench.send('live activity', priority: deferred);
        bench.send('settings');
        async.elapse(const Duration(seconds: 5));
        // Idle lane, open hold: the device request went, the deferred waits.
        expect(bench.order, ['settings']);

        fix.complete();
        async.elapse(const Duration(seconds: 5));
        expect(bench.order, ['settings', 'location', 'live activity']);
      });
    });

    test('a hold ends when its work fails', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        Object? caught;
        bench.lane
            .holdDeferred<void>(() async => throw StateError('no fix'))
            .catchError((Object e) => caught = e);
        bench.send('live activity', priority: deferred);
        async.elapse(const Duration(seconds: 1));
        expect(caught, isA<StateError>());
        expect(bench.order, ['live activity']);
      });
    });

    test('overlapping holds release on the last one', () {
      fakeAsync((async) {
        final bench = _Bench(async);
        final first = Completer<void>();
        final second = Completer<void>();
        bench.lane.holdDeferred(() => first.future);
        bench.lane.holdDeferred(() => second.future);
        bench.send('live activity', priority: deferred);
        first.complete();
        async.elapse(const Duration(seconds: 5));
        expect(bench.order, isEmpty);
        second.complete();
        async.elapse(const Duration(seconds: 1));
        expect(bench.order, ['live activity']);
      });
    });
  });
}
