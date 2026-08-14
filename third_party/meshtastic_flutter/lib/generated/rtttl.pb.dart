// This is a generated file - do not edit.
//
// Generated from meshtastic/rtttl.proto.

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
///  Canned message module configuration.
class RTTTLConfig extends $pb.GeneratedMessage {
  factory RTTTLConfig({
    $core.String? ringtone,
  }) {
    final result = create();
    if (ringtone != null) result.ringtone = ringtone;
    return result;
  }

  RTTTLConfig._();

  factory RTTTLConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RTTTLConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTTTLConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ringtone')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RTTTLConfig clone() => RTTTLConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RTTTLConfig copyWith(void Function(RTTTLConfig) updates) =>
      super.copyWith((message) => updates(message as RTTTLConfig))
          as RTTTLConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RTTTLConfig create() => RTTTLConfig._();
  @$core.override
  RTTTLConfig createEmptyInstance() => create();
  static $pb.PbList<RTTTLConfig> createRepeated() => $pb.PbList<RTTTLConfig>();
  @$core.pragma('dart2js:noInline')
  static RTTTLConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RTTTLConfig>(create);
  static RTTTLConfig? _defaultInstance;

  ///
  ///  Ringtone for PWM Buzzer in RTTTL Format.
  @$pb.TagNumber(1)
  $core.String get ringtone => $_getSZ(0);
  @$pb.TagNumber(1)
  set ringtone($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRingtone() => $_has(0);
  @$pb.TagNumber(1)
  void clearRingtone() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
