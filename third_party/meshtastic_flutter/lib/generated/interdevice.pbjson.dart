// This is a generated file - do not edit.
//
// Generated from meshtastic/interdevice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'ACK', '2': 0},
    {'1': 'COLLECT_INTERVAL', '2': 160},
    {'1': 'BEEP_ON', '2': 161},
    {'1': 'BEEP_OFF', '2': 162},
    {'1': 'SHUTDOWN', '2': 163},
    {'1': 'POWER_ON', '2': 164},
    {'1': 'SCD41_TEMP', '2': 176},
    {'1': 'SCD41_HUMIDITY', '2': 177},
    {'1': 'SCD41_CO2', '2': 178},
    {'1': 'AHT20_TEMP', '2': 179},
    {'1': 'AHT20_HUMIDITY', '2': 180},
    {'1': 'TVOC_INDEX', '2': 181},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIHCgNBQ0sQABIVChBDT0xMRUNUX0lOVEVSVkFMEKABEgwKB0JFRVBfT0'
    '4QoQESDQoIQkVFUF9PRkYQogESDQoIU0hVVERPV04QowESDQoIUE9XRVJfT04QpAESDwoKU0NE'
    'NDFfVEVNUBCwARITCg5TQ0Q0MV9IVU1JRElUWRCxARIOCglTQ0Q0MV9DTzIQsgESDwoKQUhUMj'
    'BfVEVNUBCzARITCg5BSFQyMF9IVU1JRElUWRC0ARIPCgpUVk9DX0lOREVYELUB');

@$core.Deprecated('Use sensorDataDescriptor instead')
const SensorData$json = {
  '1': 'SensorData',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.MessageType',
      '10': 'type'
    },
    {'1': 'float_value', '3': 2, '4': 1, '5': 2, '9': 0, '10': 'floatValue'},
    {'1': 'uint32_value', '3': 3, '4': 1, '5': 13, '9': 0, '10': 'uint32Value'},
  ],
  '8': [
    {'1': 'data'},
  ],
};

/// Descriptor for `SensorData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sensorDataDescriptor = $convert.base64Decode(
    'CgpTZW5zb3JEYXRhEisKBHR5cGUYASABKA4yFy5tZXNodGFzdGljLk1lc3NhZ2VUeXBlUgR0eX'
    'BlEiEKC2Zsb2F0X3ZhbHVlGAIgASgCSABSCmZsb2F0VmFsdWUSIwoMdWludDMyX3ZhbHVlGAMg'
    'ASgNSABSC3VpbnQzMlZhbHVlQgYKBGRhdGE=');

@$core.Deprecated('Use interdeviceMessageDescriptor instead')
const InterdeviceMessage$json = {
  '1': 'InterdeviceMessage',
  '2': [
    {'1': 'nmea', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'nmea'},
    {
      '1': 'sensor',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.SensorData',
      '9': 0,
      '10': 'sensor'
    },
  ],
  '8': [
    {'1': 'data'},
  ],
};

/// Descriptor for `InterdeviceMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interdeviceMessageDescriptor = $convert.base64Decode(
    'ChJJbnRlcmRldmljZU1lc3NhZ2USFAoEbm1lYRgBIAEoCUgAUgRubWVhEjAKBnNlbnNvchgCIA'
    'EoCzIWLm1lc2h0YXN0aWMuU2Vuc29yRGF0YUgAUgZzZW5zb3JCBgoEZGF0YQ==');
