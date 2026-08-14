// This is a generated file - do not edit.
//
// Generated from meshtastic/cannedmessages.proto.

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
class CannedMessageModuleConfig extends $pb.GeneratedMessage {
  factory CannedMessageModuleConfig({
    $core.String? messages,
  }) {
    final result = create();
    if (messages != null) result.messages = messages;
    return result;
  }

  CannedMessageModuleConfig._();

  factory CannedMessageModuleConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CannedMessageModuleConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CannedMessageModuleConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messages')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CannedMessageModuleConfig clone() =>
      CannedMessageModuleConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CannedMessageModuleConfig copyWith(
          void Function(CannedMessageModuleConfig) updates) =>
      super.copyWith((message) => updates(message as CannedMessageModuleConfig))
          as CannedMessageModuleConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CannedMessageModuleConfig create() => CannedMessageModuleConfig._();
  @$core.override
  CannedMessageModuleConfig createEmptyInstance() => create();
  static $pb.PbList<CannedMessageModuleConfig> createRepeated() =>
      $pb.PbList<CannedMessageModuleConfig>();
  @$core.pragma('dart2js:noInline')
  static CannedMessageModuleConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CannedMessageModuleConfig>(create);
  static CannedMessageModuleConfig? _defaultInstance;

  ///
  ///  Predefined messages for canned message module separated by '|' characters.
  @$pb.TagNumber(1)
  $core.String get messages => $_getSZ(0);
  @$pb.TagNumber(1)
  set messages($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessages() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessages() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
