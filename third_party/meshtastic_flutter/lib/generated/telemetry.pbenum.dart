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

import 'package:protobuf/protobuf.dart' as $pb;

///
///  Supported I2C Sensors for telemetry in Meshtastic
class TelemetrySensorType extends $pb.ProtobufEnum {
  ///
  ///  No external telemetry sensor explicitly set
  static const TelemetrySensorType SENSOR_UNSET =
      TelemetrySensorType._(0, _omitEnumNames ? '' : 'SENSOR_UNSET');

  ///
  ///  High accuracy temperature, pressure, humidity
  static const TelemetrySensorType BME280 =
      TelemetrySensorType._(1, _omitEnumNames ? '' : 'BME280');

  ///
  ///  High accuracy temperature, pressure, humidity, and air resistance
  static const TelemetrySensorType BME680 =
      TelemetrySensorType._(2, _omitEnumNames ? '' : 'BME680');

  ///
  ///  Very high accuracy temperature
  static const TelemetrySensorType MCP9808 =
      TelemetrySensorType._(3, _omitEnumNames ? '' : 'MCP9808');

  ///
  ///  Moderate accuracy current and voltage
  static const TelemetrySensorType INA260 =
      TelemetrySensorType._(4, _omitEnumNames ? '' : 'INA260');

  ///
  ///  Moderate accuracy current and voltage
  static const TelemetrySensorType INA219 =
      TelemetrySensorType._(5, _omitEnumNames ? '' : 'INA219');

  ///
  ///  High accuracy temperature and pressure
  static const TelemetrySensorType BMP280 =
      TelemetrySensorType._(6, _omitEnumNames ? '' : 'BMP280');

  ///
  ///  High accuracy temperature and humidity
  static const TelemetrySensorType SHTC3 =
      TelemetrySensorType._(7, _omitEnumNames ? '' : 'SHTC3');

  ///
  ///  High accuracy pressure
  static const TelemetrySensorType LPS22 =
      TelemetrySensorType._(8, _omitEnumNames ? '' : 'LPS22');

  ///
  ///  3-Axis magnetic sensor
  static const TelemetrySensorType QMC6310 =
      TelemetrySensorType._(9, _omitEnumNames ? '' : 'QMC6310');

  ///
  ///  6-Axis inertial measurement sensor
  static const TelemetrySensorType QMI8658 =
      TelemetrySensorType._(10, _omitEnumNames ? '' : 'QMI8658');

  ///
  ///  3-Axis magnetic sensor
  static const TelemetrySensorType QMC5883L =
      TelemetrySensorType._(11, _omitEnumNames ? '' : 'QMC5883L');

  ///
  ///  High accuracy temperature and humidity
  static const TelemetrySensorType SHT31 =
      TelemetrySensorType._(12, _omitEnumNames ? '' : 'SHT31');

  ///
  ///  PM2.5 air quality sensor
  static const TelemetrySensorType PMSA003I =
      TelemetrySensorType._(13, _omitEnumNames ? '' : 'PMSA003I');

  ///
  ///  INA3221 3 Channel Voltage / Current Sensor
  static const TelemetrySensorType INA3221 =
      TelemetrySensorType._(14, _omitEnumNames ? '' : 'INA3221');

  ///
  ///  BMP085/BMP180 High accuracy temperature and pressure (older Version of BMP280)
  static const TelemetrySensorType BMP085 =
      TelemetrySensorType._(15, _omitEnumNames ? '' : 'BMP085');

  ///
  ///  RCWL-9620 Doppler Radar Distance Sensor, used for water level detection
  static const TelemetrySensorType RCWL9620 =
      TelemetrySensorType._(16, _omitEnumNames ? '' : 'RCWL9620');

  ///
  ///  Sensirion High accuracy temperature and humidity
  static const TelemetrySensorType SHT4X =
      TelemetrySensorType._(17, _omitEnumNames ? '' : 'SHT4X');

  ///
  ///  VEML7700 high accuracy ambient light(Lux) digital 16-bit resolution sensor.
  static const TelemetrySensorType VEML7700 =
      TelemetrySensorType._(18, _omitEnumNames ? '' : 'VEML7700');

  ///
  ///  MLX90632 non-contact IR temperature sensor.
  static const TelemetrySensorType MLX90632 =
      TelemetrySensorType._(19, _omitEnumNames ? '' : 'MLX90632');

  ///
  ///  TI OPT3001 Ambient Light Sensor
  static const TelemetrySensorType OPT3001 =
      TelemetrySensorType._(20, _omitEnumNames ? '' : 'OPT3001');

  ///
  ///  Lite On LTR-390UV-01 UV Light Sensor
  static const TelemetrySensorType LTR390UV =
      TelemetrySensorType._(21, _omitEnumNames ? '' : 'LTR390UV');

  ///
  ///  AMS TSL25911FN RGB Light Sensor
  static const TelemetrySensorType TSL25911FN =
      TelemetrySensorType._(22, _omitEnumNames ? '' : 'TSL25911FN');

  ///
  ///  AHT10 Integrated temperature and humidity sensor
  static const TelemetrySensorType AHT10 =
      TelemetrySensorType._(23, _omitEnumNames ? '' : 'AHT10');

  ///
  ///  DFRobot Lark Weather station (temperature, humidity, pressure, wind speed and direction)
  static const TelemetrySensorType DFROBOT_LARK =
      TelemetrySensorType._(24, _omitEnumNames ? '' : 'DFROBOT_LARK');

  ///
  ///  NAU7802 Scale Chip or compatible
  static const TelemetrySensorType NAU7802 =
      TelemetrySensorType._(25, _omitEnumNames ? '' : 'NAU7802');

  ///
  ///  BMP3XX High accuracy temperature and pressure
  static const TelemetrySensorType BMP3XX =
      TelemetrySensorType._(26, _omitEnumNames ? '' : 'BMP3XX');

  ///
  ///  ICM-20948 9-Axis digital motion processor
  static const TelemetrySensorType ICM20948 =
      TelemetrySensorType._(27, _omitEnumNames ? '' : 'ICM20948');

  ///
  ///  MAX17048 1S lipo battery sensor (voltage, state of charge, time to go)
  static const TelemetrySensorType MAX17048 =
      TelemetrySensorType._(28, _omitEnumNames ? '' : 'MAX17048');

  ///
  ///  Custom I2C sensor implementation based on https://github.com/meshtastic/i2c-sensor
  static const TelemetrySensorType CUSTOM_SENSOR =
      TelemetrySensorType._(29, _omitEnumNames ? '' : 'CUSTOM_SENSOR');

  ///
  ///  MAX30102 Pulse Oximeter and Heart-Rate Sensor
  static const TelemetrySensorType MAX30102 =
      TelemetrySensorType._(30, _omitEnumNames ? '' : 'MAX30102');

  ///
  ///  MLX90614 non-contact IR temperature sensor
  static const TelemetrySensorType MLX90614 =
      TelemetrySensorType._(31, _omitEnumNames ? '' : 'MLX90614');

  ///
  ///  SCD40/SCD41 CO2, humidity, temperature sensor
  static const TelemetrySensorType SCD4X =
      TelemetrySensorType._(32, _omitEnumNames ? '' : 'SCD4X');

  ///
  ///  ClimateGuard RadSens, radiation, Geiger-Muller Tube
  static const TelemetrySensorType RADSENS =
      TelemetrySensorType._(33, _omitEnumNames ? '' : 'RADSENS');

  ///
  ///  High accuracy current and voltage
  static const TelemetrySensorType INA226 =
      TelemetrySensorType._(34, _omitEnumNames ? '' : 'INA226');

  ///
  ///  DFRobot Gravity tipping bucket rain gauge
  static const TelemetrySensorType DFROBOT_RAIN =
      TelemetrySensorType._(35, _omitEnumNames ? '' : 'DFROBOT_RAIN');

  ///
  ///  Infineon DPS310 High accuracy pressure and temperature
  static const TelemetrySensorType DPS310 =
      TelemetrySensorType._(36, _omitEnumNames ? '' : 'DPS310');

  ///
  ///  RAKWireless RAK12035 Soil Moisture Sensor Module
  static const TelemetrySensorType RAK12035 =
      TelemetrySensorType._(37, _omitEnumNames ? '' : 'RAK12035');

  ///
  ///  MAX17261 lipo battery gauge
  static const TelemetrySensorType MAX17261 =
      TelemetrySensorType._(38, _omitEnumNames ? '' : 'MAX17261');

  ///
  ///  PCT2075 Temperature Sensor
  static const TelemetrySensorType PCT2075 =
      TelemetrySensorType._(39, _omitEnumNames ? '' : 'PCT2075');

  ///
  ///  ADS1X15 ADC
  static const TelemetrySensorType ADS1X15 =
      TelemetrySensorType._(40, _omitEnumNames ? '' : 'ADS1X15');

  ///
  ///  ADS1X15 ADC_ALT
  static const TelemetrySensorType ADS1X15_ALT =
      TelemetrySensorType._(41, _omitEnumNames ? '' : 'ADS1X15_ALT');

  ///
  ///  Sensirion SFA30 Formaldehyde sensor
  static const TelemetrySensorType SFA30 =
      TelemetrySensorType._(42, _omitEnumNames ? '' : 'SFA30');

  ///
  ///  SEN5X PM SENSORS
  static const TelemetrySensorType SEN5X =
      TelemetrySensorType._(43, _omitEnumNames ? '' : 'SEN5X');

  static const $core.List<TelemetrySensorType> values = <TelemetrySensorType>[
    SENSOR_UNSET,
    BME280,
    BME680,
    MCP9808,
    INA260,
    INA219,
    BMP280,
    SHTC3,
    LPS22,
    QMC6310,
    QMI8658,
    QMC5883L,
    SHT31,
    PMSA003I,
    INA3221,
    BMP085,
    RCWL9620,
    SHT4X,
    VEML7700,
    MLX90632,
    OPT3001,
    LTR390UV,
    TSL25911FN,
    AHT10,
    DFROBOT_LARK,
    NAU7802,
    BMP3XX,
    ICM20948,
    MAX17048,
    CUSTOM_SENSOR,
    MAX30102,
    MLX90614,
    SCD4X,
    RADSENS,
    INA226,
    DFROBOT_RAIN,
    DPS310,
    RAK12035,
    MAX17261,
    PCT2075,
    ADS1X15,
    ADS1X15_ALT,
    SFA30,
    SEN5X,
  ];

  static final $core.List<TelemetrySensorType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 43);
  static TelemetrySensorType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TelemetrySensorType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
