/// Drives the notification-settings page: loads the server settings and applies
/// per-channel changes.
library;

import 'package:dpip/core/error/failure.dart';
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
class NotifyController extends ChangeNotifier {
  NotifyController(this._repository, this._token);

  final NotifyRepository _repository;
  final String? _token;

  NotifyLoadStatus _status = NotifyLoadStatus.loading;
  NotifySettings? _settings;
  Failure? _failure;
  NotifyChannel? _saving;
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
    if (!hasToken || current == null) return false;
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
}
