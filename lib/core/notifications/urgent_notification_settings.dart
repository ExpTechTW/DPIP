/// Reads Android Do Not Disturb bypass status for DPIP's urgent notification
/// channels and opens their system settings.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:flutter/services.dart';

enum UrgentNotificationChannelState {
  missing,
  doesNotBypass,
  bypasses,
  unavailable,
}

class UrgentNotificationChannelStatus {
  const UrgentNotificationChannelStatus({
    required this.requestedId,
    required this.channelId,
    required this.name,
    required this.state,
  });

  final String requestedId;
  final String? channelId;
  final String? name;
  final UrgentNotificationChannelState state;
}

class UrgentNotificationStatus {
  const UrgentNotificationStatus(this.channels);

  final List<UrgentNotificationChannelStatus> channels;

  bool get allBypass =>
      channels.isNotEmpty &&
      channels.every(
        (channel) => channel.state == UrgentNotificationChannelState.bypasses,
      );
}

class UrgentNotificationSettings {
  UrgentNotificationSettings([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/permission_settings');

  final MethodChannel _channel;

  Future<UrgentNotificationStatus> status() async {
    final keys = NotificationChannels.urgentChannelKeys.toList(growable: false);
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'urgentNotificationChannelStatus',
        {'channelIds': keys},
      );
      return UrgentNotificationStatus([
        for (final key in keys) _parse(key, response?[key]),
      ]);
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'urgent notification channel status');
      return _unavailable(keys);
    } on MissingPluginException {
      return _unavailable(keys);
    }
  }

  Future<String> openChannelSettings(String channelId) async {
    try {
      return await _channel.invokeMethod<String>(
            'openNotificationChannelSettings',
            {'channelId': channelId},
          ) ??
          'none';
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'urgent notification channel settings');
      return 'none';
    } on MissingPluginException {
      return 'none';
    }
  }

  UrgentNotificationChannelStatus _parse(String key, Object? value) {
    if (value == null) {
      return UrgentNotificationChannelStatus(
        requestedId: key,
        channelId: null,
        name: null,
        state: UrgentNotificationChannelState.missing,
      );
    }
    if (value is! Map<Object?, Object?>) return _unavailableChannel(key);
    final id = value['id'];
    final name = value['name'];
    final bypasses = value['bypassesDnd'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        bypasses is! bool) {
      return _unavailableChannel(key);
    }
    return UrgentNotificationChannelStatus(
      requestedId: key,
      channelId: id,
      name: name,
      state: bypasses
          ? UrgentNotificationChannelState.bypasses
          : UrgentNotificationChannelState.doesNotBypass,
    );
  }

  UrgentNotificationStatus _unavailable(List<String> keys) =>
      UrgentNotificationStatus([
        for (final key in keys) _unavailableChannel(key),
      ]);

  UrgentNotificationChannelStatus _unavailableChannel(String key) =>
      UrgentNotificationChannelStatus(
        requestedId: key,
        channelId: null,
        name: null,
        state: UrgentNotificationChannelState.unavailable,
      );
}
