/// Crash reports leave the device from snapshots and development builds only,
/// and only the ones worth reading.
///
/// The failure that matters most here is silent: a production build that
/// sends. The SDK remembers the collection switch across launches, so the
/// production path is tested as an action (switch off, drop the backlog), not
/// as the absence of one.
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpip/core/diagnostics/crash_reporting.dart';
import 'package:dpip/core/diagnostics/prerelease_diagnostics.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReporter implements CrashReporter {
  final calls = <String>[];
  final errors = <({Object error, String? reason, bool fatal})>[];
  final keys = <String, Object>{};
  final lines = <String>[];
  bool failRecord = false;

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      calls.add('collection=$enabled');

  @override
  Future<void> deleteUnsentReports() async => calls.add('deleteUnsent');

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    required bool fatal,
  }) async {
    if (failRecord) throw StateError('channel gone');
    errors.add((error: error, reason: reason, fatal: fatal));
  }

  @override
  Future<void> log(String message) async => lines.add(message);

  @override
  Future<void> setKey(String key, Object value) async => keys[key] = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppBuild.debugSet(label: '26w42a', code: 426000700);
    InstallSourceService.debugSet(InstallSource.testFlight);
  });

  tearDown(() {
    Log.crashSink = null;
    PrereleaseDiagnostics.debugReset();
    InstallSourceService.debugSet(null);
  });

  group('isPrereleaseBuild', () {
    test('a release build is production unless CI marked it a snapshot', () {
      expect(isPrereleaseBuild(releaseMode: true, defined: ''), isFalse);
      expect(isPrereleaseBuild(releaseMode: true, defined: 'false'), isFalse);
      // Only the exact value the workflow writes — a typo must fail safe.
      expect(isPrereleaseBuild(releaseMode: true, defined: '1'), isFalse);
      expect(isPrereleaseBuild(releaseMode: true, defined: 'true'), isTrue);
    });

    test('debug and profile builds always count', () {
      expect(isPrereleaseBuild(releaseMode: false, defined: ''), isTrue);
      expect(isPrereleaseBuild(releaseMode: false, defined: 'false'), isTrue);
    });

    test('the release workflow stamps the mark from its prerelease output', () {
      final workflow = File(
        '${Directory.current.path}/.github/workflows/release.yml',
      ).readAsStringSync();
      // Through the step's environment, not pasted into the script: the
      // workflow keeps every `${{ }}` out of `run:` text.
      expect(
        workflow,
        contains(
          r'RELEASE_PRERELEASE: ${{ needs.version.outputs.prerelease }}',
        ),
      );
      expect(
        workflow,
        contains(r'--dart-define=DPIP_PRERELEASE=$RELEASE_PRERELEASE'),
      );
      // And that output is false for a tag, which is what production ships.
      expect(
        workflow,
        contains('echo "prerelease=false" >> "\$GITHUB_OUTPUT"'),
      );
    });
  });

  // Each of these fails silently: the first two by sending before the app has
  // decided, the last by a release build dying at launch while debug works.
  group('native defaults', () {
    String read(String path) =>
        File('${Directory.current.path}/$path').readAsStringSync();

    test('Android ships with collection off', () {
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        matches(
          RegExp(
            r'android:name="firebase_crashlytics_collection_enabled"\s+'
            r'android:value="false"',
          ),
        ),
      );
    });

    test('iOS ships with collection off', () {
      expect(
        read('ios/Runner/Info.plist'),
        matches(
          RegExp(r'<key>FirebaseCrashlyticsCollectionEnabled</key>\s*<false/>'),
        ),
      );
    });

    test('the build-ID switch exists and survives resource shrinking', () {
      expect(
        read('android/app/src/main/res/values/crashlytics.xml'),
        contains('<bool name="com.crashlytics.RequireBuildId">false</bool>'),
      );
      // Only a raw keep file is read by the shrinker, and it matches the R
      // field's spelling — the dotted name is silently never matched.
      expect(
        read('android/app/src/main/res/raw/keep.xml'),
        contains('@bool/com_crashlytics_RequireBuildId'),
      );
    });
  });

  group('PrereleaseDiagnostics.start', () {
    test('production switches collection off and drops the backlog', () async {
      final reporter = _FakeReporter();
      await PrereleaseDiagnostics.start(reporter: reporter, prerelease: false);

      expect(reporter.calls, ['collection=false', 'deleteUnsent']);
      expect(Log.crashSink, isNull);
      expect(PrereleaseDiagnostics.reporter, isNull);
      expect(reporter.keys, isEmpty);
    });

    test(
      'a prerelease build sends, and says what hardware it ran on',
      () async {
        final reporter = _FakeReporter();
        await PrereleaseDiagnostics.start(
          reporter: reporter,
          prerelease: true,
          device: () async => const DeviceDetails(
            manufacturer: 'Acme',
            model: 'A1',
            osVersion: '14',
            sdkInt: 34,
            totalMemoryMb: 3072,
          ),
        );

        expect(reporter.calls, ['collection=true']);
        expect(Log.crashSink, isA<ReportingCrashSink>());
        expect(PrereleaseDiagnostics.reporter, same(reporter));
        expect(reporter.keys['build_label'], '26w42a');
        expect(reporter.keys['build_code'], 426000700);
        expect(reporter.keys['install_source'], 'testFlight');
        expect(reporter.keys['ram_mb'], 3072);
        expect(reporter.keys['android_sdk'], 34);
        expect(reporter.keys['build_mode'], 'debug');
        // The tier is decided from the host platform, so only its presence is
        // pinned here; render_tier_test owns the rule itself.
        expect(reporter.keys['render_tier'], isA<String>());
      },
    );

    test('an unreadable device leaves the hardware keys out', () async {
      final reporter = _FakeReporter();
      await PrereleaseDiagnostics.start(
        reporter: reporter,
        prerelease: true,
        device: () async => null,
      );
      expect(reporter.keys.containsKey('ram_mb'), isFalse);
      expect(reporter.keys.containsKey('render_tier'), isFalse);
      expect(reporter.keys['build_label'], '26w42a');
    });
  });

  group('ReportingCrashSink', () {
    test('forwards a handled error with its context', () async {
      final reporter = _FakeReporter();
      Log.crashSink = ReportingCrashSink(reporter);

      final error = StateError('bad row');
      Log.handle(error, StackTrace.current, 'decoding report');
      await pumpEventQueue();

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.error, same(error));
      expect(reporter.errors.single.reason, 'decoding report');
      expect(reporter.errors.single.fatal, isFalse);
    });

    test('drops the network failing, which is not a defect', () async {
      final reporter = _FakeReporter();
      final sink = ReportingCrashSink(reporter);
      final options = RequestOptions(path: '/api/v2/location/1/token/1/25,121');

      sink.report(
        DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
        StackTrace.current,
      );
      sink.report(
        DioException.badResponse(
          statusCode: 503,
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 503),
        ),
        StackTrace.current,
      );
      sink.report(const SocketException('no route'), StackTrace.current);
      sink.report(TimeoutException('slow'), StackTrace.current);
      sink.report(const HandshakeException('tls'), StackTrace.current);
      await pumpEventQueue();

      expect(reporter.errors, isEmpty);
    });

    test('the same fault is reported once a session', () async {
      final reporter = _FakeReporter();
      final sink = ReportingCrashSink(reporter);

      for (var frame = 0; frame < 30; frame++) {
        sink.report(
          FlutterErrorLike('RenderFlex overflowed by 4 pixels'),
          StackTrace.current,
          context: 'layout',
          fatal: true,
        );
      }
      sink.report(
        FlutterErrorLike('RenderFlex overflowed by 4 pixels'),
        StackTrace.current,
        context: 'a different place',
      );
      await pumpEventQueue();

      expect(reporter.errors, hasLength(2));
      expect(reporter.errors.first.fatal, isTrue);
    });

    test('stops at the per-session ceiling', () async {
      final reporter = _FakeReporter();
      final sink = ReportingCrashSink(reporter);

      for (var i = 0; i < ReportingCrashSink.maxReportsPerSession + 5; i++) {
        sink.report(StateError('fault $i'), StackTrace.current);
      }
      await pumpEventQueue();

      expect(
        reporter.errors,
        hasLength(ReportingCrashSink.maxReportsPerSession),
      );
      // The first ones are kept: they are usually the cause of the rest.
      expect((reporter.errors.first.error as StateError).message, 'fault 0');
    });

    test('a reporter that throws never reaches the caller', () async {
      final reporter = _FakeReporter()..failRecord = true;
      Log.crashSink = ReportingCrashSink(reporter);

      expect(
        () => Log.handle(StateError('boom'), StackTrace.current, 'ctx'),
        returnsNormally,
      );
      await pumpEventQueue();
      expect(reporter.errors, isEmpty);
    });

    test('a signature ignores everything after the first line', () {
      final a = ReportingCrashSink.signature(
        StateError('same\nbody one'),
        'ctx',
      );
      final b = ReportingCrashSink.signature(
        StateError('same\nbody two'),
        'ctx',
      );
      expect(a, b);
      final long = ReportingCrashSink.signature(StateError('x' * 1000), null);
      expect(long.length, lessThan(220));
    });
  });
}

/// A stand-in with a stable message, the shape a repeated layout fault has.
class FlutterErrorLike implements Exception {
  FlutterErrorLike(this.message);
  final String message;
  @override
  String toString() => message;
}
