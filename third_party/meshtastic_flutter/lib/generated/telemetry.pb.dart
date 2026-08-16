// This is a generated file - do not edit.
//
// Generated from meshtastic/telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'telemetry.pbenum.dart';

///
///  Key native device metrics such as battery level
class DeviceMetrics extends $pb.GeneratedMessage {
  factory DeviceMetrics({
    $core.int? batteryLevel,
    $core.double? voltage,
    $core.double? channelUtilization,
    $core.double? airUtilTx,
    $core.int? uptimeSeconds,
  }) {
    final result = create();
    if (batteryLevel != null) result.batteryLevel = batteryLevel;
    if (voltage != null) result.voltage = voltage;
    if (channelUtilization != null)
      result.channelUtilization = channelUtilization;
    if (airUtilTx != null) result.airUtilTx = airUtilTx;
    if (uptimeSeconds != null) result.uptimeSeconds = uptimeSeconds;
    return result;
  }

  DeviceMetrics._();

  factory DeviceMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'batteryLevel', $pb.PbFieldType.OU3)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'channelUtilization', $pb.PbFieldType.OF)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'airUtilTx', $pb.PbFieldType.OF)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'uptimeSeconds', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceMetrics clone() => DeviceMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceMetrics copyWith(void Function(DeviceMetrics) updates) =>
      super.copyWith((message) => updates(message as DeviceMetrics))
          as DeviceMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceMetrics create() => DeviceMetrics._();
  @$core.override
  DeviceMetrics createEmptyInstance() => create();
  static $pb.PbList<DeviceMetrics> createRepeated() =>
      $pb.PbList<DeviceMetrics>();
  @$core.pragma('dart2js:noInline')
  static DeviceMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceMetrics>(create);
  static DeviceMetrics? _defaultInstance;

  ///
  ///  0-100 (>100 means powered)
  @$pb.TagNumber(1)
  $core.int get batteryLevel => $_getIZ(0);
  @$pb.TagNumber(1)
  set batteryLevel($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBatteryLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearBatteryLevel() => $_clearField(1);

  ///
  ///  Voltage measured
  @$pb.TagNumber(2)
  $core.double get voltage => $_getN(1);
  @$pb.TagNumber(2)
  set voltage($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVoltage() => $_has(1);
  @$pb.TagNumber(2)
  void clearVoltage() => $_clearField(2);

  ///
  ///  Utilization for the current channel, including well formed TX, RX and malformed RX (aka noise).
  @$pb.TagNumber(3)
  $core.double get channelUtilization => $_getN(2);
  @$pb.TagNumber(3)
  set channelUtilization($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannelUtilization() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannelUtilization() => $_clearField(3);

  ///
  ///  Percent of airtime for transmission used within the last hour.
  @$pb.TagNumber(4)
  $core.double get airUtilTx => $_getN(3);
  @$pb.TagNumber(4)
  set airUtilTx($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAirUtilTx() => $_has(3);
  @$pb.TagNumber(4)
  void clearAirUtilTx() => $_clearField(4);

  ///
  ///  How long the device has been running since the last reboot (in seconds)
  @$pb.TagNumber(5)
  $core.int get uptimeSeconds => $_getIZ(4);
  @$pb.TagNumber(5)
  set uptimeSeconds($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUptimeSeconds() => $_has(4);
  @$pb.TagNumber(5)
  void clearUptimeSeconds() => $_clearField(5);
}

///
///  Weather station or other environmental metrics
class EnvironmentMetrics extends $pb.GeneratedMessage {
  factory EnvironmentMetrics({
    $core.double? temperature,
    $core.double? relativeHumidity,
    $core.double? barometricPressure,
    $core.double? gasResistance,
    $core.double? voltage,
    $core.double? current,
    $core.int? iaq,
    $core.double? distance,
    $core.double? lux,
    $core.double? whiteLux,
    $core.double? irLux,
    $core.double? uvLux,
    $core.int? windDirection,
    $core.double? windSpeed,
    $core.double? weight,
    $core.double? windGust,
    $core.double? windLull,
    $core.double? radiation,
    $core.double? rainfall1h,
    $core.double? rainfall24h,
    $core.int? soilMoisture,
    $core.double? soilTemperature,
  }) {
    final result = create();
    if (temperature != null) result.temperature = temperature;
    if (relativeHumidity != null) result.relativeHumidity = relativeHumidity;
    if (barometricPressure != null)
      result.barometricPressure = barometricPressure;
    if (gasResistance != null) result.gasResistance = gasResistance;
    if (voltage != null) result.voltage = voltage;
    if (current != null) result.current = current;
    if (iaq != null) result.iaq = iaq;
    if (distance != null) result.distance = distance;
    if (lux != null) result.lux = lux;
    if (whiteLux != null) result.whiteLux = whiteLux;
    if (irLux != null) result.irLux = irLux;
    if (uvLux != null) result.uvLux = uvLux;
    if (windDirection != null) result.windDirection = windDirection;
    if (windSpeed != null) result.windSpeed = windSpeed;
    if (weight != null) result.weight = weight;
    if (windGust != null) result.windGust = windGust;
    if (windLull != null) result.windLull = windLull;
    if (radiation != null) result.radiation = radiation;
    if (rainfall1h != null) result.rainfall1h = rainfall1h;
    if (rainfall24h != null) result.rainfall24h = rainfall24h;
    if (soilMoisture != null) result.soilMoisture = soilMoisture;
    if (soilTemperature != null) result.soilTemperature = soilTemperature;
    return result;
  }

  EnvironmentMetrics._();

  factory EnvironmentMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnvironmentMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnvironmentMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.double>(
        1, _omitFieldNames ? '' : 'temperature', $pb.PbFieldType.OF)
    ..a<$core.double>(
        2, _omitFieldNames ? '' : 'relativeHumidity', $pb.PbFieldType.OF)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'barometricPressure', $pb.PbFieldType.OF)
    ..a<$core.double>(
        4, _omitFieldNames ? '' : 'gasResistance', $pb.PbFieldType.OF)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'current', $pb.PbFieldType.OF)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'iaq', $pb.PbFieldType.OU3)
    ..a<$core.double>(8, _omitFieldNames ? '' : 'distance', $pb.PbFieldType.OF)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'lux', $pb.PbFieldType.OF)
    ..a<$core.double>(10, _omitFieldNames ? '' : 'whiteLux', $pb.PbFieldType.OF)
    ..a<$core.double>(11, _omitFieldNames ? '' : 'irLux', $pb.PbFieldType.OF)
    ..a<$core.double>(12, _omitFieldNames ? '' : 'uvLux', $pb.PbFieldType.OF)
    ..a<$core.int>(
        13, _omitFieldNames ? '' : 'windDirection', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        14, _omitFieldNames ? '' : 'windSpeed', $pb.PbFieldType.OF)
    ..a<$core.double>(15, _omitFieldNames ? '' : 'weight', $pb.PbFieldType.OF)
    ..a<$core.double>(16, _omitFieldNames ? '' : 'windGust', $pb.PbFieldType.OF)
    ..a<$core.double>(17, _omitFieldNames ? '' : 'windLull', $pb.PbFieldType.OF)
    ..a<$core.double>(
        18, _omitFieldNames ? '' : 'radiation', $pb.PbFieldType.OF)
    ..a<$core.double>(
        19, _omitFieldNames ? '' : 'rainfall1h', $pb.PbFieldType.OF,
        protoName: 'rainfall_1h')
    ..a<$core.double>(
        20, _omitFieldNames ? '' : 'rainfall24h', $pb.PbFieldType.OF,
        protoName: 'rainfall_24h')
    ..a<$core.int>(
        21, _omitFieldNames ? '' : 'soilMoisture', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        22, _omitFieldNames ? '' : 'soilTemperature', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnvironmentMetrics clone() => EnvironmentMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnvironmentMetrics copyWith(void Function(EnvironmentMetrics) updates) =>
      super.copyWith((message) => updates(message as EnvironmentMetrics))
          as EnvironmentMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnvironmentMetrics create() => EnvironmentMetrics._();
  @$core.override
  EnvironmentMetrics createEmptyInstance() => create();
  static $pb.PbList<EnvironmentMetrics> createRepeated() =>
      $pb.PbList<EnvironmentMetrics>();
  @$core.pragma('dart2js:noInline')
  static EnvironmentMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnvironmentMetrics>(create);
  static EnvironmentMetrics? _defaultInstance;

  ///
  ///  Temperature measured
  @$pb.TagNumber(1)
  $core.double get temperature => $_getN(0);
  @$pb.TagNumber(1)
  set temperature($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTemperature() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemperature() => $_clearField(1);

  ///
  ///  Relative humidity percent measured
  @$pb.TagNumber(2)
  $core.double get relativeHumidity => $_getN(1);
  @$pb.TagNumber(2)
  set relativeHumidity($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRelativeHumidity() => $_has(1);
  @$pb.TagNumber(2)
  void clearRelativeHumidity() => $_clearField(2);

  ///
  ///  Barometric pressure in hPA measured
  @$pb.TagNumber(3)
  $core.double get barometricPressure => $_getN(2);
  @$pb.TagNumber(3)
  set barometricPressure($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBarometricPressure() => $_has(2);
  @$pb.TagNumber(3)
  void clearBarometricPressure() => $_clearField(3);

  ///
  ///  Gas resistance in MOhm measured
  @$pb.TagNumber(4)
  $core.double get gasResistance => $_getN(3);
  @$pb.TagNumber(4)
  set gasResistance($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGasResistance() => $_has(3);
  @$pb.TagNumber(4)
  void clearGasResistance() => $_clearField(4);

  ///
  ///  Voltage measured (To be depreciated in favor of PowerMetrics in Meshtastic 3.x)
  @$pb.TagNumber(5)
  $core.double get voltage => $_getN(4);
  @$pb.TagNumber(5)
  set voltage($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVoltage() => $_has(4);
  @$pb.TagNumber(5)
  void clearVoltage() => $_clearField(5);

  ///
  ///  Current measured (To be depreciated in favor of PowerMetrics in Meshtastic 3.x)
  @$pb.TagNumber(6)
  $core.double get current => $_getN(5);
  @$pb.TagNumber(6)
  set current($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrent() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrent() => $_clearField(6);

  ///
  ///  relative scale IAQ value as measured by Bosch BME680 . value 0-500.
  ///  Belongs to Air Quality but is not particle but VOC measurement. Other VOC values can also be put in here.
  @$pb.TagNumber(7)
  $core.int get iaq => $_getIZ(6);
  @$pb.TagNumber(7)
  set iaq($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIaq() => $_has(6);
  @$pb.TagNumber(7)
  void clearIaq() => $_clearField(7);

  ///
  ///  RCWL9620 Doppler Radar Distance Sensor, used for water level detection. Float value in mm.
  @$pb.TagNumber(8)
  $core.double get distance => $_getN(7);
  @$pb.TagNumber(8)
  set distance($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDistance() => $_has(7);
  @$pb.TagNumber(8)
  void clearDistance() => $_clearField(8);

  ///
  ///  VEML7700 high accuracy ambient light(Lux) digital 16-bit resolution sensor.
  @$pb.TagNumber(9)
  $core.double get lux => $_getN(8);
  @$pb.TagNumber(9)
  set lux($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLux() => $_has(8);
  @$pb.TagNumber(9)
  void clearLux() => $_clearField(9);

  ///
  ///  VEML7700 high accuracy white light(irradiance) not calibrated digital 16-bit resolution sensor.
  @$pb.TagNumber(10)
  $core.double get whiteLux => $_getN(9);
  @$pb.TagNumber(10)
  set whiteLux($core.double value) => $_setFloat(9, value);
  @$pb.TagNumber(10)
  $core.bool hasWhiteLux() => $_has(9);
  @$pb.TagNumber(10)
  void clearWhiteLux() => $_clearField(10);

  ///
  ///  Infrared lux
  @$pb.TagNumber(11)
  $core.double get irLux => $_getN(10);
  @$pb.TagNumber(11)
  set irLux($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIrLux() => $_has(10);
  @$pb.TagNumber(11)
  void clearIrLux() => $_clearField(11);

  ///
  ///  Ultraviolet lux
  @$pb.TagNumber(12)
  $core.double get uvLux => $_getN(11);
  @$pb.TagNumber(12)
  set uvLux($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUvLux() => $_has(11);
  @$pb.TagNumber(12)
  void clearUvLux() => $_clearField(12);

  ///
  ///  Wind direction in degrees
  ///  0 degrees = North, 90 = East, etc...
  @$pb.TagNumber(13)
  $core.int get windDirection => $_getIZ(12);
  @$pb.TagNumber(13)
  set windDirection($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasWindDirection() => $_has(12);
  @$pb.TagNumber(13)
  void clearWindDirection() => $_clearField(13);

  ///
  ///  Wind speed in m/s
  @$pb.TagNumber(14)
  $core.double get windSpeed => $_getN(13);
  @$pb.TagNumber(14)
  set windSpeed($core.double value) => $_setFloat(13, value);
  @$pb.TagNumber(14)
  $core.bool hasWindSpeed() => $_has(13);
  @$pb.TagNumber(14)
  void clearWindSpeed() => $_clearField(14);

  ///
  ///  Weight in KG
  @$pb.TagNumber(15)
  $core.double get weight => $_getN(14);
  @$pb.TagNumber(15)
  set weight($core.double value) => $_setFloat(14, value);
  @$pb.TagNumber(15)
  $core.bool hasWeight() => $_has(14);
  @$pb.TagNumber(15)
  void clearWeight() => $_clearField(15);

  ///
  ///  Wind gust in m/s
  @$pb.TagNumber(16)
  $core.double get windGust => $_getN(15);
  @$pb.TagNumber(16)
  set windGust($core.double value) => $_setFloat(15, value);
  @$pb.TagNumber(16)
  $core.bool hasWindGust() => $_has(15);
  @$pb.TagNumber(16)
  void clearWindGust() => $_clearField(16);

  ///
  ///  Wind lull in m/s
  @$pb.TagNumber(17)
  $core.double get windLull => $_getN(16);
  @$pb.TagNumber(17)
  set windLull($core.double value) => $_setFloat(16, value);
  @$pb.TagNumber(17)
  $core.bool hasWindLull() => $_has(16);
  @$pb.TagNumber(17)
  void clearWindLull() => $_clearField(17);

  ///
  ///  Radiation in µR/h
  @$pb.TagNumber(18)
  $core.double get radiation => $_getN(17);
  @$pb.TagNumber(18)
  set radiation($core.double value) => $_setFloat(17, value);
  @$pb.TagNumber(18)
  $core.bool hasRadiation() => $_has(17);
  @$pb.TagNumber(18)
  void clearRadiation() => $_clearField(18);

  ///
  ///  Rainfall in the last hour in mm
  @$pb.TagNumber(19)
  $core.double get rainfall1h => $_getN(18);
  @$pb.TagNumber(19)
  set rainfall1h($core.double value) => $_setFloat(18, value);
  @$pb.TagNumber(19)
  $core.bool hasRainfall1h() => $_has(18);
  @$pb.TagNumber(19)
  void clearRainfall1h() => $_clearField(19);

  ///
  ///  Rainfall in the last 24 hours in mm
  @$pb.TagNumber(20)
  $core.double get rainfall24h => $_getN(19);
  @$pb.TagNumber(20)
  set rainfall24h($core.double value) => $_setFloat(19, value);
  @$pb.TagNumber(20)
  $core.bool hasRainfall24h() => $_has(19);
  @$pb.TagNumber(20)
  void clearRainfall24h() => $_clearField(20);

  ///
  ///  Soil moisture measured (% 1-100)
  @$pb.TagNumber(21)
  $core.int get soilMoisture => $_getIZ(20);
  @$pb.TagNumber(21)
  set soilMoisture($core.int value) => $_setUnsignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasSoilMoisture() => $_has(20);
  @$pb.TagNumber(21)
  void clearSoilMoisture() => $_clearField(21);

  ///
  ///  Soil temperature measured (*C)
  @$pb.TagNumber(22)
  $core.double get soilTemperature => $_getN(21);
  @$pb.TagNumber(22)
  set soilTemperature($core.double value) => $_setFloat(21, value);
  @$pb.TagNumber(22)
  $core.bool hasSoilTemperature() => $_has(21);
  @$pb.TagNumber(22)
  void clearSoilTemperature() => $_clearField(22);
}

///
///  Power Metrics (voltage / current / etc)
class PowerMetrics extends $pb.GeneratedMessage {
  factory PowerMetrics({
    $core.double? ch1Voltage,
    $core.double? ch1Current,
    $core.double? ch2Voltage,
    $core.double? ch2Current,
    $core.double? ch3Voltage,
    $core.double? ch3Current,
    $core.double? ch4Voltage,
    $core.double? ch4Current,
    $core.double? ch5Voltage,
    $core.double? ch5Current,
    $core.double? ch6Voltage,
    $core.double? ch6Current,
    $core.double? ch7Voltage,
    $core.double? ch7Current,
    $core.double? ch8Voltage,
    $core.double? ch8Current,
  }) {
    final result = create();
    if (ch1Voltage != null) result.ch1Voltage = ch1Voltage;
    if (ch1Current != null) result.ch1Current = ch1Current;
    if (ch2Voltage != null) result.ch2Voltage = ch2Voltage;
    if (ch2Current != null) result.ch2Current = ch2Current;
    if (ch3Voltage != null) result.ch3Voltage = ch3Voltage;
    if (ch3Current != null) result.ch3Current = ch3Current;
    if (ch4Voltage != null) result.ch4Voltage = ch4Voltage;
    if (ch4Current != null) result.ch4Current = ch4Current;
    if (ch5Voltage != null) result.ch5Voltage = ch5Voltage;
    if (ch5Current != null) result.ch5Current = ch5Current;
    if (ch6Voltage != null) result.ch6Voltage = ch6Voltage;
    if (ch6Current != null) result.ch6Current = ch6Current;
    if (ch7Voltage != null) result.ch7Voltage = ch7Voltage;
    if (ch7Current != null) result.ch7Current = ch7Current;
    if (ch8Voltage != null) result.ch8Voltage = ch8Voltage;
    if (ch8Current != null) result.ch8Current = ch8Current;
    return result;
  }

  PowerMetrics._();

  factory PowerMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PowerMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PowerMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.double>(
        1, _omitFieldNames ? '' : 'ch1Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        2, _omitFieldNames ? '' : 'ch1Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'ch2Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        4, _omitFieldNames ? '' : 'ch2Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        5, _omitFieldNames ? '' : 'ch3Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        6, _omitFieldNames ? '' : 'ch3Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        7, _omitFieldNames ? '' : 'ch4Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        8, _omitFieldNames ? '' : 'ch4Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        9, _omitFieldNames ? '' : 'ch5Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        10, _omitFieldNames ? '' : 'ch5Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        11, _omitFieldNames ? '' : 'ch6Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        12, _omitFieldNames ? '' : 'ch6Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        13, _omitFieldNames ? '' : 'ch7Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        14, _omitFieldNames ? '' : 'ch7Current', $pb.PbFieldType.OF)
    ..a<$core.double>(
        15, _omitFieldNames ? '' : 'ch8Voltage', $pb.PbFieldType.OF)
    ..a<$core.double>(
        16, _omitFieldNames ? '' : 'ch8Current', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerMetrics clone() => PowerMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerMetrics copyWith(void Function(PowerMetrics) updates) =>
      super.copyWith((message) => updates(message as PowerMetrics))
          as PowerMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PowerMetrics create() => PowerMetrics._();
  @$core.override
  PowerMetrics createEmptyInstance() => create();
  static $pb.PbList<PowerMetrics> createRepeated() =>
      $pb.PbList<PowerMetrics>();
  @$core.pragma('dart2js:noInline')
  static PowerMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PowerMetrics>(create);
  static PowerMetrics? _defaultInstance;

  ///
  ///  Voltage (Ch1)
  @$pb.TagNumber(1)
  $core.double get ch1Voltage => $_getN(0);
  @$pb.TagNumber(1)
  set ch1Voltage($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCh1Voltage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCh1Voltage() => $_clearField(1);

  ///
  ///  Current (Ch1)
  @$pb.TagNumber(2)
  $core.double get ch1Current => $_getN(1);
  @$pb.TagNumber(2)
  set ch1Current($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCh1Current() => $_has(1);
  @$pb.TagNumber(2)
  void clearCh1Current() => $_clearField(2);

  ///
  ///  Voltage (Ch2)
  @$pb.TagNumber(3)
  $core.double get ch2Voltage => $_getN(2);
  @$pb.TagNumber(3)
  set ch2Voltage($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCh2Voltage() => $_has(2);
  @$pb.TagNumber(3)
  void clearCh2Voltage() => $_clearField(3);

  ///
  ///  Current (Ch2)
  @$pb.TagNumber(4)
  $core.double get ch2Current => $_getN(3);
  @$pb.TagNumber(4)
  set ch2Current($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCh2Current() => $_has(3);
  @$pb.TagNumber(4)
  void clearCh2Current() => $_clearField(4);

  ///
  ///  Voltage (Ch3)
  @$pb.TagNumber(5)
  $core.double get ch3Voltage => $_getN(4);
  @$pb.TagNumber(5)
  set ch3Voltage($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCh3Voltage() => $_has(4);
  @$pb.TagNumber(5)
  void clearCh3Voltage() => $_clearField(5);

  ///
  ///  Current (Ch3)
  @$pb.TagNumber(6)
  $core.double get ch3Current => $_getN(5);
  @$pb.TagNumber(6)
  set ch3Current($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCh3Current() => $_has(5);
  @$pb.TagNumber(6)
  void clearCh3Current() => $_clearField(6);

  ///
  ///  Voltage (Ch4)
  @$pb.TagNumber(7)
  $core.double get ch4Voltage => $_getN(6);
  @$pb.TagNumber(7)
  set ch4Voltage($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCh4Voltage() => $_has(6);
  @$pb.TagNumber(7)
  void clearCh4Voltage() => $_clearField(7);

  ///
  ///  Current (Ch4)
  @$pb.TagNumber(8)
  $core.double get ch4Current => $_getN(7);
  @$pb.TagNumber(8)
  set ch4Current($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCh4Current() => $_has(7);
  @$pb.TagNumber(8)
  void clearCh4Current() => $_clearField(8);

  ///
  ///  Voltage (Ch5)
  @$pb.TagNumber(9)
  $core.double get ch5Voltage => $_getN(8);
  @$pb.TagNumber(9)
  set ch5Voltage($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCh5Voltage() => $_has(8);
  @$pb.TagNumber(9)
  void clearCh5Voltage() => $_clearField(9);

  ///
  ///  Current (Ch5)
  @$pb.TagNumber(10)
  $core.double get ch5Current => $_getN(9);
  @$pb.TagNumber(10)
  set ch5Current($core.double value) => $_setFloat(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCh5Current() => $_has(9);
  @$pb.TagNumber(10)
  void clearCh5Current() => $_clearField(10);

  ///
  ///  Voltage (Ch6)
  @$pb.TagNumber(11)
  $core.double get ch6Voltage => $_getN(10);
  @$pb.TagNumber(11)
  set ch6Voltage($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCh6Voltage() => $_has(10);
  @$pb.TagNumber(11)
  void clearCh6Voltage() => $_clearField(11);

  ///
  ///  Current (Ch6)
  @$pb.TagNumber(12)
  $core.double get ch6Current => $_getN(11);
  @$pb.TagNumber(12)
  set ch6Current($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCh6Current() => $_has(11);
  @$pb.TagNumber(12)
  void clearCh6Current() => $_clearField(12);

  ///
  ///  Voltage (Ch7)
  @$pb.TagNumber(13)
  $core.double get ch7Voltage => $_getN(12);
  @$pb.TagNumber(13)
  set ch7Voltage($core.double value) => $_setFloat(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCh7Voltage() => $_has(12);
  @$pb.TagNumber(13)
  void clearCh7Voltage() => $_clearField(13);

  ///
  ///  Current (Ch7)
  @$pb.TagNumber(14)
  $core.double get ch7Current => $_getN(13);
  @$pb.TagNumber(14)
  set ch7Current($core.double value) => $_setFloat(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCh7Current() => $_has(13);
  @$pb.TagNumber(14)
  void clearCh7Current() => $_clearField(14);

  ///
  ///  Voltage (Ch8)
  @$pb.TagNumber(15)
  $core.double get ch8Voltage => $_getN(14);
  @$pb.TagNumber(15)
  set ch8Voltage($core.double value) => $_setFloat(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCh8Voltage() => $_has(14);
  @$pb.TagNumber(15)
  void clearCh8Voltage() => $_clearField(15);

  ///
  ///  Current (Ch8)
  @$pb.TagNumber(16)
  $core.double get ch8Current => $_getN(15);
  @$pb.TagNumber(16)
  set ch8Current($core.double value) => $_setFloat(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCh8Current() => $_has(15);
  @$pb.TagNumber(16)
  void clearCh8Current() => $_clearField(16);
}

///
///  Air quality metrics
class AirQualityMetrics extends $pb.GeneratedMessage {
  factory AirQualityMetrics({
    $core.int? pm10Standard,
    $core.int? pm25Standard,
    $core.int? pm100Standard,
    $core.int? pm10Environmental,
    $core.int? pm25Environmental,
    $core.int? pm100Environmental,
    $core.int? particles03um,
    $core.int? particles05um,
    $core.int? particles10um,
    $core.int? particles25um,
    $core.int? particles50um,
    $core.int? particles100um,
    $core.int? co2,
    $core.double? co2Temperature,
    $core.double? co2Humidity,
    $core.double? formFormaldehyde,
    $core.double? formHumidity,
    $core.double? formTemperature,
    $core.int? pm40Standard,
    $core.int? particles40um,
    $core.double? pmTemperature,
    $core.double? pmHumidity,
    $core.double? pmVocIdx,
    $core.double? pmNoxIdx,
    $core.double? particlesTps,
  }) {
    final result = create();
    if (pm10Standard != null) result.pm10Standard = pm10Standard;
    if (pm25Standard != null) result.pm25Standard = pm25Standard;
    if (pm100Standard != null) result.pm100Standard = pm100Standard;
    if (pm10Environmental != null) result.pm10Environmental = pm10Environmental;
    if (pm25Environmental != null) result.pm25Environmental = pm25Environmental;
    if (pm100Environmental != null)
      result.pm100Environmental = pm100Environmental;
    if (particles03um != null) result.particles03um = particles03um;
    if (particles05um != null) result.particles05um = particles05um;
    if (particles10um != null) result.particles10um = particles10um;
    if (particles25um != null) result.particles25um = particles25um;
    if (particles50um != null) result.particles50um = particles50um;
    if (particles100um != null) result.particles100um = particles100um;
    if (co2 != null) result.co2 = co2;
    if (co2Temperature != null) result.co2Temperature = co2Temperature;
    if (co2Humidity != null) result.co2Humidity = co2Humidity;
    if (formFormaldehyde != null) result.formFormaldehyde = formFormaldehyde;
    if (formHumidity != null) result.formHumidity = formHumidity;
    if (formTemperature != null) result.formTemperature = formTemperature;
    if (pm40Standard != null) result.pm40Standard = pm40Standard;
    if (particles40um != null) result.particles40um = particles40um;
    if (pmTemperature != null) result.pmTemperature = pmTemperature;
    if (pmHumidity != null) result.pmHumidity = pmHumidity;
    if (pmVocIdx != null) result.pmVocIdx = pmVocIdx;
    if (pmNoxIdx != null) result.pmNoxIdx = pmNoxIdx;
    if (particlesTps != null) result.particlesTps = particlesTps;
    return result;
  }

  AirQualityMetrics._();

  factory AirQualityMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AirQualityMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AirQualityMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'pm10Standard', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'pm25Standard', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'pm100Standard', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'pm10Environmental', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'pm25Environmental', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'pm100Environmental', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'particles03um', $pb.PbFieldType.OU3,
        protoName: 'particles_03um')
    ..a<$core.int>(
        8, _omitFieldNames ? '' : 'particles05um', $pb.PbFieldType.OU3,
        protoName: 'particles_05um')
    ..a<$core.int>(
        9, _omitFieldNames ? '' : 'particles10um', $pb.PbFieldType.OU3,
        protoName: 'particles_10um')
    ..a<$core.int>(
        10, _omitFieldNames ? '' : 'particles25um', $pb.PbFieldType.OU3,
        protoName: 'particles_25um')
    ..a<$core.int>(
        11, _omitFieldNames ? '' : 'particles50um', $pb.PbFieldType.OU3,
        protoName: 'particles_50um')
    ..a<$core.int>(
        12, _omitFieldNames ? '' : 'particles100um', $pb.PbFieldType.OU3,
        protoName: 'particles_100um')
    ..a<$core.int>(13, _omitFieldNames ? '' : 'co2', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        14, _omitFieldNames ? '' : 'co2Temperature', $pb.PbFieldType.OF)
    ..a<$core.double>(
        15, _omitFieldNames ? '' : 'co2Humidity', $pb.PbFieldType.OF)
    ..a<$core.double>(
        16, _omitFieldNames ? '' : 'formFormaldehyde', $pb.PbFieldType.OF)
    ..a<$core.double>(
        17, _omitFieldNames ? '' : 'formHumidity', $pb.PbFieldType.OF)
    ..a<$core.double>(
        18, _omitFieldNames ? '' : 'formTemperature', $pb.PbFieldType.OF)
    ..a<$core.int>(
        19, _omitFieldNames ? '' : 'pm40Standard', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        20, _omitFieldNames ? '' : 'particles40um', $pb.PbFieldType.OU3,
        protoName: 'particles_40um')
    ..a<$core.double>(
        21, _omitFieldNames ? '' : 'pmTemperature', $pb.PbFieldType.OF)
    ..a<$core.double>(
        22, _omitFieldNames ? '' : 'pmHumidity', $pb.PbFieldType.OF)
    ..a<$core.double>(23, _omitFieldNames ? '' : 'pmVocIdx', $pb.PbFieldType.OF)
    ..a<$core.double>(24, _omitFieldNames ? '' : 'pmNoxIdx', $pb.PbFieldType.OF)
    ..a<$core.double>(
        25, _omitFieldNames ? '' : 'particlesTps', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AirQualityMetrics clone() => AirQualityMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AirQualityMetrics copyWith(void Function(AirQualityMetrics) updates) =>
      super.copyWith((message) => updates(message as AirQualityMetrics))
          as AirQualityMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AirQualityMetrics create() => AirQualityMetrics._();
  @$core.override
  AirQualityMetrics createEmptyInstance() => create();
  static $pb.PbList<AirQualityMetrics> createRepeated() =>
      $pb.PbList<AirQualityMetrics>();
  @$core.pragma('dart2js:noInline')
  static AirQualityMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AirQualityMetrics>(create);
  static AirQualityMetrics? _defaultInstance;

  ///
  ///  Concentration Units Standard PM1.0 in ug/m3
  @$pb.TagNumber(1)
  $core.int get pm10Standard => $_getIZ(0);
  @$pb.TagNumber(1)
  set pm10Standard($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPm10Standard() => $_has(0);
  @$pb.TagNumber(1)
  void clearPm10Standard() => $_clearField(1);

  ///
  ///  Concentration Units Standard PM2.5 in ug/m3
  @$pb.TagNumber(2)
  $core.int get pm25Standard => $_getIZ(1);
  @$pb.TagNumber(2)
  set pm25Standard($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPm25Standard() => $_has(1);
  @$pb.TagNumber(2)
  void clearPm25Standard() => $_clearField(2);

  ///
  ///  Concentration Units Standard PM10.0 in ug/m3
  @$pb.TagNumber(3)
  $core.int get pm100Standard => $_getIZ(2);
  @$pb.TagNumber(3)
  set pm100Standard($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPm100Standard() => $_has(2);
  @$pb.TagNumber(3)
  void clearPm100Standard() => $_clearField(3);

  ///
  ///  Concentration Units Environmental PM1.0 in ug/m3
  @$pb.TagNumber(4)
  $core.int get pm10Environmental => $_getIZ(3);
  @$pb.TagNumber(4)
  set pm10Environmental($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPm10Environmental() => $_has(3);
  @$pb.TagNumber(4)
  void clearPm10Environmental() => $_clearField(4);

  ///
  ///  Concentration Units Environmental PM2.5 in ug/m3
  @$pb.TagNumber(5)
  $core.int get pm25Environmental => $_getIZ(4);
  @$pb.TagNumber(5)
  set pm25Environmental($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPm25Environmental() => $_has(4);
  @$pb.TagNumber(5)
  void clearPm25Environmental() => $_clearField(5);

  ///
  ///  Concentration Units Environmental PM10.0 in ug/m3
  @$pb.TagNumber(6)
  $core.int get pm100Environmental => $_getIZ(5);
  @$pb.TagNumber(6)
  set pm100Environmental($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPm100Environmental() => $_has(5);
  @$pb.TagNumber(6)
  void clearPm100Environmental() => $_clearField(6);

  ///
  ///  0.3um Particle Count in #/0.1l
  @$pb.TagNumber(7)
  $core.int get particles03um => $_getIZ(6);
  @$pb.TagNumber(7)
  set particles03um($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasParticles03um() => $_has(6);
  @$pb.TagNumber(7)
  void clearParticles03um() => $_clearField(7);

  ///
  ///  0.5um Particle Count in #/0.1l
  @$pb.TagNumber(8)
  $core.int get particles05um => $_getIZ(7);
  @$pb.TagNumber(8)
  set particles05um($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasParticles05um() => $_has(7);
  @$pb.TagNumber(8)
  void clearParticles05um() => $_clearField(8);

  ///
  ///  1.0um Particle Count in #/0.1l
  @$pb.TagNumber(9)
  $core.int get particles10um => $_getIZ(8);
  @$pb.TagNumber(9)
  set particles10um($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasParticles10um() => $_has(8);
  @$pb.TagNumber(9)
  void clearParticles10um() => $_clearField(9);

  ///
  ///  2.5um Particle Count in #/0.1l
  @$pb.TagNumber(10)
  $core.int get particles25um => $_getIZ(9);
  @$pb.TagNumber(10)
  set particles25um($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasParticles25um() => $_has(9);
  @$pb.TagNumber(10)
  void clearParticles25um() => $_clearField(10);

  ///
  ///  5.0um Particle Count in #/0.1l
  @$pb.TagNumber(11)
  $core.int get particles50um => $_getIZ(10);
  @$pb.TagNumber(11)
  set particles50um($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasParticles50um() => $_has(10);
  @$pb.TagNumber(11)
  void clearParticles50um() => $_clearField(11);

  ///
  ///  10.0um Particle Count in #/0.1l
  @$pb.TagNumber(12)
  $core.int get particles100um => $_getIZ(11);
  @$pb.TagNumber(12)
  set particles100um($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasParticles100um() => $_has(11);
  @$pb.TagNumber(12)
  void clearParticles100um() => $_clearField(12);

  ///
  ///  CO2 concentration in ppm
  @$pb.TagNumber(13)
  $core.int get co2 => $_getIZ(12);
  @$pb.TagNumber(13)
  set co2($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCo2() => $_has(12);
  @$pb.TagNumber(13)
  void clearCo2() => $_clearField(13);

  ///
  ///  CO2 sensor temperature in degC
  @$pb.TagNumber(14)
  $core.double get co2Temperature => $_getN(13);
  @$pb.TagNumber(14)
  set co2Temperature($core.double value) => $_setFloat(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCo2Temperature() => $_has(13);
  @$pb.TagNumber(14)
  void clearCo2Temperature() => $_clearField(14);

  ///
  ///  CO2 sensor relative humidity in %
  @$pb.TagNumber(15)
  $core.double get co2Humidity => $_getN(14);
  @$pb.TagNumber(15)
  set co2Humidity($core.double value) => $_setFloat(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCo2Humidity() => $_has(14);
  @$pb.TagNumber(15)
  void clearCo2Humidity() => $_clearField(15);

  ///
  ///  Formaldehyde sensor formaldehyde concentration in ppb
  @$pb.TagNumber(16)
  $core.double get formFormaldehyde => $_getN(15);
  @$pb.TagNumber(16)
  set formFormaldehyde($core.double value) => $_setFloat(15, value);
  @$pb.TagNumber(16)
  $core.bool hasFormFormaldehyde() => $_has(15);
  @$pb.TagNumber(16)
  void clearFormFormaldehyde() => $_clearField(16);

  ///
  ///  Formaldehyde sensor relative humidity in %RH
  @$pb.TagNumber(17)
  $core.double get formHumidity => $_getN(16);
  @$pb.TagNumber(17)
  set formHumidity($core.double value) => $_setFloat(16, value);
  @$pb.TagNumber(17)
  $core.bool hasFormHumidity() => $_has(16);
  @$pb.TagNumber(17)
  void clearFormHumidity() => $_clearField(17);

  ///
  ///  Formaldehyde sensor temperature in degrees Celsius
  @$pb.TagNumber(18)
  $core.double get formTemperature => $_getN(17);
  @$pb.TagNumber(18)
  set formTemperature($core.double value) => $_setFloat(17, value);
  @$pb.TagNumber(18)
  $core.bool hasFormTemperature() => $_has(17);
  @$pb.TagNumber(18)
  void clearFormTemperature() => $_clearField(18);

  ///
  ///  Concentration Units Standard PM4.0 in ug/m3
  @$pb.TagNumber(19)
  $core.int get pm40Standard => $_getIZ(18);
  @$pb.TagNumber(19)
  set pm40Standard($core.int value) => $_setUnsignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPm40Standard() => $_has(18);
  @$pb.TagNumber(19)
  void clearPm40Standard() => $_clearField(19);

  ///
  ///  4.0um Particle Count in #/0.1l
  @$pb.TagNumber(20)
  $core.int get particles40um => $_getIZ(19);
  @$pb.TagNumber(20)
  set particles40um($core.int value) => $_setUnsignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasParticles40um() => $_has(19);
  @$pb.TagNumber(20)
  void clearParticles40um() => $_clearField(20);

  ///
  ///  PM Sensor Temperature
  @$pb.TagNumber(21)
  $core.double get pmTemperature => $_getN(20);
  @$pb.TagNumber(21)
  set pmTemperature($core.double value) => $_setFloat(20, value);
  @$pb.TagNumber(21)
  $core.bool hasPmTemperature() => $_has(20);
  @$pb.TagNumber(21)
  void clearPmTemperature() => $_clearField(21);

  ///
  ///  PM Sensor humidity
  @$pb.TagNumber(22)
  $core.double get pmHumidity => $_getN(21);
  @$pb.TagNumber(22)
  set pmHumidity($core.double value) => $_setFloat(21, value);
  @$pb.TagNumber(22)
  $core.bool hasPmHumidity() => $_has(21);
  @$pb.TagNumber(22)
  void clearPmHumidity() => $_clearField(22);

  ///
  ///  PM Sensor VOC Index
  @$pb.TagNumber(23)
  $core.double get pmVocIdx => $_getN(22);
  @$pb.TagNumber(23)
  set pmVocIdx($core.double value) => $_setFloat(22, value);
  @$pb.TagNumber(23)
  $core.bool hasPmVocIdx() => $_has(22);
  @$pb.TagNumber(23)
  void clearPmVocIdx() => $_clearField(23);

  ///
  ///  PM Sensor NOx Index
  @$pb.TagNumber(24)
  $core.double get pmNoxIdx => $_getN(23);
  @$pb.TagNumber(24)
  set pmNoxIdx($core.double value) => $_setFloat(23, value);
  @$pb.TagNumber(24)
  $core.bool hasPmNoxIdx() => $_has(23);
  @$pb.TagNumber(24)
  void clearPmNoxIdx() => $_clearField(24);

  ///
  ///  Typical Particle Size in um
  @$pb.TagNumber(25)
  $core.double get particlesTps => $_getN(24);
  @$pb.TagNumber(25)
  set particlesTps($core.double value) => $_setFloat(24, value);
  @$pb.TagNumber(25)
  $core.bool hasParticlesTps() => $_has(24);
  @$pb.TagNumber(25)
  void clearParticlesTps() => $_clearField(25);
}

///
///  Local device mesh statistics
class LocalStats extends $pb.GeneratedMessage {
  factory LocalStats({
    $core.int? uptimeSeconds,
    $core.double? channelUtilization,
    $core.double? airUtilTx,
    $core.int? numPacketsTx,
    $core.int? numPacketsRx,
    $core.int? numPacketsRxBad,
    $core.int? numOnlineNodes,
    $core.int? numTotalNodes,
    $core.int? numRxDupe,
    $core.int? numTxRelay,
    $core.int? numTxRelayCanceled,
    $core.int? heapTotalBytes,
    $core.int? heapFreeBytes,
  }) {
    final result = create();
    if (uptimeSeconds != null) result.uptimeSeconds = uptimeSeconds;
    if (channelUtilization != null)
      result.channelUtilization = channelUtilization;
    if (airUtilTx != null) result.airUtilTx = airUtilTx;
    if (numPacketsTx != null) result.numPacketsTx = numPacketsTx;
    if (numPacketsRx != null) result.numPacketsRx = numPacketsRx;
    if (numPacketsRxBad != null) result.numPacketsRxBad = numPacketsRxBad;
    if (numOnlineNodes != null) result.numOnlineNodes = numOnlineNodes;
    if (numTotalNodes != null) result.numTotalNodes = numTotalNodes;
    if (numRxDupe != null) result.numRxDupe = numRxDupe;
    if (numTxRelay != null) result.numTxRelay = numTxRelay;
    if (numTxRelayCanceled != null)
      result.numTxRelayCanceled = numTxRelayCanceled;
    if (heapTotalBytes != null) result.heapTotalBytes = heapTotalBytes;
    if (heapFreeBytes != null) result.heapFreeBytes = heapFreeBytes;
    return result;
  }

  LocalStats._();

  factory LocalStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocalStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'uptimeSeconds', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        2, _omitFieldNames ? '' : 'channelUtilization', $pb.PbFieldType.OF)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'airUtilTx', $pb.PbFieldType.OF)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'numPacketsTx', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'numPacketsRx', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'numPacketsRxBad', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'numOnlineNodes', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        8, _omitFieldNames ? '' : 'numTotalNodes', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'numRxDupe', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'numTxRelay', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        11, _omitFieldNames ? '' : 'numTxRelayCanceled', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        12, _omitFieldNames ? '' : 'heapTotalBytes', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        13, _omitFieldNames ? '' : 'heapFreeBytes', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalStats clone() => LocalStats()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalStats copyWith(void Function(LocalStats) updates) =>
      super.copyWith((message) => updates(message as LocalStats)) as LocalStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalStats create() => LocalStats._();
  @$core.override
  LocalStats createEmptyInstance() => create();
  static $pb.PbList<LocalStats> createRepeated() => $pb.PbList<LocalStats>();
  @$core.pragma('dart2js:noInline')
  static LocalStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalStats>(create);
  static LocalStats? _defaultInstance;

  ///
  ///  How long the device has been running since the last reboot (in seconds)
  @$pb.TagNumber(1)
  $core.int get uptimeSeconds => $_getIZ(0);
  @$pb.TagNumber(1)
  set uptimeSeconds($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUptimeSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearUptimeSeconds() => $_clearField(1);

  ///
  ///  Utilization for the current channel, including well formed TX, RX and malformed RX (aka noise).
  @$pb.TagNumber(2)
  $core.double get channelUtilization => $_getN(1);
  @$pb.TagNumber(2)
  set channelUtilization($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelUtilization() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelUtilization() => $_clearField(2);

  ///
  ///  Percent of airtime for transmission used within the last hour.
  @$pb.TagNumber(3)
  $core.double get airUtilTx => $_getN(2);
  @$pb.TagNumber(3)
  set airUtilTx($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAirUtilTx() => $_has(2);
  @$pb.TagNumber(3)
  void clearAirUtilTx() => $_clearField(3);

  ///
  ///  Number of packets sent
  @$pb.TagNumber(4)
  $core.int get numPacketsTx => $_getIZ(3);
  @$pb.TagNumber(4)
  set numPacketsTx($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNumPacketsTx() => $_has(3);
  @$pb.TagNumber(4)
  void clearNumPacketsTx() => $_clearField(4);

  ///
  ///  Number of packets received (both good and bad)
  @$pb.TagNumber(5)
  $core.int get numPacketsRx => $_getIZ(4);
  @$pb.TagNumber(5)
  set numPacketsRx($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNumPacketsRx() => $_has(4);
  @$pb.TagNumber(5)
  void clearNumPacketsRx() => $_clearField(5);

  ///
  ///  Number of packets received that are malformed or violate the protocol
  @$pb.TagNumber(6)
  $core.int get numPacketsRxBad => $_getIZ(5);
  @$pb.TagNumber(6)
  set numPacketsRxBad($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNumPacketsRxBad() => $_has(5);
  @$pb.TagNumber(6)
  void clearNumPacketsRxBad() => $_clearField(6);

  ///
  ///  Number of nodes online (in the past 2 hours)
  @$pb.TagNumber(7)
  $core.int get numOnlineNodes => $_getIZ(6);
  @$pb.TagNumber(7)
  set numOnlineNodes($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNumOnlineNodes() => $_has(6);
  @$pb.TagNumber(7)
  void clearNumOnlineNodes() => $_clearField(7);

  ///
  ///  Number of nodes total
  @$pb.TagNumber(8)
  $core.int get numTotalNodes => $_getIZ(7);
  @$pb.TagNumber(8)
  set numTotalNodes($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNumTotalNodes() => $_has(7);
  @$pb.TagNumber(8)
  void clearNumTotalNodes() => $_clearField(8);

  ///
  ///  Number of received packets that were duplicates (due to multiple nodes relaying).
  ///  If this number is high, there are nodes in the mesh relaying packets when it's unnecessary, for example due to the ROUTER/REPEATER role.
  @$pb.TagNumber(9)
  $core.int get numRxDupe => $_getIZ(8);
  @$pb.TagNumber(9)
  set numRxDupe($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNumRxDupe() => $_has(8);
  @$pb.TagNumber(9)
  void clearNumRxDupe() => $_clearField(9);

  ///
  ///  Number of packets we transmitted that were a relay for others (not originating from ourselves).
  @$pb.TagNumber(10)
  $core.int get numTxRelay => $_getIZ(9);
  @$pb.TagNumber(10)
  set numTxRelay($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasNumTxRelay() => $_has(9);
  @$pb.TagNumber(10)
  void clearNumTxRelay() => $_clearField(10);

  ///
  ///  Number of times we canceled a packet to be relayed, because someone else did it before us.
  ///  This will always be zero for ROUTERs/REPEATERs. If this number is high, some other node(s) is/are relaying faster than you.
  @$pb.TagNumber(11)
  $core.int get numTxRelayCanceled => $_getIZ(10);
  @$pb.TagNumber(11)
  set numTxRelayCanceled($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNumTxRelayCanceled() => $_has(10);
  @$pb.TagNumber(11)
  void clearNumTxRelayCanceled() => $_clearField(11);

  ///
  ///  Number of bytes used in the heap
  @$pb.TagNumber(12)
  $core.int get heapTotalBytes => $_getIZ(11);
  @$pb.TagNumber(12)
  set heapTotalBytes($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasHeapTotalBytes() => $_has(11);
  @$pb.TagNumber(12)
  void clearHeapTotalBytes() => $_clearField(12);

  ///
  ///  Number of bytes free in the heap
  @$pb.TagNumber(13)
  $core.int get heapFreeBytes => $_getIZ(12);
  @$pb.TagNumber(13)
  set heapFreeBytes($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasHeapFreeBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearHeapFreeBytes() => $_clearField(13);
}

///
///  Health telemetry metrics
class HealthMetrics extends $pb.GeneratedMessage {
  factory HealthMetrics({
    $core.int? heartBpm,
    $core.int? spO2,
    $core.double? temperature,
  }) {
    final result = create();
    if (heartBpm != null) result.heartBpm = heartBpm;
    if (spO2 != null) result.spO2 = spO2;
    if (temperature != null) result.temperature = temperature;
    return result;
  }

  HealthMetrics._();

  factory HealthMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HealthMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'heartBpm', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'spO2', $pb.PbFieldType.OU3,
        protoName: 'spO2')
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'temperature', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthMetrics clone() => HealthMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthMetrics copyWith(void Function(HealthMetrics) updates) =>
      super.copyWith((message) => updates(message as HealthMetrics))
          as HealthMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthMetrics create() => HealthMetrics._();
  @$core.override
  HealthMetrics createEmptyInstance() => create();
  static $pb.PbList<HealthMetrics> createRepeated() =>
      $pb.PbList<HealthMetrics>();
  @$core.pragma('dart2js:noInline')
  static HealthMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthMetrics>(create);
  static HealthMetrics? _defaultInstance;

  ///
  ///  Heart rate (beats per minute)
  @$pb.TagNumber(1)
  $core.int get heartBpm => $_getIZ(0);
  @$pb.TagNumber(1)
  set heartBpm($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHeartBpm() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeartBpm() => $_clearField(1);

  ///
  ///  SpO2 (blood oxygen saturation) level
  @$pb.TagNumber(2)
  $core.int get spO2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set spO2($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSpO2() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpO2() => $_clearField(2);

  ///
  ///  Body temperature in degrees Celsius
  @$pb.TagNumber(3)
  $core.double get temperature => $_getN(2);
  @$pb.TagNumber(3)
  set temperature($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTemperature() => $_has(2);
  @$pb.TagNumber(3)
  void clearTemperature() => $_clearField(3);
}

///
///  Linux host metrics
class HostMetrics extends $pb.GeneratedMessage {
  factory HostMetrics({
    $core.int? uptimeSeconds,
    $fixnum.Int64? freememBytes,
    $fixnum.Int64? diskfree1Bytes,
    $fixnum.Int64? diskfree2Bytes,
    $fixnum.Int64? diskfree3Bytes,
    $core.int? load1,
    $core.int? load5,
    $core.int? load15,
    $core.String? userString,
  }) {
    final result = create();
    if (uptimeSeconds != null) result.uptimeSeconds = uptimeSeconds;
    if (freememBytes != null) result.freememBytes = freememBytes;
    if (diskfree1Bytes != null) result.diskfree1Bytes = diskfree1Bytes;
    if (diskfree2Bytes != null) result.diskfree2Bytes = diskfree2Bytes;
    if (diskfree3Bytes != null) result.diskfree3Bytes = diskfree3Bytes;
    if (load1 != null) result.load1 = load1;
    if (load5 != null) result.load5 = load5;
    if (load15 != null) result.load15 = load15;
    if (userString != null) result.userString = userString;
    return result;
  }

  HostMetrics._();

  factory HostMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'uptimeSeconds', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'freememBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'diskfree1Bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'diskfree2Bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'diskfree3Bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'load1', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'load5', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'load15', $pb.PbFieldType.OU3)
    ..aOS(9, _omitFieldNames ? '' : 'userString')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostMetrics clone() => HostMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostMetrics copyWith(void Function(HostMetrics) updates) =>
      super.copyWith((message) => updates(message as HostMetrics))
          as HostMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostMetrics create() => HostMetrics._();
  @$core.override
  HostMetrics createEmptyInstance() => create();
  static $pb.PbList<HostMetrics> createRepeated() => $pb.PbList<HostMetrics>();
  @$core.pragma('dart2js:noInline')
  static HostMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostMetrics>(create);
  static HostMetrics? _defaultInstance;

  ///
  ///  Host system uptime
  @$pb.TagNumber(1)
  $core.int get uptimeSeconds => $_getIZ(0);
  @$pb.TagNumber(1)
  set uptimeSeconds($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUptimeSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearUptimeSeconds() => $_clearField(1);

  ///
  ///  Host system free memory
  @$pb.TagNumber(2)
  $fixnum.Int64 get freememBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set freememBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFreememBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearFreememBytes() => $_clearField(2);

  ///
  ///  Host system disk space free for /
  @$pb.TagNumber(3)
  $fixnum.Int64 get diskfree1Bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set diskfree1Bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDiskfree1Bytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearDiskfree1Bytes() => $_clearField(3);

  ///
  ///  Secondary system disk space free
  @$pb.TagNumber(4)
  $fixnum.Int64 get diskfree2Bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set diskfree2Bytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDiskfree2Bytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearDiskfree2Bytes() => $_clearField(4);

  ///
  ///  Tertiary disk space free
  @$pb.TagNumber(5)
  $fixnum.Int64 get diskfree3Bytes => $_getI64(4);
  @$pb.TagNumber(5)
  set diskfree3Bytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDiskfree3Bytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearDiskfree3Bytes() => $_clearField(5);

  ///
  ///  Host system one minute load in 1/100ths
  @$pb.TagNumber(6)
  $core.int get load1 => $_getIZ(5);
  @$pb.TagNumber(6)
  set load1($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLoad1() => $_has(5);
  @$pb.TagNumber(6)
  void clearLoad1() => $_clearField(6);

  ///
  ///  Host system five minute load  in 1/100ths
  @$pb.TagNumber(7)
  $core.int get load5 => $_getIZ(6);
  @$pb.TagNumber(7)
  set load5($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLoad5() => $_has(6);
  @$pb.TagNumber(7)
  void clearLoad5() => $_clearField(7);

  ///
  ///  Host system fifteen minute load  in 1/100ths
  @$pb.TagNumber(8)
  $core.int get load15 => $_getIZ(7);
  @$pb.TagNumber(8)
  set load15($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLoad15() => $_has(7);
  @$pb.TagNumber(8)
  void clearLoad15() => $_clearField(8);

  ///
  ///  Optional User-provided string for arbitrary host system information
  ///  that doesn't make sense as a dedicated entry.
  @$pb.TagNumber(9)
  $core.String get userString => $_getSZ(8);
  @$pb.TagNumber(9)
  set userString($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUserString() => $_has(8);
  @$pb.TagNumber(9)
  void clearUserString() => $_clearField(9);
}

enum Telemetry_Variant {
  deviceMetrics,
  environmentMetrics,
  airQualityMetrics,
  powerMetrics,
  localStats,
  healthMetrics,
  hostMetrics,
  notSet
}

///
///  Types of Measurements the telemetry module is equipped to handle
class Telemetry extends $pb.GeneratedMessage {
  factory Telemetry({
    $core.int? time,
    DeviceMetrics? deviceMetrics,
    EnvironmentMetrics? environmentMetrics,
    AirQualityMetrics? airQualityMetrics,
    PowerMetrics? powerMetrics,
    LocalStats? localStats,
    HealthMetrics? healthMetrics,
    HostMetrics? hostMetrics,
  }) {
    final result = create();
    if (time != null) result.time = time;
    if (deviceMetrics != null) result.deviceMetrics = deviceMetrics;
    if (environmentMetrics != null)
      result.environmentMetrics = environmentMetrics;
    if (airQualityMetrics != null) result.airQualityMetrics = airQualityMetrics;
    if (powerMetrics != null) result.powerMetrics = powerMetrics;
    if (localStats != null) result.localStats = localStats;
    if (healthMetrics != null) result.healthMetrics = healthMetrics;
    if (hostMetrics != null) result.hostMetrics = hostMetrics;
    return result;
  }

  Telemetry._();

  factory Telemetry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Telemetry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Telemetry_Variant> _Telemetry_VariantByTag =
      {
    2: Telemetry_Variant.deviceMetrics,
    3: Telemetry_Variant.environmentMetrics,
    4: Telemetry_Variant.airQualityMetrics,
    5: Telemetry_Variant.powerMetrics,
    6: Telemetry_Variant.localStats,
    7: Telemetry_Variant.healthMetrics,
    8: Telemetry_Variant.hostMetrics,
    0: Telemetry_Variant.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Telemetry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8])
    ..a<$core.int>(1, _omitFieldNames ? '' : 'time', $pb.PbFieldType.OF3)
    ..aOM<DeviceMetrics>(2, _omitFieldNames ? '' : 'deviceMetrics',
        subBuilder: DeviceMetrics.create)
    ..aOM<EnvironmentMetrics>(3, _omitFieldNames ? '' : 'environmentMetrics',
        subBuilder: EnvironmentMetrics.create)
    ..aOM<AirQualityMetrics>(4, _omitFieldNames ? '' : 'airQualityMetrics',
        subBuilder: AirQualityMetrics.create)
    ..aOM<PowerMetrics>(5, _omitFieldNames ? '' : 'powerMetrics',
        subBuilder: PowerMetrics.create)
    ..aOM<LocalStats>(6, _omitFieldNames ? '' : 'localStats',
        subBuilder: LocalStats.create)
    ..aOM<HealthMetrics>(7, _omitFieldNames ? '' : 'healthMetrics',
        subBuilder: HealthMetrics.create)
    ..aOM<HostMetrics>(8, _omitFieldNames ? '' : 'hostMetrics',
        subBuilder: HostMetrics.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Telemetry clone() => Telemetry()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Telemetry copyWith(void Function(Telemetry) updates) =>
      super.copyWith((message) => updates(message as Telemetry)) as Telemetry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Telemetry create() => Telemetry._();
  @$core.override
  Telemetry createEmptyInstance() => create();
  static $pb.PbList<Telemetry> createRepeated() => $pb.PbList<Telemetry>();
  @$core.pragma('dart2js:noInline')
  static Telemetry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Telemetry>(create);
  static Telemetry? _defaultInstance;

  Telemetry_Variant whichVariant() => _Telemetry_VariantByTag[$_whichOneof(0)]!;
  void clearVariant() => $_clearField($_whichOneof(0));

  ///
  ///  Seconds since 1970 - or 0 for unknown/unset
  @$pb.TagNumber(1)
  $core.int get time => $_getIZ(0);
  @$pb.TagNumber(1)
  set time($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearTime() => $_clearField(1);

  ///
  ///  Key native device metrics such as battery level
  @$pb.TagNumber(2)
  DeviceMetrics get deviceMetrics => $_getN(1);
  @$pb.TagNumber(2)
  set deviceMetrics(DeviceMetrics value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceMetrics() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceMetrics() => $_clearField(2);
  @$pb.TagNumber(2)
  DeviceMetrics ensureDeviceMetrics() => $_ensure(1);

  ///
  ///  Weather station or other environmental metrics
  @$pb.TagNumber(3)
  EnvironmentMetrics get environmentMetrics => $_getN(2);
  @$pb.TagNumber(3)
  set environmentMetrics(EnvironmentMetrics value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEnvironmentMetrics() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnvironmentMetrics() => $_clearField(3);
  @$pb.TagNumber(3)
  EnvironmentMetrics ensureEnvironmentMetrics() => $_ensure(2);

  ///
  ///  Air quality metrics
  @$pb.TagNumber(4)
  AirQualityMetrics get airQualityMetrics => $_getN(3);
  @$pb.TagNumber(4)
  set airQualityMetrics(AirQualityMetrics value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAirQualityMetrics() => $_has(3);
  @$pb.TagNumber(4)
  void clearAirQualityMetrics() => $_clearField(4);
  @$pb.TagNumber(4)
  AirQualityMetrics ensureAirQualityMetrics() => $_ensure(3);

  ///
  ///  Power Metrics
  @$pb.TagNumber(5)
  PowerMetrics get powerMetrics => $_getN(4);
  @$pb.TagNumber(5)
  set powerMetrics(PowerMetrics value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPowerMetrics() => $_has(4);
  @$pb.TagNumber(5)
  void clearPowerMetrics() => $_clearField(5);
  @$pb.TagNumber(5)
  PowerMetrics ensurePowerMetrics() => $_ensure(4);

  ///
  ///  Local device mesh statistics
  @$pb.TagNumber(6)
  LocalStats get localStats => $_getN(5);
  @$pb.TagNumber(6)
  set localStats(LocalStats value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLocalStats() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocalStats() => $_clearField(6);
  @$pb.TagNumber(6)
  LocalStats ensureLocalStats() => $_ensure(5);

  ///
  ///  Health telemetry metrics
  @$pb.TagNumber(7)
  HealthMetrics get healthMetrics => $_getN(6);
  @$pb.TagNumber(7)
  set healthMetrics(HealthMetrics value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasHealthMetrics() => $_has(6);
  @$pb.TagNumber(7)
  void clearHealthMetrics() => $_clearField(7);
  @$pb.TagNumber(7)
  HealthMetrics ensureHealthMetrics() => $_ensure(6);

  ///
  ///  Linux host metrics
  @$pb.TagNumber(8)
  HostMetrics get hostMetrics => $_getN(7);
  @$pb.TagNumber(8)
  set hostMetrics(HostMetrics value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasHostMetrics() => $_has(7);
  @$pb.TagNumber(8)
  void clearHostMetrics() => $_clearField(8);
  @$pb.TagNumber(8)
  HostMetrics ensureHostMetrics() => $_ensure(7);
}

///
///  NAU7802 Telemetry configuration, for saving to flash
class Nau7802Config extends $pb.GeneratedMessage {
  factory Nau7802Config({
    $core.int? zeroOffset,
    $core.double? calibrationFactor,
  }) {
    final result = create();
    if (zeroOffset != null) result.zeroOffset = zeroOffset;
    if (calibrationFactor != null) result.calibrationFactor = calibrationFactor;
    return result;
  }

  Nau7802Config._();

  factory Nau7802Config.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Nau7802Config.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Nau7802Config',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'zeroOffset', $pb.PbFieldType.O3,
        protoName: 'zeroOffset')
    ..a<$core.double>(
        2, _omitFieldNames ? '' : 'calibrationFactor', $pb.PbFieldType.OF,
        protoName: 'calibrationFactor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nau7802Config clone() => Nau7802Config()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nau7802Config copyWith(void Function(Nau7802Config) updates) =>
      super.copyWith((message) => updates(message as Nau7802Config))
          as Nau7802Config;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Nau7802Config create() => Nau7802Config._();
  @$core.override
  Nau7802Config createEmptyInstance() => create();
  static $pb.PbList<Nau7802Config> createRepeated() =>
      $pb.PbList<Nau7802Config>();
  @$core.pragma('dart2js:noInline')
  static Nau7802Config getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Nau7802Config>(create);
  static Nau7802Config? _defaultInstance;

  ///
  ///  The offset setting for the NAU7802
  @$pb.TagNumber(1)
  $core.int get zeroOffset => $_getIZ(0);
  @$pb.TagNumber(1)
  set zeroOffset($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasZeroOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearZeroOffset() => $_clearField(1);

  ///
  ///  The calibration factor for the NAU7802
  @$pb.TagNumber(2)
  $core.double get calibrationFactor => $_getN(1);
  @$pb.TagNumber(2)
  set calibrationFactor($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCalibrationFactor() => $_has(1);
  @$pb.TagNumber(2)
  void clearCalibrationFactor() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
