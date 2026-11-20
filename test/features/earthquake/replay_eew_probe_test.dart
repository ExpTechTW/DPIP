import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/replay_eew_probe.dart';
import 'package:flutter_test/flutter_test.dart';

/// An [ApiClient] whose replay archive answers per second, so the probe's
/// three samples can be told apart.
class _Api extends ApiClient {
  _Api(this.replies)
    : super(Dio(), RegionSelection(SettingsStore.inMemory(const {})));

  /// Seconds that answer a bulletin; every other second answers `[]`.
  final Map<int, List<Map<String, dynamic>>> replies;

  /// Seconds that should fail instead of answering.
  final Set<int> down = {};

  final asked = <int>[];

  @override
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    bool notFoundFailsOver = false,
  }) async {
    final second = int.parse(path.split('/').last);
    asked.add(second);
    if (down.contains(second)) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    return replies[second] ?? const <Map<String, dynamic>>[];
  }
}

Map<String, dynamic> _eew({
  String author = 'cwa',
  String id = 'cwa-1',
  String location = '花蓮縣',
}) => {
  'author': author,
  'id': id,
  'serial': 1,
  'status': 1,
  'final': 0,
  'eq': {
    'time': DateTime.utc(2026, 11, 1).millisecondsSinceEpoch,
    'lon': 121.6,
    'lat': 23.98,
    'depth': 10,
    'mag': 6.2,
    'loc': location,
    'max': 5,
  },
};

void main() {
  final origin = DateTime.utc(2026, 11, 1, 16, 20, 7);

  int secondAt(Duration offset) =>
      origin.add(offset).millisecondsSinceEpoch ~/ 1000;

  ReplayEewProbe probe(_Api api, {bool cwaOnly = false}) =>
      ReplayEewProbe(api, origin: origin, cwaOnly: () => cwaOnly);

  group('ReplayEewProbe', () {
    test('samples the three instants of the window, once each', () async {
      final api = _Api({});
      expect(await probe(api).run(), ReplayEewVerdict.none);
      expect(api.asked, [
        secondAt(replayProbeOffsets[0]),
        secondAt(replayProbeOffsets[1]),
        secondAt(replayProbeOffsets[2]),
      ]);
    });

    test('finds a bulletin in any one sample', () async {
      final mid = secondAt(replayProbeOffsets[1]);
      final api = _Api({
        mid: [_eew()],
      });
      expect(await probe(api).run(), ReplayEewVerdict.found);
    });

    test('stays undecided when a sample fails', () async {
      final api = _Api({})..down.add(secondAt(replayProbeOffsets[2]));
      // A dead request must never read as "no data".
      expect(await probe(api).run(), ReplayEewVerdict.undecided);
    });

    test('ignores a bulletin the replayed feed would filter out', () async {
      final mid = secondAt(replayProbeOffsets[1]);
      final jma = _Api({
        mid: [_eew(author: 'jma', id: 'jma-1')],
      });
      expect(await probe(jma).run(), ReplayEewVerdict.none);

      final nied = _Api({
        mid: [_eew(author: 'nied', id: 'nied-1')],
      });
      expect(await probe(nied, cwaOnly: true).run(), ReplayEewVerdict.none);
    });
  });

  group('replayEewSlot', () {
    RealtimeState<List<Eew>> feed({
      List<Eew>? data,
      RealtimeStatus status = RealtimeStatus.live,
      int failures = 0,
    }) => RealtimeState(
      status: status,
      data: data,
      consecutiveFailures: failures,
    );

    test('a card always wins', () {
      expect(
        replayEewSlot(
          hasAlerts: true,
          feed: feed(
            data: const [],
            failures: 5,
            status: RealtimeStatus.offline,
          ),
          verdict: ReplayEewVerdict.none,
        ),
        ReplayEewSlot.card,
      );
    });

    test('a failing feed says it is retrying, never that there is no EEW', () {
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const [], failures: 2),
          verdict: ReplayEewVerdict.none,
        ),
        ReplayEewSlot.retrying,
      );
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const [], failures: 2, status: RealtimeStatus.stale),
          verdict: ReplayEewVerdict.found,
        ),
        ReplayEewSlot.retrying,
      );
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(
            data: const [],
            failures: 9,
            status: RealtimeStatus.offline,
          ),
          verdict: null,
        ),
        ReplayEewSlot.unavailable,
      );
    });

    test('one dropped poll is not yet a failure worth saying', () {
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const [], failures: 1),
          verdict: ReplayEewVerdict.found,
        ),
        ReplayEewSlot.waiting,
      );
    });

    test('an offline feed is unavailable even with no failure counted', () {
      // A failure the source chooses not to count, or a request still
      // hanging, leaves the count at zero while the feed ages out. The status
      // is what says it is down; "not yet" or "not detected" would vouch for
      // it.
      for (final verdict in [null, ...ReplayEewVerdict.values]) {
        expect(
          replayEewSlot(
            hasAlerts: false,
            feed: feed(data: const [], status: RealtimeStatus.offline),
            verdict: verdict,
          ),
          ReplayEewSlot.unavailable,
          reason: 'with data, verdict $verdict',
        );
        expect(
          replayEewSlot(
            hasAlerts: false,
            feed: feed(status: RealtimeStatus.offline),
            verdict: verdict,
          ),
          ReplayEewSlot.unavailable,
          reason: 'never had data, verdict $verdict',
        );
      }
    });

    test('waits for the first answer instead of drawing an empty one', () {
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: const RealtimeState.connecting(),
          verdict: null,
        ),
        ReplayEewSlot.pending,
      );
    });

    test('says "not yet" until the samples rule the event out', () {
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const []),
          verdict: ReplayEewVerdict.found,
        ),
        ReplayEewSlot.waiting,
      );
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const []),
          verdict: ReplayEewVerdict.none,
        ),
        ReplayEewSlot.none,
      );
      // An undecided probe has nothing to say either way.
      expect(
        replayEewSlot(
          hasAlerts: false,
          feed: feed(data: const []),
          verdict: ReplayEewVerdict.undecided,
        ),
        ReplayEewSlot.waiting,
      );
    });
  });
}
