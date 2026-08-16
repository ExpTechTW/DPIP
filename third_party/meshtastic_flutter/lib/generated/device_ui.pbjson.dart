// This is a generated file - do not edit.
//
// Generated from meshtastic/device_ui.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use compassModeDescriptor instead')
const CompassMode$json = {
  '1': 'CompassMode',
  '2': [
    {'1': 'DYNAMIC', '2': 0},
    {'1': 'FIXED_RING', '2': 1},
    {'1': 'FREEZE_HEADING', '2': 2},
  ],
};

/// Descriptor for `CompassMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List compassModeDescriptor = $convert.base64Decode(
    'CgtDb21wYXNzTW9kZRILCgdEWU5BTUlDEAASDgoKRklYRURfUklORxABEhIKDkZSRUVaRV9IRU'
    'FESU5HEAI=');

@$core.Deprecated('Use themeDescriptor instead')
const Theme$json = {
  '1': 'Theme',
  '2': [
    {'1': 'DARK', '2': 0},
    {'1': 'LIGHT', '2': 1},
    {'1': 'RED', '2': 2},
  ],
};

/// Descriptor for `Theme`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List themeDescriptor = $convert
    .base64Decode('CgVUaGVtZRIICgREQVJLEAASCQoFTElHSFQQARIHCgNSRUQQAg==');

@$core.Deprecated('Use languageDescriptor instead')
const Language$json = {
  '1': 'Language',
  '2': [
    {'1': 'ENGLISH', '2': 0},
    {'1': 'FRENCH', '2': 1},
    {'1': 'GERMAN', '2': 2},
    {'1': 'ITALIAN', '2': 3},
    {'1': 'PORTUGUESE', '2': 4},
    {'1': 'SPANISH', '2': 5},
    {'1': 'SWEDISH', '2': 6},
    {'1': 'FINNISH', '2': 7},
    {'1': 'POLISH', '2': 8},
    {'1': 'TURKISH', '2': 9},
    {'1': 'SERBIAN', '2': 10},
    {'1': 'RUSSIAN', '2': 11},
    {'1': 'DUTCH', '2': 12},
    {'1': 'GREEK', '2': 13},
    {'1': 'NORWEGIAN', '2': 14},
    {'1': 'SLOVENIAN', '2': 15},
    {'1': 'UKRAINIAN', '2': 16},
    {'1': 'BULGARIAN', '2': 17},
    {'1': 'SIMPLIFIED_CHINESE', '2': 30},
    {'1': 'TRADITIONAL_CHINESE', '2': 31},
  ],
};

/// Descriptor for `Language`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List languageDescriptor = $convert.base64Decode(
    'CghMYW5ndWFnZRILCgdFTkdMSVNIEAASCgoGRlJFTkNIEAESCgoGR0VSTUFOEAISCwoHSVRBTE'
    'lBThADEg4KClBPUlRVR1VFU0UQBBILCgdTUEFOSVNIEAUSCwoHU1dFRElTSBAGEgsKB0ZJTk5J'
    'U0gQBxIKCgZQT0xJU0gQCBILCgdUVVJLSVNIEAkSCwoHU0VSQklBThAKEgsKB1JVU1NJQU4QCx'
    'IJCgVEVVRDSBAMEgkKBUdSRUVLEA0SDQoJTk9SV0VHSUFOEA4SDQoJU0xPVkVOSUFOEA8SDQoJ'
    'VUtSQUlOSUFOEBASDQoJQlVMR0FSSUFOEBESFgoSU0lNUExJRklFRF9DSElORVNFEB4SFwoTVF'
    'JBRElUSU9OQUxfQ0hJTkVTRRAf');

@$core.Deprecated('Use deviceUIConfigDescriptor instead')
const DeviceUIConfig$json = {
  '1': 'DeviceUIConfig',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'screen_brightness',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'screenBrightness'
    },
    {'1': 'screen_timeout', '3': 3, '4': 1, '5': 13, '10': 'screenTimeout'},
    {'1': 'screen_lock', '3': 4, '4': 1, '5': 8, '10': 'screenLock'},
    {'1': 'settings_lock', '3': 5, '4': 1, '5': 8, '10': 'settingsLock'},
    {'1': 'pin_code', '3': 6, '4': 1, '5': 13, '10': 'pinCode'},
    {
      '1': 'theme',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Theme',
      '10': 'theme'
    },
    {'1': 'alert_enabled', '3': 8, '4': 1, '5': 8, '10': 'alertEnabled'},
    {'1': 'banner_enabled', '3': 9, '4': 1, '5': 8, '10': 'bannerEnabled'},
    {'1': 'ring_tone_id', '3': 10, '4': 1, '5': 13, '10': 'ringToneId'},
    {
      '1': 'language',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Language',
      '10': 'language'
    },
    {
      '1': 'node_filter',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NodeFilter',
      '10': 'nodeFilter'
    },
    {
      '1': 'node_highlight',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NodeHighlight',
      '10': 'nodeHighlight'
    },
    {
      '1': 'calibration_data',
      '3': 14,
      '4': 1,
      '5': 12,
      '10': 'calibrationData'
    },
    {
      '1': 'map_data',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Map',
      '10': 'mapData'
    },
    {
      '1': 'compass_mode',
      '3': 16,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.CompassMode',
      '10': 'compassMode'
    },
    {'1': 'screen_rgb_color', '3': 17, '4': 1, '5': 13, '10': 'screenRgbColor'},
    {
      '1': 'is_clockface_analog',
      '3': 18,
      '4': 1,
      '5': 8,
      '10': 'isClockfaceAnalog'
    },
  ],
};

/// Descriptor for `DeviceUIConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceUIConfigDescriptor = $convert.base64Decode(
    'Cg5EZXZpY2VVSUNvbmZpZxIYCgd2ZXJzaW9uGAEgASgNUgd2ZXJzaW9uEisKEXNjcmVlbl9icm'
    'lnaHRuZXNzGAIgASgNUhBzY3JlZW5CcmlnaHRuZXNzEiUKDnNjcmVlbl90aW1lb3V0GAMgASgN'
    'Ug1zY3JlZW5UaW1lb3V0Eh8KC3NjcmVlbl9sb2NrGAQgASgIUgpzY3JlZW5Mb2NrEiMKDXNldH'
    'RpbmdzX2xvY2sYBSABKAhSDHNldHRpbmdzTG9jaxIZCghwaW5fY29kZRgGIAEoDVIHcGluQ29k'
    'ZRInCgV0aGVtZRgHIAEoDjIRLm1lc2h0YXN0aWMuVGhlbWVSBXRoZW1lEiMKDWFsZXJ0X2VuYW'
    'JsZWQYCCABKAhSDGFsZXJ0RW5hYmxlZBIlCg5iYW5uZXJfZW5hYmxlZBgJIAEoCFINYmFubmVy'
    'RW5hYmxlZBIgCgxyaW5nX3RvbmVfaWQYCiABKA1SCnJpbmdUb25lSWQSMAoIbGFuZ3VhZ2UYCy'
    'ABKA4yFC5tZXNodGFzdGljLkxhbmd1YWdlUghsYW5ndWFnZRI3Cgtub2RlX2ZpbHRlchgMIAEo'
    'CzIWLm1lc2h0YXN0aWMuTm9kZUZpbHRlclIKbm9kZUZpbHRlchJACg5ub2RlX2hpZ2hsaWdodB'
    'gNIAEoCzIZLm1lc2h0YXN0aWMuTm9kZUhpZ2hsaWdodFINbm9kZUhpZ2hsaWdodBIpChBjYWxp'
    'YnJhdGlvbl9kYXRhGA4gASgMUg9jYWxpYnJhdGlvbkRhdGESKgoIbWFwX2RhdGEYDyABKAsyDy'
    '5tZXNodGFzdGljLk1hcFIHbWFwRGF0YRI6Cgxjb21wYXNzX21vZGUYECABKA4yFy5tZXNodGFz'
    'dGljLkNvbXBhc3NNb2RlUgtjb21wYXNzTW9kZRIoChBzY3JlZW5fcmdiX2NvbG9yGBEgASgNUg'
    '5zY3JlZW5SZ2JDb2xvchIuChNpc19jbG9ja2ZhY2VfYW5hbG9nGBIgASgIUhFpc0Nsb2NrZmFj'
    'ZUFuYWxvZw==');

@$core.Deprecated('Use nodeFilterDescriptor instead')
const NodeFilter$json = {
  '1': 'NodeFilter',
  '2': [
    {'1': 'unknown_switch', '3': 1, '4': 1, '5': 8, '10': 'unknownSwitch'},
    {'1': 'offline_switch', '3': 2, '4': 1, '5': 8, '10': 'offlineSwitch'},
    {'1': 'public_key_switch', '3': 3, '4': 1, '5': 8, '10': 'publicKeySwitch'},
    {'1': 'hops_away', '3': 4, '4': 1, '5': 5, '10': 'hopsAway'},
    {'1': 'position_switch', '3': 5, '4': 1, '5': 8, '10': 'positionSwitch'},
    {'1': 'node_name', '3': 6, '4': 1, '5': 9, '10': 'nodeName'},
    {'1': 'channel', '3': 7, '4': 1, '5': 5, '10': 'channel'},
  ],
};

/// Descriptor for `NodeFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeFilterDescriptor = $convert.base64Decode(
    'CgpOb2RlRmlsdGVyEiUKDnVua25vd25fc3dpdGNoGAEgASgIUg11bmtub3duU3dpdGNoEiUKDm'
    '9mZmxpbmVfc3dpdGNoGAIgASgIUg1vZmZsaW5lU3dpdGNoEioKEXB1YmxpY19rZXlfc3dpdGNo'
    'GAMgASgIUg9wdWJsaWNLZXlTd2l0Y2gSGwoJaG9wc19hd2F5GAQgASgFUghob3BzQXdheRInCg'
    '9wb3NpdGlvbl9zd2l0Y2gYBSABKAhSDnBvc2l0aW9uU3dpdGNoEhsKCW5vZGVfbmFtZRgGIAEo'
    'CVIIbm9kZU5hbWUSGAoHY2hhbm5lbBgHIAEoBVIHY2hhbm5lbA==');

@$core.Deprecated('Use nodeHighlightDescriptor instead')
const NodeHighlight$json = {
  '1': 'NodeHighlight',
  '2': [
    {'1': 'chat_switch', '3': 1, '4': 1, '5': 8, '10': 'chatSwitch'},
    {'1': 'position_switch', '3': 2, '4': 1, '5': 8, '10': 'positionSwitch'},
    {'1': 'telemetry_switch', '3': 3, '4': 1, '5': 8, '10': 'telemetrySwitch'},
    {'1': 'iaq_switch', '3': 4, '4': 1, '5': 8, '10': 'iaqSwitch'},
    {'1': 'node_name', '3': 5, '4': 1, '5': 9, '10': 'nodeName'},
  ],
};

/// Descriptor for `NodeHighlight`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeHighlightDescriptor = $convert.base64Decode(
    'Cg1Ob2RlSGlnaGxpZ2h0Eh8KC2NoYXRfc3dpdGNoGAEgASgIUgpjaGF0U3dpdGNoEicKD3Bvc2'
    'l0aW9uX3N3aXRjaBgCIAEoCFIOcG9zaXRpb25Td2l0Y2gSKQoQdGVsZW1ldHJ5X3N3aXRjaBgD'
    'IAEoCFIPdGVsZW1ldHJ5U3dpdGNoEh0KCmlhcV9zd2l0Y2gYBCABKAhSCWlhcVN3aXRjaBIbCg'
    'lub2RlX25hbWUYBSABKAlSCG5vZGVOYW1l');

@$core.Deprecated('Use geoPointDescriptor instead')
const GeoPoint$json = {
  '1': 'GeoPoint',
  '2': [
    {'1': 'zoom', '3': 1, '4': 1, '5': 5, '10': 'zoom'},
    {'1': 'latitude', '3': 2, '4': 1, '5': 5, '10': 'latitude'},
    {'1': 'longitude', '3': 3, '4': 1, '5': 5, '10': 'longitude'},
  ],
};

/// Descriptor for `GeoPoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List geoPointDescriptor = $convert.base64Decode(
    'CghHZW9Qb2ludBISCgR6b29tGAEgASgFUgR6b29tEhoKCGxhdGl0dWRlGAIgASgFUghsYXRpdH'
    'VkZRIcCglsb25naXR1ZGUYAyABKAVSCWxvbmdpdHVkZQ==');

@$core.Deprecated('Use map_Descriptor instead')
const Map_$json = {
  '1': 'Map',
  '2': [
    {
      '1': 'home',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.GeoPoint',
      '10': 'home'
    },
    {'1': 'style', '3': 2, '4': 1, '5': 9, '10': 'style'},
    {'1': 'follow_gps', '3': 3, '4': 1, '5': 8, '10': 'followGps'},
  ],
};

/// Descriptor for `Map`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List map_Descriptor = $convert.base64Decode(
    'CgNNYXASKAoEaG9tZRgBIAEoCzIULm1lc2h0YXN0aWMuR2VvUG9pbnRSBGhvbWUSFAoFc3R5bG'
    'UYAiABKAlSBXN0eWxlEh0KCmZvbGxvd19ncHMYAyABKAhSCWZvbGxvd0dwcw==');
