// This is a generated file - do not edit.
//
// Generated from meshtastic/telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use telemetrySensorTypeDescriptor instead')
const TelemetrySensorType$json = {
  '1': 'TelemetrySensorType',
  '2': [
    {'1': 'SENSOR_UNSET', '2': 0},
    {'1': 'BME280', '2': 1},
    {'1': 'BME680', '2': 2},
    {'1': 'MCP9808', '2': 3},
    {'1': 'INA260', '2': 4},
    {'1': 'INA219', '2': 5},
    {'1': 'BMP280', '2': 6},
    {'1': 'SHTC3', '2': 7},
    {'1': 'LPS22', '2': 8},
    {'1': 'QMC6310', '2': 9},
    {'1': 'QMI8658', '2': 10},
    {'1': 'QMC5883L', '2': 11},
    {'1': 'SHT31', '2': 12},
    {'1': 'PMSA003I', '2': 13},
    {'1': 'INA3221', '2': 14},
    {'1': 'BMP085', '2': 15},
    {'1': 'RCWL9620', '2': 16},
    {'1': 'SHT4X', '2': 17},
    {'1': 'VEML7700', '2': 18},
    {'1': 'MLX90632', '2': 19},
    {'1': 'OPT3001', '2': 20},
    {'1': 'LTR390UV', '2': 21},
    {'1': 'TSL25911FN', '2': 22},
    {'1': 'AHT10', '2': 23},
    {'1': 'DFROBOT_LARK', '2': 24},
    {'1': 'NAU7802', '2': 25},
    {'1': 'BMP3XX', '2': 26},
    {'1': 'ICM20948', '2': 27},
    {'1': 'MAX17048', '2': 28},
    {'1': 'CUSTOM_SENSOR', '2': 29},
    {'1': 'MAX30102', '2': 30},
    {'1': 'MLX90614', '2': 31},
    {'1': 'SCD4X', '2': 32},
    {'1': 'RADSENS', '2': 33},
    {'1': 'INA226', '2': 34},
    {'1': 'DFROBOT_RAIN', '2': 35},
    {'1': 'DPS310', '2': 36},
    {'1': 'RAK12035', '2': 37},
    {'1': 'MAX17261', '2': 38},
    {'1': 'PCT2075', '2': 39},
    {'1': 'ADS1X15', '2': 40},
    {'1': 'ADS1X15_ALT', '2': 41},
    {'1': 'SFA30', '2': 42},
    {'1': 'SEN5X', '2': 43},
  ],
};

/// Descriptor for `TelemetrySensorType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List telemetrySensorTypeDescriptor = $convert.base64Decode(
    'ChNUZWxlbWV0cnlTZW5zb3JUeXBlEhAKDFNFTlNPUl9VTlNFVBAAEgoKBkJNRTI4MBABEgoKBk'
    'JNRTY4MBACEgsKB01DUDk4MDgQAxIKCgZJTkEyNjAQBBIKCgZJTkEyMTkQBRIKCgZCTVAyODAQ'
    'BhIJCgVTSFRDMxAHEgkKBUxQUzIyEAgSCwoHUU1DNjMxMBAJEgsKB1FNSTg2NTgQChIMCghRTU'
    'M1ODgzTBALEgkKBVNIVDMxEAwSDAoIUE1TQTAwM0kQDRILCgdJTkEzMjIxEA4SCgoGQk1QMDg1'
    'EA8SDAoIUkNXTDk2MjAQEBIJCgVTSFQ0WBAREgwKCFZFTUw3NzAwEBISDAoITUxYOTA2MzIQEx'
    'ILCgdPUFQzMDAxEBQSDAoITFRSMzkwVVYQFRIOCgpUU0wyNTkxMUZOEBYSCQoFQUhUMTAQFxIQ'
    'CgxERlJPQk9UX0xBUksQGBILCgdOQVU3ODAyEBkSCgoGQk1QM1hYEBoSDAoISUNNMjA5NDgQGx'
    'IMCghNQVgxNzA0OBAcEhEKDUNVU1RPTV9TRU5TT1IQHRIMCghNQVgzMDEwMhAeEgwKCE1MWDkw'
    'NjE0EB8SCQoFU0NENFgQIBILCgdSQURTRU5TECESCgoGSU5BMjI2ECISEAoMREZST0JPVF9SQU'
    'lOECMSCgoGRFBTMzEwECQSDAoIUkFLMTIwMzUQJRIMCghNQVgxNzI2MRAmEgsKB1BDVDIwNzUQ'
    'JxILCgdBRFMxWDE1ECgSDwoLQURTMVgxNV9BTFQQKRIJCgVTRkEzMBAqEgkKBVNFTjVYECs=');

@$core.Deprecated('Use deviceMetricsDescriptor instead')
const DeviceMetrics$json = {
  '1': 'DeviceMetrics',
  '2': [
    {
      '1': 'battery_level',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'batteryLevel',
      '17': true
    },
    {
      '1': 'voltage',
      '3': 2,
      '4': 1,
      '5': 2,
      '9': 1,
      '10': 'voltage',
      '17': true
    },
    {
      '1': 'channel_utilization',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'channelUtilization',
      '17': true
    },
    {
      '1': 'air_util_tx',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 3,
      '10': 'airUtilTx',
      '17': true
    },
    {
      '1': 'uptime_seconds',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 4,
      '10': 'uptimeSeconds',
      '17': true
    },
  ],
  '8': [
    {'1': '_battery_level'},
    {'1': '_voltage'},
    {'1': '_channel_utilization'},
    {'1': '_air_util_tx'},
    {'1': '_uptime_seconds'},
  ],
};

/// Descriptor for `DeviceMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceMetricsDescriptor = $convert.base64Decode(
    'Cg1EZXZpY2VNZXRyaWNzEigKDWJhdHRlcnlfbGV2ZWwYASABKA1IAFIMYmF0dGVyeUxldmVsiA'
    'EBEh0KB3ZvbHRhZ2UYAiABKAJIAVIHdm9sdGFnZYgBARI0ChNjaGFubmVsX3V0aWxpemF0aW9u'
    'GAMgASgCSAJSEmNoYW5uZWxVdGlsaXphdGlvbogBARIjCgthaXJfdXRpbF90eBgEIAEoAkgDUg'
    'lhaXJVdGlsVHiIAQESKgoOdXB0aW1lX3NlY29uZHMYBSABKA1IBFINdXB0aW1lU2Vjb25kc4gB'
    'AUIQCg5fYmF0dGVyeV9sZXZlbEIKCghfdm9sdGFnZUIWChRfY2hhbm5lbF91dGlsaXphdGlvbk'
    'IOCgxfYWlyX3V0aWxfdHhCEQoPX3VwdGltZV9zZWNvbmRz');

@$core.Deprecated('Use environmentMetricsDescriptor instead')
const EnvironmentMetrics$json = {
  '1': 'EnvironmentMetrics',
  '2': [
    {
      '1': 'temperature',
      '3': 1,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'temperature',
      '17': true
    },
    {
      '1': 'relative_humidity',
      '3': 2,
      '4': 1,
      '5': 2,
      '9': 1,
      '10': 'relativeHumidity',
      '17': true
    },
    {
      '1': 'barometric_pressure',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'barometricPressure',
      '17': true
    },
    {
      '1': 'gas_resistance',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 3,
      '10': 'gasResistance',
      '17': true
    },
    {
      '1': 'voltage',
      '3': 5,
      '4': 1,
      '5': 2,
      '9': 4,
      '10': 'voltage',
      '17': true
    },
    {
      '1': 'current',
      '3': 6,
      '4': 1,
      '5': 2,
      '9': 5,
      '10': 'current',
      '17': true
    },
    {'1': 'iaq', '3': 7, '4': 1, '5': 13, '9': 6, '10': 'iaq', '17': true},
    {
      '1': 'distance',
      '3': 8,
      '4': 1,
      '5': 2,
      '9': 7,
      '10': 'distance',
      '17': true
    },
    {'1': 'lux', '3': 9, '4': 1, '5': 2, '9': 8, '10': 'lux', '17': true},
    {
      '1': 'white_lux',
      '3': 10,
      '4': 1,
      '5': 2,
      '9': 9,
      '10': 'whiteLux',
      '17': true
    },
    {
      '1': 'ir_lux',
      '3': 11,
      '4': 1,
      '5': 2,
      '9': 10,
      '10': 'irLux',
      '17': true
    },
    {
      '1': 'uv_lux',
      '3': 12,
      '4': 1,
      '5': 2,
      '9': 11,
      '10': 'uvLux',
      '17': true
    },
    {
      '1': 'wind_direction',
      '3': 13,
      '4': 1,
      '5': 13,
      '9': 12,
      '10': 'windDirection',
      '17': true
    },
    {
      '1': 'wind_speed',
      '3': 14,
      '4': 1,
      '5': 2,
      '9': 13,
      '10': 'windSpeed',
      '17': true
    },
    {
      '1': 'weight',
      '3': 15,
      '4': 1,
      '5': 2,
      '9': 14,
      '10': 'weight',
      '17': true
    },
    {
      '1': 'wind_gust',
      '3': 16,
      '4': 1,
      '5': 2,
      '9': 15,
      '10': 'windGust',
      '17': true
    },
    {
      '1': 'wind_lull',
      '3': 17,
      '4': 1,
      '5': 2,
      '9': 16,
      '10': 'windLull',
      '17': true
    },
    {
      '1': 'radiation',
      '3': 18,
      '4': 1,
      '5': 2,
      '9': 17,
      '10': 'radiation',
      '17': true
    },
    {
      '1': 'rainfall_1h',
      '3': 19,
      '4': 1,
      '5': 2,
      '9': 18,
      '10': 'rainfall1h',
      '17': true
    },
    {
      '1': 'rainfall_24h',
      '3': 20,
      '4': 1,
      '5': 2,
      '9': 19,
      '10': 'rainfall24h',
      '17': true
    },
    {
      '1': 'soil_moisture',
      '3': 21,
      '4': 1,
      '5': 13,
      '9': 20,
      '10': 'soilMoisture',
      '17': true
    },
    {
      '1': 'soil_temperature',
      '3': 22,
      '4': 1,
      '5': 2,
      '9': 21,
      '10': 'soilTemperature',
      '17': true
    },
  ],
  '8': [
    {'1': '_temperature'},
    {'1': '_relative_humidity'},
    {'1': '_barometric_pressure'},
    {'1': '_gas_resistance'},
    {'1': '_voltage'},
    {'1': '_current'},
    {'1': '_iaq'},
    {'1': '_distance'},
    {'1': '_lux'},
    {'1': '_white_lux'},
    {'1': '_ir_lux'},
    {'1': '_uv_lux'},
    {'1': '_wind_direction'},
    {'1': '_wind_speed'},
    {'1': '_weight'},
    {'1': '_wind_gust'},
    {'1': '_wind_lull'},
    {'1': '_radiation'},
    {'1': '_rainfall_1h'},
    {'1': '_rainfall_24h'},
    {'1': '_soil_moisture'},
    {'1': '_soil_temperature'},
  ],
};

/// Descriptor for `EnvironmentMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List environmentMetricsDescriptor = $convert.base64Decode(
    'ChJFbnZpcm9ubWVudE1ldHJpY3MSJQoLdGVtcGVyYXR1cmUYASABKAJIAFILdGVtcGVyYXR1cm'
    'WIAQESMAoRcmVsYXRpdmVfaHVtaWRpdHkYAiABKAJIAVIQcmVsYXRpdmVIdW1pZGl0eYgBARI0'
    'ChNiYXJvbWV0cmljX3ByZXNzdXJlGAMgASgCSAJSEmJhcm9tZXRyaWNQcmVzc3VyZYgBARIqCg'
    '5nYXNfcmVzaXN0YW5jZRgEIAEoAkgDUg1nYXNSZXNpc3RhbmNliAEBEh0KB3ZvbHRhZ2UYBSAB'
    'KAJIBFIHdm9sdGFnZYgBARIdCgdjdXJyZW50GAYgASgCSAVSB2N1cnJlbnSIAQESFQoDaWFxGA'
    'cgASgNSAZSA2lhcYgBARIfCghkaXN0YW5jZRgIIAEoAkgHUghkaXN0YW5jZYgBARIVCgNsdXgY'
    'CSABKAJICFIDbHV4iAEBEiAKCXdoaXRlX2x1eBgKIAEoAkgJUgh3aGl0ZUx1eIgBARIaCgZpcl'
    '9sdXgYCyABKAJIClIFaXJMdXiIAQESGgoGdXZfbHV4GAwgASgCSAtSBXV2THV4iAEBEioKDndp'
    'bmRfZGlyZWN0aW9uGA0gASgNSAxSDXdpbmREaXJlY3Rpb26IAQESIgoKd2luZF9zcGVlZBgOIA'
    'EoAkgNUgl3aW5kU3BlZWSIAQESGwoGd2VpZ2h0GA8gASgCSA5SBndlaWdodIgBARIgCgl3aW5k'
    'X2d1c3QYECABKAJID1IId2luZEd1c3SIAQESIAoJd2luZF9sdWxsGBEgASgCSBBSCHdpbmRMdW'
    'xsiAEBEiEKCXJhZGlhdGlvbhgSIAEoAkgRUglyYWRpYXRpb26IAQESJAoLcmFpbmZhbGxfMWgY'
    'EyABKAJIElIKcmFpbmZhbGwxaIgBARImCgxyYWluZmFsbF8yNGgYFCABKAJIE1ILcmFpbmZhbG'
    'wyNGiIAQESKAoNc29pbF9tb2lzdHVyZRgVIAEoDUgUUgxzb2lsTW9pc3R1cmWIAQESLgoQc29p'
    'bF90ZW1wZXJhdHVyZRgWIAEoAkgVUg9zb2lsVGVtcGVyYXR1cmWIAQFCDgoMX3RlbXBlcmF0dX'
    'JlQhQKEl9yZWxhdGl2ZV9odW1pZGl0eUIWChRfYmFyb21ldHJpY19wcmVzc3VyZUIRCg9fZ2Fz'
    'X3Jlc2lzdGFuY2VCCgoIX3ZvbHRhZ2VCCgoIX2N1cnJlbnRCBgoEX2lhcUILCglfZGlzdGFuY2'
    'VCBgoEX2x1eEIMCgpfd2hpdGVfbHV4QgkKB19pcl9sdXhCCQoHX3V2X2x1eEIRCg9fd2luZF9k'
    'aXJlY3Rpb25CDQoLX3dpbmRfc3BlZWRCCQoHX3dlaWdodEIMCgpfd2luZF9ndXN0QgwKCl93aW'
    '5kX2x1bGxCDAoKX3JhZGlhdGlvbkIOCgxfcmFpbmZhbGxfMWhCDwoNX3JhaW5mYWxsXzI0aEIQ'
    'Cg5fc29pbF9tb2lzdHVyZUITChFfc29pbF90ZW1wZXJhdHVyZQ==');

@$core.Deprecated('Use powerMetricsDescriptor instead')
const PowerMetrics$json = {
  '1': 'PowerMetrics',
  '2': [
    {
      '1': 'ch1_voltage',
      '3': 1,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'ch1Voltage',
      '17': true
    },
    {
      '1': 'ch1_current',
      '3': 2,
      '4': 1,
      '5': 2,
      '9': 1,
      '10': 'ch1Current',
      '17': true
    },
    {
      '1': 'ch2_voltage',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'ch2Voltage',
      '17': true
    },
    {
      '1': 'ch2_current',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 3,
      '10': 'ch2Current',
      '17': true
    },
    {
      '1': 'ch3_voltage',
      '3': 5,
      '4': 1,
      '5': 2,
      '9': 4,
      '10': 'ch3Voltage',
      '17': true
    },
    {
      '1': 'ch3_current',
      '3': 6,
      '4': 1,
      '5': 2,
      '9': 5,
      '10': 'ch3Current',
      '17': true
    },
    {
      '1': 'ch4_voltage',
      '3': 7,
      '4': 1,
      '5': 2,
      '9': 6,
      '10': 'ch4Voltage',
      '17': true
    },
    {
      '1': 'ch4_current',
      '3': 8,
      '4': 1,
      '5': 2,
      '9': 7,
      '10': 'ch4Current',
      '17': true
    },
    {
      '1': 'ch5_voltage',
      '3': 9,
      '4': 1,
      '5': 2,
      '9': 8,
      '10': 'ch5Voltage',
      '17': true
    },
    {
      '1': 'ch5_current',
      '3': 10,
      '4': 1,
      '5': 2,
      '9': 9,
      '10': 'ch5Current',
      '17': true
    },
    {
      '1': 'ch6_voltage',
      '3': 11,
      '4': 1,
      '5': 2,
      '9': 10,
      '10': 'ch6Voltage',
      '17': true
    },
    {
      '1': 'ch6_current',
      '3': 12,
      '4': 1,
      '5': 2,
      '9': 11,
      '10': 'ch6Current',
      '17': true
    },
    {
      '1': 'ch7_voltage',
      '3': 13,
      '4': 1,
      '5': 2,
      '9': 12,
      '10': 'ch7Voltage',
      '17': true
    },
    {
      '1': 'ch7_current',
      '3': 14,
      '4': 1,
      '5': 2,
      '9': 13,
      '10': 'ch7Current',
      '17': true
    },
    {
      '1': 'ch8_voltage',
      '3': 15,
      '4': 1,
      '5': 2,
      '9': 14,
      '10': 'ch8Voltage',
      '17': true
    },
    {
      '1': 'ch8_current',
      '3': 16,
      '4': 1,
      '5': 2,
      '9': 15,
      '10': 'ch8Current',
      '17': true
    },
  ],
  '8': [
    {'1': '_ch1_voltage'},
    {'1': '_ch1_current'},
    {'1': '_ch2_voltage'},
    {'1': '_ch2_current'},
    {'1': '_ch3_voltage'},
    {'1': '_ch3_current'},
    {'1': '_ch4_voltage'},
    {'1': '_ch4_current'},
    {'1': '_ch5_voltage'},
    {'1': '_ch5_current'},
    {'1': '_ch6_voltage'},
    {'1': '_ch6_current'},
    {'1': '_ch7_voltage'},
    {'1': '_ch7_current'},
    {'1': '_ch8_voltage'},
    {'1': '_ch8_current'},
  ],
};

/// Descriptor for `PowerMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List powerMetricsDescriptor = $convert.base64Decode(
    'CgxQb3dlck1ldHJpY3MSJAoLY2gxX3ZvbHRhZ2UYASABKAJIAFIKY2gxVm9sdGFnZYgBARIkCg'
    'tjaDFfY3VycmVudBgCIAEoAkgBUgpjaDFDdXJyZW50iAEBEiQKC2NoMl92b2x0YWdlGAMgASgC'
    'SAJSCmNoMlZvbHRhZ2WIAQESJAoLY2gyX2N1cnJlbnQYBCABKAJIA1IKY2gyQ3VycmVudIgBAR'
    'IkCgtjaDNfdm9sdGFnZRgFIAEoAkgEUgpjaDNWb2x0YWdliAEBEiQKC2NoM19jdXJyZW50GAYg'
    'ASgCSAVSCmNoM0N1cnJlbnSIAQESJAoLY2g0X3ZvbHRhZ2UYByABKAJIBlIKY2g0Vm9sdGFnZY'
    'gBARIkCgtjaDRfY3VycmVudBgIIAEoAkgHUgpjaDRDdXJyZW50iAEBEiQKC2NoNV92b2x0YWdl'
    'GAkgASgCSAhSCmNoNVZvbHRhZ2WIAQESJAoLY2g1X2N1cnJlbnQYCiABKAJICVIKY2g1Q3Vycm'
    'VudIgBARIkCgtjaDZfdm9sdGFnZRgLIAEoAkgKUgpjaDZWb2x0YWdliAEBEiQKC2NoNl9jdXJy'
    'ZW50GAwgASgCSAtSCmNoNkN1cnJlbnSIAQESJAoLY2g3X3ZvbHRhZ2UYDSABKAJIDFIKY2g3Vm'
    '9sdGFnZYgBARIkCgtjaDdfY3VycmVudBgOIAEoAkgNUgpjaDdDdXJyZW50iAEBEiQKC2NoOF92'
    'b2x0YWdlGA8gASgCSA5SCmNoOFZvbHRhZ2WIAQESJAoLY2g4X2N1cnJlbnQYECABKAJID1IKY2'
    'g4Q3VycmVudIgBAUIOCgxfY2gxX3ZvbHRhZ2VCDgoMX2NoMV9jdXJyZW50Qg4KDF9jaDJfdm9s'
    'dGFnZUIOCgxfY2gyX2N1cnJlbnRCDgoMX2NoM192b2x0YWdlQg4KDF9jaDNfY3VycmVudEIOCg'
    'xfY2g0X3ZvbHRhZ2VCDgoMX2NoNF9jdXJyZW50Qg4KDF9jaDVfdm9sdGFnZUIOCgxfY2g1X2N1'
    'cnJlbnRCDgoMX2NoNl92b2x0YWdlQg4KDF9jaDZfY3VycmVudEIOCgxfY2g3X3ZvbHRhZ2VCDg'
    'oMX2NoN19jdXJyZW50Qg4KDF9jaDhfdm9sdGFnZUIOCgxfY2g4X2N1cnJlbnQ=');

@$core.Deprecated('Use airQualityMetricsDescriptor instead')
const AirQualityMetrics$json = {
  '1': 'AirQualityMetrics',
  '2': [
    {
      '1': 'pm10_standard',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'pm10Standard',
      '17': true
    },
    {
      '1': 'pm25_standard',
      '3': 2,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'pm25Standard',
      '17': true
    },
    {
      '1': 'pm100_standard',
      '3': 3,
      '4': 1,
      '5': 13,
      '9': 2,
      '10': 'pm100Standard',
      '17': true
    },
    {
      '1': 'pm10_environmental',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 3,
      '10': 'pm10Environmental',
      '17': true
    },
    {
      '1': 'pm25_environmental',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 4,
      '10': 'pm25Environmental',
      '17': true
    },
    {
      '1': 'pm100_environmental',
      '3': 6,
      '4': 1,
      '5': 13,
      '9': 5,
      '10': 'pm100Environmental',
      '17': true
    },
    {
      '1': 'particles_03um',
      '3': 7,
      '4': 1,
      '5': 13,
      '9': 6,
      '10': 'particles03um',
      '17': true
    },
    {
      '1': 'particles_05um',
      '3': 8,
      '4': 1,
      '5': 13,
      '9': 7,
      '10': 'particles05um',
      '17': true
    },
    {
      '1': 'particles_10um',
      '3': 9,
      '4': 1,
      '5': 13,
      '9': 8,
      '10': 'particles10um',
      '17': true
    },
    {
      '1': 'particles_25um',
      '3': 10,
      '4': 1,
      '5': 13,
      '9': 9,
      '10': 'particles25um',
      '17': true
    },
    {
      '1': 'particles_50um',
      '3': 11,
      '4': 1,
      '5': 13,
      '9': 10,
      '10': 'particles50um',
      '17': true
    },
    {
      '1': 'particles_100um',
      '3': 12,
      '4': 1,
      '5': 13,
      '9': 11,
      '10': 'particles100um',
      '17': true
    },
    {'1': 'co2', '3': 13, '4': 1, '5': 13, '9': 12, '10': 'co2', '17': true},
    {
      '1': 'co2_temperature',
      '3': 14,
      '4': 1,
      '5': 2,
      '9': 13,
      '10': 'co2Temperature',
      '17': true
    },
    {
      '1': 'co2_humidity',
      '3': 15,
      '4': 1,
      '5': 2,
      '9': 14,
      '10': 'co2Humidity',
      '17': true
    },
    {
      '1': 'form_formaldehyde',
      '3': 16,
      '4': 1,
      '5': 2,
      '9': 15,
      '10': 'formFormaldehyde',
      '17': true
    },
    {
      '1': 'form_humidity',
      '3': 17,
      '4': 1,
      '5': 2,
      '9': 16,
      '10': 'formHumidity',
      '17': true
    },
    {
      '1': 'form_temperature',
      '3': 18,
      '4': 1,
      '5': 2,
      '9': 17,
      '10': 'formTemperature',
      '17': true
    },
    {
      '1': 'pm40_standard',
      '3': 19,
      '4': 1,
      '5': 13,
      '9': 18,
      '10': 'pm40Standard',
      '17': true
    },
    {
      '1': 'particles_40um',
      '3': 20,
      '4': 1,
      '5': 13,
      '9': 19,
      '10': 'particles40um',
      '17': true
    },
    {
      '1': 'pm_temperature',
      '3': 21,
      '4': 1,
      '5': 2,
      '9': 20,
      '10': 'pmTemperature',
      '17': true
    },
    {
      '1': 'pm_humidity',
      '3': 22,
      '4': 1,
      '5': 2,
      '9': 21,
      '10': 'pmHumidity',
      '17': true
    },
    {
      '1': 'pm_voc_idx',
      '3': 23,
      '4': 1,
      '5': 2,
      '9': 22,
      '10': 'pmVocIdx',
      '17': true
    },
    {
      '1': 'pm_nox_idx',
      '3': 24,
      '4': 1,
      '5': 2,
      '9': 23,
      '10': 'pmNoxIdx',
      '17': true
    },
    {
      '1': 'particles_tps',
      '3': 25,
      '4': 1,
      '5': 2,
      '9': 24,
      '10': 'particlesTps',
      '17': true
    },
  ],
  '8': [
    {'1': '_pm10_standard'},
    {'1': '_pm25_standard'},
    {'1': '_pm100_standard'},
    {'1': '_pm10_environmental'},
    {'1': '_pm25_environmental'},
    {'1': '_pm100_environmental'},
    {'1': '_particles_03um'},
    {'1': '_particles_05um'},
    {'1': '_particles_10um'},
    {'1': '_particles_25um'},
    {'1': '_particles_50um'},
    {'1': '_particles_100um'},
    {'1': '_co2'},
    {'1': '_co2_temperature'},
    {'1': '_co2_humidity'},
    {'1': '_form_formaldehyde'},
    {'1': '_form_humidity'},
    {'1': '_form_temperature'},
    {'1': '_pm40_standard'},
    {'1': '_particles_40um'},
    {'1': '_pm_temperature'},
    {'1': '_pm_humidity'},
    {'1': '_pm_voc_idx'},
    {'1': '_pm_nox_idx'},
    {'1': '_particles_tps'},
  ],
};

/// Descriptor for `AirQualityMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List airQualityMetricsDescriptor = $convert.base64Decode(
    'ChFBaXJRdWFsaXR5TWV0cmljcxIoCg1wbTEwX3N0YW5kYXJkGAEgASgNSABSDHBtMTBTdGFuZG'
    'FyZIgBARIoCg1wbTI1X3N0YW5kYXJkGAIgASgNSAFSDHBtMjVTdGFuZGFyZIgBARIqCg5wbTEw'
    'MF9zdGFuZGFyZBgDIAEoDUgCUg1wbTEwMFN0YW5kYXJkiAEBEjIKEnBtMTBfZW52aXJvbm1lbn'
    'RhbBgEIAEoDUgDUhFwbTEwRW52aXJvbm1lbnRhbIgBARIyChJwbTI1X2Vudmlyb25tZW50YWwY'
    'BSABKA1IBFIRcG0yNUVudmlyb25tZW50YWyIAQESNAoTcG0xMDBfZW52aXJvbm1lbnRhbBgGIA'
    'EoDUgFUhJwbTEwMEVudmlyb25tZW50YWyIAQESKgoOcGFydGljbGVzXzAzdW0YByABKA1IBlIN'
    'cGFydGljbGVzMDN1bYgBARIqCg5wYXJ0aWNsZXNfMDV1bRgIIAEoDUgHUg1wYXJ0aWNsZXMwNX'
    'VtiAEBEioKDnBhcnRpY2xlc18xMHVtGAkgASgNSAhSDXBhcnRpY2xlczEwdW2IAQESKgoOcGFy'
    'dGljbGVzXzI1dW0YCiABKA1ICVINcGFydGljbGVzMjV1bYgBARIqCg5wYXJ0aWNsZXNfNTB1bR'
    'gLIAEoDUgKUg1wYXJ0aWNsZXM1MHVtiAEBEiwKD3BhcnRpY2xlc18xMDB1bRgMIAEoDUgLUg5w'
    'YXJ0aWNsZXMxMDB1bYgBARIVCgNjbzIYDSABKA1IDFIDY28yiAEBEiwKD2NvMl90ZW1wZXJhdH'
    'VyZRgOIAEoAkgNUg5jbzJUZW1wZXJhdHVyZYgBARImCgxjbzJfaHVtaWRpdHkYDyABKAJIDlIL'
    'Y28ySHVtaWRpdHmIAQESMAoRZm9ybV9mb3JtYWxkZWh5ZGUYECABKAJID1IQZm9ybUZvcm1hbG'
    'RlaHlkZYgBARIoCg1mb3JtX2h1bWlkaXR5GBEgASgCSBBSDGZvcm1IdW1pZGl0eYgBARIuChBm'
    'b3JtX3RlbXBlcmF0dXJlGBIgASgCSBFSD2Zvcm1UZW1wZXJhdHVyZYgBARIoCg1wbTQwX3N0YW'
    '5kYXJkGBMgASgNSBJSDHBtNDBTdGFuZGFyZIgBARIqCg5wYXJ0aWNsZXNfNDB1bRgUIAEoDUgT'
    'Ug1wYXJ0aWNsZXM0MHVtiAEBEioKDnBtX3RlbXBlcmF0dXJlGBUgASgCSBRSDXBtVGVtcGVyYX'
    'R1cmWIAQESJAoLcG1faHVtaWRpdHkYFiABKAJIFVIKcG1IdW1pZGl0eYgBARIhCgpwbV92b2Nf'
    'aWR4GBcgASgCSBZSCHBtVm9jSWR4iAEBEiEKCnBtX25veF9pZHgYGCABKAJIF1IIcG1Ob3hJZH'
    'iIAQESKAoNcGFydGljbGVzX3RwcxgZIAEoAkgYUgxwYXJ0aWNsZXNUcHOIAQFCEAoOX3BtMTBf'
    'c3RhbmRhcmRCEAoOX3BtMjVfc3RhbmRhcmRCEQoPX3BtMTAwX3N0YW5kYXJkQhUKE19wbTEwX2'
    'Vudmlyb25tZW50YWxCFQoTX3BtMjVfZW52aXJvbm1lbnRhbEIWChRfcG0xMDBfZW52aXJvbm1l'
    'bnRhbEIRCg9fcGFydGljbGVzXzAzdW1CEQoPX3BhcnRpY2xlc18wNXVtQhEKD19wYXJ0aWNsZX'
    'NfMTB1bUIRCg9fcGFydGljbGVzXzI1dW1CEQoPX3BhcnRpY2xlc181MHVtQhIKEF9wYXJ0aWNs'
    'ZXNfMTAwdW1CBgoEX2NvMkISChBfY28yX3RlbXBlcmF0dXJlQg8KDV9jbzJfaHVtaWRpdHlCFA'
    'oSX2Zvcm1fZm9ybWFsZGVoeWRlQhAKDl9mb3JtX2h1bWlkaXR5QhMKEV9mb3JtX3RlbXBlcmF0'
    'dXJlQhAKDl9wbTQwX3N0YW5kYXJkQhEKD19wYXJ0aWNsZXNfNDB1bUIRCg9fcG1fdGVtcGVyYX'
    'R1cmVCDgoMX3BtX2h1bWlkaXR5Qg0KC19wbV92b2NfaWR4Qg0KC19wbV9ub3hfaWR4QhAKDl9w'
    'YXJ0aWNsZXNfdHBz');

@$core.Deprecated('Use localStatsDescriptor instead')
const LocalStats$json = {
  '1': 'LocalStats',
  '2': [
    {'1': 'uptime_seconds', '3': 1, '4': 1, '5': 13, '10': 'uptimeSeconds'},
    {
      '1': 'channel_utilization',
      '3': 2,
      '4': 1,
      '5': 2,
      '10': 'channelUtilization'
    },
    {'1': 'air_util_tx', '3': 3, '4': 1, '5': 2, '10': 'airUtilTx'},
    {'1': 'num_packets_tx', '3': 4, '4': 1, '5': 13, '10': 'numPacketsTx'},
    {'1': 'num_packets_rx', '3': 5, '4': 1, '5': 13, '10': 'numPacketsRx'},
    {
      '1': 'num_packets_rx_bad',
      '3': 6,
      '4': 1,
      '5': 13,
      '10': 'numPacketsRxBad'
    },
    {'1': 'num_online_nodes', '3': 7, '4': 1, '5': 13, '10': 'numOnlineNodes'},
    {'1': 'num_total_nodes', '3': 8, '4': 1, '5': 13, '10': 'numTotalNodes'},
    {'1': 'num_rx_dupe', '3': 9, '4': 1, '5': 13, '10': 'numRxDupe'},
    {'1': 'num_tx_relay', '3': 10, '4': 1, '5': 13, '10': 'numTxRelay'},
    {
      '1': 'num_tx_relay_canceled',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'numTxRelayCanceled'
    },
    {'1': 'heap_total_bytes', '3': 12, '4': 1, '5': 13, '10': 'heapTotalBytes'},
    {'1': 'heap_free_bytes', '3': 13, '4': 1, '5': 13, '10': 'heapFreeBytes'},
  ],
};

/// Descriptor for `LocalStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localStatsDescriptor = $convert.base64Decode(
    'CgpMb2NhbFN0YXRzEiUKDnVwdGltZV9zZWNvbmRzGAEgASgNUg11cHRpbWVTZWNvbmRzEi8KE2'
    'NoYW5uZWxfdXRpbGl6YXRpb24YAiABKAJSEmNoYW5uZWxVdGlsaXphdGlvbhIeCgthaXJfdXRp'
    'bF90eBgDIAEoAlIJYWlyVXRpbFR4EiQKDm51bV9wYWNrZXRzX3R4GAQgASgNUgxudW1QYWNrZX'
    'RzVHgSJAoObnVtX3BhY2tldHNfcngYBSABKA1SDG51bVBhY2tldHNSeBIrChJudW1fcGFja2V0'
    'c19yeF9iYWQYBiABKA1SD251bVBhY2tldHNSeEJhZBIoChBudW1fb25saW5lX25vZGVzGAcgAS'
    'gNUg5udW1PbmxpbmVOb2RlcxImCg9udW1fdG90YWxfbm9kZXMYCCABKA1SDW51bVRvdGFsTm9k'
    'ZXMSHgoLbnVtX3J4X2R1cGUYCSABKA1SCW51bVJ4RHVwZRIgCgxudW1fdHhfcmVsYXkYCiABKA'
    '1SCm51bVR4UmVsYXkSMQoVbnVtX3R4X3JlbGF5X2NhbmNlbGVkGAsgASgNUhJudW1UeFJlbGF5'
    'Q2FuY2VsZWQSKAoQaGVhcF90b3RhbF9ieXRlcxgMIAEoDVIOaGVhcFRvdGFsQnl0ZXMSJgoPaG'
    'VhcF9mcmVlX2J5dGVzGA0gASgNUg1oZWFwRnJlZUJ5dGVz');

@$core.Deprecated('Use healthMetricsDescriptor instead')
const HealthMetrics$json = {
  '1': 'HealthMetrics',
  '2': [
    {
      '1': 'heart_bpm',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'heartBpm',
      '17': true
    },
    {'1': 'spO2', '3': 2, '4': 1, '5': 13, '9': 1, '10': 'spO2', '17': true},
    {
      '1': 'temperature',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'temperature',
      '17': true
    },
  ],
  '8': [
    {'1': '_heart_bpm'},
    {'1': '_spO2'},
    {'1': '_temperature'},
  ],
};

/// Descriptor for `HealthMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthMetricsDescriptor = $convert.base64Decode(
    'Cg1IZWFsdGhNZXRyaWNzEiAKCWhlYXJ0X2JwbRgBIAEoDUgAUghoZWFydEJwbYgBARIXCgRzcE'
    '8yGAIgASgNSAFSBHNwTzKIAQESJQoLdGVtcGVyYXR1cmUYAyABKAJIAlILdGVtcGVyYXR1cmWI'
    'AQFCDAoKX2hlYXJ0X2JwbUIHCgVfc3BPMkIOCgxfdGVtcGVyYXR1cmU=');

@$core.Deprecated('Use hostMetricsDescriptor instead')
const HostMetrics$json = {
  '1': 'HostMetrics',
  '2': [
    {'1': 'uptime_seconds', '3': 1, '4': 1, '5': 13, '10': 'uptimeSeconds'},
    {'1': 'freemem_bytes', '3': 2, '4': 1, '5': 4, '10': 'freememBytes'},
    {'1': 'diskfree1_bytes', '3': 3, '4': 1, '5': 4, '10': 'diskfree1Bytes'},
    {
      '1': 'diskfree2_bytes',
      '3': 4,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'diskfree2Bytes',
      '17': true
    },
    {
      '1': 'diskfree3_bytes',
      '3': 5,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'diskfree3Bytes',
      '17': true
    },
    {'1': 'load1', '3': 6, '4': 1, '5': 13, '10': 'load1'},
    {'1': 'load5', '3': 7, '4': 1, '5': 13, '10': 'load5'},
    {'1': 'load15', '3': 8, '4': 1, '5': 13, '10': 'load15'},
    {
      '1': 'user_string',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'userString',
      '17': true
    },
  ],
  '8': [
    {'1': '_diskfree2_bytes'},
    {'1': '_diskfree3_bytes'},
    {'1': '_user_string'},
  ],
};

/// Descriptor for `HostMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostMetricsDescriptor = $convert.base64Decode(
    'CgtIb3N0TWV0cmljcxIlCg51cHRpbWVfc2Vjb25kcxgBIAEoDVINdXB0aW1lU2Vjb25kcxIjCg'
    '1mcmVlbWVtX2J5dGVzGAIgASgEUgxmcmVlbWVtQnl0ZXMSJwoPZGlza2ZyZWUxX2J5dGVzGAMg'
    'ASgEUg5kaXNrZnJlZTFCeXRlcxIsCg9kaXNrZnJlZTJfYnl0ZXMYBCABKARIAFIOZGlza2ZyZW'
    'UyQnl0ZXOIAQESLAoPZGlza2ZyZWUzX2J5dGVzGAUgASgESAFSDmRpc2tmcmVlM0J5dGVziAEB'
    'EhQKBWxvYWQxGAYgASgNUgVsb2FkMRIUCgVsb2FkNRgHIAEoDVIFbG9hZDUSFgoGbG9hZDE1GA'
    'ggASgNUgZsb2FkMTUSJAoLdXNlcl9zdHJpbmcYCSABKAlIAlIKdXNlclN0cmluZ4gBAUISChBf'
    'ZGlza2ZyZWUyX2J5dGVzQhIKEF9kaXNrZnJlZTNfYnl0ZXNCDgoMX3VzZXJfc3RyaW5n');

@$core.Deprecated('Use telemetryDescriptor instead')
const Telemetry$json = {
  '1': 'Telemetry',
  '2': [
    {'1': 'time', '3': 1, '4': 1, '5': 7, '10': 'time'},
    {
      '1': 'device_metrics',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceMetrics',
      '9': 0,
      '10': 'deviceMetrics'
    },
    {
      '1': 'environment_metrics',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.EnvironmentMetrics',
      '9': 0,
      '10': 'environmentMetrics'
    },
    {
      '1': 'air_quality_metrics',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.AirQualityMetrics',
      '9': 0,
      '10': 'airQualityMetrics'
    },
    {
      '1': 'power_metrics',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.PowerMetrics',
      '9': 0,
      '10': 'powerMetrics'
    },
    {
      '1': 'local_stats',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.LocalStats',
      '9': 0,
      '10': 'localStats'
    },
    {
      '1': 'health_metrics',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.HealthMetrics',
      '9': 0,
      '10': 'healthMetrics'
    },
    {
      '1': 'host_metrics',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.HostMetrics',
      '9': 0,
      '10': 'hostMetrics'
    },
  ],
  '8': [
    {'1': 'variant'},
  ],
};

/// Descriptor for `Telemetry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetryDescriptor = $convert.base64Decode(
    'CglUZWxlbWV0cnkSEgoEdGltZRgBIAEoB1IEdGltZRJCCg5kZXZpY2VfbWV0cmljcxgCIAEoCz'
    'IZLm1lc2h0YXN0aWMuRGV2aWNlTWV0cmljc0gAUg1kZXZpY2VNZXRyaWNzElEKE2Vudmlyb25t'
    'ZW50X21ldHJpY3MYAyABKAsyHi5tZXNodGFzdGljLkVudmlyb25tZW50TWV0cmljc0gAUhJlbn'
    'Zpcm9ubWVudE1ldHJpY3MSTwoTYWlyX3F1YWxpdHlfbWV0cmljcxgEIAEoCzIdLm1lc2h0YXN0'
    'aWMuQWlyUXVhbGl0eU1ldHJpY3NIAFIRYWlyUXVhbGl0eU1ldHJpY3MSPwoNcG93ZXJfbWV0cm'
    'ljcxgFIAEoCzIYLm1lc2h0YXN0aWMuUG93ZXJNZXRyaWNzSABSDHBvd2VyTWV0cmljcxI5Cgts'
    'b2NhbF9zdGF0cxgGIAEoCzIWLm1lc2h0YXN0aWMuTG9jYWxTdGF0c0gAUgpsb2NhbFN0YXRzEk'
    'IKDmhlYWx0aF9tZXRyaWNzGAcgASgLMhkubWVzaHRhc3RpYy5IZWFsdGhNZXRyaWNzSABSDWhl'
    'YWx0aE1ldHJpY3MSPAoMaG9zdF9tZXRyaWNzGAggASgLMhcubWVzaHRhc3RpYy5Ib3N0TWV0cm'
    'ljc0gAUgtob3N0TWV0cmljc0IJCgd2YXJpYW50');

@$core.Deprecated('Use nau7802ConfigDescriptor instead')
const Nau7802Config$json = {
  '1': 'Nau7802Config',
  '2': [
    {'1': 'zeroOffset', '3': 1, '4': 1, '5': 5, '10': 'zeroOffset'},
    {
      '1': 'calibrationFactor',
      '3': 2,
      '4': 1,
      '5': 2,
      '10': 'calibrationFactor'
    },
  ],
};

/// Descriptor for `Nau7802Config`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nau7802ConfigDescriptor = $convert.base64Decode(
    'Cg1OYXU3ODAyQ29uZmlnEh4KCnplcm9PZmZzZXQYASABKAVSCnplcm9PZmZzZXQSLAoRY2FsaW'
    'JyYXRpb25GYWN0b3IYAiABKAJSEWNhbGlicmF0aW9uRmFjdG9y');
