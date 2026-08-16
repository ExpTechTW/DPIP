// This is a generated file - do not edit.
//
// Generated from meshtastic/mqtt.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use serviceEnvelopeDescriptor instead')
const ServiceEnvelope$json = {
  '1': 'ServiceEnvelope',
  '2': [
    {
      '1': 'packet',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MeshPacket',
      '10': 'packet'
    },
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'gateway_id', '3': 3, '4': 1, '5': 9, '10': 'gatewayId'},
  ],
};

/// Descriptor for `ServiceEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceEnvelopeDescriptor = $convert.base64Decode(
    'Cg9TZXJ2aWNlRW52ZWxvcGUSLgoGcGFja2V0GAEgASgLMhYubWVzaHRhc3RpYy5NZXNoUGFja2'
    'V0UgZwYWNrZXQSHQoKY2hhbm5lbF9pZBgCIAEoCVIJY2hhbm5lbElkEh0KCmdhdGV3YXlfaWQY'
    'AyABKAlSCWdhdGV3YXlJZA==');

@$core.Deprecated('Use mapReportDescriptor instead')
const MapReport$json = {
  '1': 'MapReport',
  '2': [
    {'1': 'long_name', '3': 1, '4': 1, '5': 9, '10': 'longName'},
    {'1': 'short_name', '3': 2, '4': 1, '5': 9, '10': 'shortName'},
    {
      '1': 'role',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.Role',
      '10': 'role'
    },
    {
      '1': 'hw_model',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.HardwareModel',
      '10': 'hwModel'
    },
    {'1': 'firmware_version', '3': 5, '4': 1, '5': 9, '10': 'firmwareVersion'},
    {
      '1': 'region',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.RegionCode',
      '10': 'region'
    },
    {
      '1': 'modem_preset',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.ModemPreset',
      '10': 'modemPreset'
    },
    {
      '1': 'has_default_channel',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'hasDefaultChannel'
    },
    {'1': 'latitude_i', '3': 9, '4': 1, '5': 15, '10': 'latitudeI'},
    {'1': 'longitude_i', '3': 10, '4': 1, '5': 15, '10': 'longitudeI'},
    {'1': 'altitude', '3': 11, '4': 1, '5': 5, '10': 'altitude'},
    {
      '1': 'position_precision',
      '3': 12,
      '4': 1,
      '5': 13,
      '10': 'positionPrecision'
    },
    {
      '1': 'num_online_local_nodes',
      '3': 13,
      '4': 1,
      '5': 13,
      '10': 'numOnlineLocalNodes'
    },
    {
      '1': 'has_opted_report_location',
      '3': 14,
      '4': 1,
      '5': 8,
      '10': 'hasOptedReportLocation'
    },
  ],
};

/// Descriptor for `MapReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mapReportDescriptor = $convert.base64Decode(
    'CglNYXBSZXBvcnQSGwoJbG9uZ19uYW1lGAEgASgJUghsb25nTmFtZRIdCgpzaG9ydF9uYW1lGA'
    'IgASgJUglzaG9ydE5hbWUSOAoEcm9sZRgDIAEoDjIkLm1lc2h0YXN0aWMuQ29uZmlnLkRldmlj'
    'ZUNvbmZpZy5Sb2xlUgRyb2xlEjQKCGh3X21vZGVsGAQgASgOMhkubWVzaHRhc3RpYy5IYXJkd2'
    'FyZU1vZGVsUgdod01vZGVsEikKEGZpcm13YXJlX3ZlcnNpb24YBSABKAlSD2Zpcm13YXJlVmVy'
    'c2lvbhJACgZyZWdpb24YBiABKA4yKC5tZXNodGFzdGljLkNvbmZpZy5Mb1JhQ29uZmlnLlJlZ2'
    'lvbkNvZGVSBnJlZ2lvbhJMCgxtb2RlbV9wcmVzZXQYByABKA4yKS5tZXNodGFzdGljLkNvbmZp'
    'Zy5Mb1JhQ29uZmlnLk1vZGVtUHJlc2V0Ugttb2RlbVByZXNldBIuChNoYXNfZGVmYXVsdF9jaG'
    'FubmVsGAggASgIUhFoYXNEZWZhdWx0Q2hhbm5lbBIdCgpsYXRpdHVkZV9pGAkgASgPUglsYXRp'
    'dHVkZUkSHwoLbG9uZ2l0dWRlX2kYCiABKA9SCmxvbmdpdHVkZUkSGgoIYWx0aXR1ZGUYCyABKA'
    'VSCGFsdGl0dWRlEi0KEnBvc2l0aW9uX3ByZWNpc2lvbhgMIAEoDVIRcG9zaXRpb25QcmVjaXNp'
    'b24SMwoWbnVtX29ubGluZV9sb2NhbF9ub2RlcxgNIAEoDVITbnVtT25saW5lTG9jYWxOb2Rlcx'
    'I5ChloYXNfb3B0ZWRfcmVwb3J0X2xvY2F0aW9uGA4gASgIUhZoYXNPcHRlZFJlcG9ydExvY2F0'
    'aW9u');
