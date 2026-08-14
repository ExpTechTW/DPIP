// This is a generated file - do not edit.
//
// Generated from meshtastic/remote_hardware.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use hardwareMessageDescriptor instead')
const HardwareMessage$json = {
  '1': 'HardwareMessage',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.HardwareMessage.Type',
      '10': 'type'
    },
    {'1': 'gpio_mask', '3': 2, '4': 1, '5': 4, '10': 'gpioMask'},
    {'1': 'gpio_value', '3': 3, '4': 1, '5': 4, '10': 'gpioValue'},
  ],
  '4': [HardwareMessage_Type$json],
};

@$core.Deprecated('Use hardwareMessageDescriptor instead')
const HardwareMessage_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'WRITE_GPIOS', '2': 1},
    {'1': 'WATCH_GPIOS', '2': 2},
    {'1': 'GPIOS_CHANGED', '2': 3},
    {'1': 'READ_GPIOS', '2': 4},
    {'1': 'READ_GPIOS_REPLY', '2': 5},
  ],
};

/// Descriptor for `HardwareMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hardwareMessageDescriptor = $convert.base64Decode(
    'Cg9IYXJkd2FyZU1lc3NhZ2USNAoEdHlwZRgBIAEoDjIgLm1lc2h0YXN0aWMuSGFyZHdhcmVNZX'
    'NzYWdlLlR5cGVSBHR5cGUSGwoJZ3Bpb19tYXNrGAIgASgEUghncGlvTWFzaxIdCgpncGlvX3Zh'
    'bHVlGAMgASgEUglncGlvVmFsdWUibAoEVHlwZRIJCgVVTlNFVBAAEg8KC1dSSVRFX0dQSU9TEA'
    'ESDwoLV0FUQ0hfR1BJT1MQAhIRCg1HUElPU19DSEFOR0VEEAMSDgoKUkVBRF9HUElPUxAEEhQK'
    'EFJFQURfR1BJT1NfUkVQTFkQBQ==');
