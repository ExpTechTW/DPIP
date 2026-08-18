/// Server status snapshot from the ExpTech status dashboard.
library;

/// One Grafana query result — a single number plus the instance (host) it was
/// measured on, when the query reports one.
class StatusMetric {
  const StatusMetric({required this.value, this.instance});

  /// The raw numeric value — meaning depends on the metric:
  /// `down` node count, 5xx error *rate* (0–1), latency in ms.
  final num value;

  /// The host that answered (`instance` label, e.g. `lb-tpe1`), when the query
  /// topk's by instance. Null when the dashboard did not report one.
  final String? instance;
}

/// The dashboard's three health signals, together with the instant they were
/// observed.
class ServerStatus {
  const ServerStatus({
    required this.recordedAt,
    required this.down,
    required this.errorRate,
    required this.latency,
  });

  /// When the query ran.
  final DateTime recordedAt;

  /// How many `nginx` jobs are down (`count(up==0)`). Zero means all up.
  final StatusMetric down;

  /// Top 5xx-error-rate instance over the last minute, as a 0–1 rate.
  final StatusMetric errorRate;

  /// Top average latency over the last minute, in milliseconds.
  final StatusMetric latency;

  /// Whether every service reports healthy.
  bool get allUp => down.value == 0;

  /// A coarse 0–2 health score from the three signals, for a summary colour.
  StatusHealth get health {
    if (!allUp) return StatusHealth.down;
    if (errorRate.value >= 0.1 || latency.value >= 50) {
      return StatusHealth.degraded;
    }
    return StatusHealth.ok;
  }
}

/// Aggregate health of the whole status snapshot.
enum StatusHealth { ok, degraded, down }
