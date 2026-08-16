// This is a generated file - do not edit.
//
// Generated from meshtastic/admin.proto.

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
class AdminMessage_ConfigType extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType DEVICE_CONFIG =
      AdminMessage_ConfigType._(0, _omitEnumNames ? '' : 'DEVICE_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType POSITION_CONFIG =
      AdminMessage_ConfigType._(1, _omitEnumNames ? '' : 'POSITION_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType POWER_CONFIG =
      AdminMessage_ConfigType._(2, _omitEnumNames ? '' : 'POWER_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType NETWORK_CONFIG =
      AdminMessage_ConfigType._(3, _omitEnumNames ? '' : 'NETWORK_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType DISPLAY_CONFIG =
      AdminMessage_ConfigType._(4, _omitEnumNames ? '' : 'DISPLAY_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType LORA_CONFIG =
      AdminMessage_ConfigType._(5, _omitEnumNames ? '' : 'LORA_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType BLUETOOTH_CONFIG =
      AdminMessage_ConfigType._(6, _omitEnumNames ? '' : 'BLUETOOTH_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ConfigType SECURITY_CONFIG =
      AdminMessage_ConfigType._(7, _omitEnumNames ? '' : 'SECURITY_CONFIG');

  ///
  ///  Session key config
  static const AdminMessage_ConfigType SESSIONKEY_CONFIG =
      AdminMessage_ConfigType._(8, _omitEnumNames ? '' : 'SESSIONKEY_CONFIG');

  ///
  ///  device-ui config
  static const AdminMessage_ConfigType DEVICEUI_CONFIG =
      AdminMessage_ConfigType._(9, _omitEnumNames ? '' : 'DEVICEUI_CONFIG');

  static const $core.List<AdminMessage_ConfigType> values =
      <AdminMessage_ConfigType>[
    DEVICE_CONFIG,
    POSITION_CONFIG,
    POWER_CONFIG,
    NETWORK_CONFIG,
    DISPLAY_CONFIG,
    LORA_CONFIG,
    BLUETOOTH_CONFIG,
    SECURITY_CONFIG,
    SESSIONKEY_CONFIG,
    DEVICEUI_CONFIG,
  ];

  static final $core.List<AdminMessage_ConfigType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static AdminMessage_ConfigType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdminMessage_ConfigType._(super.value, super.name);
}

///
///  TODO: REPLACE
class AdminMessage_ModuleConfigType extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType MQTT_CONFIG =
      AdminMessage_ModuleConfigType._(0, _omitEnumNames ? '' : 'MQTT_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType SERIAL_CONFIG =
      AdminMessage_ModuleConfigType._(1, _omitEnumNames ? '' : 'SERIAL_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType EXTNOTIF_CONFIG =
      AdminMessage_ModuleConfigType._(
          2, _omitEnumNames ? '' : 'EXTNOTIF_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType STOREFORWARD_CONFIG =
      AdminMessage_ModuleConfigType._(
          3, _omitEnumNames ? '' : 'STOREFORWARD_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType RANGETEST_CONFIG =
      AdminMessage_ModuleConfigType._(
          4, _omitEnumNames ? '' : 'RANGETEST_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType TELEMETRY_CONFIG =
      AdminMessage_ModuleConfigType._(
          5, _omitEnumNames ? '' : 'TELEMETRY_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType CANNEDMSG_CONFIG =
      AdminMessage_ModuleConfigType._(
          6, _omitEnumNames ? '' : 'CANNEDMSG_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType AUDIO_CONFIG =
      AdminMessage_ModuleConfigType._(7, _omitEnumNames ? '' : 'AUDIO_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType REMOTEHARDWARE_CONFIG =
      AdminMessage_ModuleConfigType._(
          8, _omitEnumNames ? '' : 'REMOTEHARDWARE_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType NEIGHBORINFO_CONFIG =
      AdminMessage_ModuleConfigType._(
          9, _omitEnumNames ? '' : 'NEIGHBORINFO_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType AMBIENTLIGHTING_CONFIG =
      AdminMessage_ModuleConfigType._(
          10, _omitEnumNames ? '' : 'AMBIENTLIGHTING_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType DETECTIONSENSOR_CONFIG =
      AdminMessage_ModuleConfigType._(
          11, _omitEnumNames ? '' : 'DETECTIONSENSOR_CONFIG');

  ///
  ///  TODO: REPLACE
  static const AdminMessage_ModuleConfigType PAXCOUNTER_CONFIG =
      AdminMessage_ModuleConfigType._(
          12, _omitEnumNames ? '' : 'PAXCOUNTER_CONFIG');

  static const $core.List<AdminMessage_ModuleConfigType> values =
      <AdminMessage_ModuleConfigType>[
    MQTT_CONFIG,
    SERIAL_CONFIG,
    EXTNOTIF_CONFIG,
    STOREFORWARD_CONFIG,
    RANGETEST_CONFIG,
    TELEMETRY_CONFIG,
    CANNEDMSG_CONFIG,
    AUDIO_CONFIG,
    REMOTEHARDWARE_CONFIG,
    NEIGHBORINFO_CONFIG,
    AMBIENTLIGHTING_CONFIG,
    DETECTIONSENSOR_CONFIG,
    PAXCOUNTER_CONFIG,
  ];

  static final $core.List<AdminMessage_ModuleConfigType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static AdminMessage_ModuleConfigType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdminMessage_ModuleConfigType._(super.value, super.name);
}

class AdminMessage_BackupLocation extends $pb.ProtobufEnum {
  ///
  ///  Backup to the internal flash
  static const AdminMessage_BackupLocation FLASH =
      AdminMessage_BackupLocation._(0, _omitEnumNames ? '' : 'FLASH');

  ///
  ///  Backup to the SD card
  static const AdminMessage_BackupLocation SD =
      AdminMessage_BackupLocation._(1, _omitEnumNames ? '' : 'SD');

  static const $core.List<AdminMessage_BackupLocation> values =
      <AdminMessage_BackupLocation>[
    FLASH,
    SD,
  ];

  static final $core.List<AdminMessage_BackupLocation?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static AdminMessage_BackupLocation? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdminMessage_BackupLocation._(super.value, super.name);
}

///
///  Three stages of this request.
class KeyVerificationAdmin_MessageType extends $pb.ProtobufEnum {
  ///
  ///  This is the first stage, where a client initiates
  static const KeyVerificationAdmin_MessageType INITIATE_VERIFICATION =
      KeyVerificationAdmin_MessageType._(
          0, _omitEnumNames ? '' : 'INITIATE_VERIFICATION');

  ///
  ///  After the nonce has been returned over the mesh, the client prompts for the security number
  ///  And uses this message to provide it to the node.
  static const KeyVerificationAdmin_MessageType PROVIDE_SECURITY_NUMBER =
      KeyVerificationAdmin_MessageType._(
          1, _omitEnumNames ? '' : 'PROVIDE_SECURITY_NUMBER');

  ///
  ///  Once the user has compared the verification message, this message notifies the node.
  static const KeyVerificationAdmin_MessageType DO_VERIFY =
      KeyVerificationAdmin_MessageType._(2, _omitEnumNames ? '' : 'DO_VERIFY');

  ///
  ///  This is the cancel path, can be taken at any point
  static const KeyVerificationAdmin_MessageType DO_NOT_VERIFY =
      KeyVerificationAdmin_MessageType._(
          3, _omitEnumNames ? '' : 'DO_NOT_VERIFY');

  static const $core.List<KeyVerificationAdmin_MessageType> values =
      <KeyVerificationAdmin_MessageType>[
    INITIATE_VERIFICATION,
    PROVIDE_SECURITY_NUMBER,
    DO_VERIFY,
    DO_NOT_VERIFY,
  ];

  static final $core.List<KeyVerificationAdmin_MessageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static KeyVerificationAdmin_MessageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KeyVerificationAdmin_MessageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
