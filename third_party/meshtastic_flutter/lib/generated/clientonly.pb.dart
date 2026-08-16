// This is a generated file - do not edit.
//
// Generated from meshtastic/clientonly.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'localonly.pb.dart' as $0;
import 'mesh.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///
///  This abstraction is used to contain any configuration for provisioning a node on any client.
///  It is useful for importing and exporting configurations.
class DeviceProfile extends $pb.GeneratedMessage {
  factory DeviceProfile({
    $core.String? longName,
    $core.String? shortName,
    $core.String? channelUrl,
    $0.LocalConfig? config,
    $0.LocalModuleConfig? moduleConfig,
    $1.Position? fixedPosition,
    $core.String? ringtone,
    $core.String? cannedMessages,
  }) {
    final result = create();
    if (longName != null) result.longName = longName;
    if (shortName != null) result.shortName = shortName;
    if (channelUrl != null) result.channelUrl = channelUrl;
    if (config != null) result.config = config;
    if (moduleConfig != null) result.moduleConfig = moduleConfig;
    if (fixedPosition != null) result.fixedPosition = fixedPosition;
    if (ringtone != null) result.ringtone = ringtone;
    if (cannedMessages != null) result.cannedMessages = cannedMessages;
    return result;
  }

  DeviceProfile._();

  factory DeviceProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'longName')
    ..aOS(2, _omitFieldNames ? '' : 'shortName')
    ..aOS(3, _omitFieldNames ? '' : 'channelUrl')
    ..aOM<$0.LocalConfig>(4, _omitFieldNames ? '' : 'config',
        subBuilder: $0.LocalConfig.create)
    ..aOM<$0.LocalModuleConfig>(5, _omitFieldNames ? '' : 'moduleConfig',
        subBuilder: $0.LocalModuleConfig.create)
    ..aOM<$1.Position>(6, _omitFieldNames ? '' : 'fixedPosition',
        subBuilder: $1.Position.create)
    ..aOS(7, _omitFieldNames ? '' : 'ringtone')
    ..aOS(8, _omitFieldNames ? '' : 'cannedMessages')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceProfile clone() => DeviceProfile()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceProfile copyWith(void Function(DeviceProfile) updates) =>
      super.copyWith((message) => updates(message as DeviceProfile))
          as DeviceProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceProfile create() => DeviceProfile._();
  @$core.override
  DeviceProfile createEmptyInstance() => create();
  static $pb.PbList<DeviceProfile> createRepeated() =>
      $pb.PbList<DeviceProfile>();
  @$core.pragma('dart2js:noInline')
  static DeviceProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceProfile>(create);
  static DeviceProfile? _defaultInstance;

  ///
  ///  Long name for the node
  @$pb.TagNumber(1)
  $core.String get longName => $_getSZ(0);
  @$pb.TagNumber(1)
  set longName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLongName() => $_has(0);
  @$pb.TagNumber(1)
  void clearLongName() => $_clearField(1);

  ///
  ///  Short name of the node
  @$pb.TagNumber(2)
  $core.String get shortName => $_getSZ(1);
  @$pb.TagNumber(2)
  set shortName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShortName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortName() => $_clearField(2);

  ///
  ///  The url of the channels from our node
  @$pb.TagNumber(3)
  $core.String get channelUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set channelUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannelUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannelUrl() => $_clearField(3);

  ///
  ///  The Config of the node
  @$pb.TagNumber(4)
  $0.LocalConfig get config => $_getN(3);
  @$pb.TagNumber(4)
  set config($0.LocalConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasConfig() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfig() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.LocalConfig ensureConfig() => $_ensure(3);

  ///
  ///  The ModuleConfig of the node
  @$pb.TagNumber(5)
  $0.LocalModuleConfig get moduleConfig => $_getN(4);
  @$pb.TagNumber(5)
  set moduleConfig($0.LocalModuleConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasModuleConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearModuleConfig() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.LocalModuleConfig ensureModuleConfig() => $_ensure(4);

  ///
  ///  Fixed position data
  @$pb.TagNumber(6)
  $1.Position get fixedPosition => $_getN(5);
  @$pb.TagNumber(6)
  set fixedPosition($1.Position value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasFixedPosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearFixedPosition() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Position ensureFixedPosition() => $_ensure(5);

  ///
  ///  Ringtone for ExternalNotification
  @$pb.TagNumber(7)
  $core.String get ringtone => $_getSZ(6);
  @$pb.TagNumber(7)
  set ringtone($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRingtone() => $_has(6);
  @$pb.TagNumber(7)
  void clearRingtone() => $_clearField(7);

  ///
  ///  Predefined messages for CannedMessage
  @$pb.TagNumber(8)
  $core.String get cannedMessages => $_getSZ(7);
  @$pb.TagNumber(8)
  set cannedMessages($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCannedMessages() => $_has(7);
  @$pb.TagNumber(8)
  void clearCannedMessages() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
