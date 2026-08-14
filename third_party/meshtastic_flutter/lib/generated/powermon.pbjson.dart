// This is a generated file - do not edit.
//
// Generated from meshtastic/powermon.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use powerMonDescriptor instead')
const PowerMon$json = {
  '1': 'PowerMon',
  '4': [PowerMon_State$json],
};

@$core.Deprecated('Use powerMonDescriptor instead')
const PowerMon_State$json = {
  '1': 'State',
  '2': [
    {'1': 'None', '2': 0},
    {'1': 'CPU_DeepSleep', '2': 1},
    {'1': 'CPU_LightSleep', '2': 2},
    {'1': 'Vext1_On', '2': 4},
    {'1': 'Lora_RXOn', '2': 8},
    {'1': 'Lora_TXOn', '2': 16},
    {'1': 'Lora_RXActive', '2': 32},
    {'1': 'BT_On', '2': 64},
    {'1': 'LED_On', '2': 128},
    {'1': 'Screen_On', '2': 256},
    {'1': 'Screen_Drawing', '2': 512},
    {'1': 'Wifi_On', '2': 1024},
    {'1': 'GPS_Active', '2': 2048},
  ],
};

/// Descriptor for `PowerMon`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List powerMonDescriptor = $convert.base64Decode(
    'CghQb3dlck1vbiLTAQoFU3RhdGUSCAoETm9uZRAAEhEKDUNQVV9EZWVwU2xlZXAQARISCg5DUF'
    'VfTGlnaHRTbGVlcBACEgwKCFZleHQxX09uEAQSDQoJTG9yYV9SWE9uEAgSDQoJTG9yYV9UWE9u'
    'EBASEQoNTG9yYV9SWEFjdGl2ZRAgEgkKBUJUX09uEEASCwoGTEVEX09uEIABEg4KCVNjcmVlbl'
    '9PbhCAAhITCg5TY3JlZW5fRHJhd2luZxCABBIMCgdXaWZpX09uEIAIEg8KCkdQU19BY3RpdmUQ'
    'gBA=');

@$core.Deprecated('Use powerStressMessageDescriptor instead')
const PowerStressMessage$json = {
  '1': 'PowerStressMessage',
  '2': [
    {
      '1': 'cmd',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.PowerStressMessage.Opcode',
      '10': 'cmd'
    },
    {'1': 'num_seconds', '3': 2, '4': 1, '5': 2, '10': 'numSeconds'},
  ],
  '4': [PowerStressMessage_Opcode$json],
};

@$core.Deprecated('Use powerStressMessageDescriptor instead')
const PowerStressMessage_Opcode$json = {
  '1': 'Opcode',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'PRINT_INFO', '2': 1},
    {'1': 'FORCE_QUIET', '2': 2},
    {'1': 'END_QUIET', '2': 3},
    {'1': 'SCREEN_ON', '2': 16},
    {'1': 'SCREEN_OFF', '2': 17},
    {'1': 'CPU_IDLE', '2': 32},
    {'1': 'CPU_DEEPSLEEP', '2': 33},
    {'1': 'CPU_FULLON', '2': 34},
    {'1': 'LED_ON', '2': 48},
    {'1': 'LED_OFF', '2': 49},
    {'1': 'LORA_OFF', '2': 64},
    {'1': 'LORA_TX', '2': 65},
    {'1': 'LORA_RX', '2': 66},
    {'1': 'BT_OFF', '2': 80},
    {'1': 'BT_ON', '2': 81},
    {'1': 'WIFI_OFF', '2': 96},
    {'1': 'WIFI_ON', '2': 97},
    {'1': 'GPS_OFF', '2': 112},
    {'1': 'GPS_ON', '2': 113},
  ],
};

/// Descriptor for `PowerStressMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List powerStressMessageDescriptor = $convert.base64Decode(
    'ChJQb3dlclN0cmVzc01lc3NhZ2USNwoDY21kGAEgASgOMiUubWVzaHRhc3RpYy5Qb3dlclN0cm'
    'Vzc01lc3NhZ2UuT3Bjb2RlUgNjbWQSHwoLbnVtX3NlY29uZHMYAiABKAJSCm51bVNlY29uZHMi'
    'nwIKBk9wY29kZRIJCgVVTlNFVBAAEg4KClBSSU5UX0lORk8QARIPCgtGT1JDRV9RVUlFVBACEg'
    '0KCUVORF9RVUlFVBADEg0KCVNDUkVFTl9PThAQEg4KClNDUkVFTl9PRkYQERIMCghDUFVfSURM'
    'RRAgEhEKDUNQVV9ERUVQU0xFRVAQIRIOCgpDUFVfRlVMTE9OECISCgoGTEVEX09OEDASCwoHTE'
    'VEX09GRhAxEgwKCExPUkFfT0ZGEEASCwoHTE9SQV9UWBBBEgsKB0xPUkFfUlgQQhIKCgZCVF9P'
    'RkYQUBIJCgVCVF9PThBREgwKCFdJRklfT0ZGEGASCwoHV0lGSV9PThBhEgsKB0dQU19PRkYQcB'
    'IKCgZHUFNfT04QcQ==');
