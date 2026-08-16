// This is a generated file - do not edit.
//
// Generated from meshtastic/powermon.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Any significant power changing event in meshtastic should be tagged with a powermon state transition.
/// If you are making new meshtastic features feel free to add new entries at the end of this definition.
class PowerMon_State extends $pb.ProtobufEnum {
  static const PowerMon_State None =
      PowerMon_State._(0, _omitEnumNames ? '' : 'None');
  static const PowerMon_State CPU_DeepSleep =
      PowerMon_State._(1, _omitEnumNames ? '' : 'CPU_DeepSleep');
  static const PowerMon_State CPU_LightSleep =
      PowerMon_State._(2, _omitEnumNames ? '' : 'CPU_LightSleep');

  ///
  /// The external Vext1 power is on.  Many boards have auxillary power rails that the CPU turns on only
  /// occasionally.  In cases where that rail has multiple devices on it we usually want to have logging on
  /// the state of that rail as an independent record.
  /// For instance on the Heltec Tracker 1.1 board, this rail is the power source for the GPS and screen.
  ///
  /// The log messages will be short and complete (see PowerMon.Event in the protobufs for details).
  /// something like "S:PM:C,0x00001234,REASON" where the hex number is the bitmask of all current states.
  /// (We use a bitmask for states so that if a log message gets lost it won't be fatal)
  static const PowerMon_State Vext1_On =
      PowerMon_State._(4, _omitEnumNames ? '' : 'Vext1_On');
  static const PowerMon_State Lora_RXOn =
      PowerMon_State._(8, _omitEnumNames ? '' : 'Lora_RXOn');
  static const PowerMon_State Lora_TXOn =
      PowerMon_State._(16, _omitEnumNames ? '' : 'Lora_TXOn');
  static const PowerMon_State Lora_RXActive =
      PowerMon_State._(32, _omitEnumNames ? '' : 'Lora_RXActive');
  static const PowerMon_State BT_On =
      PowerMon_State._(64, _omitEnumNames ? '' : 'BT_On');
  static const PowerMon_State LED_On =
      PowerMon_State._(128, _omitEnumNames ? '' : 'LED_On');
  static const PowerMon_State Screen_On =
      PowerMon_State._(256, _omitEnumNames ? '' : 'Screen_On');
  static const PowerMon_State Screen_Drawing =
      PowerMon_State._(512, _omitEnumNames ? '' : 'Screen_Drawing');
  static const PowerMon_State Wifi_On =
      PowerMon_State._(1024, _omitEnumNames ? '' : 'Wifi_On');

  ///
  ///  GPS is actively trying to find our location
  ///  See GPSPowerState for more details
  static const PowerMon_State GPS_Active =
      PowerMon_State._(2048, _omitEnumNames ? '' : 'GPS_Active');

  static const $core.List<PowerMon_State> values = <PowerMon_State>[
    None,
    CPU_DeepSleep,
    CPU_LightSleep,
    Vext1_On,
    Lora_RXOn,
    Lora_TXOn,
    Lora_RXActive,
    BT_On,
    LED_On,
    Screen_On,
    Screen_Drawing,
    Wifi_On,
    GPS_Active,
  ];

  static final $core.Map<$core.int, PowerMon_State> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static PowerMon_State? valueOf($core.int value) => _byValue[value];

  const PowerMon_State._(super.value, super.name);
}

///
///  What operation would we like the UUT to perform.
///  note: senders should probably set want_response in their request packets, so that they can know when the state
///  machine has started processing their request
class PowerStressMessage_Opcode extends $pb.ProtobufEnum {
  ///
  ///  Unset/unused
  static const PowerStressMessage_Opcode UNSET =
      PowerStressMessage_Opcode._(0, _omitEnumNames ? '' : 'UNSET');
  static const PowerStressMessage_Opcode PRINT_INFO =
      PowerStressMessage_Opcode._(1, _omitEnumNames ? '' : 'PRINT_INFO');
  static const PowerStressMessage_Opcode FORCE_QUIET =
      PowerStressMessage_Opcode._(2, _omitEnumNames ? '' : 'FORCE_QUIET');
  static const PowerStressMessage_Opcode END_QUIET =
      PowerStressMessage_Opcode._(3, _omitEnumNames ? '' : 'END_QUIET');
  static const PowerStressMessage_Opcode SCREEN_ON =
      PowerStressMessage_Opcode._(16, _omitEnumNames ? '' : 'SCREEN_ON');
  static const PowerStressMessage_Opcode SCREEN_OFF =
      PowerStressMessage_Opcode._(17, _omitEnumNames ? '' : 'SCREEN_OFF');
  static const PowerStressMessage_Opcode CPU_IDLE =
      PowerStressMessage_Opcode._(32, _omitEnumNames ? '' : 'CPU_IDLE');
  static const PowerStressMessage_Opcode CPU_DEEPSLEEP =
      PowerStressMessage_Opcode._(33, _omitEnumNames ? '' : 'CPU_DEEPSLEEP');
  static const PowerStressMessage_Opcode CPU_FULLON =
      PowerStressMessage_Opcode._(34, _omitEnumNames ? '' : 'CPU_FULLON');
  static const PowerStressMessage_Opcode LED_ON =
      PowerStressMessage_Opcode._(48, _omitEnumNames ? '' : 'LED_ON');
  static const PowerStressMessage_Opcode LED_OFF =
      PowerStressMessage_Opcode._(49, _omitEnumNames ? '' : 'LED_OFF');
  static const PowerStressMessage_Opcode LORA_OFF =
      PowerStressMessage_Opcode._(64, _omitEnumNames ? '' : 'LORA_OFF');
  static const PowerStressMessage_Opcode LORA_TX =
      PowerStressMessage_Opcode._(65, _omitEnumNames ? '' : 'LORA_TX');
  static const PowerStressMessage_Opcode LORA_RX =
      PowerStressMessage_Opcode._(66, _omitEnumNames ? '' : 'LORA_RX');
  static const PowerStressMessage_Opcode BT_OFF =
      PowerStressMessage_Opcode._(80, _omitEnumNames ? '' : 'BT_OFF');
  static const PowerStressMessage_Opcode BT_ON =
      PowerStressMessage_Opcode._(81, _omitEnumNames ? '' : 'BT_ON');
  static const PowerStressMessage_Opcode WIFI_OFF =
      PowerStressMessage_Opcode._(96, _omitEnumNames ? '' : 'WIFI_OFF');
  static const PowerStressMessage_Opcode WIFI_ON =
      PowerStressMessage_Opcode._(97, _omitEnumNames ? '' : 'WIFI_ON');
  static const PowerStressMessage_Opcode GPS_OFF =
      PowerStressMessage_Opcode._(112, _omitEnumNames ? '' : 'GPS_OFF');
  static const PowerStressMessage_Opcode GPS_ON =
      PowerStressMessage_Opcode._(113, _omitEnumNames ? '' : 'GPS_ON');

  static const $core.List<PowerStressMessage_Opcode> values =
      <PowerStressMessage_Opcode>[
    UNSET,
    PRINT_INFO,
    FORCE_QUIET,
    END_QUIET,
    SCREEN_ON,
    SCREEN_OFF,
    CPU_IDLE,
    CPU_DEEPSLEEP,
    CPU_FULLON,
    LED_ON,
    LED_OFF,
    LORA_OFF,
    LORA_TX,
    LORA_RX,
    BT_OFF,
    BT_ON,
    WIFI_OFF,
    WIFI_ON,
    GPS_OFF,
    GPS_ON,
  ];

  static final $core.Map<$core.int, PowerStressMessage_Opcode> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static PowerStressMessage_Opcode? valueOf($core.int value) => _byValue[value];

  const PowerStressMessage_Opcode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
