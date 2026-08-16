// This is a generated file - do not edit.
//
// Generated from meshtastic/config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'config.pbenum.dart';
import 'device_ui.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'config.pbenum.dart';

///
///  Configuration
class Config_DeviceConfig extends $pb.GeneratedMessage {
  factory Config_DeviceConfig({
    Config_DeviceConfig_Role? role,
    @$core.Deprecated('This field is deprecated.') $core.bool? serialEnabled,
    $core.int? buttonGpio,
    $core.int? buzzerGpio,
    Config_DeviceConfig_RebroadcastMode? rebroadcastMode,
    $core.int? nodeInfoBroadcastSecs,
    $core.bool? doubleTapAsButtonPress,
    @$core.Deprecated('This field is deprecated.') $core.bool? isManaged,
    $core.bool? disableTripleClick,
    $core.String? tzdef,
    $core.bool? ledHeartbeatDisabled,
    Config_DeviceConfig_BuzzerMode? buzzerMode,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (serialEnabled != null) result.serialEnabled = serialEnabled;
    if (buttonGpio != null) result.buttonGpio = buttonGpio;
    if (buzzerGpio != null) result.buzzerGpio = buzzerGpio;
    if (rebroadcastMode != null) result.rebroadcastMode = rebroadcastMode;
    if (nodeInfoBroadcastSecs != null)
      result.nodeInfoBroadcastSecs = nodeInfoBroadcastSecs;
    if (doubleTapAsButtonPress != null)
      result.doubleTapAsButtonPress = doubleTapAsButtonPress;
    if (isManaged != null) result.isManaged = isManaged;
    if (disableTripleClick != null)
      result.disableTripleClick = disableTripleClick;
    if (tzdef != null) result.tzdef = tzdef;
    if (ledHeartbeatDisabled != null)
      result.ledHeartbeatDisabled = ledHeartbeatDisabled;
    if (buzzerMode != null) result.buzzerMode = buzzerMode;
    return result;
  }

  Config_DeviceConfig._();

  factory Config_DeviceConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_DeviceConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.DeviceConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..e<Config_DeviceConfig_Role>(
        1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DeviceConfig_Role.CLIENT,
        valueOf: Config_DeviceConfig_Role.valueOf,
        enumValues: Config_DeviceConfig_Role.values)
    ..aOB(2, _omitFieldNames ? '' : 'serialEnabled')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'buttonGpio', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'buzzerGpio', $pb.PbFieldType.OU3)
    ..e<Config_DeviceConfig_RebroadcastMode>(
        6, _omitFieldNames ? '' : 'rebroadcastMode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DeviceConfig_RebroadcastMode.ALL,
        valueOf: Config_DeviceConfig_RebroadcastMode.valueOf,
        enumValues: Config_DeviceConfig_RebroadcastMode.values)
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'nodeInfoBroadcastSecs', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'doubleTapAsButtonPress')
    ..aOB(9, _omitFieldNames ? '' : 'isManaged')
    ..aOB(10, _omitFieldNames ? '' : 'disableTripleClick')
    ..aOS(11, _omitFieldNames ? '' : 'tzdef')
    ..aOB(12, _omitFieldNames ? '' : 'ledHeartbeatDisabled')
    ..e<Config_DeviceConfig_BuzzerMode>(
        13, _omitFieldNames ? '' : 'buzzerMode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DeviceConfig_BuzzerMode.ALL_ENABLED,
        valueOf: Config_DeviceConfig_BuzzerMode.valueOf,
        enumValues: Config_DeviceConfig_BuzzerMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_DeviceConfig clone() => Config_DeviceConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_DeviceConfig copyWith(void Function(Config_DeviceConfig) updates) =>
      super.copyWith((message) => updates(message as Config_DeviceConfig))
          as Config_DeviceConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_DeviceConfig create() => Config_DeviceConfig._();
  @$core.override
  Config_DeviceConfig createEmptyInstance() => create();
  static $pb.PbList<Config_DeviceConfig> createRepeated() =>
      $pb.PbList<Config_DeviceConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_DeviceConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_DeviceConfig>(create);
  static Config_DeviceConfig? _defaultInstance;

  ///
  ///  Sets the role of node
  @$pb.TagNumber(1)
  Config_DeviceConfig_Role get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(Config_DeviceConfig_Role value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  ///
  ///  Disabling this will disable the SerialConsole by not initilizing the StreamAPI
  ///  Moved to SecurityConfig
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool get serialEnabled => $_getBF(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  set serialEnabled($core.bool value) => $_setBool(1, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool hasSerialEnabled() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  void clearSerialEnabled() => $_clearField(2);

  ///
  ///  For boards without a hard wired button, this is the pin number that will be used
  ///  Boards that have more than one button can swap the function with this one. defaults to BUTTON_PIN if defined.
  @$pb.TagNumber(4)
  $core.int get buttonGpio => $_getIZ(2);
  @$pb.TagNumber(4)
  set buttonGpio($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(4)
  $core.bool hasButtonGpio() => $_has(2);
  @$pb.TagNumber(4)
  void clearButtonGpio() => $_clearField(4);

  ///
  ///  For boards without a PWM buzzer, this is the pin number that will be used
  ///  Defaults to PIN_BUZZER if defined.
  @$pb.TagNumber(5)
  $core.int get buzzerGpio => $_getIZ(3);
  @$pb.TagNumber(5)
  set buzzerGpio($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(5)
  $core.bool hasBuzzerGpio() => $_has(3);
  @$pb.TagNumber(5)
  void clearBuzzerGpio() => $_clearField(5);

  ///
  ///  Sets the role of node
  @$pb.TagNumber(6)
  Config_DeviceConfig_RebroadcastMode get rebroadcastMode => $_getN(4);
  @$pb.TagNumber(6)
  set rebroadcastMode(Config_DeviceConfig_RebroadcastMode value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRebroadcastMode() => $_has(4);
  @$pb.TagNumber(6)
  void clearRebroadcastMode() => $_clearField(6);

  ///
  ///  Send our nodeinfo this often
  ///  Defaults to 900 Seconds (15 minutes)
  @$pb.TagNumber(7)
  $core.int get nodeInfoBroadcastSecs => $_getIZ(5);
  @$pb.TagNumber(7)
  set nodeInfoBroadcastSecs($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(7)
  $core.bool hasNodeInfoBroadcastSecs() => $_has(5);
  @$pb.TagNumber(7)
  void clearNodeInfoBroadcastSecs() => $_clearField(7);

  ///
  ///  Treat double tap interrupt on supported accelerometers as a button press if set to true
  @$pb.TagNumber(8)
  $core.bool get doubleTapAsButtonPress => $_getBF(6);
  @$pb.TagNumber(8)
  set doubleTapAsButtonPress($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(8)
  $core.bool hasDoubleTapAsButtonPress() => $_has(6);
  @$pb.TagNumber(8)
  void clearDoubleTapAsButtonPress() => $_clearField(8);

  ///
  ///  If true, device is considered to be "managed" by a mesh administrator
  ///  Clients should then limit available configuration and administrative options inside the user interface
  ///  Moved to SecurityConfig
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool get isManaged => $_getBF(7);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  set isManaged($core.bool value) => $_setBool(7, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.bool hasIsManaged() => $_has(7);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  void clearIsManaged() => $_clearField(9);

  ///
  ///  Disables the triple-press of user button to enable or disable GPS
  @$pb.TagNumber(10)
  $core.bool get disableTripleClick => $_getBF(8);
  @$pb.TagNumber(10)
  set disableTripleClick($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasDisableTripleClick() => $_has(8);
  @$pb.TagNumber(10)
  void clearDisableTripleClick() => $_clearField(10);

  ///
  ///  POSIX Timezone definition string from https://github.com/nayarsystems/posix_tz_db/blob/master/zones.csv.
  @$pb.TagNumber(11)
  $core.String get tzdef => $_getSZ(9);
  @$pb.TagNumber(11)
  set tzdef($core.String value) => $_setString(9, value);
  @$pb.TagNumber(11)
  $core.bool hasTzdef() => $_has(9);
  @$pb.TagNumber(11)
  void clearTzdef() => $_clearField(11);

  ///
  ///  If true, disable the default blinking LED (LED_PIN) behavior on the device
  @$pb.TagNumber(12)
  $core.bool get ledHeartbeatDisabled => $_getBF(10);
  @$pb.TagNumber(12)
  set ledHeartbeatDisabled($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(12)
  $core.bool hasLedHeartbeatDisabled() => $_has(10);
  @$pb.TagNumber(12)
  void clearLedHeartbeatDisabled() => $_clearField(12);

  ///
  ///  Controls buzzer behavior for audio feedback
  ///  Defaults to ENABLED
  @$pb.TagNumber(13)
  Config_DeviceConfig_BuzzerMode get buzzerMode => $_getN(11);
  @$pb.TagNumber(13)
  set buzzerMode(Config_DeviceConfig_BuzzerMode value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasBuzzerMode() => $_has(11);
  @$pb.TagNumber(13)
  void clearBuzzerMode() => $_clearField(13);
}

///
///  Position Config
class Config_PositionConfig extends $pb.GeneratedMessage {
  factory Config_PositionConfig({
    $core.int? positionBroadcastSecs,
    $core.bool? positionBroadcastSmartEnabled,
    $core.bool? fixedPosition,
    @$core.Deprecated('This field is deprecated.') $core.bool? gpsEnabled,
    $core.int? gpsUpdateInterval,
    @$core.Deprecated('This field is deprecated.') $core.int? gpsAttemptTime,
    $core.int? positionFlags,
    $core.int? rxGpio,
    $core.int? txGpio,
    $core.int? broadcastSmartMinimumDistance,
    $core.int? broadcastSmartMinimumIntervalSecs,
    $core.int? gpsEnGpio,
    Config_PositionConfig_GpsMode? gpsMode,
  }) {
    final result = create();
    if (positionBroadcastSecs != null)
      result.positionBroadcastSecs = positionBroadcastSecs;
    if (positionBroadcastSmartEnabled != null)
      result.positionBroadcastSmartEnabled = positionBroadcastSmartEnabled;
    if (fixedPosition != null) result.fixedPosition = fixedPosition;
    if (gpsEnabled != null) result.gpsEnabled = gpsEnabled;
    if (gpsUpdateInterval != null) result.gpsUpdateInterval = gpsUpdateInterval;
    if (gpsAttemptTime != null) result.gpsAttemptTime = gpsAttemptTime;
    if (positionFlags != null) result.positionFlags = positionFlags;
    if (rxGpio != null) result.rxGpio = rxGpio;
    if (txGpio != null) result.txGpio = txGpio;
    if (broadcastSmartMinimumDistance != null)
      result.broadcastSmartMinimumDistance = broadcastSmartMinimumDistance;
    if (broadcastSmartMinimumIntervalSecs != null)
      result.broadcastSmartMinimumIntervalSecs =
          broadcastSmartMinimumIntervalSecs;
    if (gpsEnGpio != null) result.gpsEnGpio = gpsEnGpio;
    if (gpsMode != null) result.gpsMode = gpsMode;
    return result;
  }

  Config_PositionConfig._();

  factory Config_PositionConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_PositionConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.PositionConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'positionBroadcastSecs', $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'positionBroadcastSmartEnabled')
    ..aOB(3, _omitFieldNames ? '' : 'fixedPosition')
    ..aOB(4, _omitFieldNames ? '' : 'gpsEnabled')
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'gpsUpdateInterval', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'gpsAttemptTime', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'positionFlags', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'rxGpio', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'txGpio', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'broadcastSmartMinimumDistance',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        11,
        _omitFieldNames ? '' : 'broadcastSmartMinimumIntervalSecs',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'gpsEnGpio', $pb.PbFieldType.OU3)
    ..e<Config_PositionConfig_GpsMode>(
        13, _omitFieldNames ? '' : 'gpsMode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_PositionConfig_GpsMode.DISABLED,
        valueOf: Config_PositionConfig_GpsMode.valueOf,
        enumValues: Config_PositionConfig_GpsMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_PositionConfig clone() =>
      Config_PositionConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_PositionConfig copyWith(
          void Function(Config_PositionConfig) updates) =>
      super.copyWith((message) => updates(message as Config_PositionConfig))
          as Config_PositionConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_PositionConfig create() => Config_PositionConfig._();
  @$core.override
  Config_PositionConfig createEmptyInstance() => create();
  static $pb.PbList<Config_PositionConfig> createRepeated() =>
      $pb.PbList<Config_PositionConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_PositionConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_PositionConfig>(create);
  static Config_PositionConfig? _defaultInstance;

  ///
  ///  We should send our position this often (but only if it has changed significantly)
  ///  Defaults to 15 minutes
  @$pb.TagNumber(1)
  $core.int get positionBroadcastSecs => $_getIZ(0);
  @$pb.TagNumber(1)
  set positionBroadcastSecs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPositionBroadcastSecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPositionBroadcastSecs() => $_clearField(1);

  ///
  ///  Adaptive position braoadcast, which is now the default.
  @$pb.TagNumber(2)
  $core.bool get positionBroadcastSmartEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set positionBroadcastSmartEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionBroadcastSmartEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionBroadcastSmartEnabled() => $_clearField(2);

  ///
  ///  If set, this node is at a fixed position.
  ///  We will generate GPS position updates at the regular interval, but use whatever the last lat/lon/alt we have for the node.
  ///  The lat/lon/alt can be set by an internal GPS or with the help of the app.
  @$pb.TagNumber(3)
  $core.bool get fixedPosition => $_getBF(2);
  @$pb.TagNumber(3)
  set fixedPosition($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFixedPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearFixedPosition() => $_clearField(3);

  ///
  ///  Is GPS enabled for this node?
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool get gpsEnabled => $_getBF(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  set gpsEnabled($core.bool value) => $_setBool(3, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool hasGpsEnabled() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  void clearGpsEnabled() => $_clearField(4);

  ///
  ///  How often should we try to get GPS position (in seconds)
  ///  or zero for the default of once every 30 seconds
  ///  or a very large value (maxint) to update only once at boot.
  @$pb.TagNumber(5)
  $core.int get gpsUpdateInterval => $_getIZ(4);
  @$pb.TagNumber(5)
  set gpsUpdateInterval($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGpsUpdateInterval() => $_has(4);
  @$pb.TagNumber(5)
  void clearGpsUpdateInterval() => $_clearField(5);

  ///
  ///  Deprecated in favor of using smart / regular broadcast intervals as implicit attempt time
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(6)
  $core.int get gpsAttemptTime => $_getIZ(5);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(6)
  set gpsAttemptTime($core.int value) => $_setUnsignedInt32(5, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(6)
  $core.bool hasGpsAttemptTime() => $_has(5);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(6)
  void clearGpsAttemptTime() => $_clearField(6);

  ///
  ///  Bit field of boolean configuration options for POSITION messages
  ///  (bitwise OR of PositionFlags)
  @$pb.TagNumber(7)
  $core.int get positionFlags => $_getIZ(6);
  @$pb.TagNumber(7)
  set positionFlags($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPositionFlags() => $_has(6);
  @$pb.TagNumber(7)
  void clearPositionFlags() => $_clearField(7);

  ///
  ///  (Re)define GPS_RX_PIN for your board.
  @$pb.TagNumber(8)
  $core.int get rxGpio => $_getIZ(7);
  @$pb.TagNumber(8)
  set rxGpio($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRxGpio() => $_has(7);
  @$pb.TagNumber(8)
  void clearRxGpio() => $_clearField(8);

  ///
  ///  (Re)define GPS_TX_PIN for your board.
  @$pb.TagNumber(9)
  $core.int get txGpio => $_getIZ(8);
  @$pb.TagNumber(9)
  set txGpio($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTxGpio() => $_has(8);
  @$pb.TagNumber(9)
  void clearTxGpio() => $_clearField(9);

  ///
  ///  The minimum distance in meters traveled (since the last send) before we can send a position to the mesh if position_broadcast_smart_enabled
  @$pb.TagNumber(10)
  $core.int get broadcastSmartMinimumDistance => $_getIZ(9);
  @$pb.TagNumber(10)
  set broadcastSmartMinimumDistance($core.int value) =>
      $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBroadcastSmartMinimumDistance() => $_has(9);
  @$pb.TagNumber(10)
  void clearBroadcastSmartMinimumDistance() => $_clearField(10);

  ///
  ///  The minimum number of seconds (since the last send) before we can send a position to the mesh if position_broadcast_smart_enabled
  @$pb.TagNumber(11)
  $core.int get broadcastSmartMinimumIntervalSecs => $_getIZ(10);
  @$pb.TagNumber(11)
  set broadcastSmartMinimumIntervalSecs($core.int value) =>
      $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasBroadcastSmartMinimumIntervalSecs() => $_has(10);
  @$pb.TagNumber(11)
  void clearBroadcastSmartMinimumIntervalSecs() => $_clearField(11);

  ///
  ///  (Re)define PIN_GPS_EN for your board.
  @$pb.TagNumber(12)
  $core.int get gpsEnGpio => $_getIZ(11);
  @$pb.TagNumber(12)
  set gpsEnGpio($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasGpsEnGpio() => $_has(11);
  @$pb.TagNumber(12)
  void clearGpsEnGpio() => $_clearField(12);

  ///
  ///  Set where GPS is enabled, disabled, or not present
  @$pb.TagNumber(13)
  Config_PositionConfig_GpsMode get gpsMode => $_getN(12);
  @$pb.TagNumber(13)
  set gpsMode(Config_PositionConfig_GpsMode value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasGpsMode() => $_has(12);
  @$pb.TagNumber(13)
  void clearGpsMode() => $_clearField(13);
}

///
///  Power Config\
///  See [Power Config](/docs/settings/config/power) for additional power config details.
class Config_PowerConfig extends $pb.GeneratedMessage {
  factory Config_PowerConfig({
    $core.bool? isPowerSaving,
    $core.int? onBatteryShutdownAfterSecs,
    $core.double? adcMultiplierOverride,
    $core.int? waitBluetoothSecs,
    $core.int? sdsSecs,
    $core.int? lsSecs,
    $core.int? minWakeSecs,
    $core.int? deviceBatteryInaAddress,
    $fixnum.Int64? powermonEnables,
  }) {
    final result = create();
    if (isPowerSaving != null) result.isPowerSaving = isPowerSaving;
    if (onBatteryShutdownAfterSecs != null)
      result.onBatteryShutdownAfterSecs = onBatteryShutdownAfterSecs;
    if (adcMultiplierOverride != null)
      result.adcMultiplierOverride = adcMultiplierOverride;
    if (waitBluetoothSecs != null) result.waitBluetoothSecs = waitBluetoothSecs;
    if (sdsSecs != null) result.sdsSecs = sdsSecs;
    if (lsSecs != null) result.lsSecs = lsSecs;
    if (minWakeSecs != null) result.minWakeSecs = minWakeSecs;
    if (deviceBatteryInaAddress != null)
      result.deviceBatteryInaAddress = deviceBatteryInaAddress;
    if (powermonEnables != null) result.powermonEnables = powermonEnables;
    return result;
  }

  Config_PowerConfig._();

  factory Config_PowerConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_PowerConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.PowerConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isPowerSaving')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'onBatteryShutdownAfterSecs',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'adcMultiplierOverride', $pb.PbFieldType.OF)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'waitBluetoothSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'sdsSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'lsSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'minWakeSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'deviceBatteryInaAddress',
        $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        32, _omitFieldNames ? '' : 'powermonEnables', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_PowerConfig clone() => Config_PowerConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_PowerConfig copyWith(void Function(Config_PowerConfig) updates) =>
      super.copyWith((message) => updates(message as Config_PowerConfig))
          as Config_PowerConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_PowerConfig create() => Config_PowerConfig._();
  @$core.override
  Config_PowerConfig createEmptyInstance() => create();
  static $pb.PbList<Config_PowerConfig> createRepeated() =>
      $pb.PbList<Config_PowerConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_PowerConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_PowerConfig>(create);
  static Config_PowerConfig? _defaultInstance;

  ///
  ///  Description: Will sleep everything as much as possible, for the tracker and sensor role this will also include the lora radio.
  ///  Don't use this setting if you want to use your device with the phone apps or are using a device without a user button.
  ///  Technical Details: Works for ESP32 devices and NRF52 devices in the Sensor or Tracker roles
  @$pb.TagNumber(1)
  $core.bool get isPowerSaving => $_getBF(0);
  @$pb.TagNumber(1)
  set isPowerSaving($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsPowerSaving() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsPowerSaving() => $_clearField(1);

  ///
  ///   Description: If non-zero, the device will fully power off this many seconds after external power is removed.
  @$pb.TagNumber(2)
  $core.int get onBatteryShutdownAfterSecs => $_getIZ(1);
  @$pb.TagNumber(2)
  set onBatteryShutdownAfterSecs($core.int value) =>
      $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOnBatteryShutdownAfterSecs() => $_has(1);
  @$pb.TagNumber(2)
  void clearOnBatteryShutdownAfterSecs() => $_clearField(2);

  ///
  ///  Ratio of voltage divider for battery pin eg. 3.20 (R1=100k, R2=220k)
  ///  Overrides the ADC_MULTIPLIER defined in variant for battery voltage calculation.
  ///  https://meshtastic.org/docs/configuration/radio/power/#adc-multiplier-override
  ///  Should be set to floating point value between 2 and 6
  @$pb.TagNumber(3)
  $core.double get adcMultiplierOverride => $_getN(2);
  @$pb.TagNumber(3)
  set adcMultiplierOverride($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAdcMultiplierOverride() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdcMultiplierOverride() => $_clearField(3);

  ///
  ///   Description: The number of seconds for to wait before turning off BLE in No Bluetooth states
  ///   Technical Details: ESP32 Only 0 for default of 1 minute
  @$pb.TagNumber(4)
  $core.int get waitBluetoothSecs => $_getIZ(3);
  @$pb.TagNumber(4)
  set waitBluetoothSecs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWaitBluetoothSecs() => $_has(3);
  @$pb.TagNumber(4)
  void clearWaitBluetoothSecs() => $_clearField(4);

  ///
  ///  Super Deep Sleep Seconds
  ///  While in Light Sleep if mesh_sds_timeout_secs is exceeded we will lower into super deep sleep
  ///  for this value (default 1 year) or a button press
  ///  0 for default of one year
  @$pb.TagNumber(6)
  $core.int get sdsSecs => $_getIZ(4);
  @$pb.TagNumber(6)
  set sdsSecs($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(6)
  $core.bool hasSdsSecs() => $_has(4);
  @$pb.TagNumber(6)
  void clearSdsSecs() => $_clearField(6);

  ///
  ///  Description: In light sleep the CPU is suspended, LoRa radio is on, BLE is off an GPS is on
  ///  Technical Details: ESP32 Only 0 for default of 300
  @$pb.TagNumber(7)
  $core.int get lsSecs => $_getIZ(5);
  @$pb.TagNumber(7)
  set lsSecs($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(7)
  $core.bool hasLsSecs() => $_has(5);
  @$pb.TagNumber(7)
  void clearLsSecs() => $_clearField(7);

  ///
  ///  Description: While in light sleep when we receive packets on the LoRa radio we will wake and handle them and stay awake in no BLE mode for this value
  ///  Technical Details: ESP32 Only 0 for default of 10 seconds
  @$pb.TagNumber(8)
  $core.int get minWakeSecs => $_getIZ(6);
  @$pb.TagNumber(8)
  set minWakeSecs($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(8)
  $core.bool hasMinWakeSecs() => $_has(6);
  @$pb.TagNumber(8)
  void clearMinWakeSecs() => $_clearField(8);

  ///
  ///  I2C address of INA_2XX to use for reading device battery voltage
  @$pb.TagNumber(9)
  $core.int get deviceBatteryInaAddress => $_getIZ(7);
  @$pb.TagNumber(9)
  set deviceBatteryInaAddress($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(9)
  $core.bool hasDeviceBatteryInaAddress() => $_has(7);
  @$pb.TagNumber(9)
  void clearDeviceBatteryInaAddress() => $_clearField(9);

  ///
  ///  If non-zero, we want powermon log outputs.  With the particular (bitfield) sources enabled.
  ///  Note: we picked an ID of 32 so that lower more efficient IDs can be used for more frequently used options.
  @$pb.TagNumber(32)
  $fixnum.Int64 get powermonEnables => $_getI64(8);
  @$pb.TagNumber(32)
  set powermonEnables($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(32)
  $core.bool hasPowermonEnables() => $_has(8);
  @$pb.TagNumber(32)
  void clearPowermonEnables() => $_clearField(32);
}

class Config_NetworkConfig_IpV4Config extends $pb.GeneratedMessage {
  factory Config_NetworkConfig_IpV4Config({
    $core.int? ip,
    $core.int? gateway,
    $core.int? subnet,
    $core.int? dns,
  }) {
    final result = create();
    if (ip != null) result.ip = ip;
    if (gateway != null) result.gateway = gateway;
    if (subnet != null) result.subnet = subnet;
    if (dns != null) result.dns = dns;
    return result;
  }

  Config_NetworkConfig_IpV4Config._();

  factory Config_NetworkConfig_IpV4Config.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_NetworkConfig_IpV4Config.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.NetworkConfig.IpV4Config',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'ip', $pb.PbFieldType.OF3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'gateway', $pb.PbFieldType.OF3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'subnet', $pb.PbFieldType.OF3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'dns', $pb.PbFieldType.OF3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_NetworkConfig_IpV4Config clone() =>
      Config_NetworkConfig_IpV4Config()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_NetworkConfig_IpV4Config copyWith(
          void Function(Config_NetworkConfig_IpV4Config) updates) =>
      super.copyWith(
              (message) => updates(message as Config_NetworkConfig_IpV4Config))
          as Config_NetworkConfig_IpV4Config;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_NetworkConfig_IpV4Config create() =>
      Config_NetworkConfig_IpV4Config._();
  @$core.override
  Config_NetworkConfig_IpV4Config createEmptyInstance() => create();
  static $pb.PbList<Config_NetworkConfig_IpV4Config> createRepeated() =>
      $pb.PbList<Config_NetworkConfig_IpV4Config>();
  @$core.pragma('dart2js:noInline')
  static Config_NetworkConfig_IpV4Config getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_NetworkConfig_IpV4Config>(
          create);
  static Config_NetworkConfig_IpV4Config? _defaultInstance;

  ///
  ///  Static IP address
  @$pb.TagNumber(1)
  $core.int get ip => $_getIZ(0);
  @$pb.TagNumber(1)
  set ip($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIp() => $_has(0);
  @$pb.TagNumber(1)
  void clearIp() => $_clearField(1);

  ///
  ///  Static gateway address
  @$pb.TagNumber(2)
  $core.int get gateway => $_getIZ(1);
  @$pb.TagNumber(2)
  set gateway($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGateway() => $_has(1);
  @$pb.TagNumber(2)
  void clearGateway() => $_clearField(2);

  ///
  ///  Static subnet mask
  @$pb.TagNumber(3)
  $core.int get subnet => $_getIZ(2);
  @$pb.TagNumber(3)
  set subnet($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubnet() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubnet() => $_clearField(3);

  ///
  ///  Static DNS server address
  @$pb.TagNumber(4)
  $core.int get dns => $_getIZ(3);
  @$pb.TagNumber(4)
  set dns($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDns() => $_has(3);
  @$pb.TagNumber(4)
  void clearDns() => $_clearField(4);
}

///
///  Network Config
class Config_NetworkConfig extends $pb.GeneratedMessage {
  factory Config_NetworkConfig({
    $core.bool? wifiEnabled,
    $core.String? wifiSsid,
    $core.String? wifiPsk,
    $core.String? ntpServer,
    $core.bool? ethEnabled,
    Config_NetworkConfig_AddressMode? addressMode,
    Config_NetworkConfig_IpV4Config? ipv4Config,
    $core.String? rsyslogServer,
    $core.int? enabledProtocols,
    $core.bool? ipv6Enabled,
  }) {
    final result = create();
    if (wifiEnabled != null) result.wifiEnabled = wifiEnabled;
    if (wifiSsid != null) result.wifiSsid = wifiSsid;
    if (wifiPsk != null) result.wifiPsk = wifiPsk;
    if (ntpServer != null) result.ntpServer = ntpServer;
    if (ethEnabled != null) result.ethEnabled = ethEnabled;
    if (addressMode != null) result.addressMode = addressMode;
    if (ipv4Config != null) result.ipv4Config = ipv4Config;
    if (rsyslogServer != null) result.rsyslogServer = rsyslogServer;
    if (enabledProtocols != null) result.enabledProtocols = enabledProtocols;
    if (ipv6Enabled != null) result.ipv6Enabled = ipv6Enabled;
    return result;
  }

  Config_NetworkConfig._();

  factory Config_NetworkConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_NetworkConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.NetworkConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'wifiEnabled')
    ..aOS(3, _omitFieldNames ? '' : 'wifiSsid')
    ..aOS(4, _omitFieldNames ? '' : 'wifiPsk')
    ..aOS(5, _omitFieldNames ? '' : 'ntpServer')
    ..aOB(6, _omitFieldNames ? '' : 'ethEnabled')
    ..e<Config_NetworkConfig_AddressMode>(
        7, _omitFieldNames ? '' : 'addressMode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_NetworkConfig_AddressMode.DHCP,
        valueOf: Config_NetworkConfig_AddressMode.valueOf,
        enumValues: Config_NetworkConfig_AddressMode.values)
    ..aOM<Config_NetworkConfig_IpV4Config>(
        8, _omitFieldNames ? '' : 'ipv4Config',
        subBuilder: Config_NetworkConfig_IpV4Config.create)
    ..aOS(9, _omitFieldNames ? '' : 'rsyslogServer')
    ..a<$core.int>(
        10, _omitFieldNames ? '' : 'enabledProtocols', $pb.PbFieldType.OU3)
    ..aOB(11, _omitFieldNames ? '' : 'ipv6Enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_NetworkConfig clone() =>
      Config_NetworkConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_NetworkConfig copyWith(void Function(Config_NetworkConfig) updates) =>
      super.copyWith((message) => updates(message as Config_NetworkConfig))
          as Config_NetworkConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_NetworkConfig create() => Config_NetworkConfig._();
  @$core.override
  Config_NetworkConfig createEmptyInstance() => create();
  static $pb.PbList<Config_NetworkConfig> createRepeated() =>
      $pb.PbList<Config_NetworkConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_NetworkConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_NetworkConfig>(create);
  static Config_NetworkConfig? _defaultInstance;

  ///
  ///  Enable WiFi (disables Bluetooth)
  @$pb.TagNumber(1)
  $core.bool get wifiEnabled => $_getBF(0);
  @$pb.TagNumber(1)
  set wifiEnabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWifiEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearWifiEnabled() => $_clearField(1);

  ///
  ///  If set, this node will try to join the specified wifi network and
  ///  acquire an address via DHCP
  @$pb.TagNumber(3)
  $core.String get wifiSsid => $_getSZ(1);
  @$pb.TagNumber(3)
  set wifiSsid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasWifiSsid() => $_has(1);
  @$pb.TagNumber(3)
  void clearWifiSsid() => $_clearField(3);

  ///
  ///  If set, will be use to authenticate to the named wifi
  @$pb.TagNumber(4)
  $core.String get wifiPsk => $_getSZ(2);
  @$pb.TagNumber(4)
  set wifiPsk($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasWifiPsk() => $_has(2);
  @$pb.TagNumber(4)
  void clearWifiPsk() => $_clearField(4);

  ///
  ///  NTP server to use if WiFi is conneced, defaults to `meshtastic.pool.ntp.org`
  @$pb.TagNumber(5)
  $core.String get ntpServer => $_getSZ(3);
  @$pb.TagNumber(5)
  set ntpServer($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasNtpServer() => $_has(3);
  @$pb.TagNumber(5)
  void clearNtpServer() => $_clearField(5);

  ///
  ///  Enable Ethernet
  @$pb.TagNumber(6)
  $core.bool get ethEnabled => $_getBF(4);
  @$pb.TagNumber(6)
  set ethEnabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(6)
  $core.bool hasEthEnabled() => $_has(4);
  @$pb.TagNumber(6)
  void clearEthEnabled() => $_clearField(6);

  ///
  ///  acquire an address via DHCP or assign static
  @$pb.TagNumber(7)
  Config_NetworkConfig_AddressMode get addressMode => $_getN(5);
  @$pb.TagNumber(7)
  set addressMode(Config_NetworkConfig_AddressMode value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAddressMode() => $_has(5);
  @$pb.TagNumber(7)
  void clearAddressMode() => $_clearField(7);

  ///
  ///  struct to keep static address
  @$pb.TagNumber(8)
  Config_NetworkConfig_IpV4Config get ipv4Config => $_getN(6);
  @$pb.TagNumber(8)
  set ipv4Config(Config_NetworkConfig_IpV4Config value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasIpv4Config() => $_has(6);
  @$pb.TagNumber(8)
  void clearIpv4Config() => $_clearField(8);
  @$pb.TagNumber(8)
  Config_NetworkConfig_IpV4Config ensureIpv4Config() => $_ensure(6);

  ///
  ///  rsyslog Server and Port
  @$pb.TagNumber(9)
  $core.String get rsyslogServer => $_getSZ(7);
  @$pb.TagNumber(9)
  set rsyslogServer($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasRsyslogServer() => $_has(7);
  @$pb.TagNumber(9)
  void clearRsyslogServer() => $_clearField(9);

  ///
  ///  Flags for enabling/disabling network protocols
  @$pb.TagNumber(10)
  $core.int get enabledProtocols => $_getIZ(8);
  @$pb.TagNumber(10)
  set enabledProtocols($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(10)
  $core.bool hasEnabledProtocols() => $_has(8);
  @$pb.TagNumber(10)
  void clearEnabledProtocols() => $_clearField(10);

  ///
  ///  Enable/Disable ipv6 support
  @$pb.TagNumber(11)
  $core.bool get ipv6Enabled => $_getBF(9);
  @$pb.TagNumber(11)
  set ipv6Enabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(11)
  $core.bool hasIpv6Enabled() => $_has(9);
  @$pb.TagNumber(11)
  void clearIpv6Enabled() => $_clearField(11);
}

///
///  Display Config
class Config_DisplayConfig extends $pb.GeneratedMessage {
  factory Config_DisplayConfig({
    $core.int? screenOnSecs,
    @$core.Deprecated('This field is deprecated.')
    Config_DisplayConfig_GpsCoordinateFormat? gpsFormat,
    $core.int? autoScreenCarouselSecs,
    @$core.Deprecated('This field is deprecated.') $core.bool? compassNorthTop,
    $core.bool? flipScreen,
    Config_DisplayConfig_DisplayUnits? units,
    Config_DisplayConfig_OledType? oled,
    Config_DisplayConfig_DisplayMode? displaymode,
    $core.bool? headingBold,
    $core.bool? wakeOnTapOrMotion,
    Config_DisplayConfig_CompassOrientation? compassOrientation,
    $core.bool? use12hClock,
  }) {
    final result = create();
    if (screenOnSecs != null) result.screenOnSecs = screenOnSecs;
    if (gpsFormat != null) result.gpsFormat = gpsFormat;
    if (autoScreenCarouselSecs != null)
      result.autoScreenCarouselSecs = autoScreenCarouselSecs;
    if (compassNorthTop != null) result.compassNorthTop = compassNorthTop;
    if (flipScreen != null) result.flipScreen = flipScreen;
    if (units != null) result.units = units;
    if (oled != null) result.oled = oled;
    if (displaymode != null) result.displaymode = displaymode;
    if (headingBold != null) result.headingBold = headingBold;
    if (wakeOnTapOrMotion != null) result.wakeOnTapOrMotion = wakeOnTapOrMotion;
    if (compassOrientation != null)
      result.compassOrientation = compassOrientation;
    if (use12hClock != null) result.use12hClock = use12hClock;
    return result;
  }

  Config_DisplayConfig._();

  factory Config_DisplayConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_DisplayConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.DisplayConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'screenOnSecs', $pb.PbFieldType.OU3)
    ..e<Config_DisplayConfig_GpsCoordinateFormat>(
        2, _omitFieldNames ? '' : 'gpsFormat', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DisplayConfig_GpsCoordinateFormat.DEC,
        valueOf: Config_DisplayConfig_GpsCoordinateFormat.valueOf,
        enumValues: Config_DisplayConfig_GpsCoordinateFormat.values)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'autoScreenCarouselSecs', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'compassNorthTop')
    ..aOB(5, _omitFieldNames ? '' : 'flipScreen')
    ..e<Config_DisplayConfig_DisplayUnits>(
        6, _omitFieldNames ? '' : 'units', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DisplayConfig_DisplayUnits.METRIC,
        valueOf: Config_DisplayConfig_DisplayUnits.valueOf,
        enumValues: Config_DisplayConfig_DisplayUnits.values)
    ..e<Config_DisplayConfig_OledType>(
        7, _omitFieldNames ? '' : 'oled', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DisplayConfig_OledType.OLED_AUTO,
        valueOf: Config_DisplayConfig_OledType.valueOf,
        enumValues: Config_DisplayConfig_OledType.values)
    ..e<Config_DisplayConfig_DisplayMode>(
        8, _omitFieldNames ? '' : 'displaymode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DisplayConfig_DisplayMode.DEFAULT,
        valueOf: Config_DisplayConfig_DisplayMode.valueOf,
        enumValues: Config_DisplayConfig_DisplayMode.values)
    ..aOB(9, _omitFieldNames ? '' : 'headingBold')
    ..aOB(10, _omitFieldNames ? '' : 'wakeOnTapOrMotion')
    ..e<Config_DisplayConfig_CompassOrientation>(
        11, _omitFieldNames ? '' : 'compassOrientation', $pb.PbFieldType.OE,
        defaultOrMaker: Config_DisplayConfig_CompassOrientation.DEGREES_0,
        valueOf: Config_DisplayConfig_CompassOrientation.valueOf,
        enumValues: Config_DisplayConfig_CompassOrientation.values)
    ..aOB(12, _omitFieldNames ? '' : 'use12hClock', protoName: 'use_12h_clock')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_DisplayConfig clone() =>
      Config_DisplayConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_DisplayConfig copyWith(void Function(Config_DisplayConfig) updates) =>
      super.copyWith((message) => updates(message as Config_DisplayConfig))
          as Config_DisplayConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_DisplayConfig create() => Config_DisplayConfig._();
  @$core.override
  Config_DisplayConfig createEmptyInstance() => create();
  static $pb.PbList<Config_DisplayConfig> createRepeated() =>
      $pb.PbList<Config_DisplayConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_DisplayConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_DisplayConfig>(create);
  static Config_DisplayConfig? _defaultInstance;

  ///
  ///  Number of seconds the screen stays on after pressing the user button or receiving a message
  ///  0 for default of one minute MAXUINT for always on
  @$pb.TagNumber(1)
  $core.int get screenOnSecs => $_getIZ(0);
  @$pb.TagNumber(1)
  set screenOnSecs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasScreenOnSecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearScreenOnSecs() => $_clearField(1);

  ///
  ///  Deprecated in 2.7.4: Unused
  ///  How the GPS coordinates are formatted on the OLED screen.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  Config_DisplayConfig_GpsCoordinateFormat get gpsFormat => $_getN(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  set gpsFormat(Config_DisplayConfig_GpsCoordinateFormat value) =>
      $_setField(2, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool hasGpsFormat() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  void clearGpsFormat() => $_clearField(2);

  ///
  ///  Automatically toggles to the next page on the screen like a carousel, based the specified interval in seconds.
  ///  Potentially useful for devices without user buttons.
  @$pb.TagNumber(3)
  $core.int get autoScreenCarouselSecs => $_getIZ(2);
  @$pb.TagNumber(3)
  set autoScreenCarouselSecs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAutoScreenCarouselSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearAutoScreenCarouselSecs() => $_clearField(3);

  ///
  ///  If this is set, the displayed compass will always point north. if unset, the old behaviour
  ///  (top of display is heading direction) is used.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool get compassNorthTop => $_getBF(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  set compassNorthTop($core.bool value) => $_setBool(3, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool hasCompassNorthTop() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  void clearCompassNorthTop() => $_clearField(4);

  ///
  ///  Flip screen vertically, for cases that mount the screen upside down
  @$pb.TagNumber(5)
  $core.bool get flipScreen => $_getBF(4);
  @$pb.TagNumber(5)
  set flipScreen($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFlipScreen() => $_has(4);
  @$pb.TagNumber(5)
  void clearFlipScreen() => $_clearField(5);

  ///
  ///  Perferred display units
  @$pb.TagNumber(6)
  Config_DisplayConfig_DisplayUnits get units => $_getN(5);
  @$pb.TagNumber(6)
  set units(Config_DisplayConfig_DisplayUnits value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUnits() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnits() => $_clearField(6);

  ///
  ///  Override auto-detect in screen
  @$pb.TagNumber(7)
  Config_DisplayConfig_OledType get oled => $_getN(6);
  @$pb.TagNumber(7)
  set oled(Config_DisplayConfig_OledType value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOled() => $_has(6);
  @$pb.TagNumber(7)
  void clearOled() => $_clearField(7);

  ///
  ///  Display Mode
  @$pb.TagNumber(8)
  Config_DisplayConfig_DisplayMode get displaymode => $_getN(7);
  @$pb.TagNumber(8)
  set displaymode(Config_DisplayConfig_DisplayMode value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasDisplaymode() => $_has(7);
  @$pb.TagNumber(8)
  void clearDisplaymode() => $_clearField(8);

  ///
  ///  Print first line in pseudo-bold? FALSE is original style, TRUE is bold
  @$pb.TagNumber(9)
  $core.bool get headingBold => $_getBF(8);
  @$pb.TagNumber(9)
  set headingBold($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHeadingBold() => $_has(8);
  @$pb.TagNumber(9)
  void clearHeadingBold() => $_clearField(9);

  ///
  ///  Should we wake the screen up on accelerometer detected motion or tap
  @$pb.TagNumber(10)
  $core.bool get wakeOnTapOrMotion => $_getBF(9);
  @$pb.TagNumber(10)
  set wakeOnTapOrMotion($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasWakeOnTapOrMotion() => $_has(9);
  @$pb.TagNumber(10)
  void clearWakeOnTapOrMotion() => $_clearField(10);

  ///
  ///  Indicates how to rotate or invert the compass output to accurate display on the display.
  @$pb.TagNumber(11)
  Config_DisplayConfig_CompassOrientation get compassOrientation => $_getN(10);
  @$pb.TagNumber(11)
  set compassOrientation(Config_DisplayConfig_CompassOrientation value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasCompassOrientation() => $_has(10);
  @$pb.TagNumber(11)
  void clearCompassOrientation() => $_clearField(11);

  ///
  ///  If false (default), the device will display the time in 24-hour format on screen.
  ///  If true, the device will display the time in 12-hour format on screen.
  @$pb.TagNumber(12)
  $core.bool get use12hClock => $_getBF(11);
  @$pb.TagNumber(12)
  set use12hClock($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUse12hClock() => $_has(11);
  @$pb.TagNumber(12)
  void clearUse12hClock() => $_clearField(12);
}

///
///  Lora Config
class Config_LoRaConfig extends $pb.GeneratedMessage {
  factory Config_LoRaConfig({
    $core.bool? usePreset,
    Config_LoRaConfig_ModemPreset? modemPreset,
    $core.int? bandwidth,
    $core.int? spreadFactor,
    $core.int? codingRate,
    $core.double? frequencyOffset,
    Config_LoRaConfig_RegionCode? region,
    $core.int? hopLimit,
    $core.bool? txEnabled,
    $core.int? txPower,
    $core.int? channelNum,
    $core.bool? overrideDutyCycle,
    $core.bool? sx126xRxBoostedGain,
    $core.double? overrideFrequency,
    $core.bool? paFanDisabled,
    $core.Iterable<$core.int>? ignoreIncoming,
    $core.bool? ignoreMqtt,
    $core.bool? configOkToMqtt,
  }) {
    final result = create();
    if (usePreset != null) result.usePreset = usePreset;
    if (modemPreset != null) result.modemPreset = modemPreset;
    if (bandwidth != null) result.bandwidth = bandwidth;
    if (spreadFactor != null) result.spreadFactor = spreadFactor;
    if (codingRate != null) result.codingRate = codingRate;
    if (frequencyOffset != null) result.frequencyOffset = frequencyOffset;
    if (region != null) result.region = region;
    if (hopLimit != null) result.hopLimit = hopLimit;
    if (txEnabled != null) result.txEnabled = txEnabled;
    if (txPower != null) result.txPower = txPower;
    if (channelNum != null) result.channelNum = channelNum;
    if (overrideDutyCycle != null) result.overrideDutyCycle = overrideDutyCycle;
    if (sx126xRxBoostedGain != null)
      result.sx126xRxBoostedGain = sx126xRxBoostedGain;
    if (overrideFrequency != null) result.overrideFrequency = overrideFrequency;
    if (paFanDisabled != null) result.paFanDisabled = paFanDisabled;
    if (ignoreIncoming != null) result.ignoreIncoming.addAll(ignoreIncoming);
    if (ignoreMqtt != null) result.ignoreMqtt = ignoreMqtt;
    if (configOkToMqtt != null) result.configOkToMqtt = configOkToMqtt;
    return result;
  }

  Config_LoRaConfig._();

  factory Config_LoRaConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_LoRaConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.LoRaConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'usePreset')
    ..e<Config_LoRaConfig_ModemPreset>(
        2, _omitFieldNames ? '' : 'modemPreset', $pb.PbFieldType.OE,
        defaultOrMaker: Config_LoRaConfig_ModemPreset.LONG_FAST,
        valueOf: Config_LoRaConfig_ModemPreset.valueOf,
        enumValues: Config_LoRaConfig_ModemPreset.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'bandwidth', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'spreadFactor', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'codingRate', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        6, _omitFieldNames ? '' : 'frequencyOffset', $pb.PbFieldType.OF)
    ..e<Config_LoRaConfig_RegionCode>(
        7, _omitFieldNames ? '' : 'region', $pb.PbFieldType.OE,
        defaultOrMaker: Config_LoRaConfig_RegionCode.UNSET,
        valueOf: Config_LoRaConfig_RegionCode.valueOf,
        enumValues: Config_LoRaConfig_RegionCode.values)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'hopLimit', $pb.PbFieldType.OU3)
    ..aOB(9, _omitFieldNames ? '' : 'txEnabled')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'txPower', $pb.PbFieldType.O3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'channelNum', $pb.PbFieldType.OU3)
    ..aOB(12, _omitFieldNames ? '' : 'overrideDutyCycle')
    ..aOB(13, _omitFieldNames ? '' : 'sx126xRxBoostedGain')
    ..a<$core.double>(
        14, _omitFieldNames ? '' : 'overrideFrequency', $pb.PbFieldType.OF)
    ..aOB(15, _omitFieldNames ? '' : 'paFanDisabled')
    ..p<$core.int>(
        103, _omitFieldNames ? '' : 'ignoreIncoming', $pb.PbFieldType.KU3)
    ..aOB(104, _omitFieldNames ? '' : 'ignoreMqtt')
    ..aOB(105, _omitFieldNames ? '' : 'configOkToMqtt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_LoRaConfig clone() => Config_LoRaConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_LoRaConfig copyWith(void Function(Config_LoRaConfig) updates) =>
      super.copyWith((message) => updates(message as Config_LoRaConfig))
          as Config_LoRaConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_LoRaConfig create() => Config_LoRaConfig._();
  @$core.override
  Config_LoRaConfig createEmptyInstance() => create();
  static $pb.PbList<Config_LoRaConfig> createRepeated() =>
      $pb.PbList<Config_LoRaConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_LoRaConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_LoRaConfig>(create);
  static Config_LoRaConfig? _defaultInstance;

  ///
  ///  When enabled, the `modem_preset` fields will be adhered to, else the `bandwidth`/`spread_factor`/`coding_rate`
  ///  will be taked from their respective manually defined fields
  @$pb.TagNumber(1)
  $core.bool get usePreset => $_getBF(0);
  @$pb.TagNumber(1)
  set usePreset($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsePreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsePreset() => $_clearField(1);

  ///
  ///  Either modem_config or bandwidth/spreading/coding will be specified - NOT BOTH.
  ///  As a heuristic: If bandwidth is specified, do not use modem_config.
  ///  Because protobufs take ZERO space when the value is zero this works out nicely.
  ///  This value is replaced by bandwidth/spread_factor/coding_rate.
  ///  If you'd like to experiment with other options add them to MeshRadio.cpp in the device code.
  @$pb.TagNumber(2)
  Config_LoRaConfig_ModemPreset get modemPreset => $_getN(1);
  @$pb.TagNumber(2)
  set modemPreset(Config_LoRaConfig_ModemPreset value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasModemPreset() => $_has(1);
  @$pb.TagNumber(2)
  void clearModemPreset() => $_clearField(2);

  ///
  ///  Bandwidth in MHz
  ///  Certain bandwidth numbers are 'special' and will be converted to the
  ///  appropriate floating point value: 31 -> 31.25MHz
  @$pb.TagNumber(3)
  $core.int get bandwidth => $_getIZ(2);
  @$pb.TagNumber(3)
  set bandwidth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBandwidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearBandwidth() => $_clearField(3);

  ///
  ///  A number from 7 to 12.
  ///  Indicates number of chirps per symbol as 1<<spread_factor.
  @$pb.TagNumber(4)
  $core.int get spreadFactor => $_getIZ(3);
  @$pb.TagNumber(4)
  set spreadFactor($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpreadFactor() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpreadFactor() => $_clearField(4);

  ///
  ///  The denominator of the coding rate.
  ///  ie for 4/5, the value is 5. 4/8 the value is 8.
  @$pb.TagNumber(5)
  $core.int get codingRate => $_getIZ(4);
  @$pb.TagNumber(5)
  set codingRate($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCodingRate() => $_has(4);
  @$pb.TagNumber(5)
  void clearCodingRate() => $_clearField(5);

  ///
  ///  This parameter is for advanced users with advanced test equipment, we do not recommend most users use it.
  ///  A frequency offset that is added to to the calculated band center frequency.
  ///  Used to correct for crystal calibration errors.
  @$pb.TagNumber(6)
  $core.double get frequencyOffset => $_getN(5);
  @$pb.TagNumber(6)
  set frequencyOffset($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFrequencyOffset() => $_has(5);
  @$pb.TagNumber(6)
  void clearFrequencyOffset() => $_clearField(6);

  ///
  ///  The region code for the radio (US, CN, EU433, etc...)
  @$pb.TagNumber(7)
  Config_LoRaConfig_RegionCode get region => $_getN(6);
  @$pb.TagNumber(7)
  set region(Config_LoRaConfig_RegionCode value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRegion() => $_has(6);
  @$pb.TagNumber(7)
  void clearRegion() => $_clearField(7);

  ///
  ///  Maximum number of hops. This can't be greater than 7.
  ///  Default of 3
  ///  Attempting to set a value > 7 results in the default
  @$pb.TagNumber(8)
  $core.int get hopLimit => $_getIZ(7);
  @$pb.TagNumber(8)
  set hopLimit($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHopLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearHopLimit() => $_clearField(8);

  ///
  ///  Disable TX from the LoRa radio. Useful for hot-swapping antennas and other tests.
  ///  Defaults to false
  @$pb.TagNumber(9)
  $core.bool get txEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set txEnabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTxEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearTxEnabled() => $_clearField(9);

  ///
  ///  If zero, then use default max legal continuous power (ie. something that won't
  ///  burn out the radio hardware)
  ///  In most cases you should use zero here.
  ///  Units are in dBm.
  @$pb.TagNumber(10)
  $core.int get txPower => $_getIZ(9);
  @$pb.TagNumber(10)
  set txPower($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTxPower() => $_has(9);
  @$pb.TagNumber(10)
  void clearTxPower() => $_clearField(10);

  ///
  ///  This controls the actual hardware frequency the radio transmits on.
  ///  Most users should never need to be exposed to this field/concept.
  ///  A channel number between 1 and NUM_CHANNELS (whatever the max is in the current region).
  ///  If ZERO then the rule is "use the old channel name hash based
  ///  algorithm to derive the channel number")
  ///  If using the hash algorithm the channel number will be: hash(channel_name) %
  ///  NUM_CHANNELS (Where num channels depends on the regulatory region).
  @$pb.TagNumber(11)
  $core.int get channelNum => $_getIZ(10);
  @$pb.TagNumber(11)
  set channelNum($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasChannelNum() => $_has(10);
  @$pb.TagNumber(11)
  void clearChannelNum() => $_clearField(11);

  ///
  ///  If true, duty cycle limits will be exceeded and thus you're possibly not following
  ///  the local regulations if you're not a HAM.
  ///  Has no effect if the duty cycle of the used region is 100%.
  @$pb.TagNumber(12)
  $core.bool get overrideDutyCycle => $_getBF(11);
  @$pb.TagNumber(12)
  set overrideDutyCycle($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasOverrideDutyCycle() => $_has(11);
  @$pb.TagNumber(12)
  void clearOverrideDutyCycle() => $_clearField(12);

  ///
  ///  If true, sets RX boosted gain mode on SX126X based radios
  @$pb.TagNumber(13)
  $core.bool get sx126xRxBoostedGain => $_getBF(12);
  @$pb.TagNumber(13)
  set sx126xRxBoostedGain($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasSx126xRxBoostedGain() => $_has(12);
  @$pb.TagNumber(13)
  void clearSx126xRxBoostedGain() => $_clearField(13);

  ///
  ///  This parameter is for advanced users and licensed HAM radio operators.
  ///  Ignore Channel Calculation and use this frequency instead. The frequency_offset
  ///  will still be applied. This will allow you to use out-of-band frequencies.
  ///  Please respect your local laws and regulations. If you are a HAM, make sure you
  ///  enable HAM mode and turn off encryption.
  @$pb.TagNumber(14)
  $core.double get overrideFrequency => $_getN(13);
  @$pb.TagNumber(14)
  set overrideFrequency($core.double value) => $_setFloat(13, value);
  @$pb.TagNumber(14)
  $core.bool hasOverrideFrequency() => $_has(13);
  @$pb.TagNumber(14)
  void clearOverrideFrequency() => $_clearField(14);

  ///
  ///  If true, disable the build-in PA FAN using pin define in RF95_FAN_EN.
  @$pb.TagNumber(15)
  $core.bool get paFanDisabled => $_getBF(14);
  @$pb.TagNumber(15)
  set paFanDisabled($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasPaFanDisabled() => $_has(14);
  @$pb.TagNumber(15)
  void clearPaFanDisabled() => $_clearField(15);

  ///
  ///  For testing it is useful sometimes to force a node to never listen to
  ///  particular other nodes (simulating radio out of range). All nodenums listed
  ///  in ignore_incoming will have packets they send dropped on receive (by router.cpp)
  @$pb.TagNumber(103)
  $pb.PbList<$core.int> get ignoreIncoming => $_getList(15);

  ///
  ///  If true, the device will not process any packets received via LoRa that passed via MQTT anywhere on the path towards it.
  @$pb.TagNumber(104)
  $core.bool get ignoreMqtt => $_getBF(16);
  @$pb.TagNumber(104)
  set ignoreMqtt($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(104)
  $core.bool hasIgnoreMqtt() => $_has(16);
  @$pb.TagNumber(104)
  void clearIgnoreMqtt() => $_clearField(104);

  ///
  ///  Sets the ok_to_mqtt bit on outgoing packets
  @$pb.TagNumber(105)
  $core.bool get configOkToMqtt => $_getBF(17);
  @$pb.TagNumber(105)
  set configOkToMqtt($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(105)
  $core.bool hasConfigOkToMqtt() => $_has(17);
  @$pb.TagNumber(105)
  void clearConfigOkToMqtt() => $_clearField(105);
}

class Config_BluetoothConfig extends $pb.GeneratedMessage {
  factory Config_BluetoothConfig({
    $core.bool? enabled,
    Config_BluetoothConfig_PairingMode? mode,
    $core.int? fixedPin,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (mode != null) result.mode = mode;
    if (fixedPin != null) result.fixedPin = fixedPin;
    return result;
  }

  Config_BluetoothConfig._();

  factory Config_BluetoothConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_BluetoothConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.BluetoothConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..e<Config_BluetoothConfig_PairingMode>(
        2, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE,
        defaultOrMaker: Config_BluetoothConfig_PairingMode.RANDOM_PIN,
        valueOf: Config_BluetoothConfig_PairingMode.valueOf,
        enumValues: Config_BluetoothConfig_PairingMode.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'fixedPin', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_BluetoothConfig clone() =>
      Config_BluetoothConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_BluetoothConfig copyWith(
          void Function(Config_BluetoothConfig) updates) =>
      super.copyWith((message) => updates(message as Config_BluetoothConfig))
          as Config_BluetoothConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_BluetoothConfig create() => Config_BluetoothConfig._();
  @$core.override
  Config_BluetoothConfig createEmptyInstance() => create();
  static $pb.PbList<Config_BluetoothConfig> createRepeated() =>
      $pb.PbList<Config_BluetoothConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_BluetoothConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_BluetoothConfig>(create);
  static Config_BluetoothConfig? _defaultInstance;

  ///
  ///  Enable Bluetooth on the device
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  ///
  ///  Determines the pairing strategy for the device
  @$pb.TagNumber(2)
  Config_BluetoothConfig_PairingMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(Config_BluetoothConfig_PairingMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  ///
  ///  Specified PIN for PairingMode.FixedPin
  @$pb.TagNumber(3)
  $core.int get fixedPin => $_getIZ(2);
  @$pb.TagNumber(3)
  set fixedPin($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFixedPin() => $_has(2);
  @$pb.TagNumber(3)
  void clearFixedPin() => $_clearField(3);
}

class Config_SecurityConfig extends $pb.GeneratedMessage {
  factory Config_SecurityConfig({
    $core.List<$core.int>? publicKey,
    $core.List<$core.int>? privateKey,
    $core.Iterable<$core.List<$core.int>>? adminKey,
    $core.bool? isManaged,
    $core.bool? serialEnabled,
    $core.bool? debugLogApiEnabled,
    $core.bool? adminChannelEnabled,
  }) {
    final result = create();
    if (publicKey != null) result.publicKey = publicKey;
    if (privateKey != null) result.privateKey = privateKey;
    if (adminKey != null) result.adminKey.addAll(adminKey);
    if (isManaged != null) result.isManaged = isManaged;
    if (serialEnabled != null) result.serialEnabled = serialEnabled;
    if (debugLogApiEnabled != null)
      result.debugLogApiEnabled = debugLogApiEnabled;
    if (adminChannelEnabled != null)
      result.adminChannelEnabled = adminChannelEnabled;
    return result;
  }

  Config_SecurityConfig._();

  factory Config_SecurityConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_SecurityConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.SecurityConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'privateKey', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'adminKey', $pb.PbFieldType.PY)
    ..aOB(4, _omitFieldNames ? '' : 'isManaged')
    ..aOB(5, _omitFieldNames ? '' : 'serialEnabled')
    ..aOB(6, _omitFieldNames ? '' : 'debugLogApiEnabled')
    ..aOB(8, _omitFieldNames ? '' : 'adminChannelEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_SecurityConfig clone() =>
      Config_SecurityConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_SecurityConfig copyWith(
          void Function(Config_SecurityConfig) updates) =>
      super.copyWith((message) => updates(message as Config_SecurityConfig))
          as Config_SecurityConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_SecurityConfig create() => Config_SecurityConfig._();
  @$core.override
  Config_SecurityConfig createEmptyInstance() => create();
  static $pb.PbList<Config_SecurityConfig> createRepeated() =>
      $pb.PbList<Config_SecurityConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_SecurityConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_SecurityConfig>(create);
  static Config_SecurityConfig? _defaultInstance;

  ///
  ///  The public key of the user's device.
  ///  Sent out to other nodes on the mesh to allow them to compute a shared secret key.
  @$pb.TagNumber(1)
  $core.List<$core.int> get publicKey => $_getN(0);
  @$pb.TagNumber(1)
  set publicKey($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicKey() => $_clearField(1);

  ///
  ///  The private key of the device.
  ///  Used to create a shared key with a remote device.
  @$pb.TagNumber(2)
  $core.List<$core.int> get privateKey => $_getN(1);
  @$pb.TagNumber(2)
  set privateKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrivateKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrivateKey() => $_clearField(2);

  ///
  ///  The public key authorized to send admin messages to this node.
  @$pb.TagNumber(3)
  $pb.PbList<$core.List<$core.int>> get adminKey => $_getList(2);

  ///
  ///  If true, device is considered to be "managed" by a mesh administrator via admin messages
  ///  Device is managed by a mesh administrator.
  @$pb.TagNumber(4)
  $core.bool get isManaged => $_getBF(3);
  @$pb.TagNumber(4)
  set isManaged($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsManaged() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsManaged() => $_clearField(4);

  ///
  ///  Serial Console over the Stream API."
  @$pb.TagNumber(5)
  $core.bool get serialEnabled => $_getBF(4);
  @$pb.TagNumber(5)
  set serialEnabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSerialEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearSerialEnabled() => $_clearField(5);

  ///
  ///  By default we turn off logging as soon as an API client connects (to keep shared serial link quiet).
  ///  Output live debug logging over serial or bluetooth is set to true.
  @$pb.TagNumber(6)
  $core.bool get debugLogApiEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set debugLogApiEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDebugLogApiEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearDebugLogApiEnabled() => $_clearField(6);

  ///
  ///  Allow incoming device control over the insecure legacy admin channel.
  @$pb.TagNumber(8)
  $core.bool get adminChannelEnabled => $_getBF(6);
  @$pb.TagNumber(8)
  set adminChannelEnabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(8)
  $core.bool hasAdminChannelEnabled() => $_has(6);
  @$pb.TagNumber(8)
  void clearAdminChannelEnabled() => $_clearField(8);
}

///
///  Blank config request, strictly for getting the session key
class Config_SessionkeyConfig extends $pb.GeneratedMessage {
  factory Config_SessionkeyConfig() => create();

  Config_SessionkeyConfig._();

  factory Config_SessionkeyConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config_SessionkeyConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config.SessionkeyConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_SessionkeyConfig clone() =>
      Config_SessionkeyConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config_SessionkeyConfig copyWith(
          void Function(Config_SessionkeyConfig) updates) =>
      super.copyWith((message) => updates(message as Config_SessionkeyConfig))
          as Config_SessionkeyConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config_SessionkeyConfig create() => Config_SessionkeyConfig._();
  @$core.override
  Config_SessionkeyConfig createEmptyInstance() => create();
  static $pb.PbList<Config_SessionkeyConfig> createRepeated() =>
      $pb.PbList<Config_SessionkeyConfig>();
  @$core.pragma('dart2js:noInline')
  static Config_SessionkeyConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Config_SessionkeyConfig>(create);
  static Config_SessionkeyConfig? _defaultInstance;
}

enum Config_PayloadVariant {
  device,
  position,
  power,
  network,
  display,
  lora,
  bluetooth,
  security,
  sessionkey,
  deviceUi,
  notSet
}

class Config extends $pb.GeneratedMessage {
  factory Config({
    Config_DeviceConfig? device,
    Config_PositionConfig? position,
    Config_PowerConfig? power,
    Config_NetworkConfig? network,
    Config_DisplayConfig? display,
    Config_LoRaConfig? lora,
    Config_BluetoothConfig? bluetooth,
    Config_SecurityConfig? security,
    Config_SessionkeyConfig? sessionkey,
    $0.DeviceUIConfig? deviceUi,
  }) {
    final result = create();
    if (device != null) result.device = device;
    if (position != null) result.position = position;
    if (power != null) result.power = power;
    if (network != null) result.network = network;
    if (display != null) result.display = display;
    if (lora != null) result.lora = lora;
    if (bluetooth != null) result.bluetooth = bluetooth;
    if (security != null) result.security = security;
    if (sessionkey != null) result.sessionkey = sessionkey;
    if (deviceUi != null) result.deviceUi = deviceUi;
    return result;
  }

  Config._();

  factory Config.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Config_PayloadVariant>
      _Config_PayloadVariantByTag = {
    1: Config_PayloadVariant.device,
    2: Config_PayloadVariant.position,
    3: Config_PayloadVariant.power,
    4: Config_PayloadVariant.network,
    5: Config_PayloadVariant.display,
    6: Config_PayloadVariant.lora,
    7: Config_PayloadVariant.bluetooth,
    8: Config_PayloadVariant.security,
    9: Config_PayloadVariant.sessionkey,
    10: Config_PayloadVariant.deviceUi,
    0: Config_PayloadVariant.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    ..aOM<Config_DeviceConfig>(1, _omitFieldNames ? '' : 'device',
        subBuilder: Config_DeviceConfig.create)
    ..aOM<Config_PositionConfig>(2, _omitFieldNames ? '' : 'position',
        subBuilder: Config_PositionConfig.create)
    ..aOM<Config_PowerConfig>(3, _omitFieldNames ? '' : 'power',
        subBuilder: Config_PowerConfig.create)
    ..aOM<Config_NetworkConfig>(4, _omitFieldNames ? '' : 'network',
        subBuilder: Config_NetworkConfig.create)
    ..aOM<Config_DisplayConfig>(5, _omitFieldNames ? '' : 'display',
        subBuilder: Config_DisplayConfig.create)
    ..aOM<Config_LoRaConfig>(6, _omitFieldNames ? '' : 'lora',
        subBuilder: Config_LoRaConfig.create)
    ..aOM<Config_BluetoothConfig>(7, _omitFieldNames ? '' : 'bluetooth',
        subBuilder: Config_BluetoothConfig.create)
    ..aOM<Config_SecurityConfig>(8, _omitFieldNames ? '' : 'security',
        subBuilder: Config_SecurityConfig.create)
    ..aOM<Config_SessionkeyConfig>(9, _omitFieldNames ? '' : 'sessionkey',
        subBuilder: Config_SessionkeyConfig.create)
    ..aOM<$0.DeviceUIConfig>(10, _omitFieldNames ? '' : 'deviceUi',
        subBuilder: $0.DeviceUIConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config clone() => Config()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config copyWith(void Function(Config) updates) =>
      super.copyWith((message) => updates(message as Config)) as Config;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config create() => Config._();
  @$core.override
  Config createEmptyInstance() => create();
  static $pb.PbList<Config> createRepeated() => $pb.PbList<Config>();
  @$core.pragma('dart2js:noInline')
  static Config getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Config>(create);
  static Config? _defaultInstance;

  Config_PayloadVariant whichPayloadVariant() =>
      _Config_PayloadVariantByTag[$_whichOneof(0)]!;
  void clearPayloadVariant() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Config_DeviceConfig get device => $_getN(0);
  @$pb.TagNumber(1)
  set device(Config_DeviceConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  Config_DeviceConfig ensureDevice() => $_ensure(0);

  @$pb.TagNumber(2)
  Config_PositionConfig get position => $_getN(1);
  @$pb.TagNumber(2)
  set position(Config_PositionConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);
  @$pb.TagNumber(2)
  Config_PositionConfig ensurePosition() => $_ensure(1);

  @$pb.TagNumber(3)
  Config_PowerConfig get power => $_getN(2);
  @$pb.TagNumber(3)
  set power(Config_PowerConfig value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPower() => $_has(2);
  @$pb.TagNumber(3)
  void clearPower() => $_clearField(3);
  @$pb.TagNumber(3)
  Config_PowerConfig ensurePower() => $_ensure(2);

  @$pb.TagNumber(4)
  Config_NetworkConfig get network => $_getN(3);
  @$pb.TagNumber(4)
  set network(Config_NetworkConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNetwork() => $_has(3);
  @$pb.TagNumber(4)
  void clearNetwork() => $_clearField(4);
  @$pb.TagNumber(4)
  Config_NetworkConfig ensureNetwork() => $_ensure(3);

  @$pb.TagNumber(5)
  Config_DisplayConfig get display => $_getN(4);
  @$pb.TagNumber(5)
  set display(Config_DisplayConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplay() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplay() => $_clearField(5);
  @$pb.TagNumber(5)
  Config_DisplayConfig ensureDisplay() => $_ensure(4);

  @$pb.TagNumber(6)
  Config_LoRaConfig get lora => $_getN(5);
  @$pb.TagNumber(6)
  set lora(Config_LoRaConfig value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLora() => $_has(5);
  @$pb.TagNumber(6)
  void clearLora() => $_clearField(6);
  @$pb.TagNumber(6)
  Config_LoRaConfig ensureLora() => $_ensure(5);

  @$pb.TagNumber(7)
  Config_BluetoothConfig get bluetooth => $_getN(6);
  @$pb.TagNumber(7)
  set bluetooth(Config_BluetoothConfig value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasBluetooth() => $_has(6);
  @$pb.TagNumber(7)
  void clearBluetooth() => $_clearField(7);
  @$pb.TagNumber(7)
  Config_BluetoothConfig ensureBluetooth() => $_ensure(6);

  @$pb.TagNumber(8)
  Config_SecurityConfig get security => $_getN(7);
  @$pb.TagNumber(8)
  set security(Config_SecurityConfig value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSecurity() => $_has(7);
  @$pb.TagNumber(8)
  void clearSecurity() => $_clearField(8);
  @$pb.TagNumber(8)
  Config_SecurityConfig ensureSecurity() => $_ensure(7);

  @$pb.TagNumber(9)
  Config_SessionkeyConfig get sessionkey => $_getN(8);
  @$pb.TagNumber(9)
  set sessionkey(Config_SessionkeyConfig value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasSessionkey() => $_has(8);
  @$pb.TagNumber(9)
  void clearSessionkey() => $_clearField(9);
  @$pb.TagNumber(9)
  Config_SessionkeyConfig ensureSessionkey() => $_ensure(8);

  @$pb.TagNumber(10)
  $0.DeviceUIConfig get deviceUi => $_getN(9);
  @$pb.TagNumber(10)
  set deviceUi($0.DeviceUIConfig value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasDeviceUi() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeviceUi() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.DeviceUIConfig ensureDeviceUi() => $_ensure(9);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
