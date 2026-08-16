// This is a generated file - do not edit.
//
// Generated from meshtastic/xmodem.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class XModem_Control extends $pb.ProtobufEnum {
  static const XModem_Control NUL =
      XModem_Control._(0, _omitEnumNames ? '' : 'NUL');
  static const XModem_Control SOH =
      XModem_Control._(1, _omitEnumNames ? '' : 'SOH');
  static const XModem_Control STX =
      XModem_Control._(2, _omitEnumNames ? '' : 'STX');
  static const XModem_Control EOT =
      XModem_Control._(4, _omitEnumNames ? '' : 'EOT');
  static const XModem_Control ACK =
      XModem_Control._(6, _omitEnumNames ? '' : 'ACK');
  static const XModem_Control NAK =
      XModem_Control._(21, _omitEnumNames ? '' : 'NAK');
  static const XModem_Control CAN =
      XModem_Control._(24, _omitEnumNames ? '' : 'CAN');
  static const XModem_Control CTRLZ =
      XModem_Control._(26, _omitEnumNames ? '' : 'CTRLZ');

  static const $core.List<XModem_Control> values = <XModem_Control>[
    NUL,
    SOH,
    STX,
    EOT,
    ACK,
    NAK,
    CAN,
    CTRLZ,
  ];

  static final $core.Map<$core.int, XModem_Control> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static XModem_Control? valueOf($core.int value) => _byValue[value];

  const XModem_Control._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
