// This is a generated file - do not edit.
//
// Generated from meshtastic/module_config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'module_config.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'module_config.pbenum.dart';

///
///  MQTT Client Config
class ModuleConfig_MQTTConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_MQTTConfig({
    $core.bool? enabled,
    $core.String? address,
    $core.String? username,
    $core.String? password,
    $core.bool? encryptionEnabled,
    $core.bool? jsonEnabled,
    $core.bool? tlsEnabled,
    $core.String? root,
    $core.bool? proxyToClientEnabled,
    $core.bool? mapReportingEnabled,
    ModuleConfig_MapReportSettings? mapReportSettings,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (address != null) result.address = address;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (encryptionEnabled != null) result.encryptionEnabled = encryptionEnabled;
    if (jsonEnabled != null) result.jsonEnabled = jsonEnabled;
    if (tlsEnabled != null) result.tlsEnabled = tlsEnabled;
    if (root != null) result.root = root;
    if (proxyToClientEnabled != null)
      result.proxyToClientEnabled = proxyToClientEnabled;
    if (mapReportingEnabled != null)
      result.mapReportingEnabled = mapReportingEnabled;
    if (mapReportSettings != null) result.mapReportSettings = mapReportSettings;
    return result;
  }

  ModuleConfig_MQTTConfig._();

  factory ModuleConfig_MQTTConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_MQTTConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.MQTTConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..aOS(3, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'password')
    ..aOB(5, _omitFieldNames ? '' : 'encryptionEnabled')
    ..aOB(6, _omitFieldNames ? '' : 'jsonEnabled')
    ..aOB(7, _omitFieldNames ? '' : 'tlsEnabled')
    ..aOS(8, _omitFieldNames ? '' : 'root')
    ..aOB(9, _omitFieldNames ? '' : 'proxyToClientEnabled')
    ..aOB(10, _omitFieldNames ? '' : 'mapReportingEnabled')
    ..aOM<ModuleConfig_MapReportSettings>(
        11, _omitFieldNames ? '' : 'mapReportSettings',
        subBuilder: ModuleConfig_MapReportSettings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_MQTTConfig clone() =>
      ModuleConfig_MQTTConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_MQTTConfig copyWith(
          void Function(ModuleConfig_MQTTConfig) updates) =>
      super.copyWith((message) => updates(message as ModuleConfig_MQTTConfig))
          as ModuleConfig_MQTTConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_MQTTConfig create() => ModuleConfig_MQTTConfig._();
  @$core.override
  ModuleConfig_MQTTConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_MQTTConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_MQTTConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_MQTTConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_MQTTConfig>(create);
  static ModuleConfig_MQTTConfig? _defaultInstance;

  ///
  ///  If a meshtastic node is able to reach the internet it will normally attempt to gateway any channels that are marked as
  ///  is_uplink_enabled or is_downlink_enabled.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  The server to use for our MQTT global message gateway feature.
  ///  If not set, the default server will be used
  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  ///
  ///  MQTT username to use (most useful for a custom MQTT server).
  ///  If using a custom server, this will be honoured even if empty.
  ///  If using the default server, this will only be honoured if set, otherwise the device will use the default username
  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => $_clearField(3);

  ///
  ///  MQTT password to use (most useful for a custom MQTT server).
  ///  If using a custom server, this will be honoured even if empty.
  ///  If using the default server, this will only be honoured if set, otherwise the device will use the default password
  @$pb.TagNumber(4)
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => $_clearField(4);

  ///
  ///  Whether to send encrypted or decrypted packets to MQTT.
  ///  This parameter is only honoured if you also set server
  ///  (the default official mqtt.meshtastic.org server can handle encrypted packets)
  ///  Decrypted packets may be useful for external systems that want to consume meshtastic packets
  @$pb.TagNumber(5)
  $core.bool get encryptionEnabled => $_getBF(4);
  @$pb.TagNumber(5)
  set encryptionEnabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEncryptionEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearEncryptionEnabled() => $_clearField(5);

  ///
  ///  Whether to send / consume json packets on MQTT
  @$pb.TagNumber(6)
  $core.bool get jsonEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set jsonEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasJsonEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearJsonEnabled() => $_clearField(6);

  ///
  ///  If true, we attempt to establish a secure connection using TLS
  @$pb.TagNumber(7)
  $core.bool get tlsEnabled => $_getBF(6);
  @$pb.TagNumber(7)
  set tlsEnabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTlsEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearTlsEnabled() => $_clearField(7);

  ///
  ///  The root topic to use for MQTT messages. Default is "msh".
  ///  This is useful if you want to use a single MQTT server for multiple meshtastic networks and separate them via ACLs
  @$pb.TagNumber(8)
  $core.String get root => $_getSZ(7);
  @$pb.TagNumber(8)
  set root($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRoot() => $_has(7);
  @$pb.TagNumber(8)
  void clearRoot() => $_clearField(8);

  ///
  ///  If true, we can use the connected phone / client to proxy messages to MQTT instead of a direct connection
  @$pb.TagNumber(9)
  $core.bool get proxyToClientEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set proxyToClientEnabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProxyToClientEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearProxyToClientEnabled() => $_clearField(9);

  ///
  ///  If true, we will periodically report unencrypted information about our node to a map via MQTT
  @$pb.TagNumber(10)
  $core.bool get mapReportingEnabled => $_getBF(9);
  @$pb.TagNumber(10)
  set mapReportingEnabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMapReportingEnabled() => $_has(9);
  @$pb.TagNumber(10)
  void clearMapReportingEnabled() => $_clearField(10);

  ///
  ///  Settings for reporting information about our node to a map via MQTT
  @$pb.TagNumber(11)
  ModuleConfig_MapReportSettings get mapReportSettings => $_getN(10);
  @$pb.TagNumber(11)
  set mapReportSettings(ModuleConfig_MapReportSettings value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMapReportSettings() => $_has(10);
  @$pb.TagNumber(11)
  void clearMapReportSettings() => $_clearField(11);
  @$pb.TagNumber(11)
  ModuleConfig_MapReportSettings ensureMapReportSettings() => $_ensure(10);
}

///
///  Settings for reporting unencrypted information about our node to a map via MQTT
class ModuleConfig_MapReportSettings extends $pb.GeneratedMessage {
  factory ModuleConfig_MapReportSettings({
    $core.int? publishIntervalSecs,
    $core.int? positionPrecision,
    $core.bool? shouldReportLocation,
  }) {
    final result = create();
    if (publishIntervalSecs != null)
      result.publishIntervalSecs = publishIntervalSecs;
    if (positionPrecision != null) result.positionPrecision = positionPrecision;
    if (shouldReportLocation != null)
      result.shouldReportLocation = shouldReportLocation;
    return result;
  }

  ModuleConfig_MapReportSettings._();

  factory ModuleConfig_MapReportSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_MapReportSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.MapReportSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'publishIntervalSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'positionPrecision', $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'shouldReportLocation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_MapReportSettings clone() =>
      ModuleConfig_MapReportSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_MapReportSettings copyWith(
          void Function(ModuleConfig_MapReportSettings) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_MapReportSettings))
          as ModuleConfig_MapReportSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_MapReportSettings create() =>
      ModuleConfig_MapReportSettings._();
  @$core.override
  ModuleConfig_MapReportSettings createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_MapReportSettings> createRepeated() =>
      $pb.PbList<ModuleConfig_MapReportSettings>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_MapReportSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_MapReportSettings>(create);
  static ModuleConfig_MapReportSettings? _defaultInstance;

  ///
  ///  How often we should report our info to the map (in seconds)
  @$pb.TagNumber(1)
  $core.int get publishIntervalSecs => $_getIZ(0);
  @$pb.TagNumber(1)
  set publishIntervalSecs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublishIntervalSecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublishIntervalSecs() => $_clearField(1);

  ///
  ///  Bits of precision for the location sent (default of 32 is full precision).
  @$pb.TagNumber(2)
  $core.int get positionPrecision => $_getIZ(1);
  @$pb.TagNumber(2)
  set positionPrecision($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionPrecision() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionPrecision() => $_clearField(2);

  ///
  ///  Whether we have opted-in to report our location to the map
  @$pb.TagNumber(3)
  $core.bool get shouldReportLocation => $_getBF(2);
  @$pb.TagNumber(3)
  set shouldReportLocation($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasShouldReportLocation() => $_has(2);
  @$pb.TagNumber(3)
  void clearShouldReportLocation() => $_clearField(3);
}

///
///  RemoteHardwareModule Config
class ModuleConfig_RemoteHardwareConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_RemoteHardwareConfig({
    $core.bool? enabled,
    $core.bool? allowUndefinedPinAccess,
    $core.Iterable<RemoteHardwarePin>? availablePins,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (allowUndefinedPinAccess != null)
      result.allowUndefinedPinAccess = allowUndefinedPinAccess;
    if (availablePins != null) result.availablePins.addAll(availablePins);
    return result;
  }

  ModuleConfig_RemoteHardwareConfig._();

  factory ModuleConfig_RemoteHardwareConfig.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_RemoteHardwareConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.RemoteHardwareConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'allowUndefinedPinAccess')
    ..pc<RemoteHardwarePin>(
        3, _omitFieldNames ? '' : 'availablePins', $pb.PbFieldType.PM,
        subBuilder: RemoteHardwarePin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_RemoteHardwareConfig clone() =>
      ModuleConfig_RemoteHardwareConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_RemoteHardwareConfig copyWith(
          void Function(ModuleConfig_RemoteHardwareConfig) updates) =>
      super.copyWith((message) =>
              updates(message as ModuleConfig_RemoteHardwareConfig))
          as ModuleConfig_RemoteHardwareConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_RemoteHardwareConfig create() =>
      ModuleConfig_RemoteHardwareConfig._();
  @$core.override
  ModuleConfig_RemoteHardwareConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_RemoteHardwareConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_RemoteHardwareConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_RemoteHardwareConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_RemoteHardwareConfig>(
          create);
  static ModuleConfig_RemoteHardwareConfig? _defaultInstance;

  ///
  ///  Whether the Module is enabled
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  Whether the Module allows consumers to read / write to pins not defined in available_pins
  @$pb.TagNumber(2)
  $core.bool get allowUndefinedPinAccess => $_getBF(1);
  @$pb.TagNumber(2)
  set allowUndefinedPinAccess($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowUndefinedPinAccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowUndefinedPinAccess() => $_clearField(2);

  ///
  ///  Exposes the available pins to the mesh for reading and writing
  @$pb.TagNumber(3)
  $pb.PbList<RemoteHardwarePin> get availablePins => $_getList(2);
}

///
///  NeighborInfoModule Config
class ModuleConfig_NeighborInfoConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_NeighborInfoConfig({
    $core.bool? enabled,
    $core.int? updateInterval,
    $core.bool? transmitOverLora,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (updateInterval != null) result.updateInterval = updateInterval;
    if (transmitOverLora != null) result.transmitOverLora = transmitOverLora;
    return result;
  }

  ModuleConfig_NeighborInfoConfig._();

  factory ModuleConfig_NeighborInfoConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_NeighborInfoConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.NeighborInfoConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'updateInterval', $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'transmitOverLora')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_NeighborInfoConfig clone() =>
      ModuleConfig_NeighborInfoConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_NeighborInfoConfig copyWith(
          void Function(ModuleConfig_NeighborInfoConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_NeighborInfoConfig))
          as ModuleConfig_NeighborInfoConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_NeighborInfoConfig create() =>
      ModuleConfig_NeighborInfoConfig._();
  @$core.override
  ModuleConfig_NeighborInfoConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_NeighborInfoConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_NeighborInfoConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_NeighborInfoConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_NeighborInfoConfig>(
          create);
  static ModuleConfig_NeighborInfoConfig? _defaultInstance;

  ///
  ///  Whether the Module is enabled
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  Interval in seconds of how often we should try to send our
  ///  Neighbor Info (minimum is 14400, i.e., 4 hours)
  @$pb.TagNumber(2)
  $core.int get updateInterval => $_getIZ(1);
  @$pb.TagNumber(2)
  set updateInterval($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateInterval() => $_clearField(2);

  ///
  ///  Whether in addition to sending it to MQTT and the PhoneAPI, our NeighborInfo should be transmitted over LoRa.
  ///  Note that this is not available on a channel with default key and name.
  @$pb.TagNumber(3)
  $core.bool get transmitOverLora => $_getBF(2);
  @$pb.TagNumber(3)
  set transmitOverLora($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTransmitOverLora() => $_has(2);
  @$pb.TagNumber(3)
  void clearTransmitOverLora() => $_clearField(3);
}

///
///  Detection Sensor Module Config
class ModuleConfig_DetectionSensorConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_DetectionSensorConfig({
    $core.bool? enabled,
    $core.int? minimumBroadcastSecs,
    $core.int? stateBroadcastSecs,
    $core.bool? sendBell,
    $core.String? name,
    $core.int? monitorPin,
    ModuleConfig_DetectionSensorConfig_TriggerType? detectionTriggerType,
    $core.bool? usePullup,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (minimumBroadcastSecs != null)
      result.minimumBroadcastSecs = minimumBroadcastSecs;
    if (stateBroadcastSecs != null)
      result.stateBroadcastSecs = stateBroadcastSecs;
    if (sendBell != null) result.sendBell = sendBell;
    if (name != null) result.name = name;
    if (monitorPin != null) result.monitorPin = monitorPin;
    if (detectionTriggerType != null)
      result.detectionTriggerType = detectionTriggerType;
    if (usePullup != null) result.usePullup = usePullup;
    return result;
  }

  ModuleConfig_DetectionSensorConfig._();

  factory ModuleConfig_DetectionSensorConfig.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_DetectionSensorConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.DetectionSensorConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'minimumBroadcastSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'stateBroadcastSecs', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'sendBell')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'monitorPin', $pb.PbFieldType.OU3)
    ..e<ModuleConfig_DetectionSensorConfig_TriggerType>(
        7, _omitFieldNames ? '' : 'detectionTriggerType', $pb.PbFieldType.OE,
        defaultOrMaker:
            ModuleConfig_DetectionSensorConfig_TriggerType.LOGIC_LOW,
        valueOf: ModuleConfig_DetectionSensorConfig_TriggerType.valueOf,
        enumValues: ModuleConfig_DetectionSensorConfig_TriggerType.values)
    ..aOB(8, _omitFieldNames ? '' : 'usePullup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_DetectionSensorConfig clone() =>
      ModuleConfig_DetectionSensorConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_DetectionSensorConfig copyWith(
          void Function(ModuleConfig_DetectionSensorConfig) updates) =>
      super.copyWith((message) =>
              updates(message as ModuleConfig_DetectionSensorConfig))
          as ModuleConfig_DetectionSensorConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_DetectionSensorConfig create() =>
      ModuleConfig_DetectionSensorConfig._();
  @$core.override
  ModuleConfig_DetectionSensorConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_DetectionSensorConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_DetectionSensorConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_DetectionSensorConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_DetectionSensorConfig>(
          create);
  static ModuleConfig_DetectionSensorConfig? _defaultInstance;

  ///
  ///  Whether the Module is enabled
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  Interval in seconds of how often we can send a message to the mesh when a
  ///  trigger event is detected
  @$pb.TagNumber(2)
  $core.int get minimumBroadcastSecs => $_getIZ(1);
  @$pb.TagNumber(2)
  set minimumBroadcastSecs($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMinimumBroadcastSecs() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinimumBroadcastSecs() => $_clearField(2);

  ///
  ///  Interval in seconds of how often we should send a message to the mesh
  ///  with the current state regardless of trigger events When set to 0, only
  ///  trigger events will be broadcasted Works as a sort of status heartbeat
  ///  for peace of mind
  @$pb.TagNumber(3)
  $core.int get stateBroadcastSecs => $_getIZ(2);
  @$pb.TagNumber(3)
  set stateBroadcastSecs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStateBroadcastSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearStateBroadcastSecs() => $_clearField(3);

  ///
  ///  Send ASCII bell with alert message
  ///  Useful for triggering ext. notification on bell
  @$pb.TagNumber(4)
  $core.bool get sendBell => $_getBF(3);
  @$pb.TagNumber(4)
  set sendBell($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSendBell() => $_has(3);
  @$pb.TagNumber(4)
  void clearSendBell() => $_clearField(4);

  ///
  ///  Friendly name used to format message sent to mesh
  ///  Example: A name "Motion" would result in a message "Motion detected"
  ///  Maximum length of 20 characters
  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  ///
  ///  GPIO pin to monitor for state changes
  @$pb.TagNumber(6)
  $core.int get monitorPin => $_getIZ(5);
  @$pb.TagNumber(6)
  set monitorPin($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMonitorPin() => $_has(5);
  @$pb.TagNumber(6)
  void clearMonitorPin() => $_clearField(6);

  ///
  ///  The type of trigger event to be used
  @$pb.TagNumber(7)
  ModuleConfig_DetectionSensorConfig_TriggerType get detectionTriggerType =>
      $_getN(6);
  @$pb.TagNumber(7)
  set detectionTriggerType(
          ModuleConfig_DetectionSensorConfig_TriggerType value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDetectionTriggerType() => $_has(6);
  @$pb.TagNumber(7)
  void clearDetectionTriggerType() => $_clearField(7);

  ///
  ///  Whether or not use INPUT_PULLUP mode for GPIO pin
  ///  Only applicable if the board uses pull-up resistors on the pin
  @$pb.TagNumber(8)
  $core.bool get usePullup => $_getBF(7);
  @$pb.TagNumber(8)
  set usePullup($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUsePullup() => $_has(7);
  @$pb.TagNumber(8)
  void clearUsePullup() => $_clearField(8);
}

///
///  Audio Config for codec2 voice
class ModuleConfig_AudioConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_AudioConfig({
    $core.bool? codec2Enabled,
    $core.int? pttPin,
    ModuleConfig_AudioConfig_Audio_Baud? bitrate,
    $core.int? i2sWs,
    $core.int? i2sSd,
    $core.int? i2sDin,
    $core.int? i2sSck,
  }) {
    final result = create();
    if (codec2Enabled != null) result.codec2Enabled = codec2Enabled;
    if (pttPin != null) result.pttPin = pttPin;
    if (bitrate != null) result.bitrate = bitrate;
    if (i2sWs != null) result.i2sWs = i2sWs;
    if (i2sSd != null) result.i2sSd = i2sSd;
    if (i2sDin != null) result.i2sDin = i2sDin;
    if (i2sSck != null) result.i2sSck = i2sSck;
    return result;
  }

  ModuleConfig_AudioConfig._();

  factory ModuleConfig_AudioConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_AudioConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.AudioConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'codec2Enabled')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pttPin', $pb.PbFieldType.OU3)
    ..e<ModuleConfig_AudioConfig_Audio_Baud>(
        3, _omitFieldNames ? '' : 'bitrate', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_AudioConfig_Audio_Baud.CODEC2_DEFAULT,
        valueOf: ModuleConfig_AudioConfig_Audio_Baud.valueOf,
        enumValues: ModuleConfig_AudioConfig_Audio_Baud.values)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'i2sWs', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'i2sSd', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'i2sDin', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'i2sSck', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_AudioConfig clone() =>
      ModuleConfig_AudioConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_AudioConfig copyWith(
          void Function(ModuleConfig_AudioConfig) updates) =>
      super.copyWith((message) => updates(message as ModuleConfig_AudioConfig))
          as ModuleConfig_AudioConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_AudioConfig create() => ModuleConfig_AudioConfig._();
  @$core.override
  ModuleConfig_AudioConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_AudioConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_AudioConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_AudioConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_AudioConfig>(create);
  static ModuleConfig_AudioConfig? _defaultInstance;

  ///
  ///  Whether Audio is enabled
  @$pb.TagNumber(1)
  $core.bool get codec2Enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set codec2Enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCodec2Enabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearCodec2Enabled() => $_clearField(1);

  ///
  ///  PTT Pin
  @$pb.TagNumber(2)
  $core.int get pttPin => $_getIZ(1);
  @$pb.TagNumber(2)
  set pttPin($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPttPin() => $_has(1);
  @$pb.TagNumber(2)
  void clearPttPin() => $_clearField(2);

  ///
  ///  The audio sample rate to use for codec2
  @$pb.TagNumber(3)
  ModuleConfig_AudioConfig_Audio_Baud get bitrate => $_getN(2);
  @$pb.TagNumber(3)
  set bitrate(ModuleConfig_AudioConfig_Audio_Baud value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBitrate() => $_has(2);
  @$pb.TagNumber(3)
  void clearBitrate() => $_clearField(3);

  ///
  ///  I2S Word Select
  @$pb.TagNumber(4)
  $core.int get i2sWs => $_getIZ(3);
  @$pb.TagNumber(4)
  set i2sWs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasI2sWs() => $_has(3);
  @$pb.TagNumber(4)
  void clearI2sWs() => $_clearField(4);

  ///
  ///  I2S Data IN
  @$pb.TagNumber(5)
  $core.int get i2sSd => $_getIZ(4);
  @$pb.TagNumber(5)
  set i2sSd($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasI2sSd() => $_has(4);
  @$pb.TagNumber(5)
  void clearI2sSd() => $_clearField(5);

  ///
  ///  I2S Data OUT
  @$pb.TagNumber(6)
  $core.int get i2sDin => $_getIZ(5);
  @$pb.TagNumber(6)
  set i2sDin($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasI2sDin() => $_has(5);
  @$pb.TagNumber(6)
  void clearI2sDin() => $_clearField(6);

  ///
  ///  I2S Clock
  @$pb.TagNumber(7)
  $core.int get i2sSck => $_getIZ(6);
  @$pb.TagNumber(7)
  set i2sSck($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasI2sSck() => $_has(6);
  @$pb.TagNumber(7)
  void clearI2sSck() => $_clearField(7);
}

///
///  Config for the Paxcounter Module
class ModuleConfig_PaxcounterConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_PaxcounterConfig({
    $core.bool? enabled,
    $core.int? paxcounterUpdateInterval,
    $core.int? wifiThreshold,
    $core.int? bleThreshold,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (paxcounterUpdateInterval != null)
      result.paxcounterUpdateInterval = paxcounterUpdateInterval;
    if (wifiThreshold != null) result.wifiThreshold = wifiThreshold;
    if (bleThreshold != null) result.bleThreshold = bleThreshold;
    return result;
  }

  ModuleConfig_PaxcounterConfig._();

  factory ModuleConfig_PaxcounterConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_PaxcounterConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.PaxcounterConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'paxcounterUpdateInterval',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'wifiThreshold', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'bleThreshold', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_PaxcounterConfig clone() =>
      ModuleConfig_PaxcounterConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_PaxcounterConfig copyWith(
          void Function(ModuleConfig_PaxcounterConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_PaxcounterConfig))
          as ModuleConfig_PaxcounterConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_PaxcounterConfig create() =>
      ModuleConfig_PaxcounterConfig._();
  @$core.override
  ModuleConfig_PaxcounterConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_PaxcounterConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_PaxcounterConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_PaxcounterConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_PaxcounterConfig>(create);
  static ModuleConfig_PaxcounterConfig? _defaultInstance;

  ///
  ///  Enable the Paxcounter Module
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get paxcounterUpdateInterval => $_getIZ(1);
  @$pb.TagNumber(2)
  set paxcounterUpdateInterval($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPaxcounterUpdateInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearPaxcounterUpdateInterval() => $_clearField(2);

  ///
  ///  WiFi RSSI threshold. Defaults to -80
  @$pb.TagNumber(3)
  $core.int get wifiThreshold => $_getIZ(2);
  @$pb.TagNumber(3)
  set wifiThreshold($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWifiThreshold() => $_has(2);
  @$pb.TagNumber(3)
  void clearWifiThreshold() => $_clearField(3);

  ///
  ///  BLE RSSI threshold. Defaults to -80
  @$pb.TagNumber(4)
  $core.int get bleThreshold => $_getIZ(3);
  @$pb.TagNumber(4)
  set bleThreshold($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBleThreshold() => $_has(3);
  @$pb.TagNumber(4)
  void clearBleThreshold() => $_clearField(4);
}

///
///  Serial Config
class ModuleConfig_SerialConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_SerialConfig({
    $core.bool? enabled,
    $core.bool? echo,
    $core.int? rxd,
    $core.int? txd,
    ModuleConfig_SerialConfig_Serial_Baud? baud,
    $core.int? timeout,
    ModuleConfig_SerialConfig_Serial_Mode? mode,
    $core.bool? overrideConsoleSerialPort,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (echo != null) result.echo = echo;
    if (rxd != null) result.rxd = rxd;
    if (txd != null) result.txd = txd;
    if (baud != null) result.baud = baud;
    if (timeout != null) result.timeout = timeout;
    if (mode != null) result.mode = mode;
    if (overrideConsoleSerialPort != null)
      result.overrideConsoleSerialPort = overrideConsoleSerialPort;
    return result;
  }

  ModuleConfig_SerialConfig._();

  factory ModuleConfig_SerialConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_SerialConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.SerialConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'echo')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'rxd', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'txd', $pb.PbFieldType.OU3)
    ..e<ModuleConfig_SerialConfig_Serial_Baud>(
        5, _omitFieldNames ? '' : 'baud', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_SerialConfig_Serial_Baud.BAUD_DEFAULT,
        valueOf: ModuleConfig_SerialConfig_Serial_Baud.valueOf,
        enumValues: ModuleConfig_SerialConfig_Serial_Baud.values)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'timeout', $pb.PbFieldType.OU3)
    ..e<ModuleConfig_SerialConfig_Serial_Mode>(
        7, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_SerialConfig_Serial_Mode.DEFAULT,
        valueOf: ModuleConfig_SerialConfig_Serial_Mode.valueOf,
        enumValues: ModuleConfig_SerialConfig_Serial_Mode.values)
    ..aOB(8, _omitFieldNames ? '' : 'overrideConsoleSerialPort')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_SerialConfig clone() =>
      ModuleConfig_SerialConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_SerialConfig copyWith(
          void Function(ModuleConfig_SerialConfig) updates) =>
      super.copyWith((message) => updates(message as ModuleConfig_SerialConfig))
          as ModuleConfig_SerialConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_SerialConfig create() => ModuleConfig_SerialConfig._();
  @$core.override
  ModuleConfig_SerialConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_SerialConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_SerialConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_SerialConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_SerialConfig>(create);
  static ModuleConfig_SerialConfig? _defaultInstance;

  ///
  ///  Preferences for the SerialModule
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(2)
  $core.bool get echo => $_getBF(1);
  @$pb.TagNumber(2)
  set echo($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEcho() => $_has(1);
  @$pb.TagNumber(2)
  void clearEcho() => $_clearField(2);

  ///
  ///  RX pin (should match Arduino gpio pin number)
  @$pb.TagNumber(3)
  $core.int get rxd => $_getIZ(2);
  @$pb.TagNumber(3)
  set rxd($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRxd() => $_has(2);
  @$pb.TagNumber(3)
  void clearRxd() => $_clearField(3);

  ///
  ///  TX pin (should match Arduino gpio pin number)
  @$pb.TagNumber(4)
  $core.int get txd => $_getIZ(3);
  @$pb.TagNumber(4)
  set txd($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTxd() => $_has(3);
  @$pb.TagNumber(4)
  void clearTxd() => $_clearField(4);

  ///
  ///  Serial baud rate
  @$pb.TagNumber(5)
  ModuleConfig_SerialConfig_Serial_Baud get baud => $_getN(4);
  @$pb.TagNumber(5)
  set baud(ModuleConfig_SerialConfig_Serial_Baud value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasBaud() => $_has(4);
  @$pb.TagNumber(5)
  void clearBaud() => $_clearField(5);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(6)
  $core.int get timeout => $_getIZ(5);
  @$pb.TagNumber(6)
  set timeout($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimeout() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimeout() => $_clearField(6);

  ///
  ///  Mode for serial module operation
  @$pb.TagNumber(7)
  ModuleConfig_SerialConfig_Serial_Mode get mode => $_getN(6);
  @$pb.TagNumber(7)
  set mode(ModuleConfig_SerialConfig_Serial_Mode value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMode() => $_has(6);
  @$pb.TagNumber(7)
  void clearMode() => $_clearField(7);

  ///
  ///  Overrides the platform's defacto Serial port instance to use with Serial module config settings
  ///  This is currently only usable in output modes like NMEA / CalTopo and may behave strangely or not work at all in other modes
  ///  Existing logging over the Serial Console will still be present
  @$pb.TagNumber(8)
  $core.bool get overrideConsoleSerialPort => $_getBF(7);
  @$pb.TagNumber(8)
  set overrideConsoleSerialPort($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOverrideConsoleSerialPort() => $_has(7);
  @$pb.TagNumber(8)
  void clearOverrideConsoleSerialPort() => $_clearField(8);
}

///
///  External Notifications Config
class ModuleConfig_ExternalNotificationConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_ExternalNotificationConfig({
    $core.bool? enabled,
    $core.int? outputMs,
    $core.int? output,
    $core.bool? active,
    $core.bool? alertMessage,
    $core.bool? alertBell,
    $core.bool? usePwm,
    $core.int? outputVibra,
    $core.int? outputBuzzer,
    $core.bool? alertMessageVibra,
    $core.bool? alertMessageBuzzer,
    $core.bool? alertBellVibra,
    $core.bool? alertBellBuzzer,
    $core.int? nagTimeout,
    $core.bool? useI2sAsBuzzer,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (outputMs != null) result.outputMs = outputMs;
    if (output != null) result.output = output;
    if (active != null) result.active = active;
    if (alertMessage != null) result.alertMessage = alertMessage;
    if (alertBell != null) result.alertBell = alertBell;
    if (usePwm != null) result.usePwm = usePwm;
    if (outputVibra != null) result.outputVibra = outputVibra;
    if (outputBuzzer != null) result.outputBuzzer = outputBuzzer;
    if (alertMessageVibra != null) result.alertMessageVibra = alertMessageVibra;
    if (alertMessageBuzzer != null)
      result.alertMessageBuzzer = alertMessageBuzzer;
    if (alertBellVibra != null) result.alertBellVibra = alertBellVibra;
    if (alertBellBuzzer != null) result.alertBellBuzzer = alertBellBuzzer;
    if (nagTimeout != null) result.nagTimeout = nagTimeout;
    if (useI2sAsBuzzer != null) result.useI2sAsBuzzer = useI2sAsBuzzer;
    return result;
  }

  ModuleConfig_ExternalNotificationConfig._();

  factory ModuleConfig_ExternalNotificationConfig.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_ExternalNotificationConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.ExternalNotificationConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'outputMs', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'output', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'active')
    ..aOB(5, _omitFieldNames ? '' : 'alertMessage')
    ..aOB(6, _omitFieldNames ? '' : 'alertBell')
    ..aOB(7, _omitFieldNames ? '' : 'usePwm')
    ..a<$core.int>(8, _omitFieldNames ? '' : 'outputVibra', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        9, _omitFieldNames ? '' : 'outputBuzzer', $pb.PbFieldType.OU3)
    ..aOB(10, _omitFieldNames ? '' : 'alertMessageVibra')
    ..aOB(11, _omitFieldNames ? '' : 'alertMessageBuzzer')
    ..aOB(12, _omitFieldNames ? '' : 'alertBellVibra')
    ..aOB(13, _omitFieldNames ? '' : 'alertBellBuzzer')
    ..a<$core.int>(14, _omitFieldNames ? '' : 'nagTimeout', $pb.PbFieldType.OU3)
    ..aOB(15, _omitFieldNames ? '' : 'useI2sAsBuzzer')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_ExternalNotificationConfig clone() =>
      ModuleConfig_ExternalNotificationConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_ExternalNotificationConfig copyWith(
          void Function(ModuleConfig_ExternalNotificationConfig) updates) =>
      super.copyWith((message) =>
              updates(message as ModuleConfig_ExternalNotificationConfig))
          as ModuleConfig_ExternalNotificationConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_ExternalNotificationConfig create() =>
      ModuleConfig_ExternalNotificationConfig._();
  @$core.override
  ModuleConfig_ExternalNotificationConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_ExternalNotificationConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_ExternalNotificationConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_ExternalNotificationConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          ModuleConfig_ExternalNotificationConfig>(create);
  static ModuleConfig_ExternalNotificationConfig? _defaultInstance;

  ///
  ///  Enable the ExternalNotificationModule
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  When using in On/Off mode, keep the output on for this many
  ///  milliseconds. Default 1000ms (1 second).
  @$pb.TagNumber(2)
  $core.int get outputMs => $_getIZ(1);
  @$pb.TagNumber(2)
  set outputMs($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutputMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutputMs() => $_clearField(2);

  ///
  ///  Define the output pin GPIO setting Defaults to
  ///  EXT_NOTIFY_OUT if set for the board.
  ///  In standalone devices this pin should drive the LED to match the UI.
  @$pb.TagNumber(3)
  $core.int get output => $_getIZ(2);
  @$pb.TagNumber(3)
  set output($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutput() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutput() => $_clearField(3);

  ///
  ///  IF this is true, the 'output' Pin will be pulled active high, false
  ///  means active low.
  @$pb.TagNumber(4)
  $core.bool get active => $_getBF(3);
  @$pb.TagNumber(4)
  set active($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearActive() => $_clearField(4);

  ///
  ///  True: Alert when a text message arrives (output)
  @$pb.TagNumber(5)
  $core.bool get alertMessage => $_getBF(4);
  @$pb.TagNumber(5)
  set alertMessage($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlertMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlertMessage() => $_clearField(5);

  ///
  ///  True: Alert when the bell character is received (output)
  @$pb.TagNumber(6)
  $core.bool get alertBell => $_getBF(5);
  @$pb.TagNumber(6)
  set alertBell($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlertBell() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlertBell() => $_clearField(6);

  ///
  ///  use a PWM output instead of a simple on/off output. This will ignore
  ///  the 'output', 'output_ms' and 'active' settings and use the
  ///  device.buzzer_gpio instead.
  @$pb.TagNumber(7)
  $core.bool get usePwm => $_getBF(6);
  @$pb.TagNumber(7)
  set usePwm($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUsePwm() => $_has(6);
  @$pb.TagNumber(7)
  void clearUsePwm() => $_clearField(7);

  ///
  ///  Optional: Define a secondary output pin for a vibra motor
  ///  This is used in standalone devices to match the UI.
  @$pb.TagNumber(8)
  $core.int get outputVibra => $_getIZ(7);
  @$pb.TagNumber(8)
  set outputVibra($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOutputVibra() => $_has(7);
  @$pb.TagNumber(8)
  void clearOutputVibra() => $_clearField(8);

  ///
  ///  Optional: Define a tertiary output pin for an active buzzer
  ///  This is used in standalone devices to to match the UI.
  @$pb.TagNumber(9)
  $core.int get outputBuzzer => $_getIZ(8);
  @$pb.TagNumber(9)
  set outputBuzzer($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOutputBuzzer() => $_has(8);
  @$pb.TagNumber(9)
  void clearOutputBuzzer() => $_clearField(9);

  ///
  ///  True: Alert when a text message arrives (output_vibra)
  @$pb.TagNumber(10)
  $core.bool get alertMessageVibra => $_getBF(9);
  @$pb.TagNumber(10)
  set alertMessageVibra($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAlertMessageVibra() => $_has(9);
  @$pb.TagNumber(10)
  void clearAlertMessageVibra() => $_clearField(10);

  ///
  ///  True: Alert when a text message arrives (output_buzzer)
  @$pb.TagNumber(11)
  $core.bool get alertMessageBuzzer => $_getBF(10);
  @$pb.TagNumber(11)
  set alertMessageBuzzer($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAlertMessageBuzzer() => $_has(10);
  @$pb.TagNumber(11)
  void clearAlertMessageBuzzer() => $_clearField(11);

  ///
  ///  True: Alert when the bell character is received (output_vibra)
  @$pb.TagNumber(12)
  $core.bool get alertBellVibra => $_getBF(11);
  @$pb.TagNumber(12)
  set alertBellVibra($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasAlertBellVibra() => $_has(11);
  @$pb.TagNumber(12)
  void clearAlertBellVibra() => $_clearField(12);

  ///
  ///  True: Alert when the bell character is received (output_buzzer)
  @$pb.TagNumber(13)
  $core.bool get alertBellBuzzer => $_getBF(12);
  @$pb.TagNumber(13)
  set alertBellBuzzer($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasAlertBellBuzzer() => $_has(12);
  @$pb.TagNumber(13)
  void clearAlertBellBuzzer() => $_clearField(13);

  ///
  ///  The notification will toggle with 'output_ms' for this time of seconds.
  ///  Default is 0 which means don't repeat at all. 60 would mean blink
  ///  and/or beep for 60 seconds
  @$pb.TagNumber(14)
  $core.int get nagTimeout => $_getIZ(13);
  @$pb.TagNumber(14)
  set nagTimeout($core.int value) => $_setUnsignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasNagTimeout() => $_has(13);
  @$pb.TagNumber(14)
  void clearNagTimeout() => $_clearField(14);

  ///
  ///  When true, enables devices with native I2S audio output to use the RTTTL over speaker like a buzzer
  ///  T-Watch S3 and T-Deck for example have this capability
  @$pb.TagNumber(15)
  $core.bool get useI2sAsBuzzer => $_getBF(14);
  @$pb.TagNumber(15)
  set useI2sAsBuzzer($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasUseI2sAsBuzzer() => $_has(14);
  @$pb.TagNumber(15)
  void clearUseI2sAsBuzzer() => $_clearField(15);
}

///
///  Store and Forward Module Config
class ModuleConfig_StoreForwardConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_StoreForwardConfig({
    $core.bool? enabled,
    $core.bool? heartbeat,
    $core.int? records,
    $core.int? historyReturnMax,
    $core.int? historyReturnWindow,
    $core.bool? isServer,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (heartbeat != null) result.heartbeat = heartbeat;
    if (records != null) result.records = records;
    if (historyReturnMax != null) result.historyReturnMax = historyReturnMax;
    if (historyReturnWindow != null)
      result.historyReturnWindow = historyReturnWindow;
    if (isServer != null) result.isServer = isServer;
    return result;
  }

  ModuleConfig_StoreForwardConfig._();

  factory ModuleConfig_StoreForwardConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_StoreForwardConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.StoreForwardConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'heartbeat')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'records', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'historyReturnMax', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'historyReturnWindow', $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'isServer')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_StoreForwardConfig clone() =>
      ModuleConfig_StoreForwardConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_StoreForwardConfig copyWith(
          void Function(ModuleConfig_StoreForwardConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_StoreForwardConfig))
          as ModuleConfig_StoreForwardConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_StoreForwardConfig create() =>
      ModuleConfig_StoreForwardConfig._();
  @$core.override
  ModuleConfig_StoreForwardConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_StoreForwardConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_StoreForwardConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_StoreForwardConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_StoreForwardConfig>(
          create);
  static ModuleConfig_StoreForwardConfig? _defaultInstance;

  ///
  ///  Enable the Store and Forward Module
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(2)
  $core.bool get heartbeat => $_getBF(1);
  @$pb.TagNumber(2)
  set heartbeat($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeartbeat() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeartbeat() => $_clearField(2);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(3)
  $core.int get records => $_getIZ(2);
  @$pb.TagNumber(3)
  set records($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRecords() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecords() => $_clearField(3);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(4)
  $core.int get historyReturnMax => $_getIZ(3);
  @$pb.TagNumber(4)
  set historyReturnMax($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHistoryReturnMax() => $_has(3);
  @$pb.TagNumber(4)
  void clearHistoryReturnMax() => $_clearField(4);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(5)
  $core.int get historyReturnWindow => $_getIZ(4);
  @$pb.TagNumber(5)
  set historyReturnWindow($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHistoryReturnWindow() => $_has(4);
  @$pb.TagNumber(5)
  void clearHistoryReturnWindow() => $_clearField(5);

  ///
  ///  Set to true to let this node act as a server that stores received messages and resends them upon request.
  @$pb.TagNumber(6)
  $core.bool get isServer => $_getBF(5);
  @$pb.TagNumber(6)
  set isServer($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsServer() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsServer() => $_clearField(6);
}

///
///  Preferences for the RangeTestModule
class ModuleConfig_RangeTestConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_RangeTestConfig({
    $core.bool? enabled,
    $core.int? sender,
    $core.bool? save,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (sender != null) result.sender = sender;
    if (save != null) result.save = save;
    return result;
  }

  ModuleConfig_RangeTestConfig._();

  factory ModuleConfig_RangeTestConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_RangeTestConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.RangeTestConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'sender', $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'save')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_RangeTestConfig clone() =>
      ModuleConfig_RangeTestConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_RangeTestConfig copyWith(
          void Function(ModuleConfig_RangeTestConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_RangeTestConfig))
          as ModuleConfig_RangeTestConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_RangeTestConfig create() =>
      ModuleConfig_RangeTestConfig._();
  @$core.override
  ModuleConfig_RangeTestConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_RangeTestConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_RangeTestConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_RangeTestConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_RangeTestConfig>(create);
  static ModuleConfig_RangeTestConfig? _defaultInstance;

  ///
  ///  Enable the Range Test Module
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  Send out range test messages from this node
  @$pb.TagNumber(2)
  $core.int get sender => $_getIZ(1);
  @$pb.TagNumber(2)
  set sender($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSender() => $_has(1);
  @$pb.TagNumber(2)
  void clearSender() => $_clearField(2);

  ///
  ///  Bool value indicating that this node should save a RangeTest.csv file.
  ///  ESP32 Only
  @$pb.TagNumber(3)
  $core.bool get save => $_getBF(2);
  @$pb.TagNumber(3)
  set save($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSave() => $_has(2);
  @$pb.TagNumber(3)
  void clearSave() => $_clearField(3);
}

///
///  Configuration for both device and environment metrics
class ModuleConfig_TelemetryConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_TelemetryConfig({
    $core.int? deviceUpdateInterval,
    $core.int? environmentUpdateInterval,
    $core.bool? environmentMeasurementEnabled,
    $core.bool? environmentScreenEnabled,
    $core.bool? environmentDisplayFahrenheit,
    $core.bool? airQualityEnabled,
    $core.int? airQualityInterval,
    $core.bool? powerMeasurementEnabled,
    $core.int? powerUpdateInterval,
    $core.bool? powerScreenEnabled,
    $core.bool? healthMeasurementEnabled,
    $core.int? healthUpdateInterval,
    $core.bool? healthScreenEnabled,
  }) {
    final result = create();
    if (deviceUpdateInterval != null)
      result.deviceUpdateInterval = deviceUpdateInterval;
    if (environmentUpdateInterval != null)
      result.environmentUpdateInterval = environmentUpdateInterval;
    if (environmentMeasurementEnabled != null)
      result.environmentMeasurementEnabled = environmentMeasurementEnabled;
    if (environmentScreenEnabled != null)
      result.environmentScreenEnabled = environmentScreenEnabled;
    if (environmentDisplayFahrenheit != null)
      result.environmentDisplayFahrenheit = environmentDisplayFahrenheit;
    if (airQualityEnabled != null) result.airQualityEnabled = airQualityEnabled;
    if (airQualityInterval != null)
      result.airQualityInterval = airQualityInterval;
    if (powerMeasurementEnabled != null)
      result.powerMeasurementEnabled = powerMeasurementEnabled;
    if (powerUpdateInterval != null)
      result.powerUpdateInterval = powerUpdateInterval;
    if (powerScreenEnabled != null)
      result.powerScreenEnabled = powerScreenEnabled;
    if (healthMeasurementEnabled != null)
      result.healthMeasurementEnabled = healthMeasurementEnabled;
    if (healthUpdateInterval != null)
      result.healthUpdateInterval = healthUpdateInterval;
    if (healthScreenEnabled != null)
      result.healthScreenEnabled = healthScreenEnabled;
    return result;
  }

  ModuleConfig_TelemetryConfig._();

  factory ModuleConfig_TelemetryConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_TelemetryConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.TelemetryConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'deviceUpdateInterval', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'environmentUpdateInterval',
        $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'environmentMeasurementEnabled')
    ..aOB(4, _omitFieldNames ? '' : 'environmentScreenEnabled')
    ..aOB(5, _omitFieldNames ? '' : 'environmentDisplayFahrenheit')
    ..aOB(6, _omitFieldNames ? '' : 'airQualityEnabled')
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'airQualityInterval', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'powerMeasurementEnabled')
    ..a<$core.int>(
        9, _omitFieldNames ? '' : 'powerUpdateInterval', $pb.PbFieldType.OU3)
    ..aOB(10, _omitFieldNames ? '' : 'powerScreenEnabled')
    ..aOB(11, _omitFieldNames ? '' : 'healthMeasurementEnabled')
    ..a<$core.int>(
        12, _omitFieldNames ? '' : 'healthUpdateInterval', $pb.PbFieldType.OU3)
    ..aOB(13, _omitFieldNames ? '' : 'healthScreenEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_TelemetryConfig clone() =>
      ModuleConfig_TelemetryConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_TelemetryConfig copyWith(
          void Function(ModuleConfig_TelemetryConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_TelemetryConfig))
          as ModuleConfig_TelemetryConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_TelemetryConfig create() =>
      ModuleConfig_TelemetryConfig._();
  @$core.override
  ModuleConfig_TelemetryConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_TelemetryConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_TelemetryConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_TelemetryConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_TelemetryConfig>(create);
  static ModuleConfig_TelemetryConfig? _defaultInstance;

  ///
  ///  Interval in seconds of how often we should try to send our
  ///  device metrics to the mesh
  @$pb.TagNumber(1)
  $core.int get deviceUpdateInterval => $_getIZ(0);
  @$pb.TagNumber(1)
  set deviceUpdateInterval($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceUpdateInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceUpdateInterval() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get environmentUpdateInterval => $_getIZ(1);
  @$pb.TagNumber(2)
  set environmentUpdateInterval($core.int value) =>
      $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnvironmentUpdateInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnvironmentUpdateInterval() => $_clearField(2);

  ///
  ///  Preferences for the Telemetry Module (Environment)
  ///  Enable/Disable the telemetry measurement module measurement collection
  @$pb.TagNumber(3)
  $core.bool get environmentMeasurementEnabled => $_getBF(2);
  @$pb.TagNumber(3)
  set environmentMeasurementEnabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnvironmentMeasurementEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnvironmentMeasurementEnabled() => $_clearField(3);

  ///
  ///  Enable/Disable the telemetry measurement module on-device display
  @$pb.TagNumber(4)
  $core.bool get environmentScreenEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set environmentScreenEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnvironmentScreenEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnvironmentScreenEnabled() => $_clearField(4);

  ///
  ///  We'll always read the sensor in Celsius, but sometimes we might want to
  ///  display the results in Fahrenheit as a "user preference".
  @$pb.TagNumber(5)
  $core.bool get environmentDisplayFahrenheit => $_getBF(4);
  @$pb.TagNumber(5)
  set environmentDisplayFahrenheit($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnvironmentDisplayFahrenheit() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnvironmentDisplayFahrenheit() => $_clearField(5);

  ///
  ///  Enable/Disable the air quality metrics
  @$pb.TagNumber(6)
  $core.bool get airQualityEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set airQualityEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAirQualityEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearAirQualityEnabled() => $_clearField(6);

  ///
  ///  Interval in seconds of how often we should try to send our
  ///  air quality metrics to the mesh
  @$pb.TagNumber(7)
  $core.int get airQualityInterval => $_getIZ(6);
  @$pb.TagNumber(7)
  set airQualityInterval($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAirQualityInterval() => $_has(6);
  @$pb.TagNumber(7)
  void clearAirQualityInterval() => $_clearField(7);

  ///
  ///  Enable/disable Power metrics
  @$pb.TagNumber(8)
  $core.bool get powerMeasurementEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set powerMeasurementEnabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPowerMeasurementEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearPowerMeasurementEnabled() => $_clearField(8);

  ///
  ///  Interval in seconds of how often we should try to send our
  ///  power metrics to the mesh
  @$pb.TagNumber(9)
  $core.int get powerUpdateInterval => $_getIZ(8);
  @$pb.TagNumber(9)
  set powerUpdateInterval($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPowerUpdateInterval() => $_has(8);
  @$pb.TagNumber(9)
  void clearPowerUpdateInterval() => $_clearField(9);

  ///
  ///  Enable/Disable the power measurement module on-device display
  @$pb.TagNumber(10)
  $core.bool get powerScreenEnabled => $_getBF(9);
  @$pb.TagNumber(10)
  set powerScreenEnabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPowerScreenEnabled() => $_has(9);
  @$pb.TagNumber(10)
  void clearPowerScreenEnabled() => $_clearField(10);

  ///
  ///  Preferences for the (Health) Telemetry Module
  ///  Enable/Disable the telemetry measurement module measurement collection
  @$pb.TagNumber(11)
  $core.bool get healthMeasurementEnabled => $_getBF(10);
  @$pb.TagNumber(11)
  set healthMeasurementEnabled($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHealthMeasurementEnabled() => $_has(10);
  @$pb.TagNumber(11)
  void clearHealthMeasurementEnabled() => $_clearField(11);

  ///
  ///  Interval in seconds of how often we should try to send our
  ///  health metrics to the mesh
  @$pb.TagNumber(12)
  $core.int get healthUpdateInterval => $_getIZ(11);
  @$pb.TagNumber(12)
  set healthUpdateInterval($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasHealthUpdateInterval() => $_has(11);
  @$pb.TagNumber(12)
  void clearHealthUpdateInterval() => $_clearField(12);

  ///
  ///  Enable/Disable the health telemetry module on-device display
  @$pb.TagNumber(13)
  $core.bool get healthScreenEnabled => $_getBF(12);
  @$pb.TagNumber(13)
  set healthScreenEnabled($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasHealthScreenEnabled() => $_has(12);
  @$pb.TagNumber(13)
  void clearHealthScreenEnabled() => $_clearField(13);
}

///
///  Canned Messages Module Config
class ModuleConfig_CannedMessageConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_CannedMessageConfig({
    $core.bool? rotary1Enabled,
    $core.int? inputbrokerPinA,
    $core.int? inputbrokerPinB,
    $core.int? inputbrokerPinPress,
    ModuleConfig_CannedMessageConfig_InputEventChar? inputbrokerEventCw,
    ModuleConfig_CannedMessageConfig_InputEventChar? inputbrokerEventCcw,
    ModuleConfig_CannedMessageConfig_InputEventChar? inputbrokerEventPress,
    $core.bool? updown1Enabled,
    @$core.Deprecated('This field is deprecated.') $core.bool? enabled,
    @$core.Deprecated('This field is deprecated.')
    $core.String? allowInputSource,
    $core.bool? sendBell,
  }) {
    final result = create();
    if (rotary1Enabled != null) result.rotary1Enabled = rotary1Enabled;
    if (inputbrokerPinA != null) result.inputbrokerPinA = inputbrokerPinA;
    if (inputbrokerPinB != null) result.inputbrokerPinB = inputbrokerPinB;
    if (inputbrokerPinPress != null)
      result.inputbrokerPinPress = inputbrokerPinPress;
    if (inputbrokerEventCw != null)
      result.inputbrokerEventCw = inputbrokerEventCw;
    if (inputbrokerEventCcw != null)
      result.inputbrokerEventCcw = inputbrokerEventCcw;
    if (inputbrokerEventPress != null)
      result.inputbrokerEventPress = inputbrokerEventPress;
    if (updown1Enabled != null) result.updown1Enabled = updown1Enabled;
    if (enabled != null) result.enabled = enabled;
    if (allowInputSource != null) result.allowInputSource = allowInputSource;
    if (sendBell != null) result.sendBell = sendBell;
    return result;
  }

  ModuleConfig_CannedMessageConfig._();

  factory ModuleConfig_CannedMessageConfig.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_CannedMessageConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.CannedMessageConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'rotary1Enabled')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'inputbrokerPinA', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'inputbrokerPinB', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'inputbrokerPinPress', $pb.PbFieldType.OU3)
    ..e<ModuleConfig_CannedMessageConfig_InputEventChar>(
        5, _omitFieldNames ? '' : 'inputbrokerEventCw', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_CannedMessageConfig_InputEventChar.NONE,
        valueOf: ModuleConfig_CannedMessageConfig_InputEventChar.valueOf,
        enumValues: ModuleConfig_CannedMessageConfig_InputEventChar.values)
    ..e<ModuleConfig_CannedMessageConfig_InputEventChar>(
        6, _omitFieldNames ? '' : 'inputbrokerEventCcw', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_CannedMessageConfig_InputEventChar.NONE,
        valueOf: ModuleConfig_CannedMessageConfig_InputEventChar.valueOf,
        enumValues: ModuleConfig_CannedMessageConfig_InputEventChar.values)
    ..e<ModuleConfig_CannedMessageConfig_InputEventChar>(
        7, _omitFieldNames ? '' : 'inputbrokerEventPress', $pb.PbFieldType.OE,
        defaultOrMaker: ModuleConfig_CannedMessageConfig_InputEventChar.NONE,
        valueOf: ModuleConfig_CannedMessageConfig_InputEventChar.valueOf,
        enumValues: ModuleConfig_CannedMessageConfig_InputEventChar.values)
    ..aOB(8, _omitFieldNames ? '' : 'updown1Enabled')
    ..aOB(9, _omitFieldNames ? '' : 'enabled')
    ..aOS(10, _omitFieldNames ? '' : 'allowInputSource')
    ..aOB(11, _omitFieldNames ? '' : 'sendBell')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_CannedMessageConfig clone() =>
      ModuleConfig_CannedMessageConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_CannedMessageConfig copyWith(
          void Function(ModuleConfig_CannedMessageConfig) updates) =>
      super.copyWith(
              (message) => updates(message as ModuleConfig_CannedMessageConfig))
          as ModuleConfig_CannedMessageConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_CannedMessageConfig create() =>
      ModuleConfig_CannedMessageConfig._();
  @$core.override
  ModuleConfig_CannedMessageConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_CannedMessageConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_CannedMessageConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_CannedMessageConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_CannedMessageConfig>(
          create);
  static ModuleConfig_CannedMessageConfig? _defaultInstance;

  ///
  ///  Enable the rotary encoder #1. This is a 'dumb' encoder sending pulses on both A and B pins while rotating.
  @$pb.TagNumber(1)
  $core.bool get rotary1Enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set rotary1Enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRotary1Enabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearRotary1Enabled() => $_clearField(1);

  ///
  ///  GPIO pin for rotary encoder A port.
  @$pb.TagNumber(2)
  $core.int get inputbrokerPinA => $_getIZ(1);
  @$pb.TagNumber(2)
  set inputbrokerPinA($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInputbrokerPinA() => $_has(1);
  @$pb.TagNumber(2)
  void clearInputbrokerPinA() => $_clearField(2);

  ///
  ///  GPIO pin for rotary encoder B port.
  @$pb.TagNumber(3)
  $core.int get inputbrokerPinB => $_getIZ(2);
  @$pb.TagNumber(3)
  set inputbrokerPinB($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInputbrokerPinB() => $_has(2);
  @$pb.TagNumber(3)
  void clearInputbrokerPinB() => $_clearField(3);

  ///
  ///  GPIO pin for rotary encoder Press port.
  @$pb.TagNumber(4)
  $core.int get inputbrokerPinPress => $_getIZ(3);
  @$pb.TagNumber(4)
  set inputbrokerPinPress($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInputbrokerPinPress() => $_has(3);
  @$pb.TagNumber(4)
  void clearInputbrokerPinPress() => $_clearField(4);

  ///
  ///  Generate input event on CW of this kind.
  @$pb.TagNumber(5)
  ModuleConfig_CannedMessageConfig_InputEventChar get inputbrokerEventCw =>
      $_getN(4);
  @$pb.TagNumber(5)
  set inputbrokerEventCw(
          ModuleConfig_CannedMessageConfig_InputEventChar value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasInputbrokerEventCw() => $_has(4);
  @$pb.TagNumber(5)
  void clearInputbrokerEventCw() => $_clearField(5);

  ///
  ///  Generate input event on CCW of this kind.
  @$pb.TagNumber(6)
  ModuleConfig_CannedMessageConfig_InputEventChar get inputbrokerEventCcw =>
      $_getN(5);
  @$pb.TagNumber(6)
  set inputbrokerEventCcw(
          ModuleConfig_CannedMessageConfig_InputEventChar value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasInputbrokerEventCcw() => $_has(5);
  @$pb.TagNumber(6)
  void clearInputbrokerEventCcw() => $_clearField(6);

  ///
  ///  Generate input event on Press of this kind.
  @$pb.TagNumber(7)
  ModuleConfig_CannedMessageConfig_InputEventChar get inputbrokerEventPress =>
      $_getN(6);
  @$pb.TagNumber(7)
  set inputbrokerEventPress(
          ModuleConfig_CannedMessageConfig_InputEventChar value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasInputbrokerEventPress() => $_has(6);
  @$pb.TagNumber(7)
  void clearInputbrokerEventPress() => $_clearField(7);

  ///
  ///  Enable the Up/Down/Select input device. Can be RAK rotary encoder or 3 buttons. Uses the a/b/press definitions from inputbroker.
  @$pb.TagNumber(8)
  $core.bool get updown1Enabled => $_getBF(7);
  @$pb.TagNumber(8)
  set updown1Enabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdown1Enabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpdown1Enabled() => $_clearField(8);

  ///
  ///  Enable/disable CannedMessageModule.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool get enabled => $_getBF(8);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  set enabled($core.bool value) => $_setBool(8, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool hasEnabled() => $_has(8);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  void clearEnabled() => $_clearField(9);

  ///
  ///  Input event origin accepted by the canned message module.
  ///  Can be e.g. "rotEnc1", "upDownEnc1", "scanAndSelect", "cardkb", "serialkb", or keyword "_any"
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(10)
  $core.String get allowInputSource => $_getSZ(9);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(10)
  set allowInputSource($core.String value) => $_setString(9, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(10)
  $core.bool hasAllowInputSource() => $_has(9);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(10)
  void clearAllowInputSource() => $_clearField(10);

  ///
  ///  CannedMessageModule also sends a bell character with the messages.
  ///  ExternalNotificationModule can benefit from this feature.
  @$pb.TagNumber(11)
  $core.bool get sendBell => $_getBF(10);
  @$pb.TagNumber(11)
  set sendBell($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSendBell() => $_has(10);
  @$pb.TagNumber(11)
  void clearSendBell() => $_clearField(11);
}

///
/// Ambient Lighting Module - Settings for control of onboard LEDs to allow users to adjust the brightness levels and respective color levels.
/// Initially created for the RAK14001 RGB LED module.
class ModuleConfig_AmbientLightingConfig extends $pb.GeneratedMessage {
  factory ModuleConfig_AmbientLightingConfig({
    $core.bool? ledState,
    $core.int? current,
    $core.int? red,
    $core.int? green,
    $core.int? blue,
  }) {
    final result = create();
    if (ledState != null) result.ledState = ledState;
    if (current != null) result.current = current;
    if (red != null) result.red = red;
    if (green != null) result.green = green;
    if (blue != null) result.blue = blue;
    return result;
  }

  ModuleConfig_AmbientLightingConfig._();

  factory ModuleConfig_AmbientLightingConfig.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig_AmbientLightingConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig.AmbientLightingConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ledState')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'current', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'red', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'green', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'blue', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_AmbientLightingConfig clone() =>
      ModuleConfig_AmbientLightingConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig_AmbientLightingConfig copyWith(
          void Function(ModuleConfig_AmbientLightingConfig) updates) =>
      super.copyWith((message) =>
              updates(message as ModuleConfig_AmbientLightingConfig))
          as ModuleConfig_AmbientLightingConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig_AmbientLightingConfig create() =>
      ModuleConfig_AmbientLightingConfig._();
  @$core.override
  ModuleConfig_AmbientLightingConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig_AmbientLightingConfig> createRepeated() =>
      $pb.PbList<ModuleConfig_AmbientLightingConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig_AmbientLightingConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig_AmbientLightingConfig>(
          create);
  static ModuleConfig_AmbientLightingConfig? _defaultInstance;

  ///
  ///  Sets LED to on or off.
  @$pb.TagNumber(1)
  $core.bool get ledState => $_getBF(0);
  @$pb.TagNumber(1)
  set ledState($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLedState() => $_has(0);
  @$pb.TagNumber(1)
  void clearLedState() => $_clearField(1);

  ///
  ///  Sets the current for the LED output. Default is 10.
  @$pb.TagNumber(2)
  $core.int get current => $_getIZ(1);
  @$pb.TagNumber(2)
  set current($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrent() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrent() => $_clearField(2);

  ///
  ///  Sets the red LED level. Values are 0-255.
  @$pb.TagNumber(3)
  $core.int get red => $_getIZ(2);
  @$pb.TagNumber(3)
  set red($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRed() => $_has(2);
  @$pb.TagNumber(3)
  void clearRed() => $_clearField(3);

  ///
  ///  Sets the green LED level. Values are 0-255.
  @$pb.TagNumber(4)
  $core.int get green => $_getIZ(3);
  @$pb.TagNumber(4)
  set green($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGreen() => $_has(3);
  @$pb.TagNumber(4)
  void clearGreen() => $_clearField(4);

  ///
  ///  Sets the blue LED level. Values are 0-255.
  @$pb.TagNumber(5)
  $core.int get blue => $_getIZ(4);
  @$pb.TagNumber(5)
  set blue($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBlue() => $_has(4);
  @$pb.TagNumber(5)
  void clearBlue() => $_clearField(5);
}

enum ModuleConfig_PayloadVariant {
  mqtt,
  serial,
  externalNotification,
  storeForward,
  rangeTest,
  telemetry,
  cannedMessage,
  audio,
  remoteHardware,
  neighborInfo,
  ambientLighting,
  detectionSensor,
  paxcounter,
  notSet
}

///
///  Module Config
class ModuleConfig extends $pb.GeneratedMessage {
  factory ModuleConfig({
    ModuleConfig_MQTTConfig? mqtt,
    ModuleConfig_SerialConfig? serial,
    ModuleConfig_ExternalNotificationConfig? externalNotification,
    ModuleConfig_StoreForwardConfig? storeForward,
    ModuleConfig_RangeTestConfig? rangeTest,
    ModuleConfig_TelemetryConfig? telemetry,
    ModuleConfig_CannedMessageConfig? cannedMessage,
    ModuleConfig_AudioConfig? audio,
    ModuleConfig_RemoteHardwareConfig? remoteHardware,
    ModuleConfig_NeighborInfoConfig? neighborInfo,
    ModuleConfig_AmbientLightingConfig? ambientLighting,
    ModuleConfig_DetectionSensorConfig? detectionSensor,
    ModuleConfig_PaxcounterConfig? paxcounter,
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
    if (audio != null) result.audio = audio;
    if (remoteHardware != null) result.remoteHardware = remoteHardware;
    if (neighborInfo != null) result.neighborInfo = neighborInfo;
    if (ambientLighting != null) result.ambientLighting = ambientLighting;
    if (detectionSensor != null) result.detectionSensor = detectionSensor;
    if (paxcounter != null) result.paxcounter = paxcounter;
    return result;
  }

  ModuleConfig._();

  factory ModuleConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModuleConfig_PayloadVariant>
      _ModuleConfig_PayloadVariantByTag = {
    1: ModuleConfig_PayloadVariant.mqtt,
    2: ModuleConfig_PayloadVariant.serial,
    3: ModuleConfig_PayloadVariant.externalNotification,
    4: ModuleConfig_PayloadVariant.storeForward,
    5: ModuleConfig_PayloadVariant.rangeTest,
    6: ModuleConfig_PayloadVariant.telemetry,
    7: ModuleConfig_PayloadVariant.cannedMessage,
    8: ModuleConfig_PayloadVariant.audio,
    9: ModuleConfig_PayloadVariant.remoteHardware,
    10: ModuleConfig_PayloadVariant.neighborInfo,
    11: ModuleConfig_PayloadVariant.ambientLighting,
    12: ModuleConfig_PayloadVariant.detectionSensor,
    13: ModuleConfig_PayloadVariant.paxcounter,
    0: ModuleConfig_PayloadVariant.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ..aOM<ModuleConfig_MQTTConfig>(1, _omitFieldNames ? '' : 'mqtt',
        subBuilder: ModuleConfig_MQTTConfig.create)
    ..aOM<ModuleConfig_SerialConfig>(2, _omitFieldNames ? '' : 'serial',
        subBuilder: ModuleConfig_SerialConfig.create)
    ..aOM<ModuleConfig_ExternalNotificationConfig>(
        3, _omitFieldNames ? '' : 'externalNotification',
        subBuilder: ModuleConfig_ExternalNotificationConfig.create)
    ..aOM<ModuleConfig_StoreForwardConfig>(
        4, _omitFieldNames ? '' : 'storeForward',
        subBuilder: ModuleConfig_StoreForwardConfig.create)
    ..aOM<ModuleConfig_RangeTestConfig>(5, _omitFieldNames ? '' : 'rangeTest',
        subBuilder: ModuleConfig_RangeTestConfig.create)
    ..aOM<ModuleConfig_TelemetryConfig>(6, _omitFieldNames ? '' : 'telemetry',
        subBuilder: ModuleConfig_TelemetryConfig.create)
    ..aOM<ModuleConfig_CannedMessageConfig>(
        7, _omitFieldNames ? '' : 'cannedMessage',
        subBuilder: ModuleConfig_CannedMessageConfig.create)
    ..aOM<ModuleConfig_AudioConfig>(8, _omitFieldNames ? '' : 'audio',
        subBuilder: ModuleConfig_AudioConfig.create)
    ..aOM<ModuleConfig_RemoteHardwareConfig>(
        9, _omitFieldNames ? '' : 'remoteHardware',
        subBuilder: ModuleConfig_RemoteHardwareConfig.create)
    ..aOM<ModuleConfig_NeighborInfoConfig>(
        10, _omitFieldNames ? '' : 'neighborInfo',
        subBuilder: ModuleConfig_NeighborInfoConfig.create)
    ..aOM<ModuleConfig_AmbientLightingConfig>(
        11, _omitFieldNames ? '' : 'ambientLighting',
        subBuilder: ModuleConfig_AmbientLightingConfig.create)
    ..aOM<ModuleConfig_DetectionSensorConfig>(
        12, _omitFieldNames ? '' : 'detectionSensor',
        subBuilder: ModuleConfig_DetectionSensorConfig.create)
    ..aOM<ModuleConfig_PaxcounterConfig>(
        13, _omitFieldNames ? '' : 'paxcounter',
        subBuilder: ModuleConfig_PaxcounterConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig clone() => ModuleConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleConfig copyWith(void Function(ModuleConfig) updates) =>
      super.copyWith((message) => updates(message as ModuleConfig))
          as ModuleConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleConfig create() => ModuleConfig._();
  @$core.override
  ModuleConfig createEmptyInstance() => create();
  static $pb.PbList<ModuleConfig> createRepeated() =>
      $pb.PbList<ModuleConfig>();
  @$core.pragma('dart2js:noInline')
  static ModuleConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleConfig>(create);
  static ModuleConfig? _defaultInstance;

  ModuleConfig_PayloadVariant whichPayloadVariant() =>
      _ModuleConfig_PayloadVariantByTag[$_whichOneof(0)]!;
  void clearPayloadVariant() => $_clearField($_whichOneof(0));

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(1)
  ModuleConfig_MQTTConfig get mqtt => $_getN(0);
  @$pb.TagNumber(1)
  set mqtt(ModuleConfig_MQTTConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMqtt() => $_has(0);
  @$pb.TagNumber(1)
  void clearMqtt() => $_clearField(1);
  @$pb.TagNumber(1)
  ModuleConfig_MQTTConfig ensureMqtt() => $_ensure(0);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(2)
  ModuleConfig_SerialConfig get serial => $_getN(1);
  @$pb.TagNumber(2)
  set serial(ModuleConfig_SerialConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSerial() => $_has(1);
  @$pb.TagNumber(2)
  void clearSerial() => $_clearField(2);
  @$pb.TagNumber(2)
  ModuleConfig_SerialConfig ensureSerial() => $_ensure(1);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(3)
  ModuleConfig_ExternalNotificationConfig get externalNotification => $_getN(2);
  @$pb.TagNumber(3)
  set externalNotification(ModuleConfig_ExternalNotificationConfig value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExternalNotification() => $_has(2);
  @$pb.TagNumber(3)
  void clearExternalNotification() => $_clearField(3);
  @$pb.TagNumber(3)
  ModuleConfig_ExternalNotificationConfig ensureExternalNotification() =>
      $_ensure(2);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(4)
  ModuleConfig_StoreForwardConfig get storeForward => $_getN(3);
  @$pb.TagNumber(4)
  set storeForward(ModuleConfig_StoreForwardConfig value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStoreForward() => $_has(3);
  @$pb.TagNumber(4)
  void clearStoreForward() => $_clearField(4);
  @$pb.TagNumber(4)
  ModuleConfig_StoreForwardConfig ensureStoreForward() => $_ensure(3);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(5)
  ModuleConfig_RangeTestConfig get rangeTest => $_getN(4);
  @$pb.TagNumber(5)
  set rangeTest(ModuleConfig_RangeTestConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRangeTest() => $_has(4);
  @$pb.TagNumber(5)
  void clearRangeTest() => $_clearField(5);
  @$pb.TagNumber(5)
  ModuleConfig_RangeTestConfig ensureRangeTest() => $_ensure(4);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(6)
  ModuleConfig_TelemetryConfig get telemetry => $_getN(5);
  @$pb.TagNumber(6)
  set telemetry(ModuleConfig_TelemetryConfig value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasTelemetry() => $_has(5);
  @$pb.TagNumber(6)
  void clearTelemetry() => $_clearField(6);
  @$pb.TagNumber(6)
  ModuleConfig_TelemetryConfig ensureTelemetry() => $_ensure(5);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(7)
  ModuleConfig_CannedMessageConfig get cannedMessage => $_getN(6);
  @$pb.TagNumber(7)
  set cannedMessage(ModuleConfig_CannedMessageConfig value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCannedMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearCannedMessage() => $_clearField(7);
  @$pb.TagNumber(7)
  ModuleConfig_CannedMessageConfig ensureCannedMessage() => $_ensure(6);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(8)
  ModuleConfig_AudioConfig get audio => $_getN(7);
  @$pb.TagNumber(8)
  set audio(ModuleConfig_AudioConfig value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAudio() => $_has(7);
  @$pb.TagNumber(8)
  void clearAudio() => $_clearField(8);
  @$pb.TagNumber(8)
  ModuleConfig_AudioConfig ensureAudio() => $_ensure(7);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(9)
  ModuleConfig_RemoteHardwareConfig get remoteHardware => $_getN(8);
  @$pb.TagNumber(9)
  set remoteHardware(ModuleConfig_RemoteHardwareConfig value) =>
      $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasRemoteHardware() => $_has(8);
  @$pb.TagNumber(9)
  void clearRemoteHardware() => $_clearField(9);
  @$pb.TagNumber(9)
  ModuleConfig_RemoteHardwareConfig ensureRemoteHardware() => $_ensure(8);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(10)
  ModuleConfig_NeighborInfoConfig get neighborInfo => $_getN(9);
  @$pb.TagNumber(10)
  set neighborInfo(ModuleConfig_NeighborInfoConfig value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasNeighborInfo() => $_has(9);
  @$pb.TagNumber(10)
  void clearNeighborInfo() => $_clearField(10);
  @$pb.TagNumber(10)
  ModuleConfig_NeighborInfoConfig ensureNeighborInfo() => $_ensure(9);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(11)
  ModuleConfig_AmbientLightingConfig get ambientLighting => $_getN(10);
  @$pb.TagNumber(11)
  set ambientLighting(ModuleConfig_AmbientLightingConfig value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasAmbientLighting() => $_has(10);
  @$pb.TagNumber(11)
  void clearAmbientLighting() => $_clearField(11);
  @$pb.TagNumber(11)
  ModuleConfig_AmbientLightingConfig ensureAmbientLighting() => $_ensure(10);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(12)
  ModuleConfig_DetectionSensorConfig get detectionSensor => $_getN(11);
  @$pb.TagNumber(12)
  set detectionSensor(ModuleConfig_DetectionSensorConfig value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasDetectionSensor() => $_has(11);
  @$pb.TagNumber(12)
  void clearDetectionSensor() => $_clearField(12);
  @$pb.TagNumber(12)
  ModuleConfig_DetectionSensorConfig ensureDetectionSensor() => $_ensure(11);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(13)
  ModuleConfig_PaxcounterConfig get paxcounter => $_getN(12);
  @$pb.TagNumber(13)
  set paxcounter(ModuleConfig_PaxcounterConfig value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasPaxcounter() => $_has(12);
  @$pb.TagNumber(13)
  void clearPaxcounter() => $_clearField(13);
  @$pb.TagNumber(13)
  ModuleConfig_PaxcounterConfig ensurePaxcounter() => $_ensure(12);
}

///
///  A GPIO pin definition for remote hardware module
class RemoteHardwarePin extends $pb.GeneratedMessage {
  factory RemoteHardwarePin({
    $core.int? gpioPin,
    $core.String? name,
    RemoteHardwarePinType? type,
  }) {
    final result = create();
    if (gpioPin != null) result.gpioPin = gpioPin;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    return result;
  }

  RemoteHardwarePin._();

  factory RemoteHardwarePin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoteHardwarePin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteHardwarePin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'gpioPin', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..e<RemoteHardwarePinType>(
        3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: RemoteHardwarePinType.UNKNOWN,
        valueOf: RemoteHardwarePinType.valueOf,
        enumValues: RemoteHardwarePinType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteHardwarePin clone() => RemoteHardwarePin()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteHardwarePin copyWith(void Function(RemoteHardwarePin) updates) =>
      super.copyWith((message) => updates(message as RemoteHardwarePin))
          as RemoteHardwarePin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoteHardwarePin create() => RemoteHardwarePin._();
  @$core.override
  RemoteHardwarePin createEmptyInstance() => create();
  static $pb.PbList<RemoteHardwarePin> createRepeated() =>
      $pb.PbList<RemoteHardwarePin>();
  @$core.pragma('dart2js:noInline')
  static RemoteHardwarePin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteHardwarePin>(create);
  static RemoteHardwarePin? _defaultInstance;

  ///
  ///  GPIO Pin number (must match Arduino)
  @$pb.TagNumber(1)
  $core.int get gpioPin => $_getIZ(0);
  @$pb.TagNumber(1)
  set gpioPin($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGpioPin() => $_has(0);
  @$pb.TagNumber(1)
  void clearGpioPin() => $_clearField(1);

  ///
  ///  Name for the GPIO pin (i.e. Front gate, mailbox, etc)
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  ///
  ///  Type of GPIO access available to consumers on the mesh
  @$pb.TagNumber(3)
  RemoteHardwarePinType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(RemoteHardwarePinType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
