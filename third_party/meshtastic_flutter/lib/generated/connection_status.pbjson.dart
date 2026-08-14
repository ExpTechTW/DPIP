// This is a generated file - do not edit.
//
// Generated from meshtastic/connection_status.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use deviceConnectionStatusDescriptor instead')
const DeviceConnectionStatus$json = {
  '1': 'DeviceConnectionStatus',
  '2': [
    {
      '1': 'wifi',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.WifiConnectionStatus',
      '9': 0,
      '10': 'wifi',
      '17': true
    },
    {
      '1': 'ethernet',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.EthernetConnectionStatus',
      '9': 1,
      '10': 'ethernet',
      '17': true
    },
    {
      '1': 'bluetooth',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.BluetoothConnectionStatus',
      '9': 2,
      '10': 'bluetooth',
      '17': true
    },
    {
      '1': 'serial',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.SerialConnectionStatus',
      '9': 3,
      '10': 'serial',
      '17': true
    },
  ],
  '8': [
    {'1': '_wifi'},
    {'1': '_ethernet'},
    {'1': '_bluetooth'},
    {'1': '_serial'},
  ],
};

/// Descriptor for `DeviceConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceConnectionStatusDescriptor = $convert.base64Decode(
    'ChZEZXZpY2VDb25uZWN0aW9uU3RhdHVzEjkKBHdpZmkYASABKAsyIC5tZXNodGFzdGljLldpZm'
    'lDb25uZWN0aW9uU3RhdHVzSABSBHdpZmmIAQESRQoIZXRoZXJuZXQYAiABKAsyJC5tZXNodGFz'
    'dGljLkV0aGVybmV0Q29ubmVjdGlvblN0YXR1c0gBUghldGhlcm5ldIgBARJICglibHVldG9vdG'
    'gYAyABKAsyJS5tZXNodGFzdGljLkJsdWV0b290aENvbm5lY3Rpb25TdGF0dXNIAlIJYmx1ZXRv'
    'b3RoiAEBEj8KBnNlcmlhbBgEIAEoCzIiLm1lc2h0YXN0aWMuU2VyaWFsQ29ubmVjdGlvblN0YX'
    'R1c0gDUgZzZXJpYWyIAQFCBwoFX3dpZmlCCwoJX2V0aGVybmV0QgwKCl9ibHVldG9vdGhCCQoH'
    'X3NlcmlhbA==');

@$core.Deprecated('Use wifiConnectionStatusDescriptor instead')
const WifiConnectionStatus$json = {
  '1': 'WifiConnectionStatus',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NetworkConnectionStatus',
      '10': 'status'
    },
    {'1': 'ssid', '3': 2, '4': 1, '5': 9, '10': 'ssid'},
    {'1': 'rssi', '3': 3, '4': 1, '5': 5, '10': 'rssi'},
  ],
};

/// Descriptor for `WifiConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wifiConnectionStatusDescriptor = $convert.base64Decode(
    'ChRXaWZpQ29ubmVjdGlvblN0YXR1cxI7CgZzdGF0dXMYASABKAsyIy5tZXNodGFzdGljLk5ldH'
    'dvcmtDb25uZWN0aW9uU3RhdHVzUgZzdGF0dXMSEgoEc3NpZBgCIAEoCVIEc3NpZBISCgRyc3Np'
    'GAMgASgFUgRyc3Np');

@$core.Deprecated('Use ethernetConnectionStatusDescriptor instead')
const EthernetConnectionStatus$json = {
  '1': 'EthernetConnectionStatus',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NetworkConnectionStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `EthernetConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ethernetConnectionStatusDescriptor =
    $convert.base64Decode(
        'ChhFdGhlcm5ldENvbm5lY3Rpb25TdGF0dXMSOwoGc3RhdHVzGAEgASgLMiMubWVzaHRhc3RpYy'
        '5OZXR3b3JrQ29ubmVjdGlvblN0YXR1c1IGc3RhdHVz');

@$core.Deprecated('Use networkConnectionStatusDescriptor instead')
const NetworkConnectionStatus$json = {
  '1': 'NetworkConnectionStatus',
  '2': [
    {'1': 'ip_address', '3': 1, '4': 1, '5': 7, '10': 'ipAddress'},
    {'1': 'is_connected', '3': 2, '4': 1, '5': 8, '10': 'isConnected'},
    {'1': 'is_mqtt_connected', '3': 3, '4': 1, '5': 8, '10': 'isMqttConnected'},
    {
      '1': 'is_syslog_connected',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'isSyslogConnected'
    },
  ],
};

/// Descriptor for `NetworkConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List networkConnectionStatusDescriptor = $convert.base64Decode(
    'ChdOZXR3b3JrQ29ubmVjdGlvblN0YXR1cxIdCgppcF9hZGRyZXNzGAEgASgHUglpcEFkZHJlc3'
    'MSIQoMaXNfY29ubmVjdGVkGAIgASgIUgtpc0Nvbm5lY3RlZBIqChFpc19tcXR0X2Nvbm5lY3Rl'
    'ZBgDIAEoCFIPaXNNcXR0Q29ubmVjdGVkEi4KE2lzX3N5c2xvZ19jb25uZWN0ZWQYBCABKAhSEW'
    'lzU3lzbG9nQ29ubmVjdGVk');

@$core.Deprecated('Use bluetoothConnectionStatusDescriptor instead')
const BluetoothConnectionStatus$json = {
  '1': 'BluetoothConnectionStatus',
  '2': [
    {'1': 'pin', '3': 1, '4': 1, '5': 13, '10': 'pin'},
    {'1': 'rssi', '3': 2, '4': 1, '5': 5, '10': 'rssi'},
    {'1': 'is_connected', '3': 3, '4': 1, '5': 8, '10': 'isConnected'},
  ],
};

/// Descriptor for `BluetoothConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bluetoothConnectionStatusDescriptor =
    $convert.base64Decode(
        'ChlCbHVldG9vdGhDb25uZWN0aW9uU3RhdHVzEhAKA3BpbhgBIAEoDVIDcGluEhIKBHJzc2kYAi'
        'ABKAVSBHJzc2kSIQoMaXNfY29ubmVjdGVkGAMgASgIUgtpc0Nvbm5lY3RlZA==');

@$core.Deprecated('Use serialConnectionStatusDescriptor instead')
const SerialConnectionStatus$json = {
  '1': 'SerialConnectionStatus',
  '2': [
    {'1': 'baud', '3': 1, '4': 1, '5': 13, '10': 'baud'},
    {'1': 'is_connected', '3': 2, '4': 1, '5': 8, '10': 'isConnected'},
  ],
};

/// Descriptor for `SerialConnectionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serialConnectionStatusDescriptor =
    $convert.base64Decode(
        'ChZTZXJpYWxDb25uZWN0aW9uU3RhdHVzEhIKBGJhdWQYASABKA1SBGJhdWQSIQoMaXNfY29ubm'
        'VjdGVkGAIgASgIUgtpc0Nvbm5lY3RlZA==');
