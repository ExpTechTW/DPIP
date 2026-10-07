/// Manual, local EEW Live Activity prototype controls for the developer page.
library;

import 'package:flutter/services.dart';

class EewLiveActivityStatus {
  const EewLiveActivityStatus({
    required this.supported,
    required this.enabled,
    required this.active,
    required this.reportNo,
    required this.waveArrived,
    this.generic = false,
  });

  final bool supported;
  final bool enabled;
  final bool active;
  final int? reportNo;
  final bool waveArrived;
  final bool generic;

  factory EewLiveActivityStatus.fromMap(Map<Object?, Object?> raw) =>
      EewLiveActivityStatus(
        supported: raw['supported'] == true,
        enabled: raw['enabled'] == true,
        active: raw['active'] == true,
        reportNo: raw['reportNo'] as int?,
        waveArrived: raw['waveArrived'] == true,
        generic: raw['generic'] == true,
      );
}

class EewLiveActivity {
  const EewLiveActivity({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.exptech.dpip/eew_live_activity');

  final MethodChannel _channel;

  Future<EewLiveActivityStatus> getStatus() => _invoke('getStatus');
  Future<EewLiveActivityStatus> mockStart() => _invoke('mockStart');
  Future<EewLiveActivityStatus> mockStartGeneric() =>
      _invoke('mockStartGeneric');
  Future<EewLiveActivityStatus> mockUpdate(int reportNo) =>
      _invoke('mockUpdate', {'reportNo': reportNo});
  Future<EewLiveActivityStatus> mockWaveArrived() => _invoke('mockWaveArrived');
  Future<EewLiveActivityStatus> mockEnd() => _invoke('mockEnd');

  Future<EewLiveActivityStatus> _invoke(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        method,
        arguments,
      );
      if (raw == null) throw StateError('Missing EEW Live Activity status');
      return EewLiveActivityStatus.fromMap(raw);
    } on MissingPluginException {
      return const EewLiveActivityStatus(
        supported: false,
        enabled: false,
        active: false,
        reportNo: null,
        waveArrived: false,
      );
    }
  }
}
