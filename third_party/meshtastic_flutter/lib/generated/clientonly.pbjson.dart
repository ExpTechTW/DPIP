// This is a generated file - do not edit.
//
// Generated from meshtastic/clientonly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use deviceProfileDescriptor instead')
const DeviceProfile$json = {
  '1': 'DeviceProfile',
  '2': [
    {
      '1': 'long_name',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'longName',
      '17': true
    },
    {
      '1': 'short_name',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'shortName',
      '17': true
    },
    {
      '1': 'channel_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'channelUrl',
      '17': true
    },
    {
      '1': 'config',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.LocalConfig',
      '9': 3,
      '10': 'config',
      '17': true
    },
    {
      '1': 'module_config',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.LocalModuleConfig',
      '9': 4,
      '10': 'moduleConfig',
      '17': true
    },
    {
      '1': 'fixed_position',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Position',
      '9': 5,
      '10': 'fixedPosition',
      '17': true
    },
    {
      '1': 'ringtone',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'ringtone',
      '17': true
    },
    {
      '1': 'canned_messages',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'cannedMessages',
      '17': true
    },
  ],
  '8': [
    {'1': '_long_name'},
    {'1': '_short_name'},
    {'1': '_channel_url'},
    {'1': '_config'},
    {'1': '_module_config'},
    {'1': '_fixed_position'},
    {'1': '_ringtone'},
    {'1': '_canned_messages'},
  ],
};

/// Descriptor for `DeviceProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceProfileDescriptor = $convert.base64Decode(
    'Cg1EZXZpY2VQcm9maWxlEiAKCWxvbmdfbmFtZRgBIAEoCUgAUghsb25nTmFtZYgBARIiCgpzaG'
    '9ydF9uYW1lGAIgASgJSAFSCXNob3J0TmFtZYgBARIkCgtjaGFubmVsX3VybBgDIAEoCUgCUgpj'
    'aGFubmVsVXJsiAEBEjQKBmNvbmZpZxgEIAEoCzIXLm1lc2h0YXN0aWMuTG9jYWxDb25maWdIA1'
    'IGY29uZmlniAEBEkcKDW1vZHVsZV9jb25maWcYBSABKAsyHS5tZXNodGFzdGljLkxvY2FsTW9k'
    'dWxlQ29uZmlnSARSDG1vZHVsZUNvbmZpZ4gBARJACg5maXhlZF9wb3NpdGlvbhgGIAEoCzIULm'
    '1lc2h0YXN0aWMuUG9zaXRpb25IBVINZml4ZWRQb3NpdGlvbogBARIfCghyaW5ndG9uZRgHIAEo'
    'CUgGUghyaW5ndG9uZYgBARIsCg9jYW5uZWRfbWVzc2FnZXMYCCABKAlIB1IOY2FubmVkTWVzc2'
    'FnZXOIAQFCDAoKX2xvbmdfbmFtZUINCgtfc2hvcnRfbmFtZUIOCgxfY2hhbm5lbF91cmxCCQoH'
    'X2NvbmZpZ0IQCg5fbW9kdWxlX2NvbmZpZ0IRCg9fZml4ZWRfcG9zaXRpb25CCwoJX3Jpbmd0b2'
    '5lQhIKEF9jYW5uZWRfbWVzc2FnZXM=');
