// This is a generated file - do not edit.
//
// Generated from meshtastic/portnums.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use portNumDescriptor instead')
const PortNum$json = {
  '1': 'PortNum',
  '2': [
    {'1': 'UNKNOWN_APP', '2': 0},
    {'1': 'TEXT_MESSAGE_APP', '2': 1},
    {'1': 'REMOTE_HARDWARE_APP', '2': 2},
    {'1': 'POSITION_APP', '2': 3},
    {'1': 'NODEINFO_APP', '2': 4},
    {'1': 'ROUTING_APP', '2': 5},
    {'1': 'ADMIN_APP', '2': 6},
    {'1': 'TEXT_MESSAGE_COMPRESSED_APP', '2': 7},
    {'1': 'WAYPOINT_APP', '2': 8},
    {'1': 'AUDIO_APP', '2': 9},
    {'1': 'DETECTION_SENSOR_APP', '2': 10},
    {'1': 'ALERT_APP', '2': 11},
    {'1': 'KEY_VERIFICATION_APP', '2': 12},
    {'1': 'REPLY_APP', '2': 32},
    {'1': 'IP_TUNNEL_APP', '2': 33},
    {'1': 'PAXCOUNTER_APP', '2': 34},
    {'1': 'SERIAL_APP', '2': 64},
    {'1': 'STORE_FORWARD_APP', '2': 65},
    {'1': 'RANGE_TEST_APP', '2': 66},
    {'1': 'TELEMETRY_APP', '2': 67},
    {'1': 'ZPS_APP', '2': 68},
    {'1': 'SIMULATOR_APP', '2': 69},
    {'1': 'TRACEROUTE_APP', '2': 70},
    {'1': 'NEIGHBORINFO_APP', '2': 71},
    {'1': 'ATAK_PLUGIN', '2': 72},
    {'1': 'MAP_REPORT_APP', '2': 73},
    {'1': 'POWERSTRESS_APP', '2': 74},
    {'1': 'RETICULUM_TUNNEL_APP', '2': 76},
    {'1': 'CAYENNE_APP', '2': 77},
    {'1': 'PRIVATE_APP', '2': 256},
    {'1': 'ATAK_FORWARDER', '2': 257},
    {'1': 'MAX', '2': 511},
  ],
};

/// Descriptor for `PortNum`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List portNumDescriptor = $convert.base64Decode(
    'CgdQb3J0TnVtEg8KC1VOS05PV05fQVBQEAASFAoQVEVYVF9NRVNTQUdFX0FQUBABEhcKE1JFTU'
    '9URV9IQVJEV0FSRV9BUFAQAhIQCgxQT1NJVElPTl9BUFAQAxIQCgxOT0RFSU5GT19BUFAQBBIP'
    'CgtST1VUSU5HX0FQUBAFEg0KCUFETUlOX0FQUBAGEh8KG1RFWFRfTUVTU0FHRV9DT01QUkVTU0'
    'VEX0FQUBAHEhAKDFdBWVBPSU5UX0FQUBAIEg0KCUFVRElPX0FQUBAJEhgKFERFVEVDVElPTl9T'
    'RU5TT1JfQVBQEAoSDQoJQUxFUlRfQVBQEAsSGAoUS0VZX1ZFUklGSUNBVElPTl9BUFAQDBINCg'
    'lSRVBMWV9BUFAQIBIRCg1JUF9UVU5ORUxfQVBQECESEgoOUEFYQ09VTlRFUl9BUFAQIhIOCgpT'
    'RVJJQUxfQVBQEEASFQoRU1RPUkVfRk9SV0FSRF9BUFAQQRISCg5SQU5HRV9URVNUX0FQUBBCEh'
    'EKDVRFTEVNRVRSWV9BUFAQQxILCgdaUFNfQVBQEEQSEQoNU0lNVUxBVE9SX0FQUBBFEhIKDlRS'
    'QUNFUk9VVEVfQVBQEEYSFAoQTkVJR0hCT1JJTkZPX0FQUBBHEg8KC0FUQUtfUExVR0lOEEgSEg'
    'oOTUFQX1JFUE9SVF9BUFAQSRITCg9QT1dFUlNUUkVTU19BUFAQShIYChRSRVRJQ1VMVU1fVFVO'
    'TkVMX0FQUBBMEg8KC0NBWUVOTkVfQVBQEE0SEAoLUFJJVkFURV9BUFAQgAISEwoOQVRBS19GT1'
    'JXQVJERVIQgQISCAoDTUFYEP8D');
