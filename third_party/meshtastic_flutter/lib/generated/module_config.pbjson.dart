// This is a generated file - do not edit.
//
// Generated from meshtastic/module_config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use remoteHardwarePinTypeDescriptor instead')
const RemoteHardwarePinType$json = {
  '1': 'RemoteHardwarePinType',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'DIGITAL_READ', '2': 1},
    {'1': 'DIGITAL_WRITE', '2': 2},
  ],
};

/// Descriptor for `RemoteHardwarePinType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List remoteHardwarePinTypeDescriptor = $convert.base64Decode(
    'ChVSZW1vdGVIYXJkd2FyZVBpblR5cGUSCwoHVU5LTk9XThAAEhAKDERJR0lUQUxfUkVBRBABEh'
    'EKDURJR0lUQUxfV1JJVEUQAg==');

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig$json = {
  '1': 'ModuleConfig',
  '2': [
    {
      '1': 'mqtt',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.MQTTConfig',
      '9': 0,
      '10': 'mqtt'
    },
    {
      '1': 'serial',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.SerialConfig',
      '9': 0,
      '10': 'serial'
    },
    {
      '1': 'external_notification',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.ExternalNotificationConfig',
      '9': 0,
      '10': 'externalNotification'
    },
    {
      '1': 'store_forward',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.StoreForwardConfig',
      '9': 0,
      '10': 'storeForward'
    },
    {
      '1': 'range_test',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.RangeTestConfig',
      '9': 0,
      '10': 'rangeTest'
    },
    {
      '1': 'telemetry',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.TelemetryConfig',
      '9': 0,
      '10': 'telemetry'
    },
    {
      '1': 'canned_message',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.CannedMessageConfig',
      '9': 0,
      '10': 'cannedMessage'
    },
    {
      '1': 'audio',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.AudioConfig',
      '9': 0,
      '10': 'audio'
    },
    {
      '1': 'remote_hardware',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.RemoteHardwareConfig',
      '9': 0,
      '10': 'remoteHardware'
    },
    {
      '1': 'neighbor_info',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.NeighborInfoConfig',
      '9': 0,
      '10': 'neighborInfo'
    },
    {
      '1': 'ambient_lighting',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.AmbientLightingConfig',
      '9': 0,
      '10': 'ambientLighting'
    },
    {
      '1': 'detection_sensor',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.DetectionSensorConfig',
      '9': 0,
      '10': 'detectionSensor'
    },
    {
      '1': 'paxcounter',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.PaxcounterConfig',
      '9': 0,
      '10': 'paxcounter'
    },
  ],
  '3': [
    ModuleConfig_MQTTConfig$json,
    ModuleConfig_MapReportSettings$json,
    ModuleConfig_RemoteHardwareConfig$json,
    ModuleConfig_NeighborInfoConfig$json,
    ModuleConfig_DetectionSensorConfig$json,
    ModuleConfig_AudioConfig$json,
    ModuleConfig_PaxcounterConfig$json,
    ModuleConfig_SerialConfig$json,
    ModuleConfig_ExternalNotificationConfig$json,
    ModuleConfig_StoreForwardConfig$json,
    ModuleConfig_RangeTestConfig$json,
    ModuleConfig_TelemetryConfig$json,
    ModuleConfig_CannedMessageConfig$json,
    ModuleConfig_AmbientLightingConfig$json
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_MQTTConfig$json = {
  '1': 'MQTTConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 4, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'encryption_enabled',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'encryptionEnabled'
    },
    {'1': 'json_enabled', '3': 6, '4': 1, '5': 8, '10': 'jsonEnabled'},
    {'1': 'tls_enabled', '3': 7, '4': 1, '5': 8, '10': 'tlsEnabled'},
    {'1': 'root', '3': 8, '4': 1, '5': 9, '10': 'root'},
    {
      '1': 'proxy_to_client_enabled',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'proxyToClientEnabled'
    },
    {
      '1': 'map_reporting_enabled',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'mapReportingEnabled'
    },
    {
      '1': 'map_report_settings',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig.MapReportSettings',
      '10': 'mapReportSettings'
    },
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_MapReportSettings$json = {
  '1': 'MapReportSettings',
  '2': [
    {
      '1': 'publish_interval_secs',
      '3': 1,
      '4': 1,
      '5': 13,
      '10': 'publishIntervalSecs'
    },
    {
      '1': 'position_precision',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'positionPrecision'
    },
    {
      '1': 'should_report_location',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'shouldReportLocation'
    },
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_RemoteHardwareConfig$json = {
  '1': 'RemoteHardwareConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'allow_undefined_pin_access',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'allowUndefinedPinAccess'
    },
    {
      '1': 'available_pins',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.meshtastic.RemoteHardwarePin',
      '10': 'availablePins'
    },
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_NeighborInfoConfig$json = {
  '1': 'NeighborInfoConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'update_interval', '3': 2, '4': 1, '5': 13, '10': 'updateInterval'},
    {
      '1': 'transmit_over_lora',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'transmitOverLora'
    },
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_DetectionSensorConfig$json = {
  '1': 'DetectionSensorConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'minimum_broadcast_secs',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'minimumBroadcastSecs'
    },
    {
      '1': 'state_broadcast_secs',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'stateBroadcastSecs'
    },
    {'1': 'send_bell', '3': 4, '4': 1, '5': 8, '10': 'sendBell'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'monitor_pin', '3': 6, '4': 1, '5': 13, '10': 'monitorPin'},
    {
      '1': 'detection_trigger_type',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.DetectionSensorConfig.TriggerType',
      '10': 'detectionTriggerType'
    },
    {'1': 'use_pullup', '3': 8, '4': 1, '5': 8, '10': 'usePullup'},
  ],
  '4': [ModuleConfig_DetectionSensorConfig_TriggerType$json],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_DetectionSensorConfig_TriggerType$json = {
  '1': 'TriggerType',
  '2': [
    {'1': 'LOGIC_LOW', '2': 0},
    {'1': 'LOGIC_HIGH', '2': 1},
    {'1': 'FALLING_EDGE', '2': 2},
    {'1': 'RISING_EDGE', '2': 3},
    {'1': 'EITHER_EDGE_ACTIVE_LOW', '2': 4},
    {'1': 'EITHER_EDGE_ACTIVE_HIGH', '2': 5},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_AudioConfig$json = {
  '1': 'AudioConfig',
  '2': [
    {'1': 'codec2_enabled', '3': 1, '4': 1, '5': 8, '10': 'codec2Enabled'},
    {'1': 'ptt_pin', '3': 2, '4': 1, '5': 13, '10': 'pttPin'},
    {
      '1': 'bitrate',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.AudioConfig.Audio_Baud',
      '10': 'bitrate'
    },
    {'1': 'i2s_ws', '3': 4, '4': 1, '5': 13, '10': 'i2sWs'},
    {'1': 'i2s_sd', '3': 5, '4': 1, '5': 13, '10': 'i2sSd'},
    {'1': 'i2s_din', '3': 6, '4': 1, '5': 13, '10': 'i2sDin'},
    {'1': 'i2s_sck', '3': 7, '4': 1, '5': 13, '10': 'i2sSck'},
  ],
  '4': [ModuleConfig_AudioConfig_Audio_Baud$json],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_AudioConfig_Audio_Baud$json = {
  '1': 'Audio_Baud',
  '2': [
    {'1': 'CODEC2_DEFAULT', '2': 0},
    {'1': 'CODEC2_3200', '2': 1},
    {'1': 'CODEC2_2400', '2': 2},
    {'1': 'CODEC2_1600', '2': 3},
    {'1': 'CODEC2_1400', '2': 4},
    {'1': 'CODEC2_1300', '2': 5},
    {'1': 'CODEC2_1200', '2': 6},
    {'1': 'CODEC2_700', '2': 7},
    {'1': 'CODEC2_700B', '2': 8},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_PaxcounterConfig$json = {
  '1': 'PaxcounterConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'paxcounter_update_interval',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'paxcounterUpdateInterval'
    },
    {'1': 'wifi_threshold', '3': 3, '4': 1, '5': 5, '10': 'wifiThreshold'},
    {'1': 'ble_threshold', '3': 4, '4': 1, '5': 5, '10': 'bleThreshold'},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_SerialConfig$json = {
  '1': 'SerialConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'echo', '3': 2, '4': 1, '5': 8, '10': 'echo'},
    {'1': 'rxd', '3': 3, '4': 1, '5': 13, '10': 'rxd'},
    {'1': 'txd', '3': 4, '4': 1, '5': 13, '10': 'txd'},
    {
      '1': 'baud',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.SerialConfig.Serial_Baud',
      '10': 'baud'
    },
    {'1': 'timeout', '3': 6, '4': 1, '5': 13, '10': 'timeout'},
    {
      '1': 'mode',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.SerialConfig.Serial_Mode',
      '10': 'mode'
    },
    {
      '1': 'override_console_serial_port',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'overrideConsoleSerialPort'
    },
  ],
  '4': [
    ModuleConfig_SerialConfig_Serial_Baud$json,
    ModuleConfig_SerialConfig_Serial_Mode$json
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_SerialConfig_Serial_Baud$json = {
  '1': 'Serial_Baud',
  '2': [
    {'1': 'BAUD_DEFAULT', '2': 0},
    {'1': 'BAUD_110', '2': 1},
    {'1': 'BAUD_300', '2': 2},
    {'1': 'BAUD_600', '2': 3},
    {'1': 'BAUD_1200', '2': 4},
    {'1': 'BAUD_2400', '2': 5},
    {'1': 'BAUD_4800', '2': 6},
    {'1': 'BAUD_9600', '2': 7},
    {'1': 'BAUD_19200', '2': 8},
    {'1': 'BAUD_38400', '2': 9},
    {'1': 'BAUD_57600', '2': 10},
    {'1': 'BAUD_115200', '2': 11},
    {'1': 'BAUD_230400', '2': 12},
    {'1': 'BAUD_460800', '2': 13},
    {'1': 'BAUD_576000', '2': 14},
    {'1': 'BAUD_921600', '2': 15},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_SerialConfig_Serial_Mode$json = {
  '1': 'Serial_Mode',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'SIMPLE', '2': 1},
    {'1': 'PROTO', '2': 2},
    {'1': 'TEXTMSG', '2': 3},
    {'1': 'NMEA', '2': 4},
    {'1': 'CALTOPO', '2': 5},
    {'1': 'WS85', '2': 6},
    {'1': 'VE_DIRECT', '2': 7},
    {'1': 'MS_CONFIG', '2': 8},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_ExternalNotificationConfig$json = {
  '1': 'ExternalNotificationConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'output_ms', '3': 2, '4': 1, '5': 13, '10': 'outputMs'},
    {'1': 'output', '3': 3, '4': 1, '5': 13, '10': 'output'},
    {'1': 'output_vibra', '3': 8, '4': 1, '5': 13, '10': 'outputVibra'},
    {'1': 'output_buzzer', '3': 9, '4': 1, '5': 13, '10': 'outputBuzzer'},
    {'1': 'active', '3': 4, '4': 1, '5': 8, '10': 'active'},
    {'1': 'alert_message', '3': 5, '4': 1, '5': 8, '10': 'alertMessage'},
    {
      '1': 'alert_message_vibra',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'alertMessageVibra'
    },
    {
      '1': 'alert_message_buzzer',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'alertMessageBuzzer'
    },
    {'1': 'alert_bell', '3': 6, '4': 1, '5': 8, '10': 'alertBell'},
    {'1': 'alert_bell_vibra', '3': 12, '4': 1, '5': 8, '10': 'alertBellVibra'},
    {
      '1': 'alert_bell_buzzer',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'alertBellBuzzer'
    },
    {'1': 'use_pwm', '3': 7, '4': 1, '5': 8, '10': 'usePwm'},
    {'1': 'nag_timeout', '3': 14, '4': 1, '5': 13, '10': 'nagTimeout'},
    {'1': 'use_i2s_as_buzzer', '3': 15, '4': 1, '5': 8, '10': 'useI2sAsBuzzer'},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_StoreForwardConfig$json = {
  '1': 'StoreForwardConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'heartbeat', '3': 2, '4': 1, '5': 8, '10': 'heartbeat'},
    {'1': 'records', '3': 3, '4': 1, '5': 13, '10': 'records'},
    {
      '1': 'history_return_max',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'historyReturnMax'
    },
    {
      '1': 'history_return_window',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'historyReturnWindow'
    },
    {'1': 'is_server', '3': 6, '4': 1, '5': 8, '10': 'isServer'},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_RangeTestConfig$json = {
  '1': 'RangeTestConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'sender', '3': 2, '4': 1, '5': 13, '10': 'sender'},
    {'1': 'save', '3': 3, '4': 1, '5': 8, '10': 'save'},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_TelemetryConfig$json = {
  '1': 'TelemetryConfig',
  '2': [
    {
      '1': 'device_update_interval',
      '3': 1,
      '4': 1,
      '5': 13,
      '10': 'deviceUpdateInterval'
    },
    {
      '1': 'environment_update_interval',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'environmentUpdateInterval'
    },
    {
      '1': 'environment_measurement_enabled',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'environmentMeasurementEnabled'
    },
    {
      '1': 'environment_screen_enabled',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'environmentScreenEnabled'
    },
    {
      '1': 'environment_display_fahrenheit',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'environmentDisplayFahrenheit'
    },
    {
      '1': 'air_quality_enabled',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'airQualityEnabled'
    },
    {
      '1': 'air_quality_interval',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'airQualityInterval'
    },
    {
      '1': 'power_measurement_enabled',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'powerMeasurementEnabled'
    },
    {
      '1': 'power_update_interval',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'powerUpdateInterval'
    },
    {
      '1': 'power_screen_enabled',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'powerScreenEnabled'
    },
    {
      '1': 'health_measurement_enabled',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'healthMeasurementEnabled'
    },
    {
      '1': 'health_update_interval',
      '3': 12,
      '4': 1,
      '5': 13,
      '10': 'healthUpdateInterval'
    },
    {
      '1': 'health_screen_enabled',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'healthScreenEnabled'
    },
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_CannedMessageConfig$json = {
  '1': 'CannedMessageConfig',
  '2': [
    {'1': 'rotary1_enabled', '3': 1, '4': 1, '5': 8, '10': 'rotary1Enabled'},
    {
      '1': 'inputbroker_pin_a',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'inputbrokerPinA'
    },
    {
      '1': 'inputbroker_pin_b',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'inputbrokerPinB'
    },
    {
      '1': 'inputbroker_pin_press',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'inputbrokerPinPress'
    },
    {
      '1': 'inputbroker_event_cw',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.CannedMessageConfig.InputEventChar',
      '10': 'inputbrokerEventCw'
    },
    {
      '1': 'inputbroker_event_ccw',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.CannedMessageConfig.InputEventChar',
      '10': 'inputbrokerEventCcw'
    },
    {
      '1': 'inputbroker_event_press',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.ModuleConfig.CannedMessageConfig.InputEventChar',
      '10': 'inputbrokerEventPress'
    },
    {'1': 'updown1_enabled', '3': 8, '4': 1, '5': 8, '10': 'updown1Enabled'},
    {
      '1': 'enabled',
      '3': 9,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'enabled',
    },
    {
      '1': 'allow_input_source',
      '3': 10,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'allowInputSource',
    },
    {'1': 'send_bell', '3': 11, '4': 1, '5': 8, '10': 'sendBell'},
  ],
  '4': [ModuleConfig_CannedMessageConfig_InputEventChar$json],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_CannedMessageConfig_InputEventChar$json = {
  '1': 'InputEventChar',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'UP', '2': 17},
    {'1': 'DOWN', '2': 18},
    {'1': 'LEFT', '2': 19},
    {'1': 'RIGHT', '2': 20},
    {'1': 'SELECT', '2': 10},
    {'1': 'BACK', '2': 27},
    {'1': 'CANCEL', '2': 24},
  ],
};

@$core.Deprecated('Use moduleConfigDescriptor instead')
const ModuleConfig_AmbientLightingConfig$json = {
  '1': 'AmbientLightingConfig',
  '2': [
    {'1': 'led_state', '3': 1, '4': 1, '5': 8, '10': 'ledState'},
    {'1': 'current', '3': 2, '4': 1, '5': 13, '10': 'current'},
    {'1': 'red', '3': 3, '4': 1, '5': 13, '10': 'red'},
    {'1': 'green', '3': 4, '4': 1, '5': 13, '10': 'green'},
    {'1': 'blue', '3': 5, '4': 1, '5': 13, '10': 'blue'},
  ],
};

/// Descriptor for `ModuleConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moduleConfigDescriptor = $convert.base64Decode(
    'CgxNb2R1bGVDb25maWcSOQoEbXF0dBgBIAEoCzIjLm1lc2h0YXN0aWMuTW9kdWxlQ29uZmlnLk'
    '1RVFRDb25maWdIAFIEbXF0dBI/CgZzZXJpYWwYAiABKAsyJS5tZXNodGFzdGljLk1vZHVsZUNv'
    'bmZpZy5TZXJpYWxDb25maWdIAFIGc2VyaWFsEmoKFWV4dGVybmFsX25vdGlmaWNhdGlvbhgDIA'
    'EoCzIzLm1lc2h0YXN0aWMuTW9kdWxlQ29uZmlnLkV4dGVybmFsTm90aWZpY2F0aW9uQ29uZmln'
    'SABSFGV4dGVybmFsTm90aWZpY2F0aW9uElIKDXN0b3JlX2ZvcndhcmQYBCABKAsyKy5tZXNodG'
    'FzdGljLk1vZHVsZUNvbmZpZy5TdG9yZUZvcndhcmRDb25maWdIAFIMc3RvcmVGb3J3YXJkEkkK'
    'CnJhbmdlX3Rlc3QYBSABKAsyKC5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5SYW5nZVRlc3RDb2'
    '5maWdIAFIJcmFuZ2VUZXN0EkgKCXRlbGVtZXRyeRgGIAEoCzIoLm1lc2h0YXN0aWMuTW9kdWxl'
    'Q29uZmlnLlRlbGVtZXRyeUNvbmZpZ0gAUgl0ZWxlbWV0cnkSVQoOY2FubmVkX21lc3NhZ2UYBy'
    'ABKAsyLC5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5DYW5uZWRNZXNzYWdlQ29uZmlnSABSDWNh'
    'bm5lZE1lc3NhZ2USPAoFYXVkaW8YCCABKAsyJC5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5BdW'
    'Rpb0NvbmZpZ0gAUgVhdWRpbxJYCg9yZW1vdGVfaGFyZHdhcmUYCSABKAsyLS5tZXNodGFzdGlj'
    'Lk1vZHVsZUNvbmZpZy5SZW1vdGVIYXJkd2FyZUNvbmZpZ0gAUg5yZW1vdGVIYXJkd2FyZRJSCg'
    '1uZWlnaGJvcl9pbmZvGAogASgLMisubWVzaHRhc3RpYy5Nb2R1bGVDb25maWcuTmVpZ2hib3JJ'
    'bmZvQ29uZmlnSABSDG5laWdoYm9ySW5mbxJbChBhbWJpZW50X2xpZ2h0aW5nGAsgASgLMi4ubW'
    'VzaHRhc3RpYy5Nb2R1bGVDb25maWcuQW1iaWVudExpZ2h0aW5nQ29uZmlnSABSD2FtYmllbnRM'
    'aWdodGluZxJbChBkZXRlY3Rpb25fc2Vuc29yGAwgASgLMi4ubWVzaHRhc3RpYy5Nb2R1bGVDb2'
    '5maWcuRGV0ZWN0aW9uU2Vuc29yQ29uZmlnSABSD2RldGVjdGlvblNlbnNvchJLCgpwYXhjb3Vu'
    'dGVyGA0gASgLMikubWVzaHRhc3RpYy5Nb2R1bGVDb25maWcuUGF4Y291bnRlckNvbmZpZ0gAUg'
    'pwYXhjb3VudGVyGsYDCgpNUVRUQ29uZmlnEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSGAoH'
    'YWRkcmVzcxgCIAEoCVIHYWRkcmVzcxIaCgh1c2VybmFtZRgDIAEoCVIIdXNlcm5hbWUSGgoIcG'
    'Fzc3dvcmQYBCABKAlSCHBhc3N3b3JkEi0KEmVuY3J5cHRpb25fZW5hYmxlZBgFIAEoCFIRZW5j'
    'cnlwdGlvbkVuYWJsZWQSIQoManNvbl9lbmFibGVkGAYgASgIUgtqc29uRW5hYmxlZBIfCgt0bH'
    'NfZW5hYmxlZBgHIAEoCFIKdGxzRW5hYmxlZBISCgRyb290GAggASgJUgRyb290EjUKF3Byb3h5'
    'X3RvX2NsaWVudF9lbmFibGVkGAkgASgIUhRwcm94eVRvQ2xpZW50RW5hYmxlZBIyChVtYXBfcm'
    'Vwb3J0aW5nX2VuYWJsZWQYCiABKAhSE21hcFJlcG9ydGluZ0VuYWJsZWQSWgoTbWFwX3JlcG9y'
    'dF9zZXR0aW5ncxgLIAEoCzIqLm1lc2h0YXN0aWMuTW9kdWxlQ29uZmlnLk1hcFJlcG9ydFNldH'
    'RpbmdzUhFtYXBSZXBvcnRTZXR0aW5ncxqsAQoRTWFwUmVwb3J0U2V0dGluZ3MSMgoVcHVibGlz'
    'aF9pbnRlcnZhbF9zZWNzGAEgASgNUhNwdWJsaXNoSW50ZXJ2YWxTZWNzEi0KEnBvc2l0aW9uX3'
    'ByZWNpc2lvbhgCIAEoDVIRcG9zaXRpb25QcmVjaXNpb24SNAoWc2hvdWxkX3JlcG9ydF9sb2Nh'
    'dGlvbhgDIAEoCFIUc2hvdWxkUmVwb3J0TG9jYXRpb24aswEKFFJlbW90ZUhhcmR3YXJlQ29uZm'
    'lnEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSOwoaYWxsb3dfdW5kZWZpbmVkX3Bpbl9hY2Nl'
    'c3MYAiABKAhSF2FsbG93VW5kZWZpbmVkUGluQWNjZXNzEkQKDmF2YWlsYWJsZV9waW5zGAMgAy'
    'gLMh0ubWVzaHRhc3RpYy5SZW1vdGVIYXJkd2FyZVBpblINYXZhaWxhYmxlUGlucxqFAQoSTmVp'
    'Z2hib3JJbmZvQ29uZmlnEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSJwoPdXBkYXRlX2ludG'
    'VydmFsGAIgASgNUg51cGRhdGVJbnRlcnZhbBIsChJ0cmFuc21pdF9vdmVyX2xvcmEYAyABKAhS'
    'EHRyYW5zbWl0T3ZlckxvcmEahwQKFURldGVjdGlvblNlbnNvckNvbmZpZxIYCgdlbmFibGVkGA'
    'EgASgIUgdlbmFibGVkEjQKFm1pbmltdW1fYnJvYWRjYXN0X3NlY3MYAiABKA1SFG1pbmltdW1C'
    'cm9hZGNhc3RTZWNzEjAKFHN0YXRlX2Jyb2FkY2FzdF9zZWNzGAMgASgNUhJzdGF0ZUJyb2FkY2'
    'FzdFNlY3MSGwoJc2VuZF9iZWxsGAQgASgIUghzZW5kQmVsbBISCgRuYW1lGAUgASgJUgRuYW1l'
    'Eh8KC21vbml0b3JfcGluGAYgASgNUgptb25pdG9yUGluEnAKFmRldGVjdGlvbl90cmlnZ2VyX3'
    'R5cGUYByABKA4yOi5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5EZXRlY3Rpb25TZW5zb3JDb25m'
    'aWcuVHJpZ2dlclR5cGVSFGRldGVjdGlvblRyaWdnZXJUeXBlEh0KCnVzZV9wdWxsdXAYCCABKA'
    'hSCXVzZVB1bGx1cCKIAQoLVHJpZ2dlclR5cGUSDQoJTE9HSUNfTE9XEAASDgoKTE9HSUNfSElH'
    'SBABEhAKDEZBTExJTkdfRURHRRACEg8KC1JJU0lOR19FREdFEAMSGgoWRUlUSEVSX0VER0VfQU'
    'NUSVZFX0xPVxAEEhsKF0VJVEhFUl9FREdFX0FDVElWRV9ISUdIEAUaogMKC0F1ZGlvQ29uZmln'
    'EiUKDmNvZGVjMl9lbmFibGVkGAEgASgIUg1jb2RlYzJFbmFibGVkEhcKB3B0dF9waW4YAiABKA'
    '1SBnB0dFBpbhJJCgdiaXRyYXRlGAMgASgOMi8ubWVzaHRhc3RpYy5Nb2R1bGVDb25maWcuQXVk'
    'aW9Db25maWcuQXVkaW9fQmF1ZFIHYml0cmF0ZRIVCgZpMnNfd3MYBCABKA1SBWkyc1dzEhUKBm'
    'kyc19zZBgFIAEoDVIFaTJzU2QSFwoHaTJzX2RpbhgGIAEoDVIGaTJzRGluEhcKB2kyc19zY2sY'
    'ByABKA1SBmkyc1NjayKnAQoKQXVkaW9fQmF1ZBISCg5DT0RFQzJfREVGQVVMVBAAEg8KC0NPRE'
    'VDMl8zMjAwEAESDwoLQ09ERUMyXzI0MDAQAhIPCgtDT0RFQzJfMTYwMBADEg8KC0NPREVDMl8x'
    'NDAwEAQSDwoLQ09ERUMyXzEzMDAQBRIPCgtDT0RFQzJfMTIwMBAGEg4KCkNPREVDMl83MDAQBx'
    'IPCgtDT0RFQzJfNzAwQhAIGrYBChBQYXhjb3VudGVyQ29uZmlnEhgKB2VuYWJsZWQYASABKAhS'
    'B2VuYWJsZWQSPAoacGF4Y291bnRlcl91cGRhdGVfaW50ZXJ2YWwYAiABKA1SGHBheGNvdW50ZX'
    'JVcGRhdGVJbnRlcnZhbBIlCg53aWZpX3RocmVzaG9sZBgDIAEoBVINd2lmaVRocmVzaG9sZBIj'
    'Cg1ibGVfdGhyZXNob2xkGAQgASgFUgxibGVUaHJlc2hvbGQa1QUKDFNlcmlhbENvbmZpZxIYCg'
    'dlbmFibGVkGAEgASgIUgdlbmFibGVkEhIKBGVjaG8YAiABKAhSBGVjaG8SEAoDcnhkGAMgASgN'
    'UgNyeGQSEAoDdHhkGAQgASgNUgN0eGQSRQoEYmF1ZBgFIAEoDjIxLm1lc2h0YXN0aWMuTW9kdW'
    'xlQ29uZmlnLlNlcmlhbENvbmZpZy5TZXJpYWxfQmF1ZFIEYmF1ZBIYCgd0aW1lb3V0GAYgASgN'
    'Ugd0aW1lb3V0EkUKBG1vZGUYByABKA4yMS5tZXNodGFzdGljLk1vZHVsZUNvbmZpZy5TZXJpYW'
    'xDb25maWcuU2VyaWFsX01vZGVSBG1vZGUSPwocb3ZlcnJpZGVfY29uc29sZV9zZXJpYWxfcG9y'
    'dBgIIAEoCFIZb3ZlcnJpZGVDb25zb2xlU2VyaWFsUG9ydCKKAgoLU2VyaWFsX0JhdWQSEAoMQk'
    'FVRF9ERUZBVUxUEAASDAoIQkFVRF8xMTAQARIMCghCQVVEXzMwMBACEgwKCEJBVURfNjAwEAMS'
    'DQoJQkFVRF8xMjAwEAQSDQoJQkFVRF8yNDAwEAUSDQoJQkFVRF80ODAwEAYSDQoJQkFVRF85Nj'
    'AwEAcSDgoKQkFVRF8xOTIwMBAIEg4KCkJBVURfMzg0MDAQCRIOCgpCQVVEXzU3NjAwEAoSDwoL'
    'QkFVRF8xMTUyMDAQCxIPCgtCQVVEXzIzMDQwMBAMEg8KC0JBVURfNDYwODAwEA0SDwoLQkFVRF'
    '81NzYwMDAQDhIPCgtCQVVEXzkyMTYwMBAPIn0KC1NlcmlhbF9Nb2RlEgsKB0RFRkFVTFQQABIK'
    'CgZTSU1QTEUQARIJCgVQUk9UTxACEgsKB1RFWFRNU0cQAxIICgROTUVBEAQSCwoHQ0FMVE9QTx'
    'AFEggKBFdTODUQBhINCglWRV9ESVJFQ1QQBxINCglNU19DT05GSUcQCBqsBAoaRXh0ZXJuYWxO'
    'b3RpZmljYXRpb25Db25maWcSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIbCglvdXRwdXRfbX'
    'MYAiABKA1SCG91dHB1dE1zEhYKBm91dHB1dBgDIAEoDVIGb3V0cHV0EiEKDG91dHB1dF92aWJy'
    'YRgIIAEoDVILb3V0cHV0VmlicmESIwoNb3V0cHV0X2J1enplchgJIAEoDVIMb3V0cHV0QnV6em'
    'VyEhYKBmFjdGl2ZRgEIAEoCFIGYWN0aXZlEiMKDWFsZXJ0X21lc3NhZ2UYBSABKAhSDGFsZXJ0'
    'TWVzc2FnZRIuChNhbGVydF9tZXNzYWdlX3ZpYnJhGAogASgIUhFhbGVydE1lc3NhZ2VWaWJyYR'
    'IwChRhbGVydF9tZXNzYWdlX2J1enplchgLIAEoCFISYWxlcnRNZXNzYWdlQnV6emVyEh0KCmFs'
    'ZXJ0X2JlbGwYBiABKAhSCWFsZXJ0QmVsbBIoChBhbGVydF9iZWxsX3ZpYnJhGAwgASgIUg5hbG'
    'VydEJlbGxWaWJyYRIqChFhbGVydF9iZWxsX2J1enplchgNIAEoCFIPYWxlcnRCZWxsQnV6emVy'
    'EhcKB3VzZV9wd20YByABKAhSBnVzZVB3bRIfCgtuYWdfdGltZW91dBgOIAEoDVIKbmFnVGltZW'
    '91dBIpChF1c2VfaTJzX2FzX2J1enplchgPIAEoCFIOdXNlSTJzQXNCdXp6ZXIa5QEKElN0b3Jl'
    'Rm9yd2FyZENvbmZpZxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEhwKCWhlYXJ0YmVhdBgCIA'
    'EoCFIJaGVhcnRiZWF0EhgKB3JlY29yZHMYAyABKA1SB3JlY29yZHMSLAoSaGlzdG9yeV9yZXR1'
    'cm5fbWF4GAQgASgNUhBoaXN0b3J5UmV0dXJuTWF4EjIKFWhpc3RvcnlfcmV0dXJuX3dpbmRvdx'
    'gFIAEoDVITaGlzdG9yeVJldHVybldpbmRvdxIbCglpc19zZXJ2ZXIYBiABKAhSCGlzU2VydmVy'
    'GlcKD1JhbmdlVGVzdENvbmZpZxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEhYKBnNlbmRlch'
    'gCIAEoDVIGc2VuZGVyEhIKBHNhdmUYAyABKAhSBHNhdmUa/wUKD1RlbGVtZXRyeUNvbmZpZxI0'
    'ChZkZXZpY2VfdXBkYXRlX2ludGVydmFsGAEgASgNUhRkZXZpY2VVcGRhdGVJbnRlcnZhbBI+Ch'
    'tlbnZpcm9ubWVudF91cGRhdGVfaW50ZXJ2YWwYAiABKA1SGWVudmlyb25tZW50VXBkYXRlSW50'
    'ZXJ2YWwSRgofZW52aXJvbm1lbnRfbWVhc3VyZW1lbnRfZW5hYmxlZBgDIAEoCFIdZW52aXJvbm'
    '1lbnRNZWFzdXJlbWVudEVuYWJsZWQSPAoaZW52aXJvbm1lbnRfc2NyZWVuX2VuYWJsZWQYBCAB'
    'KAhSGGVudmlyb25tZW50U2NyZWVuRW5hYmxlZBJECh5lbnZpcm9ubWVudF9kaXNwbGF5X2ZhaH'
    'JlbmhlaXQYBSABKAhSHGVudmlyb25tZW50RGlzcGxheUZhaHJlbmhlaXQSLgoTYWlyX3F1YWxp'
    'dHlfZW5hYmxlZBgGIAEoCFIRYWlyUXVhbGl0eUVuYWJsZWQSMAoUYWlyX3F1YWxpdHlfaW50ZX'
    'J2YWwYByABKA1SEmFpclF1YWxpdHlJbnRlcnZhbBI6Chlwb3dlcl9tZWFzdXJlbWVudF9lbmFi'
    'bGVkGAggASgIUhdwb3dlck1lYXN1cmVtZW50RW5hYmxlZBIyChVwb3dlcl91cGRhdGVfaW50ZX'
    'J2YWwYCSABKA1SE3Bvd2VyVXBkYXRlSW50ZXJ2YWwSMAoUcG93ZXJfc2NyZWVuX2VuYWJsZWQY'
    'CiABKAhSEnBvd2VyU2NyZWVuRW5hYmxlZBI8ChpoZWFsdGhfbWVhc3VyZW1lbnRfZW5hYmxlZB'
    'gLIAEoCFIYaGVhbHRoTWVhc3VyZW1lbnRFbmFibGVkEjQKFmhlYWx0aF91cGRhdGVfaW50ZXJ2'
    'YWwYDCABKA1SFGhlYWx0aFVwZGF0ZUludGVydmFsEjIKFWhlYWx0aF9zY3JlZW5fZW5hYmxlZB'
    'gNIAEoCFITaGVhbHRoU2NyZWVuRW5hYmxlZBqaBgoTQ2FubmVkTWVzc2FnZUNvbmZpZxInCg9y'
    'b3RhcnkxX2VuYWJsZWQYASABKAhSDnJvdGFyeTFFbmFibGVkEioKEWlucHV0YnJva2VyX3Bpbl'
    '9hGAIgASgNUg9pbnB1dGJyb2tlclBpbkESKgoRaW5wdXRicm9rZXJfcGluX2IYAyABKA1SD2lu'
    'cHV0YnJva2VyUGluQhIyChVpbnB1dGJyb2tlcl9waW5fcHJlc3MYBCABKA1SE2lucHV0YnJva2'
    'VyUGluUHJlc3MSbQoUaW5wdXRicm9rZXJfZXZlbnRfY3cYBSABKA4yOy5tZXNodGFzdGljLk1v'
    'ZHVsZUNvbmZpZy5DYW5uZWRNZXNzYWdlQ29uZmlnLklucHV0RXZlbnRDaGFyUhJpbnB1dGJyb2'
    'tlckV2ZW50Q3cSbwoVaW5wdXRicm9rZXJfZXZlbnRfY2N3GAYgASgOMjsubWVzaHRhc3RpYy5N'
    'b2R1bGVDb25maWcuQ2FubmVkTWVzc2FnZUNvbmZpZy5JbnB1dEV2ZW50Q2hhclITaW5wdXRicm'
    '9rZXJFdmVudENjdxJzChdpbnB1dGJyb2tlcl9ldmVudF9wcmVzcxgHIAEoDjI7Lm1lc2h0YXN0'
    'aWMuTW9kdWxlQ29uZmlnLkNhbm5lZE1lc3NhZ2VDb25maWcuSW5wdXRFdmVudENoYXJSFWlucH'
    'V0YnJva2VyRXZlbnRQcmVzcxInCg91cGRvd24xX2VuYWJsZWQYCCABKAhSDnVwZG93bjFFbmFi'
    'bGVkEhwKB2VuYWJsZWQYCSABKAhCAhgBUgdlbmFibGVkEjAKEmFsbG93X2lucHV0X3NvdXJjZR'
    'gKIAEoCUICGAFSEGFsbG93SW5wdXRTb3VyY2USGwoJc2VuZF9iZWxsGAsgASgIUghzZW5kQmVs'
    'bCJjCg5JbnB1dEV2ZW50Q2hhchIICgROT05FEAASBgoCVVAQERIICgRET1dOEBISCAoETEVGVB'
    'ATEgkKBVJJR0hUEBQSCgoGU0VMRUNUEAoSCAoEQkFDSxAbEgoKBkNBTkNFTBAYGooBChVBbWJp'
    'ZW50TGlnaHRpbmdDb25maWcSGwoJbGVkX3N0YXRlGAEgASgIUghsZWRTdGF0ZRIYCgdjdXJyZW'
    '50GAIgASgNUgdjdXJyZW50EhAKA3JlZBgDIAEoDVIDcmVkEhQKBWdyZWVuGAQgASgNUgVncmVl'
    'bhISCgRibHVlGAUgASgNUgRibHVlQhEKD3BheWxvYWRfdmFyaWFudA==');

@$core.Deprecated('Use remoteHardwarePinDescriptor instead')
const RemoteHardwarePin$json = {
  '1': 'RemoteHardwarePin',
  '2': [
    {'1': 'gpio_pin', '3': 1, '4': 1, '5': 13, '10': 'gpioPin'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.RemoteHardwarePinType',
      '10': 'type'
    },
  ],
};

/// Descriptor for `RemoteHardwarePin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteHardwarePinDescriptor = $convert.base64Decode(
    'ChFSZW1vdGVIYXJkd2FyZVBpbhIZCghncGlvX3BpbhgBIAEoDVIHZ3Bpb1BpbhISCgRuYW1lGA'
    'IgASgJUgRuYW1lEjUKBHR5cGUYAyABKA4yIS5tZXNodGFzdGljLlJlbW90ZUhhcmR3YXJlUGlu'
    'VHlwZVIEdHlwZQ==');
