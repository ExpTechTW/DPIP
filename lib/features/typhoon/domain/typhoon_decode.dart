/// Shared decode helpers for the typhoon feed payloads.
library;

/// Decodes the `{ updated, cyclones: [...] }` shape shared by the potential /
/// probability / warning endpoints: a missing or malformed `cyclones` degrades
/// to an empty list rather than throwing, and `updated` falls back to 0.
T decodeCyclonesPayload<T>(
  Map<String, dynamic> json,
  T Function(int updated, List<dynamic> raw) build,
) {
  final updated = (json['updated'] as num?)?.toInt() ?? 0;
  final raw = json['cyclones'];
  return build(updated, raw is List ? raw : const []);
}

/// Trims [value]; a blank result becomes null (the API's empty-string sentinel).
String? trimToNull(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}
