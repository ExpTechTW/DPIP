// This is a generated file - do not edit.
//
// Generated from meshtastic/atak.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use teamDescriptor instead')
const Team$json = {
  '1': 'Team',
  '2': [
    {'1': 'Unspecifed_Color', '2': 0},
    {'1': 'White', '2': 1},
    {'1': 'Yellow', '2': 2},
    {'1': 'Orange', '2': 3},
    {'1': 'Magenta', '2': 4},
    {'1': 'Red', '2': 5},
    {'1': 'Maroon', '2': 6},
    {'1': 'Purple', '2': 7},
    {'1': 'Dark_Blue', '2': 8},
    {'1': 'Blue', '2': 9},
    {'1': 'Cyan', '2': 10},
    {'1': 'Teal', '2': 11},
    {'1': 'Green', '2': 12},
    {'1': 'Dark_Green', '2': 13},
    {'1': 'Brown', '2': 14},
  ],
};

/// Descriptor for `Team`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List teamDescriptor = $convert.base64Decode(
    'CgRUZWFtEhQKEFVuc3BlY2lmZWRfQ29sb3IQABIJCgVXaGl0ZRABEgoKBlllbGxvdxACEgoKBk'
    '9yYW5nZRADEgsKB01hZ2VudGEQBBIHCgNSZWQQBRIKCgZNYXJvb24QBhIKCgZQdXJwbGUQBxIN'
    'CglEYXJrX0JsdWUQCBIICgRCbHVlEAkSCAoEQ3lhbhAKEggKBFRlYWwQCxIJCgVHcmVlbhAMEg'
    '4KCkRhcmtfR3JlZW4QDRIJCgVCcm93bhAO');

@$core.Deprecated('Use memberRoleDescriptor instead')
const MemberRole$json = {
  '1': 'MemberRole',
  '2': [
    {'1': 'Unspecifed', '2': 0},
    {'1': 'TeamMember', '2': 1},
    {'1': 'TeamLead', '2': 2},
    {'1': 'HQ', '2': 3},
    {'1': 'Sniper', '2': 4},
    {'1': 'Medic', '2': 5},
    {'1': 'ForwardObserver', '2': 6},
    {'1': 'RTO', '2': 7},
    {'1': 'K9', '2': 8},
  ],
};

/// Descriptor for `MemberRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List memberRoleDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJSb2xlEg4KClVuc3BlY2lmZWQQABIOCgpUZWFtTWVtYmVyEAESDAoIVGVhbUxlYW'
    'QQAhIGCgJIURADEgoKBlNuaXBlchAEEgkKBU1lZGljEAUSEwoPRm9yd2FyZE9ic2VydmVyEAYS'
    'BwoDUlRPEAcSBgoCSzkQCA==');

@$core.Deprecated('Use tAKPacketDescriptor instead')
const TAKPacket$json = {
  '1': 'TAKPacket',
  '2': [
    {'1': 'is_compressed', '3': 1, '4': 1, '5': 8, '10': 'isCompressed'},
    {
      '1': 'contact',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Contact',
      '10': 'contact'
    },
    {
      '1': 'group',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Group',
      '10': 'group'
    },
    {
      '1': 'status',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Status',
      '10': 'status'
    },
    {
      '1': 'pli',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.PLI',
      '9': 0,
      '10': 'pli'
    },
    {
      '1': 'chat',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.GeoChat',
      '9': 0,
      '10': 'chat'
    },
    {'1': 'detail', '3': 7, '4': 1, '5': 12, '9': 0, '10': 'detail'},
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

/// Descriptor for `TAKPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tAKPacketDescriptor = $convert.base64Decode(
    'CglUQUtQYWNrZXQSIwoNaXNfY29tcHJlc3NlZBgBIAEoCFIMaXNDb21wcmVzc2VkEi0KB2Nvbn'
    'RhY3QYAiABKAsyEy5tZXNodGFzdGljLkNvbnRhY3RSB2NvbnRhY3QSJwoFZ3JvdXAYAyABKAsy'
    'ES5tZXNodGFzdGljLkdyb3VwUgVncm91cBIqCgZzdGF0dXMYBCABKAsyEi5tZXNodGFzdGljLl'
    'N0YXR1c1IGc3RhdHVzEiMKA3BsaRgFIAEoCzIPLm1lc2h0YXN0aWMuUExJSABSA3BsaRIpCgRj'
    'aGF0GAYgASgLMhMubWVzaHRhc3RpYy5HZW9DaGF0SABSBGNoYXQSGAoGZGV0YWlsGAcgASgMSA'
    'BSBmRldGFpbEIRCg9wYXlsb2FkX3ZhcmlhbnQ=');

@$core.Deprecated('Use geoChatDescriptor instead')
const GeoChat$json = {
  '1': 'GeoChat',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'to', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'to', '17': true},
    {
      '1': 'to_callsign',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'toCallsign',
      '17': true
    },
  ],
  '8': [
    {'1': '_to'},
    {'1': '_to_callsign'},
  ],
};

/// Descriptor for `GeoChat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List geoChatDescriptor = $convert.base64Decode(
    'CgdHZW9DaGF0EhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2USEwoCdG8YAiABKAlIAFICdG+IAQ'
    'ESJAoLdG9fY2FsbHNpZ24YAyABKAlIAVIKdG9DYWxsc2lnbogBAUIFCgNfdG9CDgoMX3RvX2Nh'
    'bGxzaWdu');

@$core.Deprecated('Use groupDescriptor instead')
const Group$json = {
  '1': 'Group',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.MemberRole',
      '10': 'role'
    },
    {
      '1': 'team',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Team',
      '10': 'team'
    },
  ],
};

/// Descriptor for `Group`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDescriptor = $convert.base64Decode(
    'CgVHcm91cBIqCgRyb2xlGAEgASgOMhYubWVzaHRhc3RpYy5NZW1iZXJSb2xlUgRyb2xlEiQKBH'
    'RlYW0YAiABKA4yEC5tZXNodGFzdGljLlRlYW1SBHRlYW0=');

@$core.Deprecated('Use statusDescriptor instead')
const Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'battery', '3': 1, '4': 1, '5': 13, '10': 'battery'},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDescriptor =
    $convert.base64Decode('CgZTdGF0dXMSGAoHYmF0dGVyeRgBIAEoDVIHYmF0dGVyeQ==');

@$core.Deprecated('Use contactDescriptor instead')
const Contact$json = {
  '1': 'Contact',
  '2': [
    {'1': 'callsign', '3': 1, '4': 1, '5': 9, '10': 'callsign'},
    {'1': 'device_callsign', '3': 2, '4': 1, '5': 9, '10': 'deviceCallsign'},
  ],
};

/// Descriptor for `Contact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contactDescriptor = $convert.base64Decode(
    'CgdDb250YWN0EhoKCGNhbGxzaWduGAEgASgJUghjYWxsc2lnbhInCg9kZXZpY2VfY2FsbHNpZ2'
    '4YAiABKAlSDmRldmljZUNhbGxzaWdu');

@$core.Deprecated('Use pLIDescriptor instead')
const PLI$json = {
  '1': 'PLI',
  '2': [
    {'1': 'latitude_i', '3': 1, '4': 1, '5': 15, '10': 'latitudeI'},
    {'1': 'longitude_i', '3': 2, '4': 1, '5': 15, '10': 'longitudeI'},
    {'1': 'altitude', '3': 3, '4': 1, '5': 5, '10': 'altitude'},
    {'1': 'speed', '3': 4, '4': 1, '5': 13, '10': 'speed'},
    {'1': 'course', '3': 5, '4': 1, '5': 13, '10': 'course'},
  ],
};

/// Descriptor for `PLI`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pLIDescriptor = $convert.base64Decode(
    'CgNQTEkSHQoKbGF0aXR1ZGVfaRgBIAEoD1IJbGF0aXR1ZGVJEh8KC2xvbmdpdHVkZV9pGAIgAS'
    'gPUgpsb25naXR1ZGVJEhoKCGFsdGl0dWRlGAMgASgFUghhbHRpdHVkZRIUCgVzcGVlZBgEIAEo'
    'DVIFc3BlZWQSFgoGY291cnNlGAUgASgNUgZjb3Vyc2U=');
