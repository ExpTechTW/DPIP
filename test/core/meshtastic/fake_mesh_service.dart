import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';

/// A [MeshtasticService] the tests drive by hand: streams they pump, results
/// they queue, and a record of everything the code under test sent.
class FakeMeshService implements MeshtasticService {
  final messages = StreamController<MeshMessage>.broadcast();
  final connections = StreamController<MeshConnectionStatus>.broadcast();
  final nodes = StreamController<MeshNode>.broadcast();
  final data = StreamController<MeshDataPacket>.broadcast();

  /// Devices [scanForDevices] yields.
  List<MeshDevice> scanResults = const [];

  /// Consumed one per connect attempt; the last one repeats.
  List<Result<void>> connectResults = const [Ok(null)];
  int connectCalls = 0;
  final List<String> connectedIds = [];

  MeshLinkOwner owner = MeshLinkOwner.free;

  @override
  bool isConnected = false;

  @override
  List<MeshChannel> channels = const [];

  @override
  String? region;

  @override
  int? myNodeNum = 0x1234;

  /// What [ensureChannel] answers, and what it was asked for.
  Result<int> ensureChannelResult = const Ok(3);
  final List<MeshChannelSpec> ensuredChannels = [];

  final List<String> appliedRegions = [];
  Result<void> applyRegionResult = const Ok(null);

  final List<({int portnum, int channel, List<int> payload})> sentData = [];
  final List<String> sentText = [];
  final List<int> sentChannels = [];
  Failure? sendFailure;

  @override
  Stream<MeshMessage> get messageStream => messages.stream;

  @override
  Stream<MeshConnectionStatus> get connectionStream => connections.stream;

  @override
  Stream<MeshNode> get nodeStream => nodes.stream;

  @override
  Stream<MeshDataPacket> get dataStream => data.stream;

  final traffics = StreamController<MeshTraffic>.broadcast();

  @override
  MeshTraffic traffic = const MeshTraffic();

  @override
  Stream<MeshTraffic> get trafficStream => traffics.stream;

  @override
  MeshRadioInfo? radioInfo;

  @override
  Future<Result<void>> initialize() async => const Ok(null);

  @override
  Stream<MeshDevice> scanForDevices({Duration timeout = Duration.zero}) =>
      Stream<MeshDevice>.fromIterable(scanResults);

  @override
  Future<Result<void>> connect(MeshDevice device) => connectToId(device.id);

  @override
  Future<Result<void>> connectToId(String id) async {
    final result =
        connectResults[connectCalls.clamp(0, connectResults.length - 1)];
    connectCalls++;
    if (result is Ok) {
      connectedIds.add(id);
      isConnected = true;
    }
    return result;
  }

  @override
  Future<MeshLinkOwner> linkOwner(String deviceId) async => owner;

  @override
  Future<Result<void>> disconnect() async {
    isConnected = false;
    // The real transport reports every teardown on the status stream, and
    // code under test relies on that.
    connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.disconnected),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> sendText(String text, {int channel = 0}) async {
    final failure = sendFailure;
    if (failure != null) return Err(failure);
    sentText.add(text);
    sentChannels.add(channel);
    return const Ok(null);
  }

  @override
  Future<Result<int>> sendData({
    required int portnum,
    required List<int> payload,
    int channel = 0,
    int? destination,
    bool wantAck = false,
    bool wantResponse = false,
  }) async {
    final failure = sendFailure;
    if (failure != null) return Err(failure);
    sentData.add((portnum: portnum, channel: channel, payload: payload));
    return Ok(nextPacketId++);
  }

  final routes = StreamController<MeshRoute>.broadcast();

  /// Ids handed back by [sendData] / [traceRoute], so a test can match a
  /// notice or a reply to the probe that caused it.
  int nextPacketId = 1;

  /// Times handed to the radio, so a test can assert the clock was set.
  final radioTimes = <DateTime>[];

  @override
  Future<Result<bool>> setRadioTime(DateTime utc) async {
    radioTimes.add(utc);
    return const Ok(true);
  }

  /// The radio's own counters, and the stream a recorder samples from.
  final localStatsUpdates = StreamController<MeshLocalStats>.broadcast();

  MeshLocalStats? localStatsValue;

  @override
  Stream<MeshLocalStats> get localStatsStream => localStatsUpdates.stream;

  @override
  MeshLocalStats? get localStats => localStatsValue;

  /// Notices the radio pushes back about a send.
  final notices = StreamController<MeshNotice>.broadcast();

  @override
  Stream<MeshNotice> get noticeStream => notices.stream;

  /// Whether [traceRoute] fails, and what it was asked for.
  Result<int>? traceResult;
  final List<int> tracedNodes = [];

  /// When set, [traceRoute] waits on it instead of answering [traceResult] —
  /// tests can hold a probe in flight.
  Completer<Result<int>>? traceGate;

  @override
  Future<Result<int>> traceRoute(int nodeNum) async {
    tracedNodes.add(nodeNum);
    final gate = traceGate;
    if (gate != null) return gate.future;
    return traceResult ?? Ok(nextPacketId++);
  }

  @override
  Stream<MeshRoute> get routeStream => routes.stream;

  @override
  Future<Result<int>> ensureChannel(MeshChannelSpec spec) async {
    ensuredChannels.add(spec);
    return ensureChannelResult;
  }

  @override
  Future<Result<void>> applyRegion(String region) async {
    appliedRegions.add(region);
    if (applyRegionResult is Ok) this.region = region;
    return applyRegionResult;
  }
}
