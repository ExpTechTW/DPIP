/// An avatar [ImageProvider] that fetches through the app's own HTTP stack.
///
/// `NetworkImage` bypasses Dio entirely — no ETag revalidation, no SQLite body
/// store, no traffic accounting. This provider hands the fetch to the bug
/// repository instead, so a Discord avatar is fetched once, stored, and then
/// revalidated with the CDN's own ETag like every other cacheable GET.
///
/// Equality is the URL alone: the same avatar URL must hit Flutter's image
/// cache as one entry regardless of which widget asked for it.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class BugAvatarImage extends ImageProvider<BugAvatarImage> {
  const BugAvatarImage(this.url, this.fetch);

  /// The avatar URL — also the cache key and the ETag identity.
  final String url;

  /// The shared fetcher: repository `avatar(url)` mapped to raw bytes.
  final Future<Uint8List?> Function(String url) fetch;

  @override
  Future<BugAvatarImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<BugAvatarImage>(this);

  @override
  ImageStreamCompleter loadImage(
    BugAvatarImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(codec: _codec(key, decode), scale: 1);
  }

  /// The decode cap, in pixels, on the longer side of the source.
  ///
  /// Every call site is a small circle — `radius: 9`, `14`, `15`, so 30 logical
  /// px across at the widest; 256 is headroom rather than a fitted bound, since
  /// the framework promises no ceiling on the device pixel ratio and Android's
  /// display-size setting and desktop display scaling both raise it past a
  /// panel's nominal one. The URL is server-supplied — `users[].img` copied
  /// straight out of the tracker payload, commonly a Discord CDN avatar served
  /// at 1024² — and opaque to this app, which is exactly why the cap belongs in
  /// the decode and not in the URL: that string is also the ETag identity and
  /// has to reach the CDN unchanged. A 1024² source is 4 MB of RGBA held for
  /// the session by Flutter's image cache, against 256 KB here.
  ///
  /// Static sources only. `ImageDescriptor.instantiateCodec` forwards a target
  /// size on its single-frame path alone, so Discord's animated `a_*` avatars
  /// go on decoding at native size.
  static const int _maxSide = 256;

  Future<ui.Codec> _codec(
    BugAvatarImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await fetch(key.url);
    if (bytes == null || bytes.isEmpty) {
      // CircleAvatar paints its background colour; nothing else to do.
      throw StateError('avatar unavailable: ${key.url}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    // Give the decoder one side only — `dart:ui` scales the omitted dimension
    // to keep the aspect ratio, whereas passing both is a stretch-to-fit that
    // would squash a non-square source `BoxFit.cover` centre-crops today.
    // Going through the framework's own `decode` also disposes `buffer`, which
    // the hand-rolled `ImageDescriptor` path used to leave to the collector.
    return decode(
      buffer,
      getTargetSize: (width, height) {
        if (width <= _maxSide && height <= _maxSide) {
          return const ui.TargetImageSize();
        }
        // `dart:ui` derives the omitted side by integer division, which
        // truncates to zero once one dimension exceeds [_maxSide] times the
        // other — and it clamps before that arithmetic, not after. Such a
        // source is already small in its short dimension; decode it whole
        // rather than ask the engine for a zero-pixel image.
        if (width > height * _maxSide || height > width * _maxSide) {
          return const ui.TargetImageSize();
        }
        return width >= height
            ? const ui.TargetImageSize(width: _maxSide)
            : const ui.TargetImageSize(height: _maxSide);
      },
    );
  }

  @override
  bool operator ==(Object other) => other is BugAvatarImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
