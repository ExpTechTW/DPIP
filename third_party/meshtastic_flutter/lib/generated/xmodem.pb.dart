// This is a generated file - do not edit.
//
// Generated from meshtastic/xmodem.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'xmodem.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'xmodem.pbenum.dart';

class XModem extends $pb.GeneratedMessage {
  factory XModem({
    XModem_Control? control,
    $core.int? seq,
    $core.int? crc16,
    $core.List<$core.int>? buffer,
  }) {
    final result = create();
    if (control != null) result.control = control;
    if (seq != null) result.seq = seq;
    if (crc16 != null) result.crc16 = crc16;
    if (buffer != null) result.buffer = buffer;
    return result;
  }

  XModem._();

  factory XModem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory XModem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'XModem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..e<XModem_Control>(1, _omitFieldNames ? '' : 'control', $pb.PbFieldType.OE,
        defaultOrMaker: XModem_Control.NUL,
        valueOf: XModem_Control.valueOf,
        enumValues: XModem_Control.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'crc16', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'buffer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  XModem clone() => XModem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  XModem copyWith(void Function(XModem) updates) =>
      super.copyWith((message) => updates(message as XModem)) as XModem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static XModem create() => XModem._();
  @$core.override
  XModem createEmptyInstance() => create();
  static $pb.PbList<XModem> createRepeated() => $pb.PbList<XModem>();
  @$core.pragma('dart2js:noInline')
  static XModem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<XModem>(create);
  static XModem? _defaultInstance;

  @$pb.TagNumber(1)
  XModem_Control get control => $_getN(0);
  @$pb.TagNumber(1)
  set control(XModem_Control value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasControl() => $_has(0);
  @$pb.TagNumber(1)
  void clearControl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get seq => $_getIZ(1);
  @$pb.TagNumber(2)
  set seq($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get crc16 => $_getIZ(2);
  @$pb.TagNumber(3)
  set crc16($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCrc16() => $_has(2);
  @$pb.TagNumber(3)
  void clearCrc16() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get buffer => $_getN(3);
  @$pb.TagNumber(4)
  set buffer($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBuffer() => $_has(3);
  @$pb.TagNumber(4)
  void clearBuffer() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
