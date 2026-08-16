// This is a generated file - do not edit.
//
// Generated from meshtastic/device_ui.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'device_ui.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'device_ui.pbenum.dart';

class DeviceUIConfig extends $pb.GeneratedMessage {
  factory DeviceUIConfig({
    $core.int? version,
    $core.int? screenBrightness,
    $core.int? screenTimeout,
    $core.bool? screenLock,
    $core.bool? settingsLock,
    $core.int? pinCode,
    Theme? theme,
    $core.bool? alertEnabled,
    $core.bool? bannerEnabled,
    $core.int? ringToneId,
    Language? language,
    NodeFilter? nodeFilter,
    NodeHighlight? nodeHighlight,
    $core.List<$core.int>? calibrationData,
    Map_? mapData,
    CompassMode? compassMode,
    $core.int? screenRgbColor,
    $core.bool? isClockfaceAnalog,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (screenBrightness != null) result.screenBrightness = screenBrightness;
    if (screenTimeout != null) result.screenTimeout = screenTimeout;
    if (screenLock != null) result.screenLock = screenLock;
    if (settingsLock != null) result.settingsLock = settingsLock;
    if (pinCode != null) result.pinCode = pinCode;
    if (theme != null) result.theme = theme;
    if (alertEnabled != null) result.alertEnabled = alertEnabled;
    if (bannerEnabled != null) result.bannerEnabled = bannerEnabled;
    if (ringToneId != null) result.ringToneId = ringToneId;
    if (language != null) result.language = language;
    if (nodeFilter != null) result.nodeFilter = nodeFilter;
    if (nodeHighlight != null) result.nodeHighlight = nodeHighlight;
    if (calibrationData != null) result.calibrationData = calibrationData;
    if (mapData != null) result.mapData = mapData;
    if (compassMode != null) result.compassMode = compassMode;
    if (screenRgbColor != null) result.screenRgbColor = screenRgbColor;
    if (isClockfaceAnalog != null) result.isClockfaceAnalog = isClockfaceAnalog;
    return result;
  }

  DeviceUIConfig._();

  factory DeviceUIConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceUIConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceUIConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'screenBrightness', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'screenTimeout', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'screenLock')
    ..aOB(5, _omitFieldNames ? '' : 'settingsLock')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'pinCode', $pb.PbFieldType.OU3)
    ..e<Theme>(7, _omitFieldNames ? '' : 'theme', $pb.PbFieldType.OE,
        defaultOrMaker: Theme.DARK,
        valueOf: Theme.valueOf,
        enumValues: Theme.values)
    ..aOB(8, _omitFieldNames ? '' : 'alertEnabled')
    ..aOB(9, _omitFieldNames ? '' : 'bannerEnabled')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'ringToneId', $pb.PbFieldType.OU3)
    ..e<Language>(11, _omitFieldNames ? '' : 'language', $pb.PbFieldType.OE,
        defaultOrMaker: Language.ENGLISH,
        valueOf: Language.valueOf,
        enumValues: Language.values)
    ..aOM<NodeFilter>(12, _omitFieldNames ? '' : 'nodeFilter',
        subBuilder: NodeFilter.create)
    ..aOM<NodeHighlight>(13, _omitFieldNames ? '' : 'nodeHighlight',
        subBuilder: NodeHighlight.create)
    ..a<$core.List<$core.int>>(
        14, _omitFieldNames ? '' : 'calibrationData', $pb.PbFieldType.OY)
    ..aOM<Map_>(15, _omitFieldNames ? '' : 'mapData', subBuilder: Map_.create)
    ..e<CompassMode>(
        16, _omitFieldNames ? '' : 'compassMode', $pb.PbFieldType.OE,
        defaultOrMaker: CompassMode.DYNAMIC,
        valueOf: CompassMode.valueOf,
        enumValues: CompassMode.values)
    ..a<$core.int>(
        17, _omitFieldNames ? '' : 'screenRgbColor', $pb.PbFieldType.OU3)
    ..aOB(18, _omitFieldNames ? '' : 'isClockfaceAnalog')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceUIConfig clone() => DeviceUIConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceUIConfig copyWith(void Function(DeviceUIConfig) updates) =>
      super.copyWith((message) => updates(message as DeviceUIConfig))
          as DeviceUIConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceUIConfig create() => DeviceUIConfig._();
  @$core.override
  DeviceUIConfig createEmptyInstance() => create();
  static $pb.PbList<DeviceUIConfig> createRepeated() =>
      $pb.PbList<DeviceUIConfig>();
  @$core.pragma('dart2js:noInline')
  static DeviceUIConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceUIConfig>(create);
  static DeviceUIConfig? _defaultInstance;

  ///
  ///  A version integer used to invalidate saved files when we make incompatible changes.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  ///
  ///  TFT display brightness 1..255
  @$pb.TagNumber(2)
  $core.int get screenBrightness => $_getIZ(1);
  @$pb.TagNumber(2)
  set screenBrightness($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScreenBrightness() => $_has(1);
  @$pb.TagNumber(2)
  void clearScreenBrightness() => $_clearField(2);

  ///
  ///  Screen timeout 0..900
  @$pb.TagNumber(3)
  $core.int get screenTimeout => $_getIZ(2);
  @$pb.TagNumber(3)
  set screenTimeout($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasScreenTimeout() => $_has(2);
  @$pb.TagNumber(3)
  void clearScreenTimeout() => $_clearField(3);

  ///
  ///  Screen/Settings lock enabled
  @$pb.TagNumber(4)
  $core.bool get screenLock => $_getBF(3);
  @$pb.TagNumber(4)
  set screenLock($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScreenLock() => $_has(3);
  @$pb.TagNumber(4)
  void clearScreenLock() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get settingsLock => $_getBF(4);
  @$pb.TagNumber(5)
  set settingsLock($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSettingsLock() => $_has(4);
  @$pb.TagNumber(5)
  void clearSettingsLock() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get pinCode => $_getIZ(5);
  @$pb.TagNumber(6)
  set pinCode($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPinCode() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinCode() => $_clearField(6);

  ///
  ///  Color theme
  @$pb.TagNumber(7)
  Theme get theme => $_getN(6);
  @$pb.TagNumber(7)
  set theme(Theme value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasTheme() => $_has(6);
  @$pb.TagNumber(7)
  void clearTheme() => $_clearField(7);

  ///
  ///  Audible message, banner and ring tone
  @$pb.TagNumber(8)
  $core.bool get alertEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set alertEnabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAlertEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlertEnabled() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get bannerEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set bannerEnabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBannerEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearBannerEnabled() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get ringToneId => $_getIZ(9);
  @$pb.TagNumber(10)
  set ringToneId($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRingToneId() => $_has(9);
  @$pb.TagNumber(10)
  void clearRingToneId() => $_clearField(10);

  ///
  ///  Localization
  @$pb.TagNumber(11)
  Language get language => $_getN(10);
  @$pb.TagNumber(11)
  set language(Language value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasLanguage() => $_has(10);
  @$pb.TagNumber(11)
  void clearLanguage() => $_clearField(11);

  ///
  ///  Node list filter
  @$pb.TagNumber(12)
  NodeFilter get nodeFilter => $_getN(11);
  @$pb.TagNumber(12)
  set nodeFilter(NodeFilter value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasNodeFilter() => $_has(11);
  @$pb.TagNumber(12)
  void clearNodeFilter() => $_clearField(12);
  @$pb.TagNumber(12)
  NodeFilter ensureNodeFilter() => $_ensure(11);

  ///
  ///  Node list highlightening
  @$pb.TagNumber(13)
  NodeHighlight get nodeHighlight => $_getN(12);
  @$pb.TagNumber(13)
  set nodeHighlight(NodeHighlight value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasNodeHighlight() => $_has(12);
  @$pb.TagNumber(13)
  void clearNodeHighlight() => $_clearField(13);
  @$pb.TagNumber(13)
  NodeHighlight ensureNodeHighlight() => $_ensure(12);

  ///
  ///  8 integers for screen calibration data
  @$pb.TagNumber(14)
  $core.List<$core.int> get calibrationData => $_getN(13);
  @$pb.TagNumber(14)
  set calibrationData($core.List<$core.int> value) => $_setBytes(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCalibrationData() => $_has(13);
  @$pb.TagNumber(14)
  void clearCalibrationData() => $_clearField(14);

  ///
  ///  Map related data
  @$pb.TagNumber(15)
  Map_ get mapData => $_getN(14);
  @$pb.TagNumber(15)
  set mapData(Map_ value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasMapData() => $_has(14);
  @$pb.TagNumber(15)
  void clearMapData() => $_clearField(15);
  @$pb.TagNumber(15)
  Map_ ensureMapData() => $_ensure(14);

  ///
  ///  Compass mode
  @$pb.TagNumber(16)
  CompassMode get compassMode => $_getN(15);
  @$pb.TagNumber(16)
  set compassMode(CompassMode value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasCompassMode() => $_has(15);
  @$pb.TagNumber(16)
  void clearCompassMode() => $_clearField(16);

  ///
  ///  RGB color for BaseUI
  ///  0xRRGGBB format, e.g. 0xFF0000 for red
  @$pb.TagNumber(17)
  $core.int get screenRgbColor => $_getIZ(16);
  @$pb.TagNumber(17)
  set screenRgbColor($core.int value) => $_setUnsignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasScreenRgbColor() => $_has(16);
  @$pb.TagNumber(17)
  void clearScreenRgbColor() => $_clearField(17);

  ///
  ///  Clockface analog style
  ///  true for analog clockface, false for digital clockface
  @$pb.TagNumber(18)
  $core.bool get isClockfaceAnalog => $_getBF(17);
  @$pb.TagNumber(18)
  set isClockfaceAnalog($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasIsClockfaceAnalog() => $_has(17);
  @$pb.TagNumber(18)
  void clearIsClockfaceAnalog() => $_clearField(18);
}

class NodeFilter extends $pb.GeneratedMessage {
  factory NodeFilter({
    $core.bool? unknownSwitch,
    $core.bool? offlineSwitch,
    $core.bool? publicKeySwitch,
    $core.int? hopsAway,
    $core.bool? positionSwitch,
    $core.String? nodeName,
    $core.int? channel,
  }) {
    final result = create();
    if (unknownSwitch != null) result.unknownSwitch = unknownSwitch;
    if (offlineSwitch != null) result.offlineSwitch = offlineSwitch;
    if (publicKeySwitch != null) result.publicKeySwitch = publicKeySwitch;
    if (hopsAway != null) result.hopsAway = hopsAway;
    if (positionSwitch != null) result.positionSwitch = positionSwitch;
    if (nodeName != null) result.nodeName = nodeName;
    if (channel != null) result.channel = channel;
    return result;
  }

  NodeFilter._();

  factory NodeFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'unknownSwitch')
    ..aOB(2, _omitFieldNames ? '' : 'offlineSwitch')
    ..aOB(3, _omitFieldNames ? '' : 'publicKeySwitch')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'hopsAway', $pb.PbFieldType.O3)
    ..aOB(5, _omitFieldNames ? '' : 'positionSwitch')
    ..aOS(6, _omitFieldNames ? '' : 'nodeName')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'channel', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeFilter clone() => NodeFilter()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeFilter copyWith(void Function(NodeFilter) updates) =>
      super.copyWith((message) => updates(message as NodeFilter)) as NodeFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeFilter create() => NodeFilter._();
  @$core.override
  NodeFilter createEmptyInstance() => create();
  static $pb.PbList<NodeFilter> createRepeated() => $pb.PbList<NodeFilter>();
  @$core.pragma('dart2js:noInline')
  static NodeFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeFilter>(create);
  static NodeFilter? _defaultInstance;

  ///
  ///  Filter unknown nodes
  @$pb.TagNumber(1)
  $core.bool get unknownSwitch => $_getBF(0);
  @$pb.TagNumber(1)
  set unknownSwitch($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnknownSwitch() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnknownSwitch() => $_clearField(1);

  ///
  ///  Filter offline nodes
  @$pb.TagNumber(2)
  $core.bool get offlineSwitch => $_getBF(1);
  @$pb.TagNumber(2)
  set offlineSwitch($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOfflineSwitch() => $_has(1);
  @$pb.TagNumber(2)
  void clearOfflineSwitch() => $_clearField(2);

  ///
  ///  Filter nodes w/o public key
  @$pb.TagNumber(3)
  $core.bool get publicKeySwitch => $_getBF(2);
  @$pb.TagNumber(3)
  set publicKeySwitch($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublicKeySwitch() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicKeySwitch() => $_clearField(3);

  ///
  ///  Filter based on hops away
  @$pb.TagNumber(4)
  $core.int get hopsAway => $_getIZ(3);
  @$pb.TagNumber(4)
  set hopsAway($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHopsAway() => $_has(3);
  @$pb.TagNumber(4)
  void clearHopsAway() => $_clearField(4);

  ///
  ///  Filter nodes w/o position
  @$pb.TagNumber(5)
  $core.bool get positionSwitch => $_getBF(4);
  @$pb.TagNumber(5)
  set positionSwitch($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPositionSwitch() => $_has(4);
  @$pb.TagNumber(5)
  void clearPositionSwitch() => $_clearField(5);

  ///
  ///  Filter nodes by matching name string
  @$pb.TagNumber(6)
  $core.String get nodeName => $_getSZ(5);
  @$pb.TagNumber(6)
  set nodeName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNodeName() => $_has(5);
  @$pb.TagNumber(6)
  void clearNodeName() => $_clearField(6);

  ///
  ///  Filter based on channel
  @$pb.TagNumber(7)
  $core.int get channel => $_getIZ(6);
  @$pb.TagNumber(7)
  set channel($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChannel() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannel() => $_clearField(7);
}

class NodeHighlight extends $pb.GeneratedMessage {
  factory NodeHighlight({
    $core.bool? chatSwitch,
    $core.bool? positionSwitch,
    $core.bool? telemetrySwitch,
    $core.bool? iaqSwitch,
    $core.String? nodeName,
  }) {
    final result = create();
    if (chatSwitch != null) result.chatSwitch = chatSwitch;
    if (positionSwitch != null) result.positionSwitch = positionSwitch;
    if (telemetrySwitch != null) result.telemetrySwitch = telemetrySwitch;
    if (iaqSwitch != null) result.iaqSwitch = iaqSwitch;
    if (nodeName != null) result.nodeName = nodeName;
    return result;
  }

  NodeHighlight._();

  factory NodeHighlight.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeHighlight.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeHighlight',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'chatSwitch')
    ..aOB(2, _omitFieldNames ? '' : 'positionSwitch')
    ..aOB(3, _omitFieldNames ? '' : 'telemetrySwitch')
    ..aOB(4, _omitFieldNames ? '' : 'iaqSwitch')
    ..aOS(5, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeHighlight clone() => NodeHighlight()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeHighlight copyWith(void Function(NodeHighlight) updates) =>
      super.copyWith((message) => updates(message as NodeHighlight))
          as NodeHighlight;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeHighlight create() => NodeHighlight._();
  @$core.override
  NodeHighlight createEmptyInstance() => create();
  static $pb.PbList<NodeHighlight> createRepeated() =>
      $pb.PbList<NodeHighlight>();
  @$core.pragma('dart2js:noInline')
  static NodeHighlight getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeHighlight>(create);
  static NodeHighlight? _defaultInstance;

  ///
  ///  Hightlight nodes w/ active chat
  @$pb.TagNumber(1)
  $core.bool get chatSwitch => $_getBF(0);
  @$pb.TagNumber(1)
  set chatSwitch($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatSwitch() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatSwitch() => $_clearField(1);

  ///
  ///  Highlight nodes w/ position
  @$pb.TagNumber(2)
  $core.bool get positionSwitch => $_getBF(1);
  @$pb.TagNumber(2)
  set positionSwitch($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionSwitch() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionSwitch() => $_clearField(2);

  ///
  ///  Highlight nodes w/ telemetry data
  @$pb.TagNumber(3)
  $core.bool get telemetrySwitch => $_getBF(2);
  @$pb.TagNumber(3)
  set telemetrySwitch($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTelemetrySwitch() => $_has(2);
  @$pb.TagNumber(3)
  void clearTelemetrySwitch() => $_clearField(3);

  ///
  ///  Highlight nodes w/ iaq data
  @$pb.TagNumber(4)
  $core.bool get iaqSwitch => $_getBF(3);
  @$pb.TagNumber(4)
  set iaqSwitch($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIaqSwitch() => $_has(3);
  @$pb.TagNumber(4)
  void clearIaqSwitch() => $_clearField(4);

  ///
  ///  Highlight nodes by matching name string
  @$pb.TagNumber(5)
  $core.String get nodeName => $_getSZ(4);
  @$pb.TagNumber(5)
  set nodeName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNodeName() => $_has(4);
  @$pb.TagNumber(5)
  void clearNodeName() => $_clearField(5);
}

class GeoPoint extends $pb.GeneratedMessage {
  factory GeoPoint({
    $core.int? zoom,
    $core.int? latitude,
    $core.int? longitude,
  }) {
    final result = create();
    if (zoom != null) result.zoom = zoom;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    return result;
  }

  GeoPoint._();

  factory GeoPoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GeoPoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GeoPoint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'zoom', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'latitude', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'longitude', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoPoint clone() => GeoPoint()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoPoint copyWith(void Function(GeoPoint) updates) =>
      super.copyWith((message) => updates(message as GeoPoint)) as GeoPoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeoPoint create() => GeoPoint._();
  @$core.override
  GeoPoint createEmptyInstance() => create();
  static $pb.PbList<GeoPoint> createRepeated() => $pb.PbList<GeoPoint>();
  @$core.pragma('dart2js:noInline')
  static GeoPoint getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GeoPoint>(create);
  static GeoPoint? _defaultInstance;

  ///
  ///  Zoom level
  @$pb.TagNumber(1)
  $core.int get zoom => $_getIZ(0);
  @$pb.TagNumber(1)
  set zoom($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasZoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearZoom() => $_clearField(1);

  ///
  ///  Coordinate: latitude
  @$pb.TagNumber(2)
  $core.int get latitude => $_getIZ(1);
  @$pb.TagNumber(2)
  set latitude($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatitude() => $_clearField(2);

  ///
  ///  Coordinate: longitude
  @$pb.TagNumber(3)
  $core.int get longitude => $_getIZ(2);
  @$pb.TagNumber(3)
  set longitude($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLongitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearLongitude() => $_clearField(3);
}

class Map_ extends $pb.GeneratedMessage {
  factory Map_({
    GeoPoint? home,
    $core.String? style,
    $core.bool? followGps,
  }) {
    final result = create();
    if (home != null) result.home = home;
    if (style != null) result.style = style;
    if (followGps != null) result.followGps = followGps;
    return result;
  }

  Map_._();

  factory Map_.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Map_.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Map',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<GeoPoint>(1, _omitFieldNames ? '' : 'home',
        subBuilder: GeoPoint.create)
    ..aOS(2, _omitFieldNames ? '' : 'style')
    ..aOB(3, _omitFieldNames ? '' : 'followGps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Map_ clone() => Map_()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Map_ copyWith(void Function(Map_) updates) =>
      super.copyWith((message) => updates(message as Map_)) as Map_;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Map_ create() => Map_._();
  @$core.override
  Map_ createEmptyInstance() => create();
  static $pb.PbList<Map_> createRepeated() => $pb.PbList<Map_>();
  @$core.pragma('dart2js:noInline')
  static Map_ getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Map_>(create);
  static Map_? _defaultInstance;

  ///
  ///  Home coordinates
  @$pb.TagNumber(1)
  GeoPoint get home => $_getN(0);
  @$pb.TagNumber(1)
  set home(GeoPoint value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHome() => $_has(0);
  @$pb.TagNumber(1)
  void clearHome() => $_clearField(1);
  @$pb.TagNumber(1)
  GeoPoint ensureHome() => $_ensure(0);

  ///
  ///  Map tile style
  @$pb.TagNumber(2)
  $core.String get style => $_getSZ(1);
  @$pb.TagNumber(2)
  set style($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStyle() => $_has(1);
  @$pb.TagNumber(2)
  void clearStyle() => $_clearField(2);

  ///
  ///  Map scroll follows GPS
  @$pb.TagNumber(3)
  $core.bool get followGps => $_getBF(2);
  @$pb.TagNumber(3)
  set followGps($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFollowGps() => $_has(2);
  @$pb.TagNumber(3)
  void clearFollowGps() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
