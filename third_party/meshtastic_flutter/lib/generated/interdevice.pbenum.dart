// This is a generated file - do not edit.
//
// Generated from meshtastic/interdevice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MessageType extends $pb.ProtobufEnum {
  static const MessageType ACK = MessageType._(0, _omitEnumNames ? '' : 'ACK');
  static const MessageType COLLECT_INTERVAL =
      MessageType._(160, _omitEnumNames ? '' : 'COLLECT_INTERVAL');
  static const MessageType BEEP_ON =
      MessageType._(161, _omitEnumNames ? '' : 'BEEP_ON');
  static const MessageType BEEP_OFF =
      MessageType._(162, _omitEnumNames ? '' : 'BEEP_OFF');
  static const MessageType SHUTDOWN =
      MessageType._(163, _omitEnumNames ? '' : 'SHUTDOWN');
  static const MessageType POWER_ON =
      MessageType._(164, _omitEnumNames ? '' : 'POWER_ON');
  static const MessageType SCD41_TEMP =
      MessageType._(176, _omitEnumNames ? '' : 'SCD41_TEMP');
  static const MessageType SCD41_HUMIDITY =
      MessageType._(177, _omitEnumNames ? '' : 'SCD41_HUMIDITY');
  static const MessageType SCD41_CO2 =
      MessageType._(178, _omitEnumNames ? '' : 'SCD41_CO2');
  static const MessageType AHT20_TEMP =
      MessageType._(179, _omitEnumNames ? '' : 'AHT20_TEMP');
  static const MessageType AHT20_HUMIDITY =
      MessageType._(180, _omitEnumNames ? '' : 'AHT20_HUMIDITY');
  static const MessageType TVOC_INDEX =
      MessageType._(181, _omitEnumNames ? '' : 'TVOC_INDEX');

  static const $core.List<MessageType> values = <MessageType>[
    ACK,
    COLLECT_INTERVAL,
    BEEP_ON,
    BEEP_OFF,
    SHUTDOWN,
    POWER_ON,
    SCD41_TEMP,
    SCD41_HUMIDITY,
    SCD41_CO2,
    AHT20_TEMP,
    AHT20_HUMIDITY,
    TVOC_INDEX,
  ];

  static final $core.Map<$core.int, MessageType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
