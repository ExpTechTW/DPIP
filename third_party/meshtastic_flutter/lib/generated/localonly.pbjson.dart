// This is a generated file - do not edit.
//
// Generated from meshtastic/localonly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use localConfigDescriptor instead')
const LocalConfig$json = {
  '1': 'LocalConfig',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DeviceConfig',
      '10': 'device'
    },
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PositionConfig',
      '10': 'position'
    },
    {
      '1': 'power',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PowerConfig',
      '10': 'power'
    },
    {
      '1': 'network',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.NetworkConfig',
      '10': 'network'
    },
    {
      '1': 'display',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DisplayConfig',
      '10': 'display'
    },
    {
      '1': 'lora',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.LoRaConfig',
      '10': 'lora'
    },
    {
      '1': 'bluetooth',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.BluetoothConfig',
      '10': 'bluetooth'
    },
    {'1': 'version', '3': 8, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'security',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.SecurityConfig',
      '10': 'security'
    },
  ],
};

/// Descriptor for `LocalConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localConfigDescriptor = $convert.base64Decode(
    'CgtMb2NhbENvbmZpZxI3CgZkZXZpY2UYASABKAsyHy5tZXNodGFzdGljLkNvbmZpZy5EZXZpY2'
    'VDb25maWdSBmRldmljZRI9Cghwb3NpdGlvbhgCIAEoCzIhLm1lc2h0YXN0aWMuQ29uZmlnLlBv'
    'c2l0aW9uQ29uZmlnUghwb3NpdGlvbhI0CgVwb3dlchgDIAEoCzIeLm1lc2h0YXN0aWMuQ29uZm'
    'lnLlBvd2VyQ29uZmlnUgVwb3dlchI6CgduZXR3b3JrGAQgASgLMiAubWVzaHRhc3RpYy5Db25m'
    'aWcuTmV0d29ya0NvbmZpZ1IHbmV0d29yaxI6CgdkaXNwbGF5GAUgASgLMiAubWVzaHRhc3RpYy'
    '5Db25maWcuRGlzcGxheUNvbmZpZ1IHZGlzcGxheRIxCgRsb3JhGAYgASgLMh0ubWVzaHRhc3Rp'
    'Yy5Db25maWcuTG9SYUNvbmZpZ1IEbG9yYRJACglibHVldG9vdGgYByABKAsyIi5tZXNodGFzdG'
    'ljLkNvbmZpZy5CbHVldG9vdGhDb25maWdSCWJsdWV0b290aBIYCgd2ZXJzaW9uGAggASgNUgd2'
    'ZXJzaW9uEj0KCHNlY3VyaXR5GAkgASgLMiEubWVzaHRhc3RpYy5Db25maWcuU2VjdXJpdHlDb2'
    '5maWdSCHNlY3VyaXR5');

@$core.Deprecated('Use localModuleConfigDescriptor instead')
const LocalModuleConfig$json = {
  '1': 'LocalModuleConfig',
  '2': [
    {
      '1': 'mqtt',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.MQTTConfig',
      '10': 'mqtt'
    },
    {
      '1': 'serial',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.SerialConfig',
      '10': 'serial'
    },
    {
      '1': 'external_notification',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.ExternalNotificationConfig',
      '10': 'externalNotification'
    },
    {
      '1': 'store_forward',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.StoreForwardConfig',
      '10': 'storeForward'
    },
    {
      '1': 'range_test',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.RangeTestConfig',
      '10': 'rangeTest'
    },
    {
      '1': 'telemetry',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.TelemetryConfig',
      '10': 'telemetry'
    },
    {
      '1': 'canned_message',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.CannedMessageConfig',
      '10': 'cannedMessage'
    },
    {
      '1': 'audio',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.AudioConfig',
      '10': 'audio'
    },
    {
      '1': 'remote_hardware',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.RemoteHardwareConfig',
      '10': 'remoteHardware'
    },
    {
      '1': 'neighbor_info',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.NeighborInfoConfig',
      '10': 'neighborInfo'
    },
    {
      '1': 'ambient_lighting',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.AmbientLightingConfig',
      '10': 'ambientLighting'
    },
    {
      '1': 'detection_sensor',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.DetectionSensorConfig',
      '10': 'detectionSensor'
    },
    {
      '1': 'paxcounter',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.PaxcounterConfig',
      '10': 'paxcounter'
    },
    {'1': 'version', '3': 8, '4': 1, '5': 13, '10': 'version'},
  ],
};

/// Descriptor for `LocalModuleConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localModuleConfigDescriptor = $convert.base64Decode(
    'ChFMb2NhbE1vZHVsZUNvbmZpZxI3CgRtcXR0GAEgASgLMiMubWVzaHRhc3RpYy5Nb2R1bGVDb2'
    '5maWcuTVFUVENvbmZpZ1IEbXF0dBI9CgZzZXJpYWwYAiABKAsyJS5tZXNodGFzdGljLk1vZHVs'
    'ZUNvbmZpZy5TZXJpYWxDb25maWdSBnNlcmlhbBJoChVleHRlcm5hbF9ub3RpZmljYXRpb24YAy'
    'ABKAsyMy5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5FeHRlcm5hbE5vdGlmaWNhdGlvbkNvbmZp'
    'Z1IUZXh0ZXJuYWxOb3RpZmljYXRpb24SUAoNc3RvcmVfZm9yd2FyZBgEIAEoCzIrLm1lc2h0YX'
    'N0aWMuTW9kdWxlQ29uZmlnLlN0b3JlRm9yd2FyZENvbmZpZ1IMc3RvcmVGb3J3YXJkEkcKCnJh'
    'bmdlX3Rlc3QYBSABKAsyKC5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5SYW5nZVRlc3RDb25maW'
    'dSCXJhbmdlVGVzdBJGCgl0ZWxlbWV0cnkYBiABKAsyKC5tZXNodGFzdGljLk1vZHVsZUNvbmZp'
    'Zy5UZWxlbWV0cnlDb25maWdSCXRlbGVtZXRyeRJTCg5jYW5uZWRfbWVzc2FnZRgHIAEoCzIsLm'
    '1lc2h0YXN0aWMuTW9kdWxlQ29uZmlnLkNhbm5lZE1lc3NhZ2VDb25maWdSDWNhbm5lZE1lc3Nh'
    'Z2USOgoFYXVkaW8YCSABKAsyJC5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5BdWRpb0NvbmZpZ1'
    'IFYXVkaW8SVgoPcmVtb3RlX2hhcmR3YXJlGAogASgLMi0ubWVzaHRhc3RpYy5Nb2R1bGVDb25m'
    'aWcuUmVtb3RlSGFyZHdhcmVDb25maWdSDnJlbW90ZUhhcmR3YXJlElAKDW5laWdoYm9yX2luZm'
    '8YCyABKAsyKy5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5OZWlnaGJvckluZm9Db25maWdSDG5l'
    'aWdoYm9ySW5mbxJZChBhbWJpZW50X2xpZ2h0aW5nGAwgASgLMi4ubWVzaHRhc3RpYy5Nb2R1bG'
    'VDb25maWcuQW1iaWVudExpZ2h0aW5nQ29uZmlnUg9hbWJpZW50TGlnaHRpbmcSWQoQZGV0ZWN0'
    'aW9uX3NlbnNvchgNIAEoCzIuLm1lc2h0YXN0aWMuTW9kdWxlQ29uZmlnLkRldGVjdGlvblNlbn'
    'NvckNvbmZpZ1IPZGV0ZWN0aW9uU2Vuc29yEkkKCnBheGNvdW50ZXIYDiABKAsyKS5tZXNodGFz'
    'dGljLk1vZHVsZUNvbmZpZy5QYXhjb3VudGVyQ29uZmlnUgpwYXhjb3VudGVyEhgKB3ZlcnNpb2'
    '4YCCABKA1SB3ZlcnNpb24=');
