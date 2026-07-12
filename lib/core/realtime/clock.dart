/// A source of "now", behind a seam so time-dependent code is testable.
///
/// Production uses [SystemClock] (the device wall clock). The realtime spine
/// injects [ServerClock] as its [Clock] so staleness is measured against
/// corrected server time; tests inject a fake that returns scripted instants.
library;

/// Reads the current instant.
abstract interface class Clock {
  DateTime now();
}

/// The device wall clock — `DateTime.now()`.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
