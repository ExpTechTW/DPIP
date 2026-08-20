/// Debug-only feature flags, read at compile time from `--dart-define`.
///
/// Deliberately in core: a flag any feature (and any layer) may consult, with
/// no dependency on the feature that implements the demo behaviour.
library;

import 'package:flutter/foundation.dart' show kDebugMode;

/// `bool.fromEnvironment` only recognises the literal string `"true"` —
/// `--dart-define=NAME=1`, the natural habit coming from most other tools'
/// env-var conventions, silently reads as **off**, with nothing to say why.
/// Reading the raw string first and accepting `1` too turns that into a
/// working flag instead of a quiet no-op.
const String _monitorDemoRaw = String.fromEnvironment('DPIP_DEMO_MONITOR');
const String _monitorDemoSevereRaw = String.fromEnvironment(
  'DPIP_DEMO_MONITOR_SEVERE',
);
const String _startupEewDemoRaw = String.fromEnvironment(
  'DPIP_DEMO_STARTUP_EEW',
);
const String _monitorDemoSoundRaw = String.fromEnvironment(
  'DPIP_DEMO_MONITOR_SOUND',
);

/// Whether the 強震監視器 demo feeds are on: debug builds launched with
/// `--dart-define=DPIP_DEMO_MONITOR=true` (or `=1`). The flag is forced off
/// outside [kDebugMode] so a release build can never ship the synthetic feeds.
const bool kMonitorDemoEnabled =
    (_monitorDemoRaw == 'true' || _monitorDemoRaw == '1') && kDebugMode;

/// Temporary startup-only EEW used for visual testing with
/// `--dart-define=DPIP_DEMO_STARTUP_EEW=true` (or `=1`). It is deliberately
/// impossible in release builds and yields to the explicit full monitor demo
/// above.
///
/// Remove this flag and the corresponding provider branch when the startup
/// alert test is finished.
const bool kStartupEewDemoEnabled =
    (_startupEewDemoRaw == 'true' || _startupEewDemoRaw == '1') &&
    kDebugMode &&
    !kMonitorDemoEnabled;

/// Whether the demo event uses a fixed, severe preset (large magnitude,
/// shallow depth) instead of the newest real report —
/// `--dart-define=DPIP_DEMO_MONITOR_SEVERE=true` (or `=1`), alongside
/// [kMonitorDemoEnabled] (a no-op without it, since only [kMonitorDemoEnabled]
/// swaps the demo sources in at all). Lets a developer see the monitor's
/// high-intensity styling — the EEW card's colour badge, the station dots'
/// red/purple end of the scale — without waiting for an actual major
/// earthquake to be the newest catalogue row.
const bool kMonitorDemoSevereEnabled =
    (_monitorDemoSevereRaw == 'true' || _monitorDemoSevereRaw == '1') &&
    kDebugMode;

/// Whether the monitor demo submits one foreground notification through the
/// real EEW announcement gate. Kept separate because the original alarm sound
/// is deliberately disruptive. It is inert outside a debug monitor demo.
const bool kMonitorDemoSoundEnabled =
    kMonitorDemoEnabled &&
    (_monitorDemoSoundRaw == 'true' || _monitorDemoSoundRaw == '1') &&
    kDebugMode;
