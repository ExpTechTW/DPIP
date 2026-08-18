/// Cloudflare status snapshot — the CDN the app's hosts sit behind.
library;

/// The Cloudflare status-page states, in the order the API reports them.
enum CloudflareComponentState {
  operational,
  degradedPerformance,
  partialOutage,
  majorOutage,
  unknown;

  static CloudflareComponentState of(String raw) => switch (raw) {
    'operational' => operational,
    'degraded_performance' => degradedPerformance,
    'partial_outage' => partialOutage,
    'major_outage' => majorOutage,
    _ => unknown,
  };
}

/// One Cloudflare ingress the app cares about — the Taipei / Kaohsiung pops
/// that answer for the DPIP hosts.
class CloudflareComponent {
  const CloudflareComponent({
    required this.name,
    required this.state,
    required this.updatedAt,
  });

  /// The display name from the status page, e.g. `Taipei - (TPE)`.
  final String name;

  final CloudflareComponentState state;

  /// When the status page last changed this component.
  final DateTime updatedAt;
}

/// A snapshot of the Cloudflare components the app depends on.
class CloudflareStatus {
  const CloudflareStatus({required this.components, required this.recordedAt});

  /// The observed Taipei / Kaohsiung components, Taipei first.
  final List<CloudflareComponent> components;

  /// When the snapshot was fetched.
  final DateTime recordedAt;

  /// Whether every observed component is operating normally. Empty means we
  /// do not know — not that everything is fine.
  bool get allOperational =>
      components.isNotEmpty &&
      components.every((c) => c.state == CloudflareComponentState.operational);
}
