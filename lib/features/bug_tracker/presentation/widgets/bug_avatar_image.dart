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
    return MultiFrameImageStreamCompleter(codec: _codec(key), scale: 1);
  }

  Future<ui.Codec> _codec(BugAvatarImage key) async {
    final bytes = await fetch(key.url);
    if (bytes == null || bytes.isEmpty) {
      // CircleAvatar paints its background colour; nothing else to do.
      throw StateError('avatar unavailable: ${key.url}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    return descriptor.instantiateCodec();
  }

  @override
  bool operator ==(Object other) => other is BugAvatarImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
