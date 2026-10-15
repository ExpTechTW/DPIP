/// [NotifyPresetApplier] is nine writes against an endpoint that answers a
/// burst with 429. What it must never do: fire two requests without the gap
/// between them, write past a failure as if it had not happened, or keep
/// writing for a caller that has gone away. Timing is checked under
/// [fakeAsync], so the real two-second spacing is what is pinned.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_preset_applier.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every channel at its local threshold — a fresh device.
NotifySettings _fresh() =>
    NotifySettings.fromWire(const [1, 1, 1, 1, 1, 1, 1, 1, 1]);

/// Echoes writes into an in-memory settings value, records when each request
/// arrived (in fake time), and fails the request numbered [failAt].
class _Repo implements NotifyRepository {
  _Repo(this.settings, this._elapsed);

  NotifySettings settings;
  final Duration Function() _elapsed;
  final List<(String call, Duration at)> calls = [];
  int? failAt;

  Result<NotifySettings> _answer(String call) {
    calls.add((call, _elapsed()));
    if (failAt == calls.length) {
      return const Err(NetworkFailure('Server error (429)'));
    }
    return Ok(settings);
  }

  @override
  Future<Result<NotifySettings>> fetch(String token) async => _answer('fetch');

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async {
    final result = _answer(channel.name);
    if (result.isOk) settings = settings.withChannel(channel, optionIndex);
    return result.isOk ? Ok(settings) : result;
  }
}

void main() {
  test('fetches first, then writes only what differs, 2 s apart', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed);
      Result<NotifySettings>? result;

      NotifyPresetApplier(repo)
          .apply('tok', NotifyPreset.recommended)
          .then((r) => result = r);
      async.flushTimers();

      expect(repo.calls.map((c) => c.$1), ['fetch', 'report']);
      expect(repo.calls.map((c) => c.$2), [
        Duration.zero,
        const Duration(seconds: 2),
      ]);
      expect(result?.valueOrNull?.optionOf(NotifyChannel.report), 0);
      expect(
        NotifyPreset.matching(result!.valueOrNull!),
        NotifyPreset.recommended,
      );
    });
  });

  test('with known settings it skips the fetch', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed);
      NotifyPresetApplier(repo)
          .apply('tok', NotifyPreset.emergencyOnly, current: _fresh());
      async.flushTimers();

      final names = repo.calls.map((c) => c.$1).toList();
      expect(names.first, 'eew');
      expect(names, isNot(contains('fetch')));
      // Six channels differ; each request waits for the one before it.
      expect(repo.calls, hasLength(6));
      for (var i = 1; i < repo.calls.length; i++) {
        expect(
          repo.calls[i].$2 - repo.calls[i - 1].$2,
          NotifyPresetApplier.requestSpacing,
        );
      }
    });
  });

  test(
    'a failure stops the sequence, reports it, and keeps what was written',
    () {
      fakeAsync((async) {
        final repo = _Repo(_fresh(), () => async.elapsed)..failAt = 3;
        final progress = <NotifySettings>[];
        Result<NotifySettings>? result;

        NotifyPresetApplier(repo)
            .apply(
              'tok',
              NotifyPreset.emergencyOnly,
              current: _fresh(),
              onProgress: progress.add,
            )
            .then((r) => result = r);
        async.flushTimers();

        expect(result?.failureOrNull, isA<NetworkFailure>());
        expect(repo.calls, hasLength(3), reason: 'nothing after the failure');
        expect(
          progress,
          hasLength(2),
          reason: 'one snapshot per accepted write',
        );
        expect(progress.last.optionOf(NotifyChannel.eew), 0);
        expect(progress.last.optionOf(NotifyChannel.monitor), 0);
        expect(progress.last.optionOf(NotifyChannel.report), 1);
      });
    },
  );

  test('running it again resumes with only the channels still differing', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed)..failAt = 3;
      final applier = NotifyPresetApplier(repo);
      applier.apply('tok', NotifyPreset.emergencyOnly, current: _fresh());
      async.flushTimers();

      repo
        ..calls.clear()
        ..failAt = null;
      Result<NotifySettings>? result;
      applier.apply('tok', NotifyPreset.emergencyOnly).then((r) => result = r);
      async.flushTimers();

      expect(repo.calls.map((c) => c.$1), [
        'fetch',
        'report',
        'intensity',
        'tsunami',
        'announcement',
      ]);
      expect(
        NotifyPreset.matching(result!.valueOrNull!),
        NotifyPreset.emergencyOnly,
      );
    });
  });

  test('a failed fetch writes nothing', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed)..failAt = 1;
      Result<NotifySettings>? result;
      NotifyPresetApplier(repo)
          .apply('tok', NotifyPreset.all)
          .then((r) => result = r);
      async.flushTimers();

      expect(repo.calls.map((c) => c.$1), ['fetch']);
      expect(result?.failureOrNull, isA<NetworkFailure>());
    });
  });

  test('a cancelled caller sends nothing further', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed);
      var gone = false;
      Result<NotifySettings>? result;
      NotifyPresetApplier(repo)
          .apply(
            'tok',
            NotifyPreset.emergencyOnly,
            current: _fresh(),
            isCancelled: () => gone,
          )
          .then((r) => result = r);
      async.elapse(const Duration(milliseconds: 100));
      expect(repo.calls, hasLength(1));

      gone = true;
      async.flushTimers();

      expect(repo.calls, hasLength(1));
      expect(result?.isOk, isFalse);
    });
  });

  test('custom writes nothing and answers with the settings it was given', () {
    fakeAsync((async) {
      final repo = _Repo(_fresh(), () => async.elapsed);
      Result<NotifySettings>? result;
      NotifyPresetApplier(repo)
          .apply('tok', NotifyPreset.custom, current: _fresh())
          .then((r) => result = r);
      async.flushTimers();

      expect(repo.calls, isEmpty);
      expect(result?.isOk, isTrue);
    });
  });
}
