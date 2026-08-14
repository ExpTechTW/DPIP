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

import 'interdevice.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'interdevice.pbenum.dart';

enum SensorData_Data { floatValue, uint32Value, notSet }

class SensorData extends $pb.GeneratedMessage {
  factory SensorData({
    MessageType? type,
    $core.double? floatValue,
    $core.int? uint32Value,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (floatValue != null) result.floatValue = floatValue;
    if (uint32Value != null) result.uint32Value = uint32Value;
    return result;
  }

  SensorData._();

  factory SensorData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SensorData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SensorData_Data> _SensorData_DataByTag = {
    2: SensorData_Data.floatValue,
    3: SensorData_Data.uint32Value,
    0: SensorData_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..e<MessageType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: MessageType.ACK,
        valueOf: MessageType.valueOf,
        enumValues: MessageType.values)
    ..a<$core.double>(
        2, _omitFieldNames ? '' : 'floatValue', $pb.PbFieldType.OF)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'uint32Value', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData clone() => SensorData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData copyWith(void Function(SensorData) updates) =>
      super.copyWith((message) => updates(message as SensorData)) as SensorData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SensorData create() => SensorData._();
  @$core.override
  SensorData createEmptyInstance() => create();
  static $pb.PbList<SensorData> createRepeated() => $pb.PbList<SensorData>();
  @$core.pragma('dart2js:noInline')
  static SensorData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SensorData>(create);
  static SensorData? _defaultInstance;

  SensorData_Data whichData() => _SensorData_DataByTag[$_whichOneof(0)]!;
  void clearData() => $_clearField($_whichOneof(0));

  /// The message type
  @$pb.TagNumber(1)
  MessageType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(MessageType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get floatValue => $_getN(1);
  @$pb.TagNumber(2)
  set floatValue($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFloatValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearFloatValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get uint32Value => $_getIZ(2);
  @$pb.TagNumber(3)
  set uint32Value($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUint32Value() => $_has(2);
  @$pb.TagNumber(3)
  void clearUint32Value() => $_clearField(3);
}

enum InterdeviceMessage_Data { nmea, sensor, notSet }

class InterdeviceMessage extends $pb.GeneratedMessage {
  factory InterdeviceMessage({
    $core.String? nmea,
    SensorData? sensor,
  }) {
    final result = create();
    if (nmea != null) result.nmea = nmea;
    if (sensor != null) result.sensor = sensor;
    return result;
  }

  InterdeviceMessage._();

  factory InterdeviceMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InterdeviceMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InterdeviceMessage_Data>
      _InterdeviceMessage_DataByTag = {
    1: InterdeviceMessage_Data.nmea,
    2: InterdeviceMessage_Data.sensor,
    0: InterdeviceMessage_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InterdeviceMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'nmea')
    ..aOM<SensorData>(2, _omitFieldNames ? '' : 'sensor',
        subBuilder: SensorData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterdeviceMessage clone() => InterdeviceMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterdeviceMessage copyWith(void Function(InterdeviceMessage) updates) =>
      super.copyWith((message) => updates(message as InterdeviceMessage))
          as InterdeviceMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InterdeviceMessage create() => InterdeviceMessage._();
  @$core.override
  InterdeviceMessage createEmptyInstance() => create();
  static $pb.PbList<InterdeviceMessage> createRepeated() =>
      $pb.PbList<InterdeviceMessage>();
  @$core.pragma('dart2js:noInline')
  static InterdeviceMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InterdeviceMessage>(create);
  static InterdeviceMessage? _defaultInstance;

  InterdeviceMessage_Data whichData() =>
      _InterdeviceMessage_DataByTag[$_whichOneof(0)]!;
  void clearData() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get nmea => $_getSZ(0);
  @$pb.TagNumber(1)
  set nmea($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNmea() => $_has(0);
  @$pb.TagNumber(1)
  void clearNmea() => $_clearField(1);

  @$pb.TagNumber(2)
  SensorData get sensor => $_getN(1);
  @$pb.TagNumber(2)
  set sensor(SensorData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSensor() => $_has(1);
  @$pb.TagNumber(2)
  void clearSensor() => $_clearField(2);
  @$pb.TagNumber(2)
  SensorData ensureSensor() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
