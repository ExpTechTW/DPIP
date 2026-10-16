import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Native allowlist key for versioned Widget shared data.
enum WidgetSnapshotKind { weatherForecast, currentWeather, locationCatalog }

/// Writes an already encoded, versioned JSON snapshot for a future widget.
/// The caller owns its schema; this boundary owns delivery and persistence.
abstract interface class WidgetSnapshotWriter {
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  });

  /// Clears [kind]. Android also supports clearing only [sourceIdentifier]'s
  /// entry for current weather; iOS always clears the whole kind.
  ///
  /// Home selection changes must not clear Android snapshots, even by source:
  /// an independently configured desktop widget may still display that source.
  Future<Result<void>> clear({
    required WidgetSnapshotKind kind,
    String? sourceIdentifier,
  });
}

/// The one MethodChannel protocol both platforms speak.
///
/// iOS's `WidgetSnapshotPlugin` and Android's `WidgetSnapshotChannel` implement
/// the same method names, argument keys and error codes, so the delivery and
/// error-handling half of the boundary is written once here and only the
/// platform gate differs. Before this existed the Android side would have been
/// a second copy of the switch below, and the copies would have drifted the
/// first time one platform gained a code.
///
/// `base` so it can only be extended in this library: the subclasses are the
/// complete set of platforms this app ships, and a new one should be a
/// deliberate addition here rather than an extension of the plumbing.
base class _MethodChannelWidgetSnapshotWriter implements WidgetSnapshotWriter {
  _MethodChannelWidgetSnapshotWriter(this._channel, this._isSupportedPlatform);

  final MethodChannel _channel;
  final bool _isSupportedPlatform;

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    if (!_isSupportedPlatform) return _unavailable();

    try {
      await _channel.invokeMethod<void>('write', {
        'kind': kind.name,
        'json': json,
        'sourceIdentifier': ?sourceIdentifier,
      });
      return const Ok(null);
    } on MissingPluginException {
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.unavailable,
          'Widget snapshot writer is unavailable.',
        ),
      );
    } on PlatformException catch (error) {
      final failure = _writeFailure(error.code);
      Log.warning('Widget snapshot write failed: ${failure.reason.name}');
      return Err(failure);
    } on Object {
      Log.warning('Widget snapshot write failed unexpectedly');
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.writeFailed,
          'Widget snapshot could not be written.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> clear({
    required WidgetSnapshotKind kind,
    String? sourceIdentifier,
  }) async {
    if (!_isSupportedPlatform) return _unavailable();

    try {
      await _channel.invokeMethod<void>('clear', {
        'kind': kind.name,
        'sourceIdentifier': ?sourceIdentifier,
      });

      return const Ok(null);
    } on MissingPluginException {
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.unavailable,
          'Widget snapshot writer is unavailable.',
        ),
      );
    } on PlatformException catch (error) {
      final failure = switch (error.code) {
        'invalid_kind' => const WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.invalidKind,
          'Widget snapshot kind is unsupported.',
        ),
        'app_group_unavailable' => const WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.appGroupUnavailable,
          'Widget shared storage is unavailable.',
        ),
        _ => const WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.writeFailed,
          'Widget snapshot could not be cleared.',
        ),
      };

      Log.warning('Widget snapshot clear failed: ${failure.reason.name}');
      return Err(failure);
    } on Object {
      Log.warning('Widget snapshot clear failed unexpectedly');
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.writeFailed,
          'Widget snapshot could not be cleared.',
        ),
      );
    }
  }

  static Result<void> _unavailable() => const Err(
    WidgetSnapshotFailure(
      WidgetSnapshotFailureReason.unavailable,
      'Widget snapshot writer is unavailable on this platform.',
    ),
  );

  static WidgetSnapshotFailure _writeFailure(String code) {
    return switch (code) {
      'invalid_kind' => const WidgetSnapshotFailure(
        WidgetSnapshotFailureReason.invalidKind,
        'Widget snapshot kind is unsupported.',
      ),
      'invalid_payload' => const WidgetSnapshotFailure(
        WidgetSnapshotFailureReason.invalidPayload,
        'Widget snapshot JSON is invalid or too large.',
      ),
      'app_group_unavailable' => const WidgetSnapshotFailure(
        WidgetSnapshotFailureReason.appGroupUnavailable,
        'Widget shared storage is unavailable.',
      ),
      _ => const WidgetSnapshotFailure(
        WidgetSnapshotFailureReason.writeFailed,
        'Widget snapshot could not be written.',
      ),
    };
  }
}

/// iOS implementation. No App Group path or filename crosses this boundary.
final class IosWidgetSnapshotWriter extends _MethodChannelWidgetSnapshotWriter {
  IosWidgetSnapshotWriter({MethodChannel? channel, bool? isSupportedPlatform})
    : super(
        channel ?? const MethodChannel('com.exptech.dpip/widget_snapshot'),
        isSupportedPlatform ?? Platform.isIOS,
      );
}

/// Android implementation. No database path or table name crosses this boundary.
final class AndroidWidgetSnapshotWriter
    extends _MethodChannelWidgetSnapshotWriter {
  AndroidWidgetSnapshotWriter({
    MethodChannel? channel,
    bool? isSupportedPlatform,
  }) : super(
         channel ?? const MethodChannel('com.exptech.dpip/widget_snapshot'),
         isSupportedPlatform ?? Platform.isAndroid,
       );
}

/// The writer for a platform with no Widget: every call is `unavailable`.
///
/// It exists so the wiring has no nullable writer and no `Platform` check of
/// its own — the desktop and test hosts get the same object every launch, and
/// the failure a caller sees there is the same typed one iOS sees when the
/// extension is absent.
final class UnsupportedWidgetSnapshotWriter implements WidgetSnapshotWriter {
  const UnsupportedWidgetSnapshotWriter();

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async => const Err(
    WidgetSnapshotFailure(
      WidgetSnapshotFailureReason.unavailable,
      'Widget snapshot writer is unavailable on this platform.',
    ),
  );

  @override
  Future<Result<void>> clear({
    required WidgetSnapshotKind kind,
    String? sourceIdentifier,
  }) async => const Err(
    WidgetSnapshotFailure(
      WidgetSnapshotFailureReason.unavailable,
      'Widget snapshot writer is unavailable on this platform.',
    ),
  );
}

/// The writer for the platform this build is running on.
///
/// Every construction site goes through this: `bootstrap` wires the location
/// catalog coordinator and the weather providers wire the current-weather
/// synchronizer, and two `Platform` checks would be two places for a platform's
/// writer to be forgotten.
///
/// [isIOS] and [isAndroid] exist so the selection itself can be tested: `dart:io`
/// `Platform` answers for the machine the test runs on, which is neither of the
/// two platforms this app ships, so a test could otherwise only ever see the
/// unsupported writer — and would prove nothing about the branch it exists to
/// check. Production passes neither.
WidgetSnapshotWriter createWidgetSnapshotWriter({
  bool? isIOS,
  bool? isAndroid,
}) {
  final ios = isIOS ?? Platform.isIOS;
  final android = isAndroid ?? Platform.isAndroid;
  if (ios) return IosWidgetSnapshotWriter();
  if (android) return AndroidWidgetSnapshotWriter();
  return const UnsupportedWidgetSnapshotWriter();
}
