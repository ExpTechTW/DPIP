/// An update button that ignores the installer sends a TestFlight tester to
/// the App Store. The parse has to keep every distributor, and a failed read
/// has to stay unknown rather than throw.
library;

import 'package:dpip/core/platform/install_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.exptech.dpip/device_info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    InstallSourceService.debugSet(null);
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<InstallSource> load(Object? raw) async {
    InstallSourceService.debugSet(null);
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInstallSource');
      if (raw is Exception) throw raw;
      return raw;
    });
    return InstallSourceService.load();
  }

  test('each wire value maps to its distributor', () async {
    expect(await load('appStore'), InstallSource.appStore);
    expect(await load('testFlight'), InstallSource.testFlight);
    expect(InstallSource.testFlight.isBeta, isTrue);
    expect(InstallSource.appStore.isBeta, isFalse);
    expect(await load('playStore'), InstallSource.playStore);
    expect(await load('development'), InstallSource.development);
    expect(await load('sideload'), InstallSource.github);
    expect(await load('github'), InstallSource.github);
    expect(await load('nope'), InstallSource.unknown);
    expect(await load(null), InstallSource.unknown);
  });

  test('a channel failure is unknown, and the answer is cached', () async {
    expect(await load(Exception('down')), InstallSource.unknown);
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw StateError('should not be asked again');
    });
    expect(await InstallSourceService.load(), InstallSource.unknown);

    InstallSourceService.debugSet(InstallSource.playStore);
    expect(await InstallSourceService.load(), InstallSource.playStore);
  });
}
