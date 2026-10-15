/// Latest-report-wins speech state machine for a seismic monitor.
///
/// In `domain/` rather than beside the panel that first used it: the live
/// monitor lives in the map feature and the 重播 page in this one, and the
/// layering gate forbids either feature from importing the other's
/// presentation. Nothing here is presentation anyway — no Flutter import, no
/// widget, no build; it is the announcement policy, driven by a feed snapshot.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_priority.dart';

/// A shaking scale together with whether it is local or the max fallback.
typedef SpokenEewEstimate = ({int scale, bool isLocal});

/// Resolves the phrase after a local/fallback estimate has been selected.
typedef EewSpeechFormatter = String Function(SpokenEewEstimate estimate);

/// Announces each new active EEW serial while the monitor is visible — of
/// the most relevant alert only, when several are up.
///
/// Every accepted update stops the previous utterance immediately. Async
/// estimate/speech completions carry a generation, so an obsolete report can
/// neither speak late nor release the warning sound for a newer report.
class MonitorEewAnnouncementController {
  MonitorEewAnnouncementController(
    this._speech,
    this._gate,
    this._estimate, {
    Eew Function(List<Eew> alerts)? primary,
    // Android's system engine can spend several seconds starting an utterance.
    // The stock Google zh-TW voice did not finish even inside five seconds on
    // the emulator, while en-US and ja-JP did. Eight still bounds a wedged
    // engine without overriding the user's system speech rate. Notification
    // playback has its own, slightly longer safety fallback in the foreground
    // gate, so a healthy slow voice never overlaps the alarm.
    this.speechTimeout = const Duration(seconds: 8),
  }) : _primary = primary ?? _rankedFirst;

  static Eew _rankedFirst(List<Eew> alerts) => primaryEew(alerts)!;

  final SpeechService _speech;
  final ForegroundEewAnnouncementGate _gate;
  final Future<SpokenEewEstimate> Function(Eew alert) _estimate;
  final Duration speechTimeout;

  /// Picks the one alert to speak from the uncancelled ones (never empty).
  /// The caller's [rankEews] — it alone knows where the listener is and what
  /// time it is on the timeline being watched; the default ranks without an
  /// observer (highest maximum intensity, then newest report).
  final Eew Function(List<Eew> alerts) _primary;

  /// The highest serial announced per event ([EewIdentityX.eventKey]).
  final Map<String, int> _seenSerials = {};
  bool _active = false;
  bool _hasCurrentAlert = false;

  /// The event the current (or last) phrase was about — so a cancel that
  /// lands for it mid-phrase can cut it off even while another alert stays up.
  String? _spokenKey;
  int _generation = 0;

  /// Activates announcements only for the foreground, visible monitor.
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    _generation++;
    _gate.setActive(value);
    if (!value) {
      _hasCurrentAlert = false;
      _spokenKey = null;
      unawaited(_speech.stop());
    }
  }

  /// Consumes a feed snapshot. Stale/offline/calm snapshots stop speech; live
  /// duplicates and older serials are ignored.
  ///
  /// A cancelled report is never announced, and a snapshot whose alerts are
  /// all cancelled counts as calm: an intensity read out for an event the
  /// agency has just withdrawn is the one thing worse than silence, so a
  /// phrase already in flight for it is cut off.
  void update(
    RealtimeState<List<Eew>> state, {
    required String languageTag,
    required EewSpeechFormatter format,
  }) {
    if (!_active) return;
    final all = state.data;
    if (state.status != RealtimeStatus.live || all == null) {
      _silence();
      return;
    }
    final alerts = all.uncancelled;
    if (alerts.isEmpty) {
      _silence();
      return;
    }
    final spoken = _spokenKey;
    if (spoken != null &&
        all.any((alert) => alert.isCancelled && alert.eventKey == spoken)) {
      _silence();
    }

    final alert = _primary(alerts);
    final key = alert.eventKey;
    final previous = _seenSerials[key];
    if (previous != null && alert.serial <= previous) return;
    _seenSerials[key] = alert.serial;
    _hasCurrentAlert = true;
    _spokenKey = key;

    final generation = ++_generation;
    final gateGeneration = _gate.beginAnnouncement();
    unawaited(
      _announce(alert, generation, gateGeneration, languageTag, format),
    );
  }

  /// Stops whatever is being said and releases the warning sound the gate was
  /// holding for it — a calm feed, an aged one, or a withdrawn report.
  void _silence() {
    if (!_hasCurrentAlert) return;
    _hasCurrentAlert = false;
    _spokenKey = null;
    _generation++;
    _gate.cancelAnnouncement();
    unawaited(_speech.stop());
  }

  Future<void> _announce(
    Eew alert,
    int generation,
    int gateGeneration,
    String languageTag,
    EewSpeechFormatter format,
  ) async {
    try {
      await _speech.stop();
      final estimate = await _estimate(alert);
      if (!_active || generation != _generation) return;
      await _speech
          .speak(format(estimate), languageTag: languageTag)
          .timeout(speechTimeout);
    } catch (error, stackTrace) {
      // stop() completing the superseded speak future with a non-success result
      // is the expected latest-report-wins path, not a TTS engine failure.
      if (!_active || generation != _generation) return;
      Log.handle(error, stackTrace, 'foreground EEW speech');
      await _speech.stop();
    } finally {
      if (_active && generation == _generation) {
        await _gate.completeAnnouncement(gateGeneration);
      }
    }
  }

  /// Stops speech and releases any foreground warning retained by the gate.
  void dispose() {
    _active = false;
    _hasCurrentAlert = false;
    _spokenKey = null;
    _generation++;
    _gate.setActive(false);
    unawaited(_speech.stop());
  }
}
