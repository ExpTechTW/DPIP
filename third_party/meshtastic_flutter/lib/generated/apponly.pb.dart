// This is a generated file - do not edit.
//
// Generated from meshtastic/apponly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'channel.pb.dart' as $0;
import 'config.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///
///  This is the most compact possible representation for a set of channels.
///  It includes only one PRIMARY channel (which must be first) and
///  any SECONDARY channels.
///  No DISABLED channels are included.
///  This abstraction is used only on the the 'app side' of the world (ie python, javascript and android etc) to show a group of Channels as a (long) URL
class ChannelSet extends $pb.GeneratedMessage {
  factory ChannelSet({
    $core.Iterable<$0.ChannelSettings>? settings,
    $1.Config_LoRaConfig? loraConfig,
  }) {
    final result = create();
    if (settings != null) result.settings.addAll(settings);
    if (loraConfig != null) result.loraConfig = loraConfig;
    return result;
  }

  ChannelSet._();

  factory ChannelSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..pc<$0.ChannelSettings>(
        1, _omitFieldNames ? '' : 'settings', $pb.PbFieldType.PM,
        subBuilder: $0.ChannelSettings.create)
    ..aOM<$1.Config_LoRaConfig>(2, _omitFieldNames ? '' : 'loraConfig',
        subBuilder: $1.Config_LoRaConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelSet clone() => ChannelSet()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelSet copyWith(void Function(ChannelSet) updates) =>
      super.copyWith((message) => updates(message as ChannelSet)) as ChannelSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelSet create() => ChannelSet._();
  @$core.override
  ChannelSet createEmptyInstance() => create();
  static $pb.PbList<ChannelSet> createRepeated() => $pb.PbList<ChannelSet>();
  @$core.pragma('dart2js:noInline')
  static ChannelSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelSet>(create);
  static ChannelSet? _defaultInstance;

  ///
  ///  Channel list with settings
  @$pb.TagNumber(1)
  $pb.PbList<$0.ChannelSettings> get settings => $_getList(0);

  ///
  ///  LoRa config
  @$pb.TagNumber(2)
  $1.Config_LoRaConfig get loraConfig => $_getN(1);
  @$pb.TagNumber(2)
  set loraConfig($1.Config_LoRaConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLoraConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoraConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Config_LoRaConfig ensureLoraConfig() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
