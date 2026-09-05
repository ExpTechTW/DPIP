/// Latest-report-wins speech state machine for the visible seismic monitor.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';

/// A shaking scale together with whether it is local or the max fallback.
typedef SpokenEewEstimate = ({int scale, bool isLocal});

/// Resolves the phrase after a local/fallback estimate has been selected.
typedef EewSpeechFormatter = String Function(SpokenEewEstimate estimate);

/// Announces each new active EEW serial while the monitor is visible.
///
/// Every accepted update stops the previous utterance immediately. Async
/// estimate/speech completions carry a generation, so an obsolete report can
/// neither speak late nor release the warning sound for a newer report.
class MonitorEewAnnouncementController {
  MonitorEewAnnouncementController(
    this._speech,
    this._gate,
    this._estimate, {
    // Android's system engine can spend several seconds starting an utterance.
    // The stock Google zh-TW voice did not finish even inside five seconds on
    // the emulator, while en-US and ja-JP did. Eight still bounds a wedged
    // engine without overriding the user's system speech rate. Notification
    // playback has its own, slightly longer safety fallback in the foreground
    // gate, so a healthy slow voice never overlaps the alarm.
    this.speechTimeout = const Duration(seconds: 8),
  });

  final SpeechService _speech;
  final ForegroundEewAnnouncementGate _gate;
  final Future<SpokenEewEstimate> Function(Eew alert) _estimate;
  final Duration speechTimeout;

  final Map<String, int> _seenSerials = {};
  bool _active = false;
  bool _hasCurrentAlert = false;
  int _generation = 0;

  /// Activates announcements only for the foreground, visible monitor.
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    _generation++;
    _gate.setActive(value);
    if (!value) {
      _hasCurrentAlert = false;
      unawaited(_speech.stop());
    }
  }

  /// Consumes a feed snapshot. Stale/offline/calm snapshots stop speech; live
  /// duplicates and older serials are ignored.
  void update(
    RealtimeState<List<Eew>> state, {
    required String languageTag,
    required EewSpeechFormatter format,
  }) {
    if (!_active) return;
    final alerts = state.data;
    if (state.status != RealtimeStatus.live ||
        alerts == null ||
        alerts.isEmpty) {
      if (!_hasCurrentAlert) return;
      _hasCurrentAlert = false;
      _generation++;
      _gate.cancelAnnouncement();
      unawaited(_speech.stop());
      return;
    }

    final alert = alerts.first;
    final previous = _seenSerials[alert.id];
    if (previous != null && alert.serial <= previous) return;
    _seenSerials[alert.id] = alert.serial;
    _hasCurrentAlert = true;

    final generation = ++_generation;
    final gateGeneration = _gate.beginAnnouncement();
    unawaited(
      _announce(alert, generation, gateGeneration, languageTag, format),
    );
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
    _generation++;
    _gate.setActive(false);
    unawaited(_speech.stop());
  }
}
