/// An [ImageProvider] whose cache identity is the URL alone, and whose decode
/// caps a source image before it ever reaches Flutter's image cache.
///
/// Equality by URL only (not by [BugAvatarImage.fetch]) is what lets the same
/// avatar, requested from two widgets that each close over their own fetch
/// callback, collapse into one cache entry instead of two. The decode side
/// caps the longer edge at 256 px so a 1024² Discord avatar costs 256 KB of
/// decoded RGBA instead of 4 MB — except when the source is both larger than
/// the cap AND extremely elongated, where scaling the shorter side by integer
/// division would truncate to zero and ask the engine to decode a zero-pixel
/// image; that combination is decoded unchanged instead, the same call the
/// plain-small-image case makes.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/features/bug_tracker/presentation/widgets/bug_avatar_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List?> _fetchNull(String url) async => null;

/// A real, decodable PNG of exactly [width] x [height] — not a hardcoded
/// blob, so the pixel dimensions this test asserts on are the same ones the
/// decoder measured, not a number copied from a comment.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// Drives [provider] through Flutter's real image-resolution pipeline and
/// returns the decoded image (or throws whatever the stream reported).
Future<ui.Image> _resolve(BugAvatarImage provider) {
  final completer = Completer<ui.Image>();
  final listener = ImageStreamListener(
    (image, synchronousCall) => completer.complete(image.image),
    onError: (error, stackTrace) => completer.completeError(error, stackTrace),
  );
  final stream = provider.resolve(ImageConfiguration.empty);
  stream.addListener(listener);
  return completer.future.whenComplete(() => stream.removeListener(listener));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PaintingBinding.instance.imageCache.clear();
  });

  test('equality and hashCode depend only on the URL, not the fetcher', () {
    Future<Uint8List?> fetchA(String url) async => null;
    Future<Uint8List?> fetchB(String url) async => null;
    final a = BugAvatarImage('https://cdn.example/eq-a.png', fetchA);
    final b = BugAvatarImage('https://cdn.example/eq-a.png', fetchB);
    final c = BugAvatarImage('https://cdn.example/eq-c.png', fetchA);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });

  test('obtainKey resolves synchronously to the provider itself', () async {
    final provider = BugAvatarImage(
      'https://cdn.example/obtain-key.png',
      _fetchNull,
    );

    final key = await provider.obtainKey(ImageConfiguration.empty);

    expect(identical(key, provider), isTrue);
  });

  test('an image already within the cap decodes unchanged', () async {
    final bytes = await _png(64, 48);
    final provider = BugAvatarImage(
      'https://cdn.example/small.png',
      (url) async => bytes,
    );

    final image = await _resolve(provider);
    addTearDown(image.dispose);

    expect(image.width, 64);
    expect(image.height, 48);
  });

  test('an oversized image is scaled so its longer side is capped', () async {
    final bytes = await _png(1024, 512);
    final provider = BugAvatarImage(
      'https://cdn.example/wide.png',
      (url) async => bytes,
    );

    final image = await _resolve(provider);
    addTearDown(image.dispose);

    expect(image.width, 256);
    expect(image.height, 128);
  });

  test('an extremely elongated source decodes unchanged rather than asking '
      'for a zero-pixel image', () async {
    final bytes = await _png(512, 1);
    final provider = BugAvatarImage(
      'https://cdn.example/sliver.png',
      (url) async => bytes,
    );

    final image = await _resolve(provider);
    addTearDown(image.dispose);

    expect(image.width, 512);
    expect(image.height, 1);
  });

  test('no bytes from the fetcher fails the stream, not the app', () async {
    final provider = BugAvatarImage(
      'https://cdn.example/missing.png',
      _fetchNull,
    );

    await expectLater(_resolve(provider), throwsA(isA<StateError>()));
  });
}
