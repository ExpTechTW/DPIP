import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A repository that echoes an in-memory settings value, optionally failing.
class _FakeRepo implements NotifyRepository {
  _FakeRepo(this.settings);

  NotifySettings settings;
  bool fail = false;
  int setCalls = 0;

  /// Fails only the write numbered this (1-based), when set.
  int? failSetAt;

  @override
  Future<Result<NotifySettings>> fetch(String token) async =>
      fail ? const Err(NetworkFailure('boom')) : Ok(settings);

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async {
    setCalls++;
    if (fail || failSetAt == setCalls) return const Err(NetworkFailure('boom'));
    settings = settings.withChannel(channel, optionIndex);
    return Ok(settings);
  }
}

NotifySettings _settings() =>
    NotifySettings.fromWire(const [1, 1, 1, 1, 1, 1, 1, 0, 1]);

void main() {
  test(
    'load without a token lands on noToken and never calls the repo',
    () async {
      final repo = _FakeRepo(_settings());
      final controller = NotifyController(repo, null);

      await controller.load();

      expect(controller.status, NotifyLoadStatus.noToken);
      expect(controller.hasToken, isFalse);
    },
  );

  test('load success exposes the settings', () async {
    final controller = NotifyController(_FakeRepo(_settings()), 'tok');

    await controller.load();

    expect(controller.status, NotifyLoadStatus.ready);
    expect(controller.settings!.optionOf(NotifyChannel.eew), 1);
  });

  test('load failure surfaces the error for retry', () async {
    final controller = NotifyController(
      _FakeRepo(_settings())..fail = true,
      'tok',
    );

    await controller.load();

    expect(controller.status, NotifyLoadStatus.error);
    expect(controller.failure, isA<NetworkFailure>());
  });

  test('setChannel adopts the server echo and reports success', () async {
    final controller = NotifyController(_FakeRepo(_settings()), 'tok');
    await controller.load();

    final ok = await controller.setChannel(NotifyChannel.eew, 2);

    expect(ok, isTrue);
    expect(controller.settings!.optionOf(NotifyChannel.eew), 2);
    expect(controller.saving, isNull);
  });

  test('an unchanged value is a no-op success (no request)', () async {
    final repo = _FakeRepo(_settings());
    final controller = NotifyController(repo, 'tok');
    await controller.load();

    final ok = await controller.setChannel(NotifyChannel.eew, 1); // already 1

    expect(ok, isTrue);
    expect(repo.setCalls, 0);
  });

  test('a failed save keeps the previous value and reports failure', () async {
    final repo = _FakeRepo(_settings());
    final controller = NotifyController(repo, 'tok');
    await controller.load();
    repo.fail = true;

    final ok = await controller.setChannel(NotifyChannel.eew, 2);

    expect(ok, isFalse);
    expect(controller.settings!.optionOf(NotifyChannel.eew), 1); // unchanged
    expect(controller.saving, isNull);
  });

  group('presets', () {
    NotifyController controller0(_FakeRepo repo) =>
        NotifyController(repo, 'tok', presetSpacing: Duration.zero);

    test('the loaded settings name the preset they match', () async {
      final controller = controller0(_FakeRepo(_settings()));
      expect(controller.preset, isNull, reason: 'nothing loaded yet');

      await controller.load();

      expect(controller.preset, NotifyPreset.custom);
    });

    test('applying adopts every echo and lands on the preset', () async {
      final repo = _FakeRepo(_settings());
      final controller = controller0(repo);
      await controller.load();
      final seen = <NotifyPreset?>[];
      controller.addListener(() => seen.add(controller.applying));

      final ok = await controller.applyPreset(NotifyPreset.emergencyOnly);

      expect(ok, isTrue);
      expect(controller.preset, NotifyPreset.emergencyOnly);
      expect(controller.applying, isNull);
      expect(controller.busy, isFalse);
      // Marked as applying throughout, with a notify per accepted write.
      expect(seen.first, NotifyPreset.emergencyOnly);
      expect(seen.length, repo.setCalls + 2);
    });

    test('a failure part-way keeps what the server accepted', () async {
      final repo = _FakeRepo(_settings())..failSetAt = 2;
      final controller = controller0(repo);
      await controller.load();

      final ok = await controller.applyPreset(NotifyPreset.emergencyOnly);

      expect(ok, isFalse);
      expect(repo.setCalls, 2);
      expect(controller.settings!.optionOf(NotifyChannel.eew), 0);
      expect(controller.preset, NotifyPreset.custom);
      expect(controller.applying, isNull);
    });

    test('a preset already in place sends nothing', () async {
      final repo = _FakeRepo(_settings());
      final controller = controller0(repo);
      await controller.load();
      await controller.applyPreset(NotifyPreset.all);
      final writes = repo.setCalls;

      expect(await controller.applyPreset(NotifyPreset.all), isTrue);
      expect(repo.setCalls, writes);
    });

    test('custom has nothing to apply', () async {
      final repo = _FakeRepo(_settings());
      final controller = controller0(repo);
      await controller.load();

      expect(await controller.applyPreset(NotifyPreset.custom), isFalse);
      expect(repo.setCalls, 0);
    });

    test('no write starts while a preset is being applied', () async {
      final repo = _FakeRepo(_settings());
      final controller = controller0(repo);
      await controller.load();

      final applying = controller.applyPreset(NotifyPreset.emergencyOnly);
      expect(controller.busy, isTrue);
      expect(await controller.setChannel(NotifyChannel.report, 2), isFalse);
      expect(await controller.applyPreset(NotifyPreset.all), isFalse);
      await applying;

      expect(controller.preset, NotifyPreset.emergencyOnly);
    });
  });
}
