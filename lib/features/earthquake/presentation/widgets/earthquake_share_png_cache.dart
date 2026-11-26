import 'dart:typed_data';

/// Stores successful, Dart-owned compressed PNGs for one sharing dialog.
final class EarthquakeSharePngCache<Key> {
  static const _maxEntries = 14;
  static const _maxBytes = 8 * 1024 * 1024;

  final _images = <Key, Uint8List>{};
  int _bytes = 0;

  Uint8List? lookup(Key key) {
    final png = _images.remove(key);
    if (png != null) _images[key] = png;
    return png;
  }

  void store(Key key, Uint8List png) {
    if (png.lengthInBytes > _maxBytes) return;
    final previous = _images.remove(key);
    _bytes -= previous?.lengthInBytes ?? 0;
    while (_images.length >= _maxEntries ||
        _bytes + png.lengthInBytes > _maxBytes) {
      _bytes -= _images.remove(_images.keys.first)!.lengthInBytes;
    }
    _images[key] = png;
    _bytes += png.lengthInBytes;
  }

  void clear() {
    _images.clear();
    _bytes = 0;
  }
}
