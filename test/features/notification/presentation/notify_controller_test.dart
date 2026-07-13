import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
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
    if (fail) return const Err(NetworkFailure('boom'));
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
}
