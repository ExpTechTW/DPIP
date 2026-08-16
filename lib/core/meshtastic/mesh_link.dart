/// Keeps a radio attached for as long as the app is running, and makes sure it
/// is provisioned for DPIP once it is.
///
/// Lives in `core/` and is created at bootstrap, not by a page: the mesh is a
/// reception path for disaster information, so the link must outlive whatever
/// screen the user is on. Leaving the mesh page changes nothing; only
/// [detach] (the user asking) or the app dying ends a session.
///
/// What it owns, and why each piece exists:
///
/// - **Intent.** The chosen radio's id is persisted, and its presence *is* the
///   intent to be connected. Nothing reconnects after [detach].
/// - **Reconnection.** BLE links drop constantly — the user walks away, the
///   radio reboots, the OS reclaims the connection. A drop schedules a retry
///   with a capped backoff; a resume from background retries at once.
/// - **Single flight.** Drops, resumes and manual taps all want to connect.
///   Exactly one attempt runs at a time, and the transport's own
///   disconnect-before-connect can't be mistaken for a link loss.
/// - **Provisioning.** After each successful connect, the DPIP channel is
///   verified/created and the LoRa region checked, so a radio that reboots or
///   gets reconfigured elsewhere heals on reconnect.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/widgets.dart';

/// How far provisioning the DPIP channel got on the attached radio.
enum MeshProvisionState {
  /// No radio, or nothing tried yet.
  idle,

  /// Reading/writing the channel table.
  working,

  /// The DPIP channel is present with the right key.
  ready,

  /// Every secondary slot is taken by the user's own channels. We never
  /// overwrite one, so this needs a human.
  noFreeSlot,

  /// A channel already carries DPIP's name but a different key. Also a human's
  /// call — rewriting it would replace the user's key with the public default.
  conflict,

  /// The radio refused or never confirmed the write.
  failed,
}

/// What the radio's LoRa region means for DPIP.
enum MeshRegionState {
  /// Not known yet (no config download).
  unknown,

  /// Already on the DPIP region.
  ok,

  /// A brand-new radio with no region — safe to set without asking.
  unset,

  /// A different region, deliberately chosen by someone. Changing it reboots
  /// the radio and moves every one of the user's other channels with it, so
  /// this one only changes on an explicit confirmation.
  mismatch,
}

class MeshLink extends ChangeNotifier {
  MeshLink(this._service, this._settings);

  /// What [attach] returns when another app on this phone holds the radio —
  /// not a message, a signal for the UI to ask whether to connect anyway.
  static const String busySentinel = '__mesh_link_busy__';

  /// Reconnect delays, in seconds; the last one repeats forever. Front-loaded
  /// because most drops are momentary, capped because a radio that is out of
  /// range or powered off must not keep the radio hardware busy.
  static const List<int> _backoffSeconds = [2, 5, 10, 20, 40, 60];

  /// A radio that just took a region change reboots; skip straight to a slower
  /// retry instead of hammering a device that is deliberately away.
  static const Duration _rebootGrace = Duration(seconds: 12);

  /// How long a link must hold before the backoff counts as recovered.
  ///
  /// Resetting on `connected` alone is what turns an edge-of-range radio into
  /// a permanent 2-second connect/drop loop: every cycle "succeeds" long
  /// enough to zero the counter, so the backoff never escalates past its first
  /// step.
  static const Duration _stableAfter = Duration(seconds: 45);

  /// Ceiling on one connect attempt, including the rediscovery scan. A stuck
  /// attempt would otherwise hold `_attempting` forever, and that flag gates
  /// both retry scheduling and the resume-from-background path.
  static const Duration _attemptBudget = Duration(seconds: 50);

  final MeshtasticService _service;
  final SettingsStore _settings;

  StreamSubscription<MeshConnectionStatus>? _statusSub;
  AppLifecycleListener? _lifecycle;
  Timer? _retryTimer;
  Timer? _stabilityTimer;
  bool _disposed = false;

  /// Bumped by every [attach] / [detach]. An attempt (or a provisioning run)
  /// whose generation is stale must not write state or settings — it is working
  /// on a radio the user has already moved on from.
  int _generation = 0;
  Future<String?>? _inFlight;

  MeshConnectionStatus _status = const MeshConnectionStatus(
    state: MeshConnectionState.disconnected,
  );
  String? _deviceId;
  String? _deviceName;
  bool _attempting = false;
  int _failures = 0;
  bool _regionApplied = false;
  bool _everConnected = false;
  String? _lastError;

  MeshProvisionState _provision = MeshProvisionState.idle;
  String? _provisionError;
  int? _dpipChannel;
  int? _lastDpipChannel;

  /// The transport's current connection state.
  MeshConnectionStatus get status => _status;

  /// Whether a radio is connected and configured.
  bool get isConnected => _status.state == MeshConnectionState.connected;

  /// The radio this app will keep reconnecting to, if any.
  String? get savedRadioId => _deviceId;
  String? get savedRadioName => _deviceName;

  /// Whether the link is being *re*-established — a first connect is reported
  /// through [status] instead, so the UI doesn't say "reconnecting" to someone
  /// who has never connected.
  bool get reconnecting =>
      _everConnected &&
      _deviceId != null &&
      !isConnected &&
      (_attempting || _retryTimer != null);

  /// Whether another attempt is queued. True even before the first successful
  /// connection, where [reconnecting] is deliberately false.
  bool get willRetry => _retryTimer != null;

  /// Why the last automatic attempt failed, if one did. The automatic paths
  /// have no caller to return to, so this is how a silent stop (a revoked
  /// permission, a radio that never answers) becomes visible.
  String? get lastError => _lastError;

  /// The DPIP channel's index on the attached radio, once provisioned — what
  /// the gateway sends and filters on. Cleared on a drop, because an index
  /// from the previous radio must never be transmitted on.
  int? get dpipChannel => _dpipChannel;

  /// Where DPIP was last seen, kept across a drop.
  ///
  /// Display only — never send on this. It exists so a disconnected UI can
  /// still default to the DPIP conversation instead of falling back to
  /// whatever channel happens to sort first.
  int? get lastKnownDpipChannel => _dpipChannel ?? _lastDpipChannel;

  MeshProvisionState get provision => _provision;

  /// Why provisioning failed, when it did.
  String? get provisionError => _provisionError;

  /// The radio's LoRa region as last read.
  String? get region => _service.region;

  MeshRegionState get regionState {
    final current = _service.region;
    if (!isConnected || current == null) return MeshRegionState.unknown;
    if (current == DpipMeshChannel.region) return MeshRegionState.ok;
    if (current == 'UNSET') return MeshRegionState.unset;
    return MeshRegionState.mismatch;
  }

  /// Wires the link up at bootstrap and, if a radio was chosen in an earlier
  /// session, starts reconnecting to it.
  void start() {
    _statusSub ??= _service.connectionStream.listen(_onStatus);
    _lifecycle ??= AppLifecycleListener(onResume: _onResume);
    _deviceId = _settings.getString(SettingKeys.meshDeviceId);
    _deviceName = _settings.getString(SettingKeys.meshDeviceName);
    _lastDpipChannel ??= _settings.getInt(SettingKeys.meshDpipChannel);
    if (_deviceId == null) return;
    Log.info('mesh link: resuming saved radio ${_deviceName ?? _deviceId}');
    unawaited(_attempt());
  }

  /// Adopts [device] as *the* radio: remembered, connected, provisioned, and
  /// reconnected to until [detach].
  ///
  /// Returns null on success, else a message for the user. When another app on
  /// this phone already holds the radio the attempt stops with an explanation
  /// unless [force] is set — neither iOS nor Android can evict another app's
  /// link, and two clients draining one radio steal each other's packets.
  Future<String?> attach(MeshDevice device, {bool force = false}) async {
    if (!force) {
      final owner = await _service.linkOwner(device.id);
      if (owner == MeshLinkOwner.otherApp) return busySentinel;
    }
    // Supersede whatever is going on. Without this the single-flight guard in
    // `_attempt` would drop the request and *report success*, so picking a
    // second radio while connected (or mid-reconnect) would silently keep the
    // old one — and a stale attempt could even write its own radio back into
    // settings afterwards.
    // The choice is recorded **synchronously**, before any await, so two taps
    // resolve in a defined order (the later one wins) rather than racing each
    // other's writes.
    final generation = ++_generation;
    _deviceId = device.id;
    _deviceName = device.name;
    _failures = 0;
    _regionApplied = false;
    _lastError = null;
    _cancelRetry();
    _notify();

    if (_attempting || _service.isConnected) {
      Log.info(
        'mesh link: superseding the current radio with "${device.name}"',
      );
      await _service.disconnect();
      await _inFlight;
    }
    // Only the newest choice reaches storage — an overtaken attach must not
    // leave its radio behind as the one to reconnect to.
    if (generation != _generation) return null;
    await _settings.setString(SettingKeys.meshDeviceId, device.id);
    await _settings.setString(SettingKeys.meshDeviceName, device.name);
    if (generation != _generation) return null;
    return _attempt();
  }

  /// Forgets the radio and disconnects. Nothing reconnects afterwards.
  Future<void> detach() async {
    Log.info('mesh link: detaching ${_deviceName ?? _deviceId}');
    _generation++; // an attempt still in flight is now working for nobody
    _cancelRetry();
    _stabilityTimer?.cancel();
    _deviceId = null;
    _deviceName = null;
    _dpipChannel = null;
    _lastDpipChannel = null;
    _provision = MeshProvisionState.idle;
    _provisionError = null;
    _lastError = null;
    await _settings.remove(SettingKeys.meshDeviceId);
    await _settings.remove(SettingKeys.meshDeviceName);
    // Forgetting the radio forgets its channel map with it — the next radio's
    // DPIP may live in a different slot.
    await _settings.remove(SettingKeys.meshDpipChannel);
    await _service.disconnect();
    notifyListeners();
  }

  /// Applies the DPIP LoRa region after the user confirmed it.
  ///
  /// The link *will* drop: the firmware turns Bluetooth off and reboots when
  /// radio parameters change. That drop is expected, and the normal reconnect
  /// path picks the radio back up once it is booted.
  Future<String?> applyRegion() async {
    final result = await _service.applyRegion(DpipMeshChannel.region);
    if (result case Err(:final failure)) return failure.message;
    _regionApplied = true;
    // Give the radio its reboot window instead of retrying into a dead link.
    _cancelRetry();
    _retryTimer = Timer(_rebootGrace, () {
      _retryTimer = null;
      unawaited(_attempt());
    });
    notifyListeners();
    return null;
  }

  Future<String?> _attempt() {
    final id = _deviceId;
    // Guarded on the transport, not on [status]: the status is an echo that
    // can still read `connected` right after we dropped a link ourselves, and
    // trusting it there would skip the connect to the radio just chosen.
    if (id == null || _attempting || _service.isConnected) {
      return Future.value();
    }
    _cancelRetry();
    _attempting = true;
    notifyListeners();
    // Bounded, and the timeout is *inside* the tracked future: an attempt that
    // never returns would pin `_attempting` true forever, and that flag gates
    // retry scheduling and the resume path both.
    final attempt = _run(id, _generation)
        .timeout(
          _attemptBudget,
          onTimeout: () {
            Log.warning('mesh link: connect attempt timed out');
            _failures++;
            _scheduleRetry();
            return 'The radio did not answer in time';
          },
        )
        .whenComplete(() {
          _attempting = false;
          _inFlight = null;
          _notify();
        });
    return _inFlight = attempt;
  }

  Future<String?> _run(String id, int generation) async {
    final result = await _service.connectToId(id);
    if (result case Err(:final failure)) {
      // Retrying a denied permission just re-prompts (or silently fails)
      // forever — that one needs the user, not a timer.
      if (failure is PermissionDeniedFailure) {
        Log.warning('mesh link: stopping retries — ${failure.message}');
        return _fail(failure.message, retry: false);
      }
      Log.warning('mesh link: connect by id failed (${failure.message})');
      final rediscovered = await _rediscover(id);
      if (rediscovered == null || generation != _generation) {
        return _fail(failure.message);
      }
      final retry = await _service.connect(rediscovered);
      if (retry case Err(:final failure)) return _fail(failure.message);
      if (generation != _generation) return null;
      await _remember(rediscovered);
    }
    if (generation != _generation) {
      // The user attached a different radio (or detached) while this attempt
      // was in flight — this link is nobody's, so don't keep it.
      Log.info('mesh link: attempt superseded, dropping the link');
      await _service.disconnect();
      return null;
    }
    // Every `disconnected` seen during the attempt was written off as the
    // transport's own teardown. If one of them was a real drop — a radio that
    // accepts the link then goes away — nothing else will report it, and the
    // link would sit down forever. Ask the transport directly.
    if (!_service.isConnected) {
      Log.warning('mesh link: connected then lost immediately');
      return _fail('The radio dropped the connection');
    }
    _lastError = null;
    return null;
  }

  /// Records why an attempt failed and (unless told otherwise) queues another.
  String _fail(String message, {bool retry = true}) {
    _lastError = message;
    if (retry) {
      _failures++;
      _scheduleRetry();
    }
    return message;
  }

  /// One short scan looking for the saved radio.
  ///
  /// Matches on the id **or the saved name**, because the id is exactly what
  /// may have gone stale: an iOS peripheral identifier is per-install and
  /// rotates when the system forgets the peripheral, so it comes back under a
  /// new UUID. Matching only the id — the id that just failed — would make
  /// this whole path unreachable for the case it exists to repair. The name is
  /// weaker (two radios can share one) but it is what the user recognises, and
  /// the new id is written back on success.
  Future<MeshDevice?> _rediscover(String id) async {
    final name = _deviceName;
    MeshDevice? byName;
    try {
      await for (final device in _service.scanForDevices(
        timeout: const Duration(seconds: 6),
      )) {
        if (device.id == id) return device;
        if (name != null && name.isNotEmpty && device.name == name) {
          byName ??= device;
        }
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh link rediscover');
      return byName;
    }
    if (byName != null) {
      Log.info('mesh link: "$name" came back under a new id (${byName.id})');
    }
    return byName;
  }

  Future<void> _remember(MeshDevice device) async {
    _deviceId = device.id;
    _deviceName = device.name;
    await _settings.setString(SettingKeys.meshDeviceId, device.id);
    await _settings.setString(SettingKeys.meshDeviceName, device.name);
  }

  void _onStatus(MeshConnectionStatus status) {
    _status = status;
    switch (status.state) {
      case MeshConnectionState.connected:
        if (_deviceId == null) {
          // A link that finished landing after the user forgot the radio. Left
          // alone it would show as "connected" forever with nothing watching
          // it — drop it instead of adopting it.
          Log.info('mesh link: connected to a forgotten radio — dropping');
          unawaited(_service.disconnect());
          break;
        }
        _everConnected = true;
        _cancelRetry();
        // The backoff is only forgiven once the link has *held*. Zeroing it on
        // `connected` alone lets a radio that connects and drops every second
        // sit at the 2 s step forever.
        _stabilityTimer?.cancel();
        _stabilityTimer = Timer(_stableAfter, () {
          _stabilityTimer = null;
          _failures = 0;
        });
        unawaited(_provisionRadio(_generation));
      case MeshConnectionState.disconnected:
      case MeshConnectionState.error:
        _stabilityTimer?.cancel();
        _stabilityTimer = null;
        _dpipChannel = null;
        _provision = MeshProvisionState.idle;
        // The transport disconnects before it connects, so a drop reported
        // while our own attempt is running is not a link loss. (The attempt
        // re-checks liveness when it finishes, so a real drop in that window
        // is still caught.)
        if (_deviceId != null && !_attempting) {
          Log.info('mesh link: link lost — scheduling reconnect');
          _scheduleRetry();
        }
      case MeshConnectionState.connecting:
      case MeshConnectionState.configuring:
        break;
    }
    _notify();
  }

  void _onResume() {
    if (_deviceId == null || isConnected || _attempting) return;
    // Coming back to the app is the one moment the user is watching, so spend
    // the retry now instead of sitting out the rest of a 60 s backoff. The
    // failure count is deliberately *not* reset — otherwise app-switching
    // would hold a hopeless radio at the shortest retry interval forever.
    Log.info('mesh link: app resumed — reconnecting now');
    _cancelRetry();
    unawaited(_attempt());
  }

  void _scheduleRetry() {
    if (_retryTimer != null || _deviceId == null || _disposed) return;
    final index = (_failures - 1).clamp(0, _backoffSeconds.length - 1);
    final delay = Duration(seconds: _backoffSeconds[index]);
    Log.info('mesh link: retrying in ${delay.inSeconds}s');
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_attempt());
    });
    _notify();
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// [notifyListeners] that tolerates a disposed link — an attempt or a
  /// provisioning run can outlive it.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Verifies the radio carries the DPIP channel, creating it when it doesn't,
  /// and reports what the region needs. Runs after every successful connect —
  /// a radio reconfigured elsewhere heals on the next reconnect.
  Future<void> _provisionRadio(int generation) async {
    _provision = MeshProvisionState.working;
    _provisionError = null;
    _notify();

    final result = await _service.ensureChannel(DpipMeshChannel.spec);
    // A run whose generation is stale belongs to a link that has since gone
    // (or to a radio the user replaced). Letting it write would let a slow,
    // failed pass overwrite the state a later, successful one already set.
    if (generation != _generation || !isConnected) {
      Log.debug('mesh link: discarding a stale provisioning result');
      return;
    }
    switch (result) {
      case Ok(:final value):
        _dpipChannel = value;
        _lastDpipChannel = value;
        // Persisted so a *restarted* disconnected app still defaults to the
        // DPIP conversation — the in-memory copy only survived a drop, which
        // made the chat page open on a different channel after a relaunch
        // than after a disconnect: the "wrong channel" history report.
        unawaited(_settings.setInt(SettingKeys.meshDpipChannel, value));
        _provision = MeshProvisionState.ready;
      case Err(:final failure):
        _dpipChannel = null;
        _provisionError = failure.message;
        _provision = switch (failure) {
          MeshChannelNoSlotFailure() => MeshProvisionState.noFreeSlot,
          MeshChannelConflictFailure() => MeshProvisionState.conflict,
          _ => MeshProvisionState.failed,
        };
        Log.warning('mesh link: provisioning failed — ${failure.message}');
    }
    _notify();

    // Hand the radio our calibrated time. It stamps every packet it delivers
    // with its own RTC, which nothing else in this app sets — so a radio that
    // inherited a wrong clock (from a mis-set phone, or from a mesh peer)
    // mis-dates the whole conversation and the whole node table, and the app
    // then ages both against a calibrated clock. Fixing the source beats
    // correcting every consumer. Best-effort: a radio that refuses costs us
    // nothing we did not already have.
    unawaited(_service.setRadioTime(AppTime.utc));

    // A radio that has never been configured has no region; setting it is what
    // the user came here for and costs them nothing. Any *other* region is
    // someone's deliberate choice — that one waits for a confirmation.
    if (regionState == MeshRegionState.unset && !_regionApplied) {
      Log.info('mesh link: radio has no region — setting TW');
      await applyRegion();
    }
  }

  @override
  void dispose() {
    // Stops the machine, not just the listeners: an attempt still in flight
    // would otherwise schedule a retry that fires against a dead object and
    // reconnects BLE nobody is watching.
    _disposed = true;
    _generation++;
    _deviceId = null;
    _cancelRetry();
    _stabilityTimer?.cancel();
    unawaited(_statusSub?.cancel());
    _lifecycle?.dispose();
    super.dispose();
  }
}
