// This is a generated file - do not edit.
//
// Generated from meshtastic/deviceonly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'channel.pb.dart' as $2;
import 'config.pbenum.dart' as $4;
import 'localonly.pb.dart' as $3;
import 'mesh.pb.dart' as $1;
import 'telemetry.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///
///  Position with static location information only for NodeDBLite
class PositionLite extends $pb.GeneratedMessage {
  factory PositionLite({
    $core.int? latitudeI,
    $core.int? longitudeI,
    $core.int? altitude,
    $core.int? time,
    $1.Position_LocSource? locationSource,
  }) {
    final result = create();
    if (latitudeI != null) result.latitudeI = latitudeI;
    if (longitudeI != null) result.longitudeI = longitudeI;
    if (altitude != null) result.altitude = altitude;
    if (time != null) result.time = time;
    if (locationSource != null) result.locationSource = locationSource;
    return result;
  }

  PositionLite._();

  factory PositionLite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PositionLite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PositionLite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'latitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'longitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'altitude', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'time', $pb.PbFieldType.OF3)
    ..e<$1.Position_LocSource>(
        5, _omitFieldNames ? '' : 'locationSource', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Position_LocSource.LOC_UNSET,
        valueOf: $1.Position_LocSource.valueOf,
        enumValues: $1.Position_LocSource.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PositionLite clone() => PositionLite()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PositionLite copyWith(void Function(PositionLite) updates) =>
      super.copyWith((message) => updates(message as PositionLite))
          as PositionLite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PositionLite create() => PositionLite._();
  @$core.override
  PositionLite createEmptyInstance() => create();
  static $pb.PbList<PositionLite> createRepeated() =>
      $pb.PbList<PositionLite>();
  @$core.pragma('dart2js:noInline')
  static PositionLite getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PositionLite>(create);
  static PositionLite? _defaultInstance;

  ///
  ///  The new preferred location encoding, multiply by 1e-7 to get degrees
  ///  in floating point
  @$pb.TagNumber(1)
  $core.int get latitudeI => $_getIZ(0);
  @$pb.TagNumber(1)
  set latitudeI($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLatitudeI() => $_has(0);
  @$pb.TagNumber(1)
  void clearLatitudeI() => $_clearField(1);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(2)
  $core.int get longitudeI => $_getIZ(1);
  @$pb.TagNumber(2)
  set longitudeI($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongitudeI() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongitudeI() => $_clearField(2);

  ///
  ///  In meters above MSL (but see issue #359)
  @$pb.TagNumber(3)
  $core.int get altitude => $_getIZ(2);
  @$pb.TagNumber(3)
  set altitude($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAltitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearAltitude() => $_clearField(3);

  ///
  ///  This is usually not sent over the mesh (to save space), but it is sent
  ///  from the phone so that the local device can set its RTC If it is sent over
  ///  the mesh (because there are devices on the mesh without GPS), it will only
  ///  be sent by devices which has a hardware GPS clock.
  ///  seconds since 1970
  @$pb.TagNumber(4)
  $core.int get time => $_getIZ(3);
  @$pb.TagNumber(4)
  set time($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearTime() => $_clearField(4);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(5)
  $1.Position_LocSource get locationSource => $_getN(4);
  @$pb.TagNumber(5)
  set locationSource($1.Position_LocSource value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLocationSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearLocationSource() => $_clearField(5);
}

class UserLite extends $pb.GeneratedMessage {
  factory UserLite({
    @$core.Deprecated('This field is deprecated.')
    $core.List<$core.int>? macaddr,
    $core.String? longName,
    $core.String? shortName,
    $1.HardwareModel? hwModel,
    $core.bool? isLicensed,
    $4.Config_DeviceConfig_Role? role,
    $core.List<$core.int>? publicKey,
    $core.bool? isUnmessagable,
  }) {
    final result = create();
    if (macaddr != null) result.macaddr = macaddr;
    if (longName != null) result.longName = longName;
    if (shortName != null) result.shortName = shortName;
    if (hwModel != null) result.hwModel = hwModel;
    if (isLicensed != null) result.isLicensed = isLicensed;
    if (role != null) result.role = role;
    if (publicKey != null) result.publicKey = publicKey;
    if (isUnmessagable != null) result.isUnmessagable = isUnmessagable;
    return result;
  }

  UserLite._();

  factory UserLite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserLite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserLite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'macaddr', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'longName')
    ..aOS(3, _omitFieldNames ? '' : 'shortName')
    ..e<$1.HardwareModel>(
        4, _omitFieldNames ? '' : 'hwModel', $pb.PbFieldType.OE,
        defaultOrMaker: $1.HardwareModel.UNSET,
        valueOf: $1.HardwareModel.valueOf,
        enumValues: $1.HardwareModel.values)
    ..aOB(5, _omitFieldNames ? '' : 'isLicensed')
    ..e<$4.Config_DeviceConfig_Role>(
        6, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: $4.Config_DeviceConfig_Role.CLIENT,
        valueOf: $4.Config_DeviceConfig_Role.valueOf,
        enumValues: $4.Config_DeviceConfig_Role.values)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..aOB(9, _omitFieldNames ? '' : 'isUnmessagable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserLite clone() => UserLite()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserLite copyWith(void Function(UserLite) updates) =>
      super.copyWith((message) => updates(message as UserLite)) as UserLite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserLite create() => UserLite._();
  @$core.override
  UserLite createEmptyInstance() => create();
  static $pb.PbList<UserLite> createRepeated() => $pb.PbList<UserLite>();
  @$core.pragma('dart2js:noInline')
  static UserLite getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserLite>(create);
  static UserLite? _defaultInstance;

  ///
  ///  This is the addr of the radio.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.List<$core.int> get macaddr => $_getN(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  set macaddr($core.List<$core.int> value) => $_setBytes(0, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.bool hasMacaddr() => $_has(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  void clearMacaddr() => $_clearField(1);

  ///
  ///  A full name for this user, i.e. "Kevin Hester"
  @$pb.TagNumber(2)
  $core.String get longName => $_getSZ(1);
  @$pb.TagNumber(2)
  set longName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongName() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongName() => $_clearField(2);

  ///
  ///  A VERY short name, ideally two characters.
  ///  Suitable for a tiny OLED screen
  @$pb.TagNumber(3)
  $core.String get shortName => $_getSZ(2);
  @$pb.TagNumber(3)
  set shortName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasShortName() => $_has(2);
  @$pb.TagNumber(3)
  void clearShortName() => $_clearField(3);

  ///
  ///  TBEAM, HELTEC, etc...
  ///  Starting in 1.2.11 moved to hw_model enum in the NodeInfo object.
  ///  Apps will still need the string here for older builds
  ///  (so OTA update can find the right image), but if the enum is available it will be used instead.
  @$pb.TagNumber(4)
  $1.HardwareModel get hwModel => $_getN(3);
  @$pb.TagNumber(4)
  set hwModel($1.HardwareModel value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasHwModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearHwModel() => $_clearField(4);

  ///
  ///  In some regions Ham radio operators have different bandwidth limitations than others.
  ///  If this user is a licensed operator, set this flag.
  ///  Also, "long_name" should be their licence number.
  @$pb.TagNumber(5)
  $core.bool get isLicensed => $_getBF(4);
  @$pb.TagNumber(5)
  set isLicensed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsLicensed() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsLicensed() => $_clearField(5);

  ///
  ///  Indicates that the user's role in the mesh
  @$pb.TagNumber(6)
  $4.Config_DeviceConfig_Role get role => $_getN(5);
  @$pb.TagNumber(6)
  set role($4.Config_DeviceConfig_Role value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRole() => $_has(5);
  @$pb.TagNumber(6)
  void clearRole() => $_clearField(6);

  ///
  ///  The public key of the user's device.
  ///  This is sent out to other nodes on the mesh to allow them to compute a shared secret key.
  @$pb.TagNumber(7)
  $core.List<$core.int> get publicKey => $_getN(6);
  @$pb.TagNumber(7)
  set publicKey($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPublicKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearPublicKey() => $_clearField(7);

  ///
  ///  Whether or not the node can be messaged
  @$pb.TagNumber(9)
  $core.bool get isUnmessagable => $_getBF(7);
  @$pb.TagNumber(9)
  set isUnmessagable($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(9)
  $core.bool hasIsUnmessagable() => $_has(7);
  @$pb.TagNumber(9)
  void clearIsUnmessagable() => $_clearField(9);
}

class NodeInfoLite extends $pb.GeneratedMessage {
  factory NodeInfoLite({
    $core.int? num,
    UserLite? user,
    PositionLite? position,
    $core.double? snr,
    $core.int? lastHeard,
    $0.DeviceMetrics? deviceMetrics,
    $core.int? channel,
    $core.bool? viaMqtt,
    $core.int? hopsAway,
    $core.bool? isFavorite,
    $core.bool? isIgnored,
    $core.int? nextHop,
    $core.int? bitfield,
  }) {
    final result = create();
    if (num != null) result.num = num;
    if (user != null) result.user = user;
    if (position != null) result.position = position;
    if (snr != null) result.snr = snr;
    if (lastHeard != null) result.lastHeard = lastHeard;
    if (deviceMetrics != null) result.deviceMetrics = deviceMetrics;
    if (channel != null) result.channel = channel;
    if (viaMqtt != null) result.viaMqtt = viaMqtt;
    if (hopsAway != null) result.hopsAway = hopsAway;
    if (isFavorite != null) result.isFavorite = isFavorite;
    if (isIgnored != null) result.isIgnored = isIgnored;
    if (nextHop != null) result.nextHop = nextHop;
    if (bitfield != null) result.bitfield = bitfield;
    return result;
  }

  NodeInfoLite._();

  factory NodeInfoLite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeInfoLite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeInfoLite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'num', $pb.PbFieldType.OU3)
    ..aOM<UserLite>(2, _omitFieldNames ? '' : 'user',
        subBuilder: UserLite.create)
    ..aOM<PositionLite>(3, _omitFieldNames ? '' : 'position',
        subBuilder: PositionLite.create)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'snr', $pb.PbFieldType.OF)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'lastHeard', $pb.PbFieldType.OF3)
    ..aOM<$0.DeviceMetrics>(6, _omitFieldNames ? '' : 'deviceMetrics',
        subBuilder: $0.DeviceMetrics.create)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'channel', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'viaMqtt')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'hopsAway', $pb.PbFieldType.OU3)
    ..aOB(10, _omitFieldNames ? '' : 'isFavorite')
    ..aOB(11, _omitFieldNames ? '' : 'isIgnored')
    ..a<$core.int>(12, _omitFieldNames ? '' : 'nextHop', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'bitfield', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfoLite clone() => NodeInfoLite()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfoLite copyWith(void Function(NodeInfoLite) updates) =>
      super.copyWith((message) => updates(message as NodeInfoLite))
          as NodeInfoLite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeInfoLite create() => NodeInfoLite._();
  @$core.override
  NodeInfoLite createEmptyInstance() => create();
  static $pb.PbList<NodeInfoLite> createRepeated() =>
      $pb.PbList<NodeInfoLite>();
  @$core.pragma('dart2js:noInline')
  static NodeInfoLite getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeInfoLite>(create);
  static NodeInfoLite? _defaultInstance;

  ///
  ///  The node number
  @$pb.TagNumber(1)
  $core.int get num => $_getIZ(0);
  @$pb.TagNumber(1)
  set num($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearNum() => $_clearField(1);

  ///
  ///  The user info for this node
  @$pb.TagNumber(2)
  UserLite get user => $_getN(1);
  @$pb.TagNumber(2)
  set user(UserLite value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  UserLite ensureUser() => $_ensure(1);

  ///
  ///  This position data. Note: before 1.2.14 we would also store the last time we've heard from this node in position.time, that is no longer true.
  ///  Position.time now indicates the last time we received a POSITION from that node.
  @$pb.TagNumber(3)
  PositionLite get position => $_getN(2);
  @$pb.TagNumber(3)
  set position(PositionLite value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearPosition() => $_clearField(3);
  @$pb.TagNumber(3)
  PositionLite ensurePosition() => $_ensure(2);

  ///
  ///  Returns the Signal-to-noise ratio (SNR) of the last received message,
  ///  as measured by the receiver. Return SNR of the last received message in dB
  @$pb.TagNumber(4)
  $core.double get snr => $_getN(3);
  @$pb.TagNumber(4)
  set snr($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSnr() => $_has(3);
  @$pb.TagNumber(4)
  void clearSnr() => $_clearField(4);

  ///
  ///  Set to indicate the last time we received a packet from this node
  @$pb.TagNumber(5)
  $core.int get lastHeard => $_getIZ(4);
  @$pb.TagNumber(5)
  set lastHeard($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastHeard() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastHeard() => $_clearField(5);

  ///
  ///  The latest device metrics for the node.
  @$pb.TagNumber(6)
  $0.DeviceMetrics get deviceMetrics => $_getN(5);
  @$pb.TagNumber(6)
  set deviceMetrics($0.DeviceMetrics value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDeviceMetrics() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceMetrics() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.DeviceMetrics ensureDeviceMetrics() => $_ensure(5);

  ///
  ///  local channel index we heard that node on. Only populated if its not the default channel.
  @$pb.TagNumber(7)
  $core.int get channel => $_getIZ(6);
  @$pb.TagNumber(7)
  set channel($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChannel() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannel() => $_clearField(7);

  ///
  ///  True if we witnessed the node over MQTT instead of LoRA transport
  @$pb.TagNumber(8)
  $core.bool get viaMqtt => $_getBF(7);
  @$pb.TagNumber(8)
  set viaMqtt($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasViaMqtt() => $_has(7);
  @$pb.TagNumber(8)
  void clearViaMqtt() => $_clearField(8);

  ///
  ///  Number of hops away from us this node is (0 if direct neighbor)
  @$pb.TagNumber(9)
  $core.int get hopsAway => $_getIZ(8);
  @$pb.TagNumber(9)
  set hopsAway($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHopsAway() => $_has(8);
  @$pb.TagNumber(9)
  void clearHopsAway() => $_clearField(9);

  ///
  ///  True if node is in our favorites list
  ///  Persists between NodeDB internal clean ups
  @$pb.TagNumber(10)
  $core.bool get isFavorite => $_getBF(9);
  @$pb.TagNumber(10)
  set isFavorite($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsFavorite() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsFavorite() => $_clearField(10);

  ///
  ///  True if node is in our ignored list
  ///  Persists between NodeDB internal clean ups
  @$pb.TagNumber(11)
  $core.bool get isIgnored => $_getBF(10);
  @$pb.TagNumber(11)
  set isIgnored($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIsIgnored() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsIgnored() => $_clearField(11);

  ///
  ///  Last byte of the node number of the node that should be used as the next hop to reach this node.
  @$pb.TagNumber(12)
  $core.int get nextHop => $_getIZ(11);
  @$pb.TagNumber(12)
  set nextHop($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasNextHop() => $_has(11);
  @$pb.TagNumber(12)
  void clearNextHop() => $_clearField(12);

  ///
  ///  Bitfield for storing booleans.
  ///  LSB 0 is_key_manually_verified
  @$pb.TagNumber(13)
  $core.int get bitfield => $_getIZ(12);
  @$pb.TagNumber(13)
  set bitfield($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBitfield() => $_has(12);
  @$pb.TagNumber(13)
  void clearBitfield() => $_clearField(13);
}

///
///  This message is never sent over the wire, but it is used for serializing DB
///  state to flash in the device code
///  FIXME, since we write this each time we enter deep sleep (and have infinite
///  flash) it would be better to use some sort of append only data structure for
///  the receive queue and use the preferences store for the other stuff
class DeviceState extends $pb.GeneratedMessage {
  factory DeviceState({
    $1.MyNodeInfo? myNode,
    $1.User? owner,
    $core.Iterable<$1.MeshPacket>? receiveQueue,
    $1.MeshPacket? rxTextMessage,
    $core.int? version,
    @$core.Deprecated('This field is deprecated.') $core.bool? noSave,
    @$core.Deprecated('This field is deprecated.') $core.bool? didGpsReset,
    $1.MeshPacket? rxWaypoint,
    $core.Iterable<$1.NodeRemoteHardwarePin>? nodeRemoteHardwarePins,
  }) {
    final result = create();
    if (myNode != null) result.myNode = myNode;
    if (owner != null) result.owner = owner;
    if (receiveQueue != null) result.receiveQueue.addAll(receiveQueue);
    if (rxTextMessage != null) result.rxTextMessage = rxTextMessage;
    if (version != null) result.version = version;
    if (noSave != null) result.noSave = noSave;
    if (didGpsReset != null) result.didGpsReset = didGpsReset;
    if (rxWaypoint != null) result.rxWaypoint = rxWaypoint;
    if (nodeRemoteHardwarePins != null)
      result.nodeRemoteHardwarePins.addAll(nodeRemoteHardwarePins);
    return result;
  }

  DeviceState._();

  factory DeviceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<$1.MyNodeInfo>(2, _omitFieldNames ? '' : 'myNode',
        subBuilder: $1.MyNodeInfo.create)
    ..aOM<$1.User>(3, _omitFieldNames ? '' : 'owner',
        subBuilder: $1.User.create)
    ..pc<$1.MeshPacket>(
        5, _omitFieldNames ? '' : 'receiveQueue', $pb.PbFieldType.PM,
        subBuilder: $1.MeshPacket.create)
    ..aOM<$1.MeshPacket>(7, _omitFieldNames ? '' : 'rxTextMessage',
        subBuilder: $1.MeshPacket.create)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..aOB(9, _omitFieldNames ? '' : 'noSave')
    ..aOB(11, _omitFieldNames ? '' : 'didGpsReset')
    ..aOM<$1.MeshPacket>(12, _omitFieldNames ? '' : 'rxWaypoint',
        subBuilder: $1.MeshPacket.create)
    ..pc<$1.NodeRemoteHardwarePin>(
        13, _omitFieldNames ? '' : 'nodeRemoteHardwarePins', $pb.PbFieldType.PM,
        subBuilder: $1.NodeRemoteHardwarePin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceState clone() => DeviceState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceState copyWith(void Function(DeviceState) updates) =>
      super.copyWith((message) => updates(message as DeviceState))
          as DeviceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceState create() => DeviceState._();
  @$core.override
  DeviceState createEmptyInstance() => create();
  static $pb.PbList<DeviceState> createRepeated() => $pb.PbList<DeviceState>();
  @$core.pragma('dart2js:noInline')
  static DeviceState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceState>(create);
  static DeviceState? _defaultInstance;

  ///
  ///  Read only settings/info about this node
  @$pb.TagNumber(2)
  $1.MyNodeInfo get myNode => $_getN(0);
  @$pb.TagNumber(2)
  set myNode($1.MyNodeInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMyNode() => $_has(0);
  @$pb.TagNumber(2)
  void clearMyNode() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.MyNodeInfo ensureMyNode() => $_ensure(0);

  ///
  ///  My owner info
  @$pb.TagNumber(3)
  $1.User get owner => $_getN(1);
  @$pb.TagNumber(3)
  set owner($1.User value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(3)
  void clearOwner() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.User ensureOwner() => $_ensure(1);

  ///
  ///  Received packets saved for delivery to the phone
  @$pb.TagNumber(5)
  $pb.PbList<$1.MeshPacket> get receiveQueue => $_getList(2);

  ///
  ///  We keep the last received text message (only) stored in the device flash,
  ///  so we can show it on the screen.
  ///  Might be null
  @$pb.TagNumber(7)
  $1.MeshPacket get rxTextMessage => $_getN(3);
  @$pb.TagNumber(7)
  set rxTextMessage($1.MeshPacket value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRxTextMessage() => $_has(3);
  @$pb.TagNumber(7)
  void clearRxTextMessage() => $_clearField(7);
  @$pb.TagNumber(7)
  $1.MeshPacket ensureRxTextMessage() => $_ensure(3);

  ///
  ///  A version integer used to invalidate old save files when we make
  ///  incompatible changes This integer is set at build time and is private to
  ///  NodeDB.cpp in the device code.
  @$pb.TagNumber(8)
  $core.int get version => $_getIZ(4);
  @$pb.TagNumber(8)
  set version($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(4);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  ///
  ///  Used only during development.
  ///  Indicates developer is testing and changes should never be saved to flash.
  ///  Deprecated in 2.3.1
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool get noSave => $_getBF(5);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  set noSave($core.bool value) => $_setBool(5, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool hasNoSave() => $_has(5);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  void clearNoSave() => $_clearField(9);

  ///
  ///  Previously used to manage GPS factory resets.
  ///  Deprecated in 2.5.23
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  $core.bool get didGpsReset => $_getBF(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  set didGpsReset($core.bool value) => $_setBool(6, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  $core.bool hasDidGpsReset() => $_has(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  void clearDidGpsReset() => $_clearField(11);

  ///
  ///  We keep the last received waypoint stored in the device flash,
  ///  so we can show it on the screen.
  ///  Might be null
  @$pb.TagNumber(12)
  $1.MeshPacket get rxWaypoint => $_getN(7);
  @$pb.TagNumber(12)
  set rxWaypoint($1.MeshPacket value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasRxWaypoint() => $_has(7);
  @$pb.TagNumber(12)
  void clearRxWaypoint() => $_clearField(12);
  @$pb.TagNumber(12)
  $1.MeshPacket ensureRxWaypoint() => $_ensure(7);

  ///
  ///  The mesh's nodes with their available gpio pins for RemoteHardware module
  @$pb.TagNumber(13)
  $pb.PbList<$1.NodeRemoteHardwarePin> get nodeRemoteHardwarePins =>
      $_getList(8);
}

class NodeDatabase extends $pb.GeneratedMessage {
  factory NodeDatabase({
    $core.int? version,
    $core.Iterable<NodeInfoLite>? nodes,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (nodes != null) result.nodes.addAll(nodes);
    return result;
  }

  NodeDatabase._();

  factory NodeDatabase.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeDatabase.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeDatabase',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..pc<NodeInfoLite>(2, _omitFieldNames ? '' : 'nodes', $pb.PbFieldType.PM,
        subBuilder: NodeInfoLite.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeDatabase clone() => NodeDatabase()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeDatabase copyWith(void Function(NodeDatabase) updates) =>
      super.copyWith((message) => updates(message as NodeDatabase))
          as NodeDatabase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeDatabase create() => NodeDatabase._();
  @$core.override
  NodeDatabase createEmptyInstance() => create();
  static $pb.PbList<NodeDatabase> createRepeated() =>
      $pb.PbList<NodeDatabase>();
  @$core.pragma('dart2js:noInline')
  static NodeDatabase getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeDatabase>(create);
  static NodeDatabase? _defaultInstance;

  ///
  ///  A version integer used to invalidate old save files when we make
  ///  incompatible changes This integer is set at build time and is private to
  ///  NodeDB.cpp in the device code.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  ///
  ///  New lite version of NodeDB to decrease memory footprint
  @$pb.TagNumber(2)
  $pb.PbList<NodeInfoLite> get nodes => $_getList(1);
}

///
///  The on-disk saved channels
class ChannelFile extends $pb.GeneratedMessage {
  factory ChannelFile({
    $core.Iterable<$2.Channel>? channels,
    $core.int? version,
  }) {
    final result = create();
    if (channels != null) result.channels.addAll(channels);
    if (version != null) result.version = version;
    return result;
  }

  ChannelFile._();

  factory ChannelFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..pc<$2.Channel>(1, _omitFieldNames ? '' : 'channels', $pb.PbFieldType.PM,
        subBuilder: $2.Channel.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelFile clone() => ChannelFile()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelFile copyWith(void Function(ChannelFile) updates) =>
      super.copyWith((message) => updates(message as ChannelFile))
          as ChannelFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelFile create() => ChannelFile._();
  @$core.override
  ChannelFile createEmptyInstance() => create();
  static $pb.PbList<ChannelFile> createRepeated() => $pb.PbList<ChannelFile>();
  @$core.pragma('dart2js:noInline')
  static ChannelFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelFile>(create);
  static ChannelFile? _defaultInstance;

  ///
  ///  The channels our node knows about
  @$pb.TagNumber(1)
  $pb.PbList<$2.Channel> get channels => $_getList(0);

  ///
  ///  A version integer used to invalidate old save files when we make
  ///  incompatible changes This integer is set at build time and is private to
  ///  NodeDB.cpp in the device code.
  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

///
///  The on-disk backup of the node's preferences
class BackupPreferences extends $pb.GeneratedMessage {
  factory BackupPreferences({
    $core.int? version,
    $core.int? timestamp,
    $3.LocalConfig? config,
    $3.LocalModuleConfig? moduleConfig,
    ChannelFile? channels,
    $1.User? owner,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (timestamp != null) result.timestamp = timestamp;
    if (config != null) result.config = config;
    if (moduleConfig != null) result.moduleConfig = moduleConfig;
    if (channels != null) result.channels = channels;
    if (owner != null) result.owner = owner;
    return result;
  }

  BackupPreferences._();

  factory BackupPreferences.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackupPreferences.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackupPreferences',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OF3)
    ..aOM<$3.LocalConfig>(3, _omitFieldNames ? '' : 'config',
        subBuilder: $3.LocalConfig.create)
    ..aOM<$3.LocalModuleConfig>(4, _omitFieldNames ? '' : 'moduleConfig',
        subBuilder: $3.LocalModuleConfig.create)
    ..aOM<ChannelFile>(5, _omitFieldNames ? '' : 'channels',
        subBuilder: ChannelFile.create)
    ..aOM<$1.User>(6, _omitFieldNames ? '' : 'owner',
        subBuilder: $1.User.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackupPreferences clone() => BackupPreferences()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackupPreferences copyWith(void Function(BackupPreferences) updates) =>
      super.copyWith((message) => updates(message as BackupPreferences))
          as BackupPreferences;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackupPreferences create() => BackupPreferences._();
  @$core.override
  BackupPreferences createEmptyInstance() => create();
  static $pb.PbList<BackupPreferences> createRepeated() =>
      $pb.PbList<BackupPreferences>();
  @$core.pragma('dart2js:noInline')
  static BackupPreferences getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackupPreferences>(create);
  static BackupPreferences? _defaultInstance;

  ///
  ///  The version of the backup
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  ///
  ///  The timestamp of the backup (if node has time)
  @$pb.TagNumber(2)
  $core.int get timestamp => $_getIZ(1);
  @$pb.TagNumber(2)
  set timestamp($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => $_clearField(2);

  ///
  ///  The node's configuration
  @$pb.TagNumber(3)
  $3.LocalConfig get config => $_getN(2);
  @$pb.TagNumber(3)
  set config($3.LocalConfig value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfig() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.LocalConfig ensureConfig() => $_ensure(2);

  ///
  ///  The node's module configuration
  @$pb.TagNumber(4)
  $3.LocalModuleConfig get moduleConfig => $_getN(3);
  @$pb.TagNumber(4)
  set moduleConfig($3.LocalModuleConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasModuleConfig() => $_has(3);
  @$pb.TagNumber(4)
  void clearModuleConfig() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.LocalModuleConfig ensureModuleConfig() => $_ensure(3);

  ///
  ///  The node's channels
  @$pb.TagNumber(5)
  ChannelFile get channels => $_getN(4);
  @$pb.TagNumber(5)
  set channels(ChannelFile value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasChannels() => $_has(4);
  @$pb.TagNumber(5)
  void clearChannels() => $_clearField(5);
  @$pb.TagNumber(5)
  ChannelFile ensureChannels() => $_ensure(4);

  ///
  ///  The node's user (owner) information
  @$pb.TagNumber(6)
  $1.User get owner => $_getN(5);
  @$pb.TagNumber(6)
  set owner($1.User value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOwner() => $_has(5);
  @$pb.TagNumber(6)
  void clearOwner() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.User ensureOwner() => $_ensure(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
