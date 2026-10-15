/// Downloads the basemap tiles a launch with no network needs, and packs them
/// into the assets the app plants in its tile store
/// (`assets/map/basemap_seed/*.bin` + `lib/shared/map/basemap_seed.g.dart`).
///
/// **Why the app carries any tiles at all.** The basemap is otherwise
/// network-only: MapLibre asks the app's SQLite store first and the origin
/// second, so a first launch — or any launch after the cache was cleared or
/// purged by the OS — with no network draws an empty map. Right after a large
/// earthquake is exactly when that happens, and exactly when the map matters.
///
/// **What it fetches.** Taiwan and its outlying islands ([_bounds]) at every
/// zoom the basemap source serves ([_minZoom]–[_maxZoom]; the style overzooms
/// past it), plus the whole world up to [_worldMaxZoom] so a map zoomed out
/// past Taiwan still has the coastlines around it. Nothing more: each extra
/// zoom level over Taiwan roughly doubles the bundle, and the network replaces
/// these tiles the moment it can.
///
/// **What it writes.** Each tile's decoded body, gzipped at level 9 — the form
/// the tile store already keeps a compressible body in — packed into parts of at
/// most [_partBudget] bytes so the app never holds more than one part in memory
/// while planting. The index records where every tile sits, plus a content
/// version ([basemapSeedVersion]) the app stamps into each row's ETag: a
/// regenerated bundle with different tiles gets a new version and reseeds
/// installed copies; a rerun that fetched the same tiles keeps the old one.
///
/// Run it through `tool/gen/basemap_seed.sh`, which pins the toolchain and
/// formats the index. The parts and the index are committed; a normal build
/// never runs this. `test/shared/map/basemap_seeder_test.dart` checks the
/// committed output against the constants below.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/shared/map/basemap_seed_format.dart';

/// Origin template — `basemapOriginTileUrl` in `lib/shared/map/map_style.dart`.
/// The tiles are stored under exactly these URLs, so the two must match; the
/// test holds them together because this tool cannot import Flutter code.
const String _source =
    'https://static.lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf';

/// Taiwan, Penghu, Kinmen (118.2°E), Matsu (26.4°N), Lanyu and Orchid Island
/// down to 21.9°N, with a small margin.
const BasemapSeedBounds _bounds = (
  west: 118.0,
  south: 21.7,
  east: 122.2,
  north: 26.5,
);

/// Zooms bundled over [_bounds] — the basemap source's whole range
/// (`basemapSourceMaxZoom`).
const int _minZoom = 0;
const int _maxZoom = 9;

/// Zooms bundled for the whole world.
const int _worldMaxZoom = 2;

/// Largest part, in bytes. The app plants one part at a time, so this is the
/// most bundle it ever holds at once.
const int _partBudget = 256 * 1024;

/// Simultaneous downloads. The origin is a CDN; a handful is polite and enough.
const int _concurrency = 6;

const String _assetDir = 'assets/map/basemap_seed';
const String _indexPath = 'lib/shared/map/basemap_seed.g.dart';

Future<void> main() async {
  final coverage = basemapSeedCoverage(
    _bounds,
    minZoom: _minZoom,
    maxZoom: _maxZoom,
    worldMaxZoom: _worldMaxZoom,
  );
  stdout.writeln('fetching ${coverage.length} tiles from $_source');

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'dpip-basemap-seed';
  final bodies = List<Uint8List?>.filled(coverage.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < coverage.length) {
      final i = next++;
      final (z, x, y) = coverage[i];
      bodies[i] = await _fetch(client, basemapSeedUrl(_source, z, x, y));
    }
  }

  try {
    await Future.wait([for (var i = 0; i < _concurrency; i++) worker()]);
  } finally {
    client.close(force: true);
  }

  // Compress first, then pack, so a failure above never leaves a half-written
  // bundle on disk.
  final codec = GZipCodec(level: 9);
  final members = <Uint8List>[
    for (final body in bodies)
      body!.isEmpty ? Uint8List(0) : _gzip(codec, body),
  ];

  // A part closes once the next tile would push it past the budget. A single
  // tile larger than the budget still gets a part of its own.
  final parts = <({String asset, BytesBuilder data, List<String> tiles})>[];
  for (var i = 0; i < coverage.length; i++) {
    final member = members[i];
    if (parts.isEmpty ||
        (parts.last.data.isNotEmpty &&
            parts.last.data.length + member.length > _partBudget)) {
      parts.add((
        asset: '$_assetDir/${parts.length}.bin',
        data: BytesBuilder(copy: false),
        tiles: <String>[],
      ));
    }
    final part = parts.last;
    final (z, x, y) = coverage[i];
    part.tiles.add(
      '(z: $z, x: $x, y: $y, offset: ${part.data.length}, '
      'length: ${member.length})',
    );
    part.data.add(member);
  }

  final version = basemapSeedVersion([
    for (var i = 0; i < coverage.length; i++)
      (
        z: coverage[i].$1,
        x: coverage[i].$2,
        y: coverage[i].$3,
        bytes: bodies[i]!,
      ),
  ]);

  final dir = Directory(_assetDir);
  if (dir.existsSync()) {
    for (final stale in dir.listSync().whereType<File>()) {
      if (stale.path.endsWith('.bin')) stale.deleteSync();
    }
  } else {
    dir.createSync(recursive: true);
  }
  final sizes = <int>[];
  for (final part in parts) {
    final bytes = part.data.takeBytes();
    sizes.add(bytes.length);
    File(part.asset).writeAsBytesSync(bytes);
  }

  final index = StringBuffer()
    ..writeln('// GENERATED by tool/gen/basemap_seed.dart — do not edit.')
    ..writeln('//')
    ..writeln(
      '// Where each bundled basemap tile sits in assets/map/basemap_seed.',
    )
    ..writeln('// Regenerate with tool/gen/basemap_seed.sh.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'package:dpip/shared/map/basemap_seed_format.dart';")
    ..writeln()
    ..writeln(
      '/// The tiles `BasemapSeeder` plants — see `basemap_seed_format.dart`.',
    )
    ..writeln('const BasemapSeedIndex bundledBasemapSeed = (')
    ..writeln("  version: '$version',")
    ..writeln("  source: '$_source',")
    ..writeln(
      '  bounds: (west: ${_bounds.west}, south: ${_bounds.south}, '
      'east: ${_bounds.east}, north: ${_bounds.north}),',
    )
    ..writeln('  minZoom: $_minZoom,')
    ..writeln('  maxZoom: $_maxZoom,')
    ..writeln('  worldMaxZoom: $_worldMaxZoom,')
    ..writeln('  parts: [');
  for (var i = 0; i < parts.length; i++) {
    index
      ..writeln('    (')
      ..writeln("      asset: '${parts[i].asset}',")
      ..writeln('      bytes: ${sizes[i]},')
      ..writeln('      tiles: [');
    for (final tile in parts[i].tiles) {
      index.writeln('        $tile,');
    }
    index
      ..writeln('      ],')
      ..writeln('    ),');
  }
  index
    ..writeln('  ],')
    ..writeln(');');
  File(_indexPath).writeAsStringSync(index.toString());

  final raw = bodies.fold<int>(0, (sum, body) => sum + body!.length);
  final packed = sizes.fold<int>(0, (sum, size) => sum + size);
  final empty = bodies.where((body) => body!.isEmpty).length;
  stdout
    ..writeln(
      '${coverage.length} tiles ($empty without content), '
      '${_kib(raw)} decoded -> ${_kib(packed)} in ${parts.length} parts',
    )
    ..writeln('version $version -> $_indexPath');
}

/// One tile's decoded body; empty for a tile the origin has no content for.
///
/// `HttpClient` inflates a gzip response itself, so the body is what MapLibre
/// would parse. Anything other than content or a deliberate "nothing here"
/// fails the run: a bundle silently missing a tile is the kind of hole that is
/// only found offline.
Future<Uint8List> _fetch(HttpClient client, String url) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final builder = BytesBuilder(copy: false);
      await response.forEach(builder.add);
      final body = builder.takeBytes();
      switch (response.statusCode) {
        case HttpStatus.ok:
          if (body.length >= 2 && body[0] == 0x1f && body[1] == 0x8b) {
            throw StateError('$url arrived still gzipped');
          }
          return body;
        case HttpStatus.noContent || HttpStatus.notFound:
          // Open sea. MapLibre draws both as an empty tile.
          return Uint8List(0);
        default:
          throw HttpException(
            'HTTP ${response.statusCode}',
            uri: Uri.parse(url),
          );
      }
    } on Object catch (error) {
      if (error is StateError || attempt >= 3) {
        stderr.writeln('failed: $url ($error)');
        rethrow;
      }
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
}

/// gzip with the header's OS byte set to "unknown" (255), so the same tiles
/// produce the same bytes whichever machine packs them.
Uint8List _gzip(GZipCodec codec, Uint8List body) {
  final member = Uint8List.fromList(codec.encode(body));
  member[9] = 0xff;
  return member;
}

String _kib(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KiB';
