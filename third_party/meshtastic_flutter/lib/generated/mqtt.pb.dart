// This is a generated file - do not edit.
//
// Generated from meshtastic/mqtt.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'config.pbenum.dart' as $1;
import 'mesh.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///
///  This message wraps a MeshPacket with extra metadata about the sender and how it arrived.
class ServiceEnvelope extends $pb.GeneratedMessage {
  factory ServiceEnvelope({
    $0.MeshPacket? packet,
    $core.String? channelId,
    $core.String? gatewayId,
  }) {
    final result = create();
    if (packet != null) result.packet = packet;
    if (channelId != null) result.channelId = channelId;
    if (gatewayId != null) result.gatewayId = gatewayId;
    return result;
  }

  ServiceEnvelope._();

  factory ServiceEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<$0.MeshPacket>(1, _omitFieldNames ? '' : 'packet',
        subBuilder: $0.MeshPacket.create)
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'gatewayId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceEnvelope clone() => ServiceEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceEnvelope copyWith(void Function(ServiceEnvelope) updates) =>
      super.copyWith((message) => updates(message as ServiceEnvelope))
          as ServiceEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceEnvelope create() => ServiceEnvelope._();
  @$core.override
  ServiceEnvelope createEmptyInstance() => create();
  static $pb.PbList<ServiceEnvelope> createRepeated() =>
      $pb.PbList<ServiceEnvelope>();
  @$core.pragma('dart2js:noInline')
  static ServiceEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceEnvelope>(create);
  static ServiceEnvelope? _defaultInstance;

  ///
  ///  The (probably encrypted) packet
  @$pb.TagNumber(1)
  $0.MeshPacket get packet => $_getN(0);
  @$pb.TagNumber(1)
  set packet($0.MeshPacket value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPacket() => $_has(0);
  @$pb.TagNumber(1)
  void clearPacket() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.MeshPacket ensurePacket() => $_ensure(0);

  ///
  ///  The global channel ID it was sent on
  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  ///
  ///  The sending gateway node ID. Can we use this to authenticate/prevent fake
  ///  nodeid impersonation for senders? - i.e. use gateway/mesh id (which is authenticated) + local node id as
  ///  the globally trusted nodenum
  @$pb.TagNumber(3)
  $core.String get gatewayId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gatewayId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGatewayId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGatewayId() => $_clearField(3);
}

///
///  Information about a node intended to be reported unencrypted to a map using MQTT.
class MapReport extends $pb.GeneratedMessage {
  factory MapReport({
    $core.String? longName,
    $core.String? shortName,
    $1.Config_DeviceConfig_Role? role,
    $0.HardwareModel? hwModel,
    $core.String? firmwareVersion,
    $1.Config_LoRaConfig_RegionCode? region,
    $1.Config_LoRaConfig_ModemPreset? modemPreset,
    $core.bool? hasDefaultChannel,
    $core.int? latitudeI,
    $core.int? longitudeI,
    $core.int? altitude,
    $core.int? positionPrecision,
    $core.int? numOnlineLocalNodes,
    $core.bool? hasOptedReportLocation,
  }) {
    final result = create();
    if (longName != null) result.longName = longName;
    if (shortName != null) result.shortName = shortName;
    if (role != null) result.role = role;
    if (hwModel != null) result.hwModel = hwModel;
    if (firmwareVersion != null) result.firmwareVersion = firmwareVersion;
    if (region != null) result.region = region;
    if (modemPreset != null) result.modemPreset = modemPreset;
    if (hasDefaultChannel != null) result.hasDefaultChannel = hasDefaultChannel;
    if (latitudeI != null) result.latitudeI = latitudeI;
    if (longitudeI != null) result.longitudeI = longitudeI;
    if (altitude != null) result.altitude = altitude;
    if (positionPrecision != null) result.positionPrecision = positionPrecision;
    if (numOnlineLocalNodes != null)
      result.numOnlineLocalNodes = numOnlineLocalNodes;
    if (hasOptedReportLocation != null)
      result.hasOptedReportLocation = hasOptedReportLocation;
    return result;
  }

  MapReport._();

  factory MapReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MapReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MapReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'longName')
    ..aOS(2, _omitFieldNames ? '' : 'shortName')
    ..e<$1.Config_DeviceConfig_Role>(
        3, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Config_DeviceConfig_Role.CLIENT,
        valueOf: $1.Config_DeviceConfig_Role.valueOf,
        enumValues: $1.Config_DeviceConfig_Role.values)
    ..e<$0.HardwareModel>(
        4, _omitFieldNames ? '' : 'hwModel', $pb.PbFieldType.OE,
        defaultOrMaker: $0.HardwareModel.UNSET,
        valueOf: $0.HardwareModel.valueOf,
        enumValues: $0.HardwareModel.values)
    ..aOS(5, _omitFieldNames ? '' : 'firmwareVersion')
    ..e<$1.Config_LoRaConfig_RegionCode>(
        6, _omitFieldNames ? '' : 'region', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Config_LoRaConfig_RegionCode.UNSET,
        valueOf: $1.Config_LoRaConfig_RegionCode.valueOf,
        enumValues: $1.Config_LoRaConfig_RegionCode.values)
    ..e<$1.Config_LoRaConfig_ModemPreset>(
        7, _omitFieldNames ? '' : 'modemPreset', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Config_LoRaConfig_ModemPreset.LONG_FAST,
        valueOf: $1.Config_LoRaConfig_ModemPreset.valueOf,
        enumValues: $1.Config_LoRaConfig_ModemPreset.values)
    ..aOB(8, _omitFieldNames ? '' : 'hasDefaultChannel')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'latitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(
        10, _omitFieldNames ? '' : 'longitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'altitude', $pb.PbFieldType.O3)
    ..a<$core.int>(
        12, _omitFieldNames ? '' : 'positionPrecision', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        13, _omitFieldNames ? '' : 'numOnlineLocalNodes', $pb.PbFieldType.OU3)
    ..aOB(14, _omitFieldNames ? '' : 'hasOptedReportLocation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapReport clone() => MapReport()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapReport copyWith(void Function(MapReport) updates) =>
      super.copyWith((message) => updates(message as MapReport)) as MapReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MapReport create() => MapReport._();
  @$core.override
  MapReport createEmptyInstance() => create();
  static $pb.PbList<MapReport> createRepeated() => $pb.PbList<MapReport>();
  @$core.pragma('dart2js:noInline')
  static MapReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MapReport>(create);
  static MapReport? _defaultInstance;

  ///
  ///  A full name for this user, i.e. "Kevin Hester"
  @$pb.TagNumber(1)
  $core.String get longName => $_getSZ(0);
  @$pb.TagNumber(1)
  set longName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLongName() => $_has(0);
  @$pb.TagNumber(1)
  void clearLongName() => $_clearField(1);

  ///
  ///  A VERY short name, ideally two characters.
  ///  Suitable for a tiny OLED screen
  @$pb.TagNumber(2)
  $core.String get shortName => $_getSZ(1);
  @$pb.TagNumber(2)
  set shortName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShortName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortName() => $_clearField(2);

  ///
  ///  Role of the node that applies specific settings for a particular use-case
  @$pb.TagNumber(3)
  $1.Config_DeviceConfig_Role get role => $_getN(2);
  @$pb.TagNumber(3)
  set role($1.Config_DeviceConfig_Role value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearRole() => $_clearField(3);

  ///
  ///  Hardware model of the node, i.e. T-Beam, Heltec V3, etc...
  @$pb.TagNumber(4)
  $0.HardwareModel get hwModel => $_getN(3);
  @$pb.TagNumber(4)
  set hwModel($0.HardwareModel value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasHwModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearHwModel() => $_clearField(4);

  ///
  ///  Device firmware version string
  @$pb.TagNumber(5)
  $core.String get firmwareVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set firmwareVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFirmwareVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearFirmwareVersion() => $_clearField(5);

  ///
  ///  The region code for the radio (US, CN, EU433, etc...)
  @$pb.TagNumber(6)
  $1.Config_LoRaConfig_RegionCode get region => $_getN(5);
  @$pb.TagNumber(6)
  set region($1.Config_LoRaConfig_RegionCode value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRegion() => $_has(5);
  @$pb.TagNumber(6)
  void clearRegion() => $_clearField(6);

  ///
  ///  Modem preset used by the radio (LongFast, MediumSlow, etc...)
  @$pb.TagNumber(7)
  $1.Config_LoRaConfig_ModemPreset get modemPreset => $_getN(6);
  @$pb.TagNumber(7)
  set modemPreset($1.Config_LoRaConfig_ModemPreset value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasModemPreset() => $_has(6);
  @$pb.TagNumber(7)
  void clearModemPreset() => $_clearField(7);

  ///
  ///  Whether the node has a channel with default PSK and name (LongFast, MediumSlow, etc...)
  ///  and it uses the default frequency slot given the region and modem preset.
  @$pb.TagNumber(8)
  $core.bool get hasDefaultChannel => $_getBF(7);
  @$pb.TagNumber(8)
  set hasDefaultChannel($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasDefaultChannel() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasDefaultChannel() => $_clearField(8);

  ///
  ///  Latitude: multiply by 1e-7 to get degrees in floating point
  @$pb.TagNumber(9)
  $core.int get latitudeI => $_getIZ(8);
  @$pb.TagNumber(9)
  set latitudeI($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLatitudeI() => $_has(8);
  @$pb.TagNumber(9)
  void clearLatitudeI() => $_clearField(9);

  ///
  ///  Longitude: multiply by 1e-7 to get degrees in floating point
  @$pb.TagNumber(10)
  $core.int get longitudeI => $_getIZ(9);
  @$pb.TagNumber(10)
  set longitudeI($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLongitudeI() => $_has(9);
  @$pb.TagNumber(10)
  void clearLongitudeI() => $_clearField(10);

  ///
  ///  Altitude in meters above MSL
  @$pb.TagNumber(11)
  $core.int get altitude => $_getIZ(10);
  @$pb.TagNumber(11)
  set altitude($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAltitude() => $_has(10);
  @$pb.TagNumber(11)
  void clearAltitude() => $_clearField(11);

  ///
  ///  Indicates the bits of precision for latitude and longitude set by the sending node
  @$pb.TagNumber(12)
  $core.int get positionPrecision => $_getIZ(11);
  @$pb.TagNumber(12)
  set positionPrecision($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPositionPrecision() => $_has(11);
  @$pb.TagNumber(12)
  void clearPositionPrecision() => $_clearField(12);

  ///
  ///  Number of online nodes (heard in the last 2 hours) this node has in its list that were received locally (not via MQTT)
  @$pb.TagNumber(13)
  $core.int get numOnlineLocalNodes => $_getIZ(12);
  @$pb.TagNumber(13)
  set numOnlineLocalNodes($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasNumOnlineLocalNodes() => $_has(12);
  @$pb.TagNumber(13)
  void clearNumOnlineLocalNodes() => $_clearField(13);

  ///
  ///  User has opted in to share their location (map report) with the mqtt server
  ///  Controlled by map_report.should_report_location
  @$pb.TagNumber(14)
  $core.bool get hasOptedReportLocation => $_getBF(13);
  @$pb.TagNumber(14)
  set hasOptedReportLocation($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasHasOptedReportLocation() => $_has(13);
  @$pb.TagNumber(14)
  void clearHasOptedReportLocation() => $_clearField(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
