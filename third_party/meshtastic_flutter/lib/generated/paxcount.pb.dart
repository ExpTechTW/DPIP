// This is a generated file - do not edit.
//
// Generated from meshtastic/paxcount.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///
///  TODO: REPLACE
class Paxcount extends $pb.GeneratedMessage {
  factory Paxcount({
    $core.int? wifi,
    $core.int? ble,
    $core.int? uptime,
  }) {
    final result = create();
    if (wifi != null) result.wifi = wifi;
    if (ble != null) result.ble = ble;
    if (uptime != null) result.uptime = uptime;
    return result;
  }

  Paxcount._();

  factory Paxcount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Paxcount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Paxcount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'wifi', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ble', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'uptime', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Paxcount clone() => Paxcount()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Paxcount copyWith(void Function(Paxcount) updates) =>
      super.copyWith((message) => updates(message as Paxcount)) as Paxcount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Paxcount create() => Paxcount._();
  @$core.override
  Paxcount createEmptyInstance() => create();
  static $pb.PbList<Paxcount> createRepeated() => $pb.PbList<Paxcount>();
  @$core.pragma('dart2js:noInline')
  static Paxcount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Paxcount>(create);
  static Paxcount? _defaultInstance;

  ///
  ///  seen Wifi devices
  @$pb.TagNumber(1)
  $core.int get wifi => $_getIZ(0);
  @$pb.TagNumber(1)
  set wifi($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWifi() => $_has(0);
  @$pb.TagNumber(1)
  void clearWifi() => $_clearField(1);

  ///
  ///  Seen BLE devices
  @$pb.TagNumber(2)
  $core.int get ble => $_getIZ(1);
  @$pb.TagNumber(2)
  set ble($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBle() => $_has(1);
  @$pb.TagNumber(2)
  void clearBle() => $_clearField(2);

  ///
  ///  Uptime in seconds
  @$pb.TagNumber(3)
  $core.int get uptime => $_getIZ(2);
  @$pb.TagNumber(3)
  set uptime($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUptime() => $_has(2);
  @$pb.TagNumber(3)
  void clearUptime() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
