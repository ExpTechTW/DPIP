/// Drives the notification-settings page: loads the server settings and applies
/// per-channel changes and presets.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_preset_applier.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:flutter/foundation.dart';

/// Where the initial load stands.
enum NotifyLoadStatus {
  /// The push token is missing, so nothing can be loaded or saved yet.
  noToken,

  /// The first fetch is in flight.
  loading,

  /// Settings are loaded and editable.
  ready,

  /// The first fetch failed (retryable).
  error,
}

/// Holds the settings state and mediates every change through the repository —
/// each save round-trips to the server and adopts the echoed settings, so the
/// UI can never drift from the backend. A failed save keeps the previous value
/// and reports `false` so the page can surface it.
///
/// A preset goes through the very same repository call, once per channel that
/// differs ([NotifyPresetApplier]); each echo is adopted as it arrives, so the
/// rows below the preset fill in one by one and a failure part-way shows
/// exactly what the server ended up holding.
class NotifyController extends ChangeNotifier {
  NotifyController(
    NotifyRepository repository,
    this._token, {
    Duration presetSpacing = NotifyPresetApplier.requestSpacing,
  }) : _repository = repository,
       _presets = NotifyPresetApplier(repository, spacing: presetSpacing);

  final NotifyRepository _repository;
  final NotifyPresetApplier _presets;
  final String? _token;

  NotifyLoadStatus _status = NotifyLoadStatus.loading;
  NotifySettings? _settings;
  Failure? _failure;
  NotifyChannel? _saving;
  NotifyPreset? _applying;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// The load state.
  NotifyLoadStatus get status => _status;

  /// The loaded settings, or null until [status] is [NotifyLoadStatus.ready].
  NotifySettings? get settings => _settings;

  /// The failure behind [NotifyLoadStatus.error].
  Failure? get failure => _failure;

  /// The channel with a save in flight, if any (for a per-row spinner).
  NotifyChannel? get saving => _saving;

  /// The preset being applied, if any (for the preset row's spinner).
  NotifyPreset? get applying => _applying;

  /// Whether any write is in flight — every row is locked meanwhile, so two
  /// writes never race for the same token's rate limit.
  bool get busy => _saving != null || _applying != null;

  /// The preset the loaded settings are exactly — [NotifyPreset.custom] when
  /// they are none of them — or null until loaded.
  NotifyPreset? get preset {
    final settings = _settings;
    return settings == null ? null : NotifyPreset.matching(settings);
  }

  /// Whether a push token exists — without one there is nothing to target.
  bool get hasToken => _token != null && _token.isNotEmpty;

  /// Fetches the current settings (no-op without a token — the page shows the
  /// "not ready" state instead).
  Future<void> load() async {
    if (!hasToken) {
      _status = NotifyLoadStatus.noToken;
      notifyListeners();
      return;
    }
    _status = NotifyLoadStatus.loading;
    notifyListeners();
    final result = await _repository.fetch(_token!);
    // Page popped mid-load — don't touch a disposed notifier.
    if (_disposed) return;
    result.when(
      ok: (settings) {
        _settings = settings;
        _status = NotifyLoadStatus.ready;
      },
      err: (failure) {
        _failure = failure;
        _status = NotifyLoadStatus.error;
      },
    );
    notifyListeners();
  }

  /// Sets [channel] to option [optionIndex]. Returns whether it was saved (a
  /// no-op when unchanged counts as success); a failed save leaves the previous
  /// value intact.
  Future<bool> setChannel(NotifyChannel channel, int optionIndex) async {
    final current = _settings;
    if (!hasToken || current == null || busy) return false;
    if (current.optionOf(channel) == optionIndex) return true;

    _saving = channel;
    notifyListeners();
    final result = await _repository.setChannel(_token!, channel, optionIndex);
    if (_disposed) return false; // page popped mid-save — don't notify
    _saving = null;
    return result.when(
      ok: (settings) {
        _settings = settings;
        notifyListeners();
        return true;
      },
      err: (_) {
        notifyListeners();
        return false;
      },
    );
  }

  /// Applies [preset] — every channel it covers, one request at a time.
  /// Returns whether all of it was saved (already matching counts as success).
  ///
  /// A failure keeps whatever the server had accepted before it, so the rows
  /// and the preset row both show the true state, which is usually
  /// [NotifyPreset.custom]; calling this again resumes from there.
  /// [NotifyPreset.custom] has nothing to apply and reports false.
  Future<bool> applyPreset(NotifyPreset preset) async {
    final current = _settings;
    if (!hasToken || current == null || busy) return false;
    if (preset == NotifyPreset.custom) return false;
    if (NotifyPreset.matching(current) == preset) return true;

    _applying = preset;
    notifyListeners();
    final result = await _presets.apply(
      _token!,
      preset,
      current: current,
      onProgress: (settings) {
        if (_disposed) return;
        _settings = settings;
        notifyListeners();
      },
      // Page popped mid-apply: send nothing further. What was written stays,
      // and reopening the page shows it as it is.
      isCancelled: () => _disposed,
    );
    if (_disposed) return false;
    _applying = null;
    notifyListeners();
    return result.isOk;
  }
}
