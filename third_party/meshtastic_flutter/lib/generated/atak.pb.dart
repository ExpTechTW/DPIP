// This is a generated file - do not edit.
//
// Generated from meshtastic/atak.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'atak.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'atak.pbenum.dart';

enum TAKPacket_PayloadVariant { pli, chat, detail, notSet }

///
///  Packets for the official ATAK Plugin
class TAKPacket extends $pb.GeneratedMessage {
  factory TAKPacket({
    $core.bool? isCompressed,
    Contact? contact,
    Group? group,
    Status? status,
    PLI? pli,
    GeoChat? chat,
    $core.List<$core.int>? detail,
  }) {
    final result = create();
    if (isCompressed != null) result.isCompressed = isCompressed;
    if (contact != null) result.contact = contact;
    if (group != null) result.group = group;
    if (status != null) result.status = status;
    if (pli != null) result.pli = pli;
    if (chat != null) result.chat = chat;
    if (detail != null) result.detail = detail;
    return result;
  }

  TAKPacket._();

  factory TAKPacket.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TAKPacket.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, TAKPacket_PayloadVariant>
      _TAKPacket_PayloadVariantByTag = {
    5: TAKPacket_PayloadVariant.pli,
    6: TAKPacket_PayloadVariant.chat,
    7: TAKPacket_PayloadVariant.detail,
    0: TAKPacket_PayloadVariant.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TAKPacket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [5, 6, 7])
    ..aOB(1, _omitFieldNames ? '' : 'isCompressed')
    ..aOM<Contact>(2, _omitFieldNames ? '' : 'contact',
        subBuilder: Contact.create)
    ..aOM<Group>(3, _omitFieldNames ? '' : 'group', subBuilder: Group.create)
    ..aOM<Status>(4, _omitFieldNames ? '' : 'status', subBuilder: Status.create)
    ..aOM<PLI>(5, _omitFieldNames ? '' : 'pli', subBuilder: PLI.create)
    ..aOM<GeoChat>(6, _omitFieldNames ? '' : 'chat', subBuilder: GeoChat.create)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'detail', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TAKPacket clone() => TAKPacket()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TAKPacket copyWith(void Function(TAKPacket) updates) =>
      super.copyWith((message) => updates(message as TAKPacket)) as TAKPacket;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TAKPacket create() => TAKPacket._();
  @$core.override
  TAKPacket createEmptyInstance() => create();
  static $pb.PbList<TAKPacket> createRepeated() => $pb.PbList<TAKPacket>();
  @$core.pragma('dart2js:noInline')
  static TAKPacket getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TAKPacket>(create);
  static TAKPacket? _defaultInstance;

  TAKPacket_PayloadVariant whichPayloadVariant() =>
      _TAKPacket_PayloadVariantByTag[$_whichOneof(0)]!;
  void clearPayloadVariant() => $_clearField($_whichOneof(0));

  ///
  ///  Are the payloads strings compressed for LoRA transport?
  @$pb.TagNumber(1)
  $core.bool get isCompressed => $_getBF(0);
  @$pb.TagNumber(1)
  set isCompressed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsCompressed() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsCompressed() => $_clearField(1);

  ///
  ///  The contact / callsign for ATAK user
  @$pb.TagNumber(2)
  Contact get contact => $_getN(1);
  @$pb.TagNumber(2)
  set contact(Contact value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContact() => $_has(1);
  @$pb.TagNumber(2)
  void clearContact() => $_clearField(2);
  @$pb.TagNumber(2)
  Contact ensureContact() => $_ensure(1);

  ///
  ///  The group for ATAK user
  @$pb.TagNumber(3)
  Group get group => $_getN(2);
  @$pb.TagNumber(3)
  set group(Group value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGroup() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroup() => $_clearField(3);
  @$pb.TagNumber(3)
  Group ensureGroup() => $_ensure(2);

  ///
  ///  The status of the ATAK EUD
  @$pb.TagNumber(4)
  Status get status => $_getN(3);
  @$pb.TagNumber(4)
  set status(Status value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);
  @$pb.TagNumber(4)
  Status ensureStatus() => $_ensure(3);

  ///
  ///  TAK position report
  @$pb.TagNumber(5)
  PLI get pli => $_getN(4);
  @$pb.TagNumber(5)
  set pli(PLI value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPli() => $_has(4);
  @$pb.TagNumber(5)
  void clearPli() => $_clearField(5);
  @$pb.TagNumber(5)
  PLI ensurePli() => $_ensure(4);

  ///
  ///  ATAK GeoChat message
  @$pb.TagNumber(6)
  GeoChat get chat => $_getN(5);
  @$pb.TagNumber(6)
  set chat(GeoChat value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasChat() => $_has(5);
  @$pb.TagNumber(6)
  void clearChat() => $_clearField(6);
  @$pb.TagNumber(6)
  GeoChat ensureChat() => $_ensure(5);

  ///
  ///  Generic CoT detail XML
  ///  May be compressed / truncated by the sender (EUD)
  @$pb.TagNumber(7)
  $core.List<$core.int> get detail => $_getN(6);
  @$pb.TagNumber(7)
  set detail($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDetail() => $_has(6);
  @$pb.TagNumber(7)
  void clearDetail() => $_clearField(7);
}

///
///  ATAK GeoChat message
class GeoChat extends $pb.GeneratedMessage {
  factory GeoChat({
    $core.String? message,
    $core.String? to,
    $core.String? toCallsign,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (to != null) result.to = to;
    if (toCallsign != null) result.toCallsign = toCallsign;
    return result;
  }

  GeoChat._();

  factory GeoChat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GeoChat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GeoChat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aOS(2, _omitFieldNames ? '' : 'to')
    ..aOS(3, _omitFieldNames ? '' : 'toCallsign')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoChat clone() => GeoChat()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoChat copyWith(void Function(GeoChat) updates) =>
      super.copyWith((message) => updates(message as GeoChat)) as GeoChat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeoChat create() => GeoChat._();
  @$core.override
  GeoChat createEmptyInstance() => create();
  static $pb.PbList<GeoChat> createRepeated() => $pb.PbList<GeoChat>();
  @$core.pragma('dart2js:noInline')
  static GeoChat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GeoChat>(create);
  static GeoChat? _defaultInstance;

  ///
  ///  The text message
  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  ///
  ///  Uid recipient of the message
  @$pb.TagNumber(2)
  $core.String get to => $_getSZ(1);
  @$pb.TagNumber(2)
  set to($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);

  ///
  ///  Callsign of the recipient for the message
  @$pb.TagNumber(3)
  $core.String get toCallsign => $_getSZ(2);
  @$pb.TagNumber(3)
  set toCallsign($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToCallsign() => $_has(2);
  @$pb.TagNumber(3)
  void clearToCallsign() => $_clearField(3);
}

///
///  ATAK Group
///  <__group role='Team Member' name='Cyan'/>
class Group extends $pb.GeneratedMessage {
  factory Group({
    MemberRole? role,
    Team? team,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (team != null) result.team = team;
    return result;
  }

  Group._();

  factory Group.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Group.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Group',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..e<MemberRole>(1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: MemberRole.Unspecifed,
        valueOf: MemberRole.valueOf,
        enumValues: MemberRole.values)
    ..e<Team>(2, _omitFieldNames ? '' : 'team', $pb.PbFieldType.OE,
        defaultOrMaker: Team.Unspecifed_Color,
        valueOf: Team.valueOf,
        enumValues: Team.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group clone() => Group()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group copyWith(void Function(Group) updates) =>
      super.copyWith((message) => updates(message as Group)) as Group;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Group create() => Group._();
  @$core.override
  Group createEmptyInstance() => create();
  static $pb.PbList<Group> createRepeated() => $pb.PbList<Group>();
  @$core.pragma('dart2js:noInline')
  static Group getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Group>(create);
  static Group? _defaultInstance;

  ///
  ///  Role of the group member
  @$pb.TagNumber(1)
  MemberRole get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(MemberRole value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  ///
  ///  Team (color)
  ///  Default Cyan
  @$pb.TagNumber(2)
  Team get team => $_getN(1);
  @$pb.TagNumber(2)
  set team(Team value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTeam() => $_has(1);
  @$pb.TagNumber(2)
  void clearTeam() => $_clearField(2);
}

///
///  ATAK EUD Status
///  status battery='100'
class Status extends $pb.GeneratedMessage {
  factory Status({
    $core.int? battery,
  }) {
    final result = create();
    if (battery != null) result.battery = battery;
    return result;
  }

  Status._();

  factory Status.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Status.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Status',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'battery', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status clone() => Status()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status copyWith(void Function(Status) updates) =>
      super.copyWith((message) => updates(message as Status)) as Status;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Status create() => Status._();
  @$core.override
  Status createEmptyInstance() => create();
  static $pb.PbList<Status> createRepeated() => $pb.PbList<Status>();
  @$core.pragma('dart2js:noInline')
  static Status getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Status>(create);
  static Status? _defaultInstance;

  ///
  ///  Battery level
  @$pb.TagNumber(1)
  $core.int get battery => $_getIZ(0);
  @$pb.TagNumber(1)
  set battery($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBattery() => $_has(0);
  @$pb.TagNumber(1)
  void clearBattery() => $_clearField(1);
}

///
///  ATAK Contact
///  contact endpoint='0.0.0.0:4242:tcp' phone='+12345678' callsign='FALKE'
class Contact extends $pb.GeneratedMessage {
  factory Contact({
    $core.String? callsign,
    $core.String? deviceCallsign,
  }) {
    final result = create();
    if (callsign != null) result.callsign = callsign;
    if (deviceCallsign != null) result.deviceCallsign = deviceCallsign;
    return result;
  }

  Contact._();

  factory Contact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Contact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Contact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callsign')
    ..aOS(2, _omitFieldNames ? '' : 'deviceCallsign')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contact clone() => Contact()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contact copyWith(void Function(Contact) updates) =>
      super.copyWith((message) => updates(message as Contact)) as Contact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Contact create() => Contact._();
  @$core.override
  Contact createEmptyInstance() => create();
  static $pb.PbList<Contact> createRepeated() => $pb.PbList<Contact>();
  @$core.pragma('dart2js:noInline')
  static Contact getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Contact>(create);
  static Contact? _defaultInstance;

  ///
  ///  Callsign
  @$pb.TagNumber(1)
  $core.String get callsign => $_getSZ(0);
  @$pb.TagNumber(1)
  set callsign($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallsign() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallsign() => $_clearField(1);

  ///
  ///  Device callsign
  @$pb.TagNumber(2)
  $core.String get deviceCallsign => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceCallsign($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceCallsign() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceCallsign() => $_clearField(2);
}

///
///  Position Location Information from ATAK
class PLI extends $pb.GeneratedMessage {
  factory PLI({
    $core.int? latitudeI,
    $core.int? longitudeI,
    $core.int? altitude,
    $core.int? speed,
    $core.int? course,
  }) {
    final result = create();
    if (latitudeI != null) result.latitudeI = latitudeI;
    if (longitudeI != null) result.longitudeI = longitudeI;
    if (altitude != null) result.altitude = altitude;
    if (speed != null) result.speed = speed;
    if (course != null) result.course = course;
    return result;
  }

  PLI._();

  factory PLI.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PLI.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PLI',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'latitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'longitudeI', $pb.PbFieldType.OSF3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'altitude', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'speed', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'course', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PLI clone() => PLI()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PLI copyWith(void Function(PLI) updates) =>
      super.copyWith((message) => updates(message as PLI)) as PLI;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PLI create() => PLI._();
  @$core.override
  PLI createEmptyInstance() => create();
  static $pb.PbList<PLI> createRepeated() => $pb.PbList<PLI>();
  @$core.pragma('dart2js:noInline')
  static PLI getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PLI>(create);
  static PLI? _defaultInstance;

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
  ///  The new preferred location encoding, multiply by 1e-7 to get degrees
  ///  in floating point
  @$pb.TagNumber(2)
  $core.int get longitudeI => $_getIZ(1);
  @$pb.TagNumber(2)
  set longitudeI($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongitudeI() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongitudeI() => $_clearField(2);

  ///
  ///  Altitude (ATAK prefers HAE)
  @$pb.TagNumber(3)
  $core.int get altitude => $_getIZ(2);
  @$pb.TagNumber(3)
  set altitude($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAltitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearAltitude() => $_clearField(3);

  ///
  ///  Speed
  @$pb.TagNumber(4)
  $core.int get speed => $_getIZ(3);
  @$pb.TagNumber(4)
  set speed($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpeed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeed() => $_clearField(4);

  ///
  ///  Course in degrees
  @$pb.TagNumber(5)
  $core.int get course => $_getIZ(4);
  @$pb.TagNumber(5)
  set course($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCourse() => $_has(4);
  @$pb.TagNumber(5)
  void clearCourse() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
