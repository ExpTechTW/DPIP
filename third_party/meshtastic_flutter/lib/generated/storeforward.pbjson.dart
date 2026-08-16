// This is a generated file - do not edit.
//
// Generated from meshtastic/storeforward.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use storeAndForwardDescriptor instead')
const StoreAndForward$json = {
  '1': 'StoreAndForward',
  '2': [
    {
      '1': 'rr',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.StoreAndForward.RequestResponse',
      '10': 'rr'
    },
    {
      '1': 'stats',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.StoreAndForward.Statistics',
      '9': 0,
      '10': 'stats'
    },
    {
      '1': 'history',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.StoreAndForward.History',
      '9': 0,
      '10': 'history'
    },
    {
      '1': 'heartbeat',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.StoreAndForward.Heartbeat',
      '9': 0,
      '10': 'heartbeat'
    },
    {'1': 'text', '3': 5, '4': 1, '5': 12, '9': 0, '10': 'text'},
  ],
  '3': [
    StoreAndForward_Statistics$json,
    StoreAndForward_History$json,
    StoreAndForward_Heartbeat$json
  ],
  '4': [StoreAndForward_RequestResponse$json],
  '8': [
    {'1': 'variant'},
  ],
};

@$core.Deprecated('Use storeAndForwardDescriptor instead')
const StoreAndForward_Statistics$json = {
  '1': 'Statistics',
  '2': [
    {'1': 'messages_total', '3': 1, '4': 1, '5': 13, '10': 'messagesTotal'},
    {'1': 'messages_saved', '3': 2, '4': 1, '5': 13, '10': 'messagesSaved'},
    {'1': 'messages_max', '3': 3, '4': 1, '5': 13, '10': 'messagesMax'},
    {'1': 'up_time', '3': 4, '4': 1, '5': 13, '10': 'upTime'},
    {'1': 'requests', '3': 5, '4': 1, '5': 13, '10': 'requests'},
    {'1': 'requests_history', '3': 6, '4': 1, '5': 13, '10': 'requestsHistory'},
    {'1': 'heartbeat', '3': 7, '4': 1, '5': 8, '10': 'heartbeat'},
    {'1': 'return_max', '3': 8, '4': 1, '5': 13, '10': 'returnMax'},
    {'1': 'return_window', '3': 9, '4': 1, '5': 13, '10': 'returnWindow'},
  ],
};

@$core.Deprecated('Use storeAndForwardDescriptor instead')
const StoreAndForward_History$json = {
  '1': 'History',
  '2': [
    {'1': 'history_messages', '3': 1, '4': 1, '5': 13, '10': 'historyMessages'},
    {'1': 'window', '3': 2, '4': 1, '5': 13, '10': 'window'},
    {'1': 'last_request', '3': 3, '4': 1, '5': 13, '10': 'lastRequest'},
  ],
};

@$core.Deprecated('Use storeAndForwardDescriptor instead')
const StoreAndForward_Heartbeat$json = {
  '1': 'Heartbeat',
  '2': [
    {'1': 'period', '3': 1, '4': 1, '5': 13, '10': 'period'},
    {'1': 'secondary', '3': 2, '4': 1, '5': 13, '10': 'secondary'},
  ],
};

@$core.Deprecated('Use storeAndForwardDescriptor instead')
const StoreAndForward_RequestResponse$json = {
  '1': 'RequestResponse',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'ROUTER_ERROR', '2': 1},
    {'1': 'ROUTER_HEARTBEAT', '2': 2},
    {'1': 'ROUTER_PING', '2': 3},
    {'1': 'ROUTER_PONG', '2': 4},
    {'1': 'ROUTER_BUSY', '2': 5},
    {'1': 'ROUTER_HISTORY', '2': 6},
    {'1': 'ROUTER_STATS', '2': 7},
    {'1': 'ROUTER_TEXT_DIRECT', '2': 8},
    {'1': 'ROUTER_TEXT_BROADCAST', '2': 9},
    {'1': 'CLIENT_ERROR', '2': 64},
    {'1': 'CLIENT_HISTORY', '2': 65},
    {'1': 'CLIENT_STATS', '2': 66},
    {'1': 'CLIENT_PING', '2': 67},
    {'1': 'CLIENT_PONG', '2': 68},
    {'1': 'CLIENT_ABORT', '2': 106},
  ],
};

/// Descriptor for `StoreAndForward`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storeAndForwardDescriptor = $convert.base64Decode(
    'Cg9TdG9yZUFuZEZvcndhcmQSOwoCcnIYASABKA4yKy5tZXNodGFzdGljLlN0b3JlQW5kRm9yd2'
    'FyZC5SZXF1ZXN0UmVzcG9uc2VSAnJyEj4KBXN0YXRzGAIgASgLMiYubWVzaHRhc3RpYy5TdG9y'
    'ZUFuZEZvcndhcmQuU3RhdGlzdGljc0gAUgVzdGF0cxI/CgdoaXN0b3J5GAMgASgLMiMubWVzaH'
    'Rhc3RpYy5TdG9yZUFuZEZvcndhcmQuSGlzdG9yeUgAUgdoaXN0b3J5EkUKCWhlYXJ0YmVhdBgE'
    'IAEoCzIlLm1lc2h0YXN0aWMuU3RvcmVBbmRGb3J3YXJkLkhlYXJ0YmVhdEgAUgloZWFydGJlYX'
    'QSFAoEdGV4dBgFIAEoDEgAUgR0ZXh0Gr8CCgpTdGF0aXN0aWNzEiUKDm1lc3NhZ2VzX3RvdGFs'
    'GAEgASgNUg1tZXNzYWdlc1RvdGFsEiUKDm1lc3NhZ2VzX3NhdmVkGAIgASgNUg1tZXNzYWdlc1'
    'NhdmVkEiEKDG1lc3NhZ2VzX21heBgDIAEoDVILbWVzc2FnZXNNYXgSFwoHdXBfdGltZRgEIAEo'
    'DVIGdXBUaW1lEhoKCHJlcXVlc3RzGAUgASgNUghyZXF1ZXN0cxIpChByZXF1ZXN0c19oaXN0b3'
    'J5GAYgASgNUg9yZXF1ZXN0c0hpc3RvcnkSHAoJaGVhcnRiZWF0GAcgASgIUgloZWFydGJlYXQS'
    'HQoKcmV0dXJuX21heBgIIAEoDVIJcmV0dXJuTWF4EiMKDXJldHVybl93aW5kb3cYCSABKA1SDH'
    'JldHVybldpbmRvdxpvCgdIaXN0b3J5EikKEGhpc3RvcnlfbWVzc2FnZXMYASABKA1SD2hpc3Rv'
    'cnlNZXNzYWdlcxIWCgZ3aW5kb3cYAiABKA1SBndpbmRvdxIhCgxsYXN0X3JlcXVlc3QYAyABKA'
    '1SC2xhc3RSZXF1ZXN0GkEKCUhlYXJ0YmVhdBIWCgZwZXJpb2QYASABKA1SBnBlcmlvZBIcCglz'
    'ZWNvbmRhcnkYAiABKA1SCXNlY29uZGFyeSK8AgoPUmVxdWVzdFJlc3BvbnNlEgkKBVVOU0VUEA'
    'ASEAoMUk9VVEVSX0VSUk9SEAESFAoQUk9VVEVSX0hFQVJUQkVBVBACEg8KC1JPVVRFUl9QSU5H'
    'EAMSDwoLUk9VVEVSX1BPTkcQBBIPCgtST1VURVJfQlVTWRAFEhIKDlJPVVRFUl9ISVNUT1JZEA'
    'YSEAoMUk9VVEVSX1NUQVRTEAcSFgoSUk9VVEVSX1RFWFRfRElSRUNUEAgSGQoVUk9VVEVSX1RF'
    'WFRfQlJPQURDQVNUEAkSEAoMQ0xJRU5UX0VSUk9SEEASEgoOQ0xJRU5UX0hJU1RPUlkQQRIQCg'
    'xDTElFTlRfU1RBVFMQQhIPCgtDTElFTlRfUElORxBDEg8KC0NMSUVOVF9QT05HEEQSEAoMQ0xJ'
    'RU5UX0FCT1JUEGpCCQoHdmFyaWFudA==');
