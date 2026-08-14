// This is a generated file - do not edit.
//
// Generated from meshtastic/xmodem.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use xModemDescriptor instead')
const XModem$json = {
  '1': 'XModem',
  '2': [
    {
      '1': 'control',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.XModem.Control',
      '10': 'control'
    },
    {'1': 'seq', '3': 2, '4': 1, '5': 13, '10': 'seq'},
    {'1': 'crc16', '3': 3, '4': 1, '5': 13, '10': 'crc16'},
    {'1': 'buffer', '3': 4, '4': 1, '5': 12, '10': 'buffer'},
  ],
  '4': [XModem_Control$json],
};

@$core.Deprecated('Use xModemDescriptor instead')
const XModem_Control$json = {
  '1': 'Control',
  '2': [
    {'1': 'NUL', '2': 0},
    {'1': 'SOH', '2': 1},
    {'1': 'STX', '2': 2},
    {'1': 'EOT', '2': 4},
    {'1': 'ACK', '2': 6},
    {'1': 'NAK', '2': 21},
    {'1': 'CAN', '2': 24},
    {'1': 'CTRLZ', '2': 26},
  ],
};

/// Descriptor for `XModem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List xModemDescriptor = $convert.base64Decode(
    'CgZYTW9kZW0SNAoHY29udHJvbBgBIAEoDjIaLm1lc2h0YXN0aWMuWE1vZGVtLkNvbnRyb2xSB2'
    'NvbnRyb2wSEAoDc2VxGAIgASgNUgNzZXESFAoFY3JjMTYYAyABKA1SBWNyYzE2EhYKBmJ1ZmZl'
    'chgEIAEoDFIGYnVmZmVyIlMKB0NvbnRyb2wSBwoDTlVMEAASBwoDU09IEAESBwoDU1RYEAISBw'
    'oDRU9UEAQSBwoDQUNLEAYSBwoDTkFLEBUSBwoDQ0FOEBgSCQoFQ1RSTFoQGg==');
