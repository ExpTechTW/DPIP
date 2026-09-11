/// String-level helpers for the XYZ tile URLs the map warms by the thousand.
///
/// A settled radar fill names 12k+ tile URLs, and everything that used to be
/// derived from one of them — is it a cacheable tile, which frame directory
/// does it belong to, what does its template expand to — was derived again
/// for every sibling `z/x/y` of the same frame. The helpers here make that
/// once-per-frame instead of once-per-tile without changing a single answer.
library;

import 'package:dpip/shared/map/xyz_tiles.dart';

/// Index just past the `/` that precedes a plain `z/x/y.ext` tail, or `-1`.
///
/// A *plain* tail is exactly three decimal runs and an ASCII-alphanumeric
/// extension — `7/108/56.webp` — never one with a query or fragment
/// (`…/56.webp?style=jma`), a non-numeric coordinate, or fewer than three
/// segments. The restriction is what makes [TileUrlMemo] exact: a plain tail
/// contains nothing `Uri.parse` would reject, escape or treat as a delimiter,
/// so it can neither change whether the URL parses nor how the part before it
/// is normalised.
int tileUrlDirectoryEnd(String url) {
  var i = url.length - 1;
  // Extension: one or more `[A-Za-z0-9]`, then the dot.
  final extEnd = i;
  while (i >= 0 && _isAlphanumeric(url.codeUnitAt(i))) {
    i--;
  }
  if (i == extEnd || i < 0 || url.codeUnitAt(i) != _dot) return -1;
  i--;
  // Three decimal runs, `/`-separated, each preceded by a `/`.
  for (var run = 0; run < 3; run++) {
    final runEnd = i;
    while (i >= 0 && _isDigit(url.codeUnitAt(i))) {
      i--;
    }
    if (i == runEnd || i < 0 || url.codeUnitAt(i) != _slash) return -1;
    if (run < 2) i--;
  }
  return i + 1;
}

const int _dot = 0x2E;
const int _slash = 0x2F;

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

bool _isAlphanumeric(int unit) =>
    _isDigit(unit) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A);

/// Memoises a per-URL derivation on the URL's directory.
///
/// [derive] must give the same answer for every URL that shares a directory
/// and differs only in a plain `z/x/y.ext` tail (see [tileUrlDirectoryEnd]);
/// each call site states why its function does. A URL whose tail is not
/// plain is derived directly and never cached, so the memo can only ever
/// return what [derive] would have.
///
/// Bounded: the table is cleared once it reaches [capacity] entries. The keys
/// are frame directories — a few hundred per timeline — so it is cleared
/// rarely and refilled at one derivation per frame.
class TileUrlMemo<T> {
  TileUrlMemo(this._derive, {this.capacity = 512});

  final T Function(String url) _derive;
  final int capacity;
  final Map<String, T> _byDirectory = {};

  T call(String url) {
    final end = tileUrlDirectoryEnd(url);
    if (end < 0) return _derive(url);
    final directory = url.substring(0, end);
    // `containsKey` rather than a null check: `T` may itself be nullable.
    if (_byDirectory.containsKey(directory)) {
      return _byDirectory[directory] as T;
    }
    if (_byDirectory.length >= capacity) _byDirectory.clear();
    return _byDirectory[directory] = _derive(url);
  }
}

/// A tile URL template split once around its `{z}` / `{x}` / `{y}` slots.
///
/// [expand] is byte-for-byte what
/// `template.replaceFirst('{z}', z).replaceFirst('{x}', x).replaceFirst('{y}', y)`
/// produces, at one string build per tile instead of three scans and three
/// intermediate strings. The two agree because the substituted values are
/// decimal digits: they can never create, destroy or shift a later `{…}`
/// occurrence, so the first occurrence of each token in the original template
/// is the one every `replaceFirst` would have found. A token the template does
/// not contain is left out, exactly as `replaceFirst` leaves it.
final class TileUrlTemplate {
  factory TileUrlTemplate(String template) {
    final slots = <(int, int)>[
      for (final (axis, token) in const [(0, '{z}'), (1, '{x}'), (2, '{y}')])
        if (template.indexOf(token) case final at when at >= 0) (at, axis),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final pieces = <String>[];
    final axes = <int>[];
    var from = 0;
    for (final (at, axis) in slots) {
      pieces.add(template.substring(from, at));
      axes.add(axis);
      from = at + 3;
    }
    pieces.add(template.substring(from));
    return TileUrlTemplate._(
      List.unmodifiable(pieces),
      List.unmodifiable(axes),
    );
  }

  const TileUrlTemplate._(this._pieces, this._axes);

  /// Literal text between slots — always one more than [_axes].
  final List<String> _pieces;

  /// Which coordinate each slot takes: 0 = z, 1 = x, 2 = y, in template order.
  final List<int> _axes;

  String expand(XyzTile tile) {
    final out = StringBuffer(_pieces[0]);
    for (var i = 0; i < _axes.length; i++) {
      out.write(switch (_axes[i]) {
        0 => tile.z,
        1 => tile.x,
        _ => tile.y,
      });
      out.write(_pieces[i + 1]);
    }
    return out.toString();
  }
}
