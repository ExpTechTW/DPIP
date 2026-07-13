/// Access to the server-side notification filter settings.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';

/// Reads and writes the per-channel push filters bound to a device push [token].
///
/// The repository template: the settings page depends on this abstraction, the
/// concrete implementation and its JSON mapping live in `data/`, and both
/// methods return a [Result] so a failed save is explicit (never a silent
/// success that leaves the UI showing the wrong filter).
abstract interface class NotifyRepository {
  /// The current settings for the device [token].
  Future<Result<NotifySettings>> fetch(String token);

  /// Sets [channel] to option [optionIndex] for [token]; the server echoes back
  /// the full updated settings.
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  );
}
