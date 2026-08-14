// This is a generated file - do not edit.
//
// Generated from meshtastic/remote_hardware.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  TODO: REPLACE
class HardwareMessage_Type extends $pb.ProtobufEnum {
  ///
  ///  Unset/unused
  static const HardwareMessage_Type UNSET =
      HardwareMessage_Type._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  Set gpio gpios based on gpio_mask/gpio_value
  static const HardwareMessage_Type WRITE_GPIOS =
      HardwareMessage_Type._(1, _omitEnumNames ? '' : 'WRITE_GPIOS');

  ///
  ///  We are now interested in watching the gpio_mask gpios.
  ///  If the selected gpios change, please broadcast GPIOS_CHANGED.
  ///  Will implicitly change the gpios requested to be INPUT gpios.
  static const HardwareMessage_Type WATCH_GPIOS =
      HardwareMessage_Type._(2, _omitEnumNames ? '' : 'WATCH_GPIOS');

  ///
  ///  The gpios listed in gpio_mask have changed, the new values are listed in gpio_value
  static const HardwareMessage_Type GPIOS_CHANGED =
      HardwareMessage_Type._(3, _omitEnumNames ? '' : 'GPIOS_CHANGED');

  ///
  ///  Read the gpios specified in gpio_mask, send back a READ_GPIOS_REPLY reply with gpio_value populated
  static const HardwareMessage_Type READ_GPIOS =
      HardwareMessage_Type._(4, _omitEnumNames ? '' : 'READ_GPIOS');

  ///
  ///  A reply to READ_GPIOS. gpio_mask and gpio_value will be populated
  static const HardwareMessage_Type READ_GPIOS_REPLY =
      HardwareMessage_Type._(5, _omitEnumNames ? '' : 'READ_GPIOS_REPLY');

  static const $core.List<HardwareMessage_Type> values = <HardwareMessage_Type>[
    UNSET,
    WRITE_GPIOS,
    WATCH_GPIOS,
    GPIOS_CHANGED,
    READ_GPIOS,
    READ_GPIOS_REPLY,
  ];

  static final $core.List<HardwareMessage_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static HardwareMessage_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HardwareMessage_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
