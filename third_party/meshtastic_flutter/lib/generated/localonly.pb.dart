// This is a generated file - do not edit.
//
// Generated from meshtastic/localonly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'config.pb.dart' as $0;
import 'module_config.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LocalConfig extends $pb.GeneratedMessage {
  factory LocalConfig({
    $0.Config_DeviceConfig? device,
    $0.Config_PositionConfig? position,
    $0.Config_PowerConfig? power,
    $0.Config_NetworkConfig? network,
    $0.Config_DisplayConfig? display,
    $0.Config_LoRaConfig? lora,
    $0.Config_BluetoothConfig? bluetooth,
    $core.int? version,
    $0.Config_SecurityConfig? security,
  }) {
    final result = create();
    if (device != null) result.device = device;
    if (position != null) result.position = position;
    if (power != null) result.power = power;
    if (network != null) result.network = network;
    if (display != null) result.display = display;
    if (lora != null) result.lora = lora;
    if (bluetooth != null) result.bluetooth = bluetooth;
    if (version != null) result.version = version;
    if (security != null) result.security = security;
    return result;
  }

  LocalConfig._();

  factory LocalConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<$0.Config_DeviceConfig>(1, _omitFieldNames ? '' : 'device',
        subBuilder: $0.Config_DeviceConfig.create)
    ..aOM<$0.Config_PositionConfig>(2, _omitFieldNames ? '' : 'position',
        subBuilder: $0.Config_PositionConfig.create)
    ..aOM<$0.Config_PowerConfig>(3, _omitFieldNames ? '' : 'power',
        subBuilder: $0.Config_PowerConfig.create)
    ..aOM<$0.Config_NetworkConfig>(4, _omitFieldNames ? '' : 'network',
        subBuilder: $0.Config_NetworkConfig.create)
    ..aOM<$0.Config_DisplayConfig>(5, _omitFieldNames ? '' : 'display',
        subBuilder: $0.Config_DisplayConfig.create)
    ..aOM<$0.Config_LoRaConfig>(6, _omitFieldNames ? '' : 'lora',
        subBuilder: $0.Config_LoRaConfig.create)
    ..aOM<$0.Config_BluetoothConfig>(7, _omitFieldNames ? '' : 'bluetooth',
        subBuilder: $0.Config_BluetoothConfig.create)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..aOM<$0.Config_SecurityConfig>(9, _omitFieldNames ? '' : 'security',
        subBuilder: $0.Config_SecurityConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalConfig clone() => LocalConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalConfig copyWith(void Function(LocalConfig) updates) =>
      super.copyWith((message) => updates(message as LocalConfig))
          as LocalConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalConfig create() => LocalConfig._();
  @$core.override
  LocalConfig createEmptyInstance() => create();
  static $pb.PbList<LocalConfig> createRepeated() => $pb.PbList<LocalConfig>();
  @$core.pragma('dart2js:noInline')
  static LocalConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalConfig>(create);
  static LocalConfig? _defaultInstance;

  ///
  ///  The part of the config that is specific to the Device
  @$pb.TagNumber(1)
  $0.Config_DeviceConfig get device => $_getN(0);
  @$pb.TagNumber(1)
  set device($0.Config_DeviceConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Config_DeviceConfig ensureDevice() => $_ensure(0);

  ///
  ///  The part of the config that is specific to the GPS Position
  @$pb.TagNumber(2)
  $0.Config_PositionConfig get position => $_getN(1);
  @$pb.TagNumber(2)
  set position($0.Config_PositionConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Config_PositionConfig ensurePosition() => $_ensure(1);

  ///
  ///  The part of the config that is specific to the Power settings
  @$pb.TagNumber(3)
  $0.Config_PowerConfig get power => $_getN(2);
  @$pb.TagNumber(3)
  set power($0.Config_PowerConfig value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPower() => $_has(2);
  @$pb.TagNumber(3)
  void clearPower() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Config_PowerConfig ensurePower() => $_ensure(2);

  ///
  ///  The part of the config that is specific to the Wifi Settings
  @$pb.TagNumber(4)
  $0.Config_NetworkConfig get network => $_getN(3);
  @$pb.TagNumber(4)
  set network($0.Config_NetworkConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNetwork() => $_has(3);
  @$pb.TagNumber(4)
  void clearNetwork() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Config_NetworkConfig ensureNetwork() => $_ensure(3);

  ///
  ///  The part of the config that is specific to the Display
  @$pb.TagNumber(5)
  $0.Config_DisplayConfig get display => $_getN(4);
  @$pb.TagNumber(5)
  set display($0.Config_DisplayConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplay() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplay() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Config_DisplayConfig ensureDisplay() => $_ensure(4);

  ///
  ///  The part of the config that is specific to the Lora Radio
  @$pb.TagNumber(6)
  $0.Config_LoRaConfig get lora => $_getN(5);
  @$pb.TagNumber(6)
  set lora($0.Config_LoRaConfig value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLora() => $_has(5);
  @$pb.TagNumber(6)
  void clearLora() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Config_LoRaConfig ensureLora() => $_ensure(5);

  ///
  ///  The part of the config that is specific to the Bluetooth settings
  @$pb.TagNumber(7)
  $0.Config_BluetoothConfig get bluetooth => $_getN(6);
  @$pb.TagNumber(7)
  set bluetooth($0.Config_BluetoothConfig value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasBluetooth() => $_has(6);
  @$pb.TagNumber(7)
  void clearBluetooth() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Config_BluetoothConfig ensureBluetooth() => $_ensure(6);

  ///
  ///  A version integer used to invalidate old save files when we make
  ///  incompatible changes This integer is set at build time and is private to
  ///  NodeDB.cpp in the device code.
  @$pb.TagNumber(8)
  $core.int get version => $_getIZ(7);
  @$pb.TagNumber(8)
  set version($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  ///
  ///  The part of the config that is specific to Security settings
  @$pb.TagNumber(9)
  $0.Config_SecurityConfig get security => $_getN(8);
  @$pb.TagNumber(9)
  set security($0.Config_SecurityConfig value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasSecurity() => $_has(8);
  @$pb.TagNumber(9)
  void clearSecurity() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Config_SecurityConfig ensureSecurity() => $_ensure(8);
}

class LocalModuleConfig extends $pb.GeneratedMessage {
  factory LocalModuleConfig({
    $1.ModuleConfig_MQTTConfig? mqtt,
    $1.ModuleConfig_SerialConfig? serial,
    $1.ModuleConfig_ExternalNotificationConfig? externalNotification,
    $1.ModuleConfig_StoreForwardConfig? storeForward,
    $1.ModuleConfig_RangeTestConfig? rangeTest,
    $1.ModuleConfig_TelemetryConfig? telemetry,
    $1.ModuleConfig_CannedMessageConfig? cannedMessage,
    $core.int? version,
    $1.ModuleConfig_AudioConfig? audio,
    $1.ModuleConfig_RemoteHardwareConfig? remoteHardware,
    $1.ModuleConfig_NeighborInfoConfig? neighborInfo,
    $1.ModuleConfig_AmbientLightingConfig? ambientLighting,
    $1.ModuleConfig_DetectionSensorConfig? detectionSensor,
    $1.ModuleConfig_PaxcounterConfig? paxcounter,
  }) {
    final result = create();
    if (mqtt != null) result.mqtt = mqtt;
    if (serial != null) result.serial = serial;
    if (externalNotification != null)
      result.externalNotification = externalNotification;
    if (storeForward != null) result.storeForward = storeForward;
    if (rangeTest != null) result.rangeTest = rangeTest;
    if (telemetry != null) result.telemetry = telemetry;
    if (cannedMessage != null) result.cannedMessage = cannedMessage;
    if (version != null) result.version = version;
    if (audio != null) result.audio = audio;
    if (remoteHardware != null) result.remoteHardware = remoteHardware;
    if (neighborInfo != null) result.neighborInfo = neighborInfo;
    if (ambientLighting != null) result.ambientLighting = ambientLighting;
    if (detectionSensor != null) result.detectionSensor = detectionSensor;
    if (paxcounter != null) result.paxcounter = paxcounter;
    return result;
  }

  LocalModuleConfig._();

  factory LocalModuleConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalModuleConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalModuleConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<$1.ModuleConfig_MQTTConfig>(1, _omitFieldNames ? '' : 'mqtt',
        subBuilder: $1.ModuleConfig_MQTTConfig.create)
    ..aOM<$1.ModuleConfig_SerialConfig>(2, _omitFieldNames ? '' : 'serial',
        subBuilder: $1.ModuleConfig_SerialConfig.create)
    ..aOM<$1.ModuleConfig_ExternalNotificationConfig>(
        3, _omitFieldNames ? '' : 'externalNotification',
        subBuilder: $1.ModuleConfig_ExternalNotificationConfig.create)
    ..aOM<$1.ModuleConfig_StoreForwardConfig>(
        4, _omitFieldNames ? '' : 'storeForward',
        subBuilder: $1.ModuleConfig_StoreForwardConfig.create)
    ..aOM<$1.ModuleConfig_RangeTestConfig>(
        5, _omitFieldNames ? '' : 'rangeTest',
        subBuilder: $1.ModuleConfig_RangeTestConfig.create)
    ..aOM<$1.ModuleConfig_TelemetryConfig>(
        6, _omitFieldNames ? '' : 'telemetry',
        subBuilder: $1.ModuleConfig_TelemetryConfig.create)
    ..aOM<$1.ModuleConfig_CannedMessageConfig>(
        7, _omitFieldNames ? '' : 'cannedMessage',
        subBuilder: $1.ModuleConfig_CannedMessageConfig.create)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..aOM<$1.ModuleConfig_AudioConfig>(9, _omitFieldNames ? '' : 'audio',
        subBuilder: $1.ModuleConfig_AudioConfig.create)
    ..aOM<$1.ModuleConfig_RemoteHardwareConfig>(
        10, _omitFieldNames ? '' : 'remoteHardware',
        subBuilder: $1.ModuleConfig_RemoteHardwareConfig.create)
    ..aOM<$1.ModuleConfig_NeighborInfoConfig>(
        11, _omitFieldNames ? '' : 'neighborInfo',
        subBuilder: $1.ModuleConfig_NeighborInfoConfig.create)
    ..aOM<$1.ModuleConfig_AmbientLightingConfig>(
        12, _omitFieldNames ? '' : 'ambientLighting',
        subBuilder: $1.ModuleConfig_AmbientLightingConfig.create)
    ..aOM<$1.ModuleConfig_DetectionSensorConfig>(
        13, _omitFieldNames ? '' : 'detectionSensor',
        subBuilder: $1.ModuleConfig_DetectionSensorConfig.create)
    ..aOM<$1.ModuleConfig_PaxcounterConfig>(
        14, _omitFieldNames ? '' : 'paxcounter',
        subBuilder: $1.ModuleConfig_PaxcounterConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalModuleConfig clone() => LocalModuleConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalModuleConfig copyWith(void Function(LocalModuleConfig) updates) =>
      super.copyWith((message) => updates(message as LocalModuleConfig))
          as LocalModuleConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalModuleConfig create() => LocalModuleConfig._();
  @$core.override
  LocalModuleConfig createEmptyInstance() => create();
  static $pb.PbList<LocalModuleConfig> createRepeated() =>
      $pb.PbList<LocalModuleConfig>();
  @$core.pragma('dart2js:noInline')
  static LocalModuleConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalModuleConfig>(create);
  static LocalModuleConfig? _defaultInstance;

  ///
  ///  The part of the config that is specific to the MQTT module
  @$pb.TagNumber(1)
  $1.ModuleConfig_MQTTConfig get mqtt => $_getN(0);
  @$pb.TagNumber(1)
  set mqtt($1.ModuleConfig_MQTTConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMqtt() => $_has(0);
  @$pb.TagNumber(1)
  void clearMqtt() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ModuleConfig_MQTTConfig ensureMqtt() => $_ensure(0);

  ///
  ///  The part of the config that is specific to the Serial module
  @$pb.TagNumber(2)
  $1.ModuleConfig_SerialConfig get serial => $_getN(1);
  @$pb.TagNumber(2)
  set serial($1.ModuleConfig_SerialConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSerial() => $_has(1);
  @$pb.TagNumber(2)
  void clearSerial() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModuleConfig_SerialConfig ensureSerial() => $_ensure(1);

  ///
  ///  The part of the config that is specific to the ExternalNotification module
  @$pb.TagNumber(3)
  $1.ModuleConfig_ExternalNotificationConfig get externalNotification =>
      $_getN(2);
  @$pb.TagNumber(3)
  set externalNotification($1.ModuleConfig_ExternalNotificationConfig value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExternalNotification() => $_has(2);
  @$pb.TagNumber(3)
  void clearExternalNotification() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ModuleConfig_ExternalNotificationConfig ensureExternalNotification() =>
      $_ensure(2);

  ///
  ///  The part of the config that is specific to the Store & Forward module
  @$pb.TagNumber(4)
  $1.ModuleConfig_StoreForwardConfig get storeForward => $_getN(3);
  @$pb.TagNumber(4)
  set storeForward($1.ModuleConfig_StoreForwardConfig value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStoreForward() => $_has(3);
  @$pb.TagNumber(4)
  void clearStoreForward() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.ModuleConfig_StoreForwardConfig ensureStoreForward() => $_ensure(3);

  ///
  ///  The part of the config that is specific to the RangeTest module
  @$pb.TagNumber(5)
  $1.ModuleConfig_RangeTestConfig get rangeTest => $_getN(4);
  @$pb.TagNumber(5)
  set rangeTest($1.ModuleConfig_RangeTestConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRangeTest() => $_has(4);
  @$pb.TagNumber(5)
  void clearRangeTest() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.ModuleConfig_RangeTestConfig ensureRangeTest() => $_ensure(4);

  ///
  ///  The part of the config that is specific to the Telemetry module
  @$pb.TagNumber(6)
  $1.ModuleConfig_TelemetryConfig get telemetry => $_getN(5);
  @$pb.TagNumber(6)
  set telemetry($1.ModuleConfig_TelemetryConfig value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasTelemetry() => $_has(5);
  @$pb.TagNumber(6)
  void clearTelemetry() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.ModuleConfig_TelemetryConfig ensureTelemetry() => $_ensure(5);

  ///
  ///  The part of the config that is specific to the Canned Message module
  @$pb.TagNumber(7)
  $1.ModuleConfig_CannedMessageConfig get cannedMessage => $_getN(6);
  @$pb.TagNumber(7)
  set cannedMessage($1.ModuleConfig_CannedMessageConfig value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCannedMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearCannedMessage() => $_clearField(7);
  @$pb.TagNumber(7)
  $1.ModuleConfig_CannedMessageConfig ensureCannedMessage() => $_ensure(6);

  ///
  ///  A version integer used to invalidate old save files when we make
  ///  incompatible changes This integer is set at build time and is private to
  ///  NodeDB.cpp in the device code.
  @$pb.TagNumber(8)
  $core.int get version => $_getIZ(7);
  @$pb.TagNumber(8)
  set version($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  ///
  ///  The part of the config that is specific to the Audio module
  @$pb.TagNumber(9)
  $1.ModuleConfig_AudioConfig get audio => $_getN(8);
  @$pb.TagNumber(9)
  set audio($1.ModuleConfig_AudioConfig value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAudio() => $_has(8);
  @$pb.TagNumber(9)
  void clearAudio() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.ModuleConfig_AudioConfig ensureAudio() => $_ensure(8);

  ///
  ///  The part of the config that is specific to the Remote Hardware module
  @$pb.TagNumber(10)
  $1.ModuleConfig_RemoteHardwareConfig get remoteHardware => $_getN(9);
  @$pb.TagNumber(10)
  set remoteHardware($1.ModuleConfig_RemoteHardwareConfig value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRemoteHardware() => $_has(9);
  @$pb.TagNumber(10)
  void clearRemoteHardware() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.ModuleConfig_RemoteHardwareConfig ensureRemoteHardware() => $_ensure(9);

  ///
  ///  The part of the config that is specific to the Neighbor Info module
  @$pb.TagNumber(11)
  $1.ModuleConfig_NeighborInfoConfig get neighborInfo => $_getN(10);
  @$pb.TagNumber(11)
  set neighborInfo($1.ModuleConfig_NeighborInfoConfig value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasNeighborInfo() => $_has(10);
  @$pb.TagNumber(11)
  void clearNeighborInfo() => $_clearField(11);
  @$pb.TagNumber(11)
  $1.ModuleConfig_NeighborInfoConfig ensureNeighborInfo() => $_ensure(10);

  ///
  ///  The part of the config that is specific to the Ambient Lighting module
  @$pb.TagNumber(12)
  $1.ModuleConfig_AmbientLightingConfig get ambientLighting => $_getN(11);
  @$pb.TagNumber(12)
  set ambientLighting($1.ModuleConfig_AmbientLightingConfig value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAmbientLighting() => $_has(11);
  @$pb.TagNumber(12)
  void clearAmbientLighting() => $_clearField(12);
  @$pb.TagNumber(12)
  $1.ModuleConfig_AmbientLightingConfig ensureAmbientLighting() => $_ensure(11);

  ///
  ///  The part of the config that is specific to the Detection Sensor module
  @$pb.TagNumber(13)
  $1.ModuleConfig_DetectionSensorConfig get detectionSensor => $_getN(12);
  @$pb.TagNumber(13)
  set detectionSensor($1.ModuleConfig_DetectionSensorConfig value) =>
      $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasDetectionSensor() => $_has(12);
  @$pb.TagNumber(13)
  void clearDetectionSensor() => $_clearField(13);
  @$pb.TagNumber(13)
  $1.ModuleConfig_DetectionSensorConfig ensureDetectionSensor() => $_ensure(12);

  ///
  ///  Paxcounter Config
  @$pb.TagNumber(14)
  $1.ModuleConfig_PaxcounterConfig get paxcounter => $_getN(13);
  @$pb.TagNumber(14)
  set paxcounter($1.ModuleConfig_PaxcounterConfig value) =>
      $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasPaxcounter() => $_has(13);
  @$pb.TagNumber(14)
  void clearPaxcounter() => $_clearField(14);
  @$pb.TagNumber(14)
  $1.ModuleConfig_PaxcounterConfig ensurePaxcounter() => $_ensure(13);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
