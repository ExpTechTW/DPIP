/// How the ML v1 model reaches the device and stays there.
///
/// The model is what colours the island during an alert, and an alert is when
/// the network is least reliable. So:
/// - the first open downloads it once, verified against the pinned SHA-256 —
///   a mirror serving a different (retrained) file is refused, or the map would
///   disagree with the server's levels without anyone noticing;
/// - every later session builds from the stored copy with no network at all;
/// - a failed download does not retry on every alert update, which on a phone
///   offline mid-quake would start a 2 MB download each second;
/// - scoring runs in a worker isolate, and a repeated serial is not rescored.
///
/// Runs a real worker isolate over a tiny hand-built model (see
/// `onnx_fixture.dart`) — the 14.7 MB model is the golden test's business.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/ml_model_store.dart';
import 'package:dpip/features/earthquake/data/ml_intensity_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/storage/memory_db.dart';
import '../domain/ml/onnx_fixture.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responder);

  ResponseBody Function(Uri uri) responder;
  final List<Uri> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    return responder(options.uri);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _bytes(Uint8List body) => ResponseBody.fromBytes(body, 200);

/// Two towns: at the epicentre (dist 0 < 10 → tree 0 gives 1) and far away.
Future<MlTownPoints> _points() async =>
    parseMlTownPoints('{"100":[23.5,121.0],"900":[25.5,121.0]}');

const _quake = EewInfo(
  time: 0,
  longitude: 121.0,
  latitude: 23.5,
  depth: 10,
  magnitude: 6,
  location: '',
  max: 5,
);

void main() {
  final model = testModel();
  final modelSha = sha256.convert(model).toString();
  late _Adapter adapter;
  late MlModelStore store;
  var now = DateTime.utc(2026, 9, 28);

  MlIntensityService service({List<String>? sources}) => MlIntensityService(
    client: ApiClient(
      Dio()..httpClientAdapter = adapter,
      RegionSelection(SettingsStore.inMemory({})),
    ),
    store: store,
    now: () => now,
    points: _points,
    sha256: modelSha,
    sources:
        sources ?? const ['https://a.test/m.onnx', 'https://b.test/m.onnx'],
  );

  setUp(() async {
    final db = openMemoryDb();
    await MlModelStore.createSchema(db);
    store = MlModelStore(db);
    now = DateTime.utc(2026, 9, 28);
  });

  test('the first prepare downloads, verifies, stores it compressed', () async {
    adapter = _Adapter((_) => _bytes(model));
    final ml = service();
    addTearDown(ml.dispose);

    expect(await ml.townLevels(_quake), isNull, reason: 'not ready yet');
    expect(await ml.prepare(), isTrue);

    expect(adapter.requests.single.host, 'a.test');
    final stored = await store.read(MlIntensityService.modelName);
    expect(stored?.sha256, modelSha);
    expect(gzip.decode(stored!.gzip), model);
    // M 6 > 5 → tree 1 gives 4 at both; the epicentre adds 1: 5.35 gal,
    // PGV exp(6) = 403 cm/s — level 9 from PGV either way.
    expect(await ml.townLevels(_quake), {'100': 9, '900': 9});
  });

  test(
    'a later session builds from the stored copy, with no network',
    () async {
      await store.write(
        MlIntensityService.modelName,
        gzip: Uint8List.fromList(gzip.encode(model)),
        sha256: modelSha,
        fetchedAt: now,
      );
      adapter = _Adapter((_) => throw StateError('offline'));
      final ml = service();
      addTearDown(ml.dispose);

      expect(await ml.prepare(), isTrue);
      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'a mirror serving a different file is refused; the next is tried',
    () async {
      adapter = _Adapter(
        (uri) => _bytes(
          uri.host == 'a.test' ? Uint8List.fromList([...model, 0]) : model,
        ),
      );
      final ml = service();
      addTearDown(ml.dispose);

      expect(await ml.prepare(), isTrue);
      expect(adapter.requests.map((u) => u.host), ['a.test', 'b.test']);
    },
  );

  test('a failed download waits a minute before trying again', () async {
    adapter = _Adapter((_) => ResponseBody.fromString('', 503));
    final ml = service();
    addTearDown(ml.dispose);

    expect(await ml.prepare(), isFalse);
    final tried = adapter.requests.length;
    expect(await ml.prepare(), isFalse);
    expect(adapter.requests, hasLength(tried), reason: 'held off');

    now = now.add(const Duration(minutes: 1));
    adapter.responder = (_) => _bytes(model);
    expect(await ml.prepare(), isTrue);
  });

  test(
    'a stored copy that no longer builds is dropped and refetched',
    () async {
      await store.write(
        MlIntensityService.modelName,
        gzip: Uint8List.fromList(gzip.encode([1, 2, 3])),
        sha256: modelSha,
        fetchedAt: now,
      );
      adapter = _Adapter((_) => _bytes(model));
      final ml = service();
      addTearDown(ml.dispose);

      expect(await ml.prepare(), isTrue);
      expect(adapter.requests, hasLength(1));
      expect(
        gzip.decode((await store.read(MlIntensityService.modelName))!.gzip),
        model,
      );
    },
  );

  test('concurrent prepares share one download', () async {
    adapter = _Adapter((_) => _bytes(model));
    final ml = service();
    addTearDown(ml.dispose);

    final results = await Future.wait([
      ml.prepare(),
      ml.prepare(),
      ml.prepare(),
    ]);

    expect(results, [true, true, true]);
    expect(adapter.requests, hasLength(1));
  });

  test(
    'the same quake again returns the same answer without rescoring',
    () async {
      adapter = _Adapter((_) => _bytes(model));
      final ml = service();
      addTearDown(ml.dispose);
      await ml.prepare();

      final first = ml.townLevels(_quake);
      expect(identical(ml.townLevels(_quake), first), isTrue);
      expect(
        identical(ml.townLevels(_quake.copyWith(depth: 11)), first),
        isFalse,
      );
    },
  );
}
