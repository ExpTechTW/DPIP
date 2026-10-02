import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Native allowlist key. This reserves a file only; no forecast producer exists.
enum WidgetSnapshotKind { weatherForecast, currentWeather }

/// Writes an already encoded, versioned JSON snapshot for a future widget.
/// The caller owns its schema; this boundary owns delivery and persistence.
abstract interface class WidgetSnapshotWriter {
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
  });

  Future<Result<void>> clear({required WidgetSnapshotKind kind});
}

/// iOS implementation. No App Group path or filename crosses this boundary.
final class IosWidgetSnapshotWriter implements WidgetSnapshotWriter {
  IosWidgetSnapshotWriter({MethodChannel? channel, bool? isSupportedPlatform})
    : _channel =
          channel ?? const MethodChannel('com.exptech.dpip/widget_snapshot'),
      _isSupportedPlatform = isSupportedPlatform ?? Platform.isIOS;

  final MethodChannel _channel;
  final bool _isSupportedPlatform;

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
  }) async {
    if (!_isSupportedPlatform) {
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.unavailable,
          'Widget snapshot writer is unavailable on this platform.',
        ),
      );
    }

    try {
      await _channel.invokeMethod<void>('write', {
        'kind': kind.name,
        'json': json,
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
  Future<Result<void>> clear({required WidgetSnapshotKind kind}) async {
    if (!_isSupportedPlatform) {
      return const Err(
        WidgetSnapshotFailure(
          WidgetSnapshotFailureReason.unavailable,
          'Widget snapshot writer is unavailable on this platform.',
        ),
      );
    }

    try {
      await _channel.invokeMethod<void>('clear', {'kind': kind.name});

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
}
