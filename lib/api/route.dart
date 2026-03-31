import 'dart:math';

class _BaseUrlGenerator {
  final String _prefix;
  final int _count;

  const _BaseUrlGenerator({required String prefix, required int count})
    : _prefix = prefix,
      _count = count;

  String call([int? i]) {
    i ??= Random().nextInt(_count) + 1;

    if (i < 1 || i > _count) {
      throw ArgumentError.value(
        i,
        'i',
        'Server index must be between 1 and $_count',
      );
    }

    return 'https://$_prefix-$i.exptech.dev/api';
  }

  @override
  String toString() => call();
}

/// API base url generator. Use as `'$api/path'` for a random
/// server, or `'${api(1)}/path'` to pin to a specific server index.
const api = _BaseUrlGenerator(prefix: 'api', count: 2);

/// Load-balancer base url generator. Use as `'$lb/path'` for a random
/// server, or `'${lb(1)}/path'` to pin to a specific server index.
const lb = _BaseUrlGenerator(prefix: 'lb', count: 4);

/// Base host for NTP requests.
String get ntpBase => 'https://lb-${Random().nextInt(4) + 1}.exptech.dev';

/// Base host for radar tile requests.
String radarTile(String timestamp) =>
    'https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png';
