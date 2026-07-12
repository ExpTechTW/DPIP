/// JSON coercion helpers for `@JsonKey(fromJson:)` on API models.
///
/// The ExpTech API encodes some booleans as `0`/`1` (or their string forms);
/// use [boolishInt] to decode them.
library;

/// Decodes a `0`/`1` (int or string) into a `bool`.
bool boolishInt(Object? value) => value == 1 || value == '1';

/// Encodes a `bool` back to `0`/`1` — the inverse of [boolishInt], so
/// `fromJson`/`toJson` round-trip symmetrically.
int intFromBool(bool value) => value ? 1 : 0;
