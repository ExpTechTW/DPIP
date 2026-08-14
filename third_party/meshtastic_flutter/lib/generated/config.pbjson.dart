// This is a generated file - do not edit.
//
// Generated from meshtastic/config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use configDescriptor instead')
const Config$json = {
  '1': 'Config',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DeviceConfig',
      '9': 0,
      '10': 'device'
    },
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PositionConfig',
      '9': 0,
      '10': 'position'
    },
    {
      '1': 'power',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PowerConfig',
      '9': 0,
      '10': 'power'
    },
    {
      '1': 'network',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.NetworkConfig',
      '9': 0,
      '10': 'network'
    },
    {
      '1': 'display',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DisplayConfig',
      '9': 0,
      '10': 'display'
    },
    {
      '1': 'lora',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.LoRaConfig',
      '9': 0,
      '10': 'lora'
    },
    {
      '1': 'bluetooth',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.BluetoothConfig',
      '9': 0,
      '10': 'bluetooth'
    },
    {
      '1': 'security',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.SecurityConfig',
      '9': 0,
      '10': 'security'
    },
    {
      '1': 'sessionkey',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.SessionkeyConfig',
      '9': 0,
      '10': 'sessionkey'
    },
    {
      '1': 'device_ui',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceUIConfig',
      '9': 0,
      '10': 'deviceUi'
    },
  ],
  '3': [
    Config_DeviceConfig$json,
    Config_PositionConfig$json,
    Config_PowerConfig$json,
    Config_NetworkConfig$json,
    Config_DisplayConfig$json,
    Config_LoRaConfig$json,
    Config_BluetoothConfig$json,
    Config_SecurityConfig$json,
    Config_SessionkeyConfig$json
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig$json = {
  '1': 'DeviceConfig',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.Role',
      '10': 'role'
    },
    {
      '1': 'serial_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'serialEnabled',
    },
    {'1': 'button_gpio', '3': 4, '4': 1, '5': 13, '10': 'buttonGpio'},
    {'1': 'buzzer_gpio', '3': 5, '4': 1, '5': 13, '10': 'buzzerGpio'},
    {
      '1': 'rebroadcast_mode',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.RebroadcastMode',
      '10': 'rebroadcastMode'
    },
    {
      '1': 'node_info_broadcast_secs',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'nodeInfoBroadcastSecs'
    },
    {
      '1': 'double_tap_as_button_press',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'doubleTapAsButtonPress'
    },
    {
      '1': 'is_managed',
      '3': 9,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'isManaged',
    },
    {
      '1': 'disable_triple_click',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'disableTripleClick'
    },
    {'1': 'tzdef', '3': 11, '4': 1, '5': 9, '10': 'tzdef'},
    {
      '1': 'led_heartbeat_disabled',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'ledHeartbeatDisabled'
    },
    {
      '1': 'buzzer_mode',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.BuzzerMode',
      '10': 'buzzerMode'
    },
  ],
  '4': [
    Config_DeviceConfig_Role$json,
    Config_DeviceConfig_RebroadcastMode$json,
    Config_DeviceConfig_BuzzerMode$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig_Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'CLIENT', '2': 0},
    {'1': 'CLIENT_MUTE', '2': 1},
    {'1': 'ROUTER', '2': 2},
    {
      '1': 'ROUTER_CLIENT',
      '2': 3,
      '3': {'1': true},
    },
    {'1': 'REPEATER', '2': 4},
    {'1': 'TRACKER', '2': 5},
    {'1': 'SENSOR', '2': 6},
    {'1': 'TAK', '2': 7},
    {'1': 'CLIENT_HIDDEN', '2': 8},
    {'1': 'LOST_AND_FOUND', '2': 9},
    {'1': 'TAK_TRACKER', '2': 10},
    {'1': 'ROUTER_LATE', '2': 11},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig_RebroadcastMode$json = {
  '1': 'RebroadcastMode',
  '2': [
    {'1': 'ALL', '2': 0},
    {'1': 'ALL_SKIP_DECODING', '2': 1},
    {'1': 'LOCAL_ONLY', '2': 2},
    {'1': 'KNOWN_ONLY', '2': 3},
    {'1': 'NONE', '2': 4},
    {'1': 'CORE_PORTNUMS_ONLY', '2': 5},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig_BuzzerMode$json = {
  '1': 'BuzzerMode',
  '2': [
    {'1': 'ALL_ENABLED', '2': 0},
    {'1': 'DISABLED', '2': 1},
    {'1': 'NOTIFICATIONS_ONLY', '2': 2},
    {'1': 'SYSTEM_ONLY', '2': 3},
    {'1': 'DIRECT_MSG_ONLY', '2': 4},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig$json = {
  '1': 'PositionConfig',
  '2': [
    {
      '1': 'position_broadcast_secs',
      '3': 1,
      '4': 1,
      '5': 13,
      '10': 'positionBroadcastSecs'
    },
    {
      '1': 'position_broadcast_smart_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'positionBroadcastSmartEnabled'
    },
    {'1': 'fixed_position', '3': 3, '4': 1, '5': 8, '10': 'fixedPosition'},
    {
      '1': 'gps_enabled',
      '3': 4,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'gpsEnabled',
    },
    {
      '1': 'gps_update_interval',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'gpsUpdateInterval'
    },
    {
      '1': 'gps_attempt_time',
      '3': 6,
      '4': 1,
      '5': 13,
      '8': {'3': true},
      '10': 'gpsAttemptTime',
    },
    {'1': 'position_flags', '3': 7, '4': 1, '5': 13, '10': 'positionFlags'},
    {'1': 'rx_gpio', '3': 8, '4': 1, '5': 13, '10': 'rxGpio'},
    {'1': 'tx_gpio', '3': 9, '4': 1, '5': 13, '10': 'txGpio'},
    {
      '1': 'broadcast_smart_minimum_distance',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'broadcastSmartMinimumDistance'
    },
    {
      '1': 'broadcast_smart_minimum_interval_secs',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'broadcastSmartMinimumIntervalSecs'
    },
    {'1': 'gps_en_gpio', '3': 12, '4': 1, '5': 13, '10': 'gpsEnGpio'},
    {
      '1': 'gps_mode',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.PositionConfig.GpsMode',
      '10': 'gpsMode'
    },
  ],
  '4': [
    Config_PositionConfig_PositionFlags$json,
    Config_PositionConfig_GpsMode$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig_PositionFlags$json = {
  '1': 'PositionFlags',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'ALTITUDE', '2': 1},
    {'1': 'ALTITUDE_MSL', '2': 2},
    {'1': 'GEOIDAL_SEPARATION', '2': 4},
    {'1': 'DOP', '2': 8},
    {'1': 'HVDOP', '2': 16},
    {'1': 'SATINVIEW', '2': 32},
    {'1': 'SEQ_NO', '2': 64},
    {'1': 'TIMESTAMP', '2': 128},
    {'1': 'HEADING', '2': 256},
    {'1': 'SPEED', '2': 512},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig_GpsMode$json = {
  '1': 'GpsMode',
  '2': [
    {'1': 'DISABLED', '2': 0},
    {'1': 'ENABLED', '2': 1},
    {'1': 'NOT_PRESENT', '2': 2},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PowerConfig$json = {
  '1': 'PowerConfig',
  '2': [
    {'1': 'is_power_saving', '3': 1, '4': 1, '5': 8, '10': 'isPowerSaving'},
    {
      '1': 'on_battery_shutdown_after_secs',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'onBatteryShutdownAfterSecs'
    },
    {
      '1': 'adc_multiplier_override',
      '3': 3,
      '4': 1,
      '5': 2,
      '10': 'adcMultiplierOverride'
    },
    {
      '1': 'wait_bluetooth_secs',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'waitBluetoothSecs'
    },
    {'1': 'sds_secs', '3': 6, '4': 1, '5': 13, '10': 'sdsSecs'},
    {'1': 'ls_secs', '3': 7, '4': 1, '5': 13, '10': 'lsSecs'},
    {'1': 'min_wake_secs', '3': 8, '4': 1, '5': 13, '10': 'minWakeSecs'},
    {
      '1': 'device_battery_ina_address',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'deviceBatteryInaAddress'
    },
    {'1': 'powermon_enables', '3': 32, '4': 1, '5': 4, '10': 'powermonEnables'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig$json = {
  '1': 'NetworkConfig',
  '2': [
    {'1': 'wifi_enabled', '3': 1, '4': 1, '5': 8, '10': 'wifiEnabled'},
    {'1': 'wifi_ssid', '3': 3, '4': 1, '5': 9, '10': 'wifiSsid'},
    {'1': 'wifi_psk', '3': 4, '4': 1, '5': 9, '10': 'wifiPsk'},
    {'1': 'ntp_server', '3': 5, '4': 1, '5': 9, '10': 'ntpServer'},
    {'1': 'eth_enabled', '3': 6, '4': 1, '5': 8, '10': 'ethEnabled'},
    {
      '1': 'address_mode',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.NetworkConfig.AddressMode',
      '10': 'addressMode'
    },
    {
      '1': 'ipv4_config',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.NetworkConfig.IpV4Config',
      '10': 'ipv4Config'
    },
    {'1': 'rsyslog_server', '3': 9, '4': 1, '5': 9, '10': 'rsyslogServer'},
    {
      '1': 'enabled_protocols',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'enabledProtocols'
    },
    {'1': 'ipv6_enabled', '3': 11, '4': 1, '5': 8, '10': 'ipv6Enabled'},
  ],
  '3': [Config_NetworkConfig_IpV4Config$json],
  '4': [
    Config_NetworkConfig_AddressMode$json,
    Config_NetworkConfig_ProtocolFlags$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_IpV4Config$json = {
  '1': 'IpV4Config',
  '2': [
    {'1': 'ip', '3': 1, '4': 1, '5': 7, '10': 'ip'},
    {'1': 'gateway', '3': 2, '4': 1, '5': 7, '10': 'gateway'},
    {'1': 'subnet', '3': 3, '4': 1, '5': 7, '10': 'subnet'},
    {'1': 'dns', '3': 4, '4': 1, '5': 7, '10': 'dns'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_AddressMode$json = {
  '1': 'AddressMode',
  '2': [
    {'1': 'DHCP', '2': 0},
    {'1': 'STATIC', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_ProtocolFlags$json = {
  '1': 'ProtocolFlags',
  '2': [
    {'1': 'NO_BROADCAST', '2': 0},
    {'1': 'UDP_BROADCAST', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig$json = {
  '1': 'DisplayConfig',
  '2': [
    {'1': 'screen_on_secs', '3': 1, '4': 1, '5': 13, '10': 'screenOnSecs'},
    {
      '1': 'gps_format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.GpsCoordinateFormat',
      '8': {'3': true},
      '10': 'gpsFormat',
    },
    {
      '1': 'auto_screen_carousel_secs',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'autoScreenCarouselSecs'
    },
    {
      '1': 'compass_north_top',
      '3': 4,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'compassNorthTop',
    },
    {'1': 'flip_screen', '3': 5, '4': 1, '5': 8, '10': 'flipScreen'},
    {
      '1': 'units',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.DisplayUnits',
      '10': 'units'
    },
    {
      '1': 'oled',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.OledType',
      '10': 'oled'
    },
    {
      '1': 'displaymode',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.DisplayMode',
      '10': 'displaymode'
    },
    {'1': 'heading_bold', '3': 9, '4': 1, '5': 8, '10': 'headingBold'},
    {
      '1': 'wake_on_tap_or_motion',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'wakeOnTapOrMotion'
    },
    {
      '1': 'compass_orientation',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.CompassOrientation',
      '10': 'compassOrientation'
    },
    {'1': 'use_12h_clock', '3': 12, '4': 1, '5': 8, '10': 'use12hClock'},
  ],
  '4': [
    Config_DisplayConfig_GpsCoordinateFormat$json,
    Config_DisplayConfig_DisplayUnits$json,
    Config_DisplayConfig_OledType$json,
    Config_DisplayConfig_DisplayMode$json,
    Config_DisplayConfig_CompassOrientation$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_GpsCoordinateFormat$json = {
  '1': 'GpsCoordinateFormat',
  '2': [
    {'1': 'DEC', '2': 0},
    {'1': 'DMS', '2': 1},
    {'1': 'UTM', '2': 2},
    {'1': 'MGRS', '2': 3},
    {'1': 'OLC', '2': 4},
    {'1': 'OSGR', '2': 5},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_DisplayUnits$json = {
  '1': 'DisplayUnits',
  '2': [
    {'1': 'METRIC', '2': 0},
    {'1': 'IMPERIAL', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_OledType$json = {
  '1': 'OledType',
  '2': [
    {'1': 'OLED_AUTO', '2': 0},
    {'1': 'OLED_SSD1306', '2': 1},
    {'1': 'OLED_SH1106', '2': 2},
    {'1': 'OLED_SH1107', '2': 3},
    {'1': 'OLED_SH1107_128_64', '2': 4},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_DisplayMode$json = {
  '1': 'DisplayMode',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'TWOCOLOR', '2': 1},
    {'1': 'INVERTED', '2': 2},
    {'1': 'COLOR', '2': 3},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_CompassOrientation$json = {
  '1': 'CompassOrientation',
  '2': [
    {'1': 'DEGREES_0', '2': 0},
    {'1': 'DEGREES_90', '2': 1},
    {'1': 'DEGREES_180', '2': 2},
    {'1': 'DEGREES_270', '2': 3},
    {'1': 'DEGREES_0_INVERTED', '2': 4},
    {'1': 'DEGREES_90_INVERTED', '2': 5},
    {'1': 'DEGREES_180_INVERTED', '2': 6},
    {'1': 'DEGREES_270_INVERTED', '2': 7},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig$json = {
  '1': 'LoRaConfig',
  '2': [
    {'1': 'use_preset', '3': 1, '4': 1, '5': 8, '10': 'usePreset'},
    {
      '1': 'modem_preset',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.ModemPreset',
      '10': 'modemPreset'
    },
    {'1': 'bandwidth', '3': 3, '4': 1, '5': 13, '10': 'bandwidth'},
    {'1': 'spread_factor', '3': 4, '4': 1, '5': 13, '10': 'spreadFactor'},
    {'1': 'coding_rate', '3': 5, '4': 1, '5': 13, '10': 'codingRate'},
    {'1': 'frequency_offset', '3': 6, '4': 1, '5': 2, '10': 'frequencyOffset'},
    {
      '1': 'region',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.RegionCode',
      '10': 'region'
    },
    {'1': 'hop_limit', '3': 8, '4': 1, '5': 13, '10': 'hopLimit'},
    {'1': 'tx_enabled', '3': 9, '4': 1, '5': 8, '10': 'txEnabled'},
    {'1': 'tx_power', '3': 10, '4': 1, '5': 5, '10': 'txPower'},
    {'1': 'channel_num', '3': 11, '4': 1, '5': 13, '10': 'channelNum'},
    {
      '1': 'override_duty_cycle',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'overrideDutyCycle'
    },
    {
      '1': 'sx126x_rx_boosted_gain',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'sx126xRxBoostedGain'
    },
    {
      '1': 'override_frequency',
      '3': 14,
      '4': 1,
      '5': 2,
      '10': 'overrideFrequency'
    },
    {'1': 'pa_fan_disabled', '3': 15, '4': 1, '5': 8, '10': 'paFanDisabled'},
    {'1': 'ignore_incoming', '3': 103, '4': 3, '5': 13, '10': 'ignoreIncoming'},
    {'1': 'ignore_mqtt', '3': 104, '4': 1, '5': 8, '10': 'ignoreMqtt'},
    {
      '1': 'config_ok_to_mqtt',
      '3': 105,
      '4': 1,
      '5': 8,
      '10': 'configOkToMqtt'
    },
  ],
  '4': [Config_LoRaConfig_RegionCode$json, Config_LoRaConfig_ModemPreset$json],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig_RegionCode$json = {
  '1': 'RegionCode',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'US', '2': 1},
    {'1': 'EU_433', '2': 2},
    {'1': 'EU_868', '2': 3},
    {'1': 'CN', '2': 4},
    {'1': 'JP', '2': 5},
    {'1': 'ANZ', '2': 6},
    {'1': 'KR', '2': 7},
    {'1': 'TW', '2': 8},
    {'1': 'RU', '2': 9},
    {'1': 'IN', '2': 10},
    {'1': 'NZ_865', '2': 11},
    {'1': 'TH', '2': 12},
    {'1': 'LORA_24', '2': 13},
    {'1': 'UA_433', '2': 14},
    {'1': 'UA_868', '2': 15},
    {'1': 'MY_433', '2': 16},
    {'1': 'MY_919', '2': 17},
    {'1': 'SG_923', '2': 18},
    {'1': 'PH_433', '2': 19},
    {'1': 'PH_868', '2': 20},
    {'1': 'PH_915', '2': 21},
    {'1': 'ANZ_433', '2': 22},
    {'1': 'KZ_433', '2': 23},
    {'1': 'KZ_863', '2': 24},
    {'1': 'NP_865', '2': 25},
    {'1': 'BR_902', '2': 26},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig_ModemPreset$json = {
  '1': 'ModemPreset',
  '2': [
    {'1': 'LONG_FAST', '2': 0},
    {'1': 'LONG_SLOW', '2': 1},
    {
      '1': 'VERY_LONG_SLOW',
      '2': 2,
      '3': {'1': true},
    },
    {'1': 'MEDIUM_SLOW', '2': 3},
    {'1': 'MEDIUM_FAST', '2': 4},
    {'1': 'SHORT_SLOW', '2': 5},
    {'1': 'SHORT_FAST', '2': 6},
    {'1': 'LONG_MODERATE', '2': 7},
    {'1': 'SHORT_TURBO', '2': 8},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_BluetoothConfig$json = {
  '1': 'BluetoothConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.BluetoothConfig.PairingMode',
      '10': 'mode'
    },
    {'1': 'fixed_pin', '3': 3, '4': 1, '5': 13, '10': 'fixedPin'},
  ],
  '4': [Config_BluetoothConfig_PairingMode$json],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_BluetoothConfig_PairingMode$json = {
  '1': 'PairingMode',
  '2': [
    {'1': 'RANDOM_PIN', '2': 0},
    {'1': 'FIXED_PIN', '2': 1},
    {'1': 'NO_PIN', '2': 2},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_SecurityConfig$json = {
  '1': 'SecurityConfig',
  '2': [
    {'1': 'public_key', '3': 1, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'private_key', '3': 2, '4': 1, '5': 12, '10': 'privateKey'},
    {'1': 'admin_key', '3': 3, '4': 3, '5': 12, '10': 'adminKey'},
    {'1': 'is_managed', '3': 4, '4': 1, '5': 8, '10': 'isManaged'},
    {'1': 'serial_enabled', '3': 5, '4': 1, '5': 8, '10': 'serialEnabled'},
    {
      '1': 'debug_log_api_enabled',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'debugLogApiEnabled'
    },
    {
      '1': 'admin_channel_enabled',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'adminChannelEnabled'
    },
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_SessionkeyConfig$json = {
  '1': 'SessionkeyConfig',
};

/// Descriptor for `Config`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configDescriptor = $convert.base64Decode(
    'CgZDb25maWcSOQoGZGV2aWNlGAEgASgLMh8ubWVzaHRhc3RpYy5Db25maWcuRGV2aWNlQ29uZm'
    'lnSABSBmRldmljZRI/Cghwb3NpdGlvbhgCIAEoCzIhLm1lc2h0YXN0aWMuQ29uZmlnLlBvc2l0'
    'aW9uQ29uZmlnSABSCHBvc2l0aW9uEjYKBXBvd2VyGAMgASgLMh4ubWVzaHRhc3RpYy5Db25maW'
    'cuUG93ZXJDb25maWdIAFIFcG93ZXISPAoHbmV0d29yaxgEIAEoCzIgLm1lc2h0YXN0aWMuQ29u'
    'ZmlnLk5ldHdvcmtDb25maWdIAFIHbmV0d29yaxI8CgdkaXNwbGF5GAUgASgLMiAubWVzaHRhc3'
    'RpYy5Db25maWcuRGlzcGxheUNvbmZpZ0gAUgdkaXNwbGF5EjMKBGxvcmEYBiABKAsyHS5tZXNo'
    'dGFzdGljLkNvbmZpZy5Mb1JhQ29uZmlnSABSBGxvcmESQgoJYmx1ZXRvb3RoGAcgASgLMiIubW'
    'VzaHRhc3RpYy5Db25maWcuQmx1ZXRvb3RoQ29uZmlnSABSCWJsdWV0b290aBI/CghzZWN1cml0'
    'eRgIIAEoCzIhLm1lc2h0YXN0aWMuQ29uZmlnLlNlY3VyaXR5Q29uZmlnSABSCHNlY3VyaXR5Ek'
    'UKCnNlc3Npb25rZXkYCSABKAsyIy5tZXNodGFzdGljLkNvbmZpZy5TZXNzaW9ua2V5Q29uZmln'
    'SABSCnNlc3Npb25rZXkSOQoJZGV2aWNlX3VpGAogASgLMhoubWVzaHRhc3RpYy5EZXZpY2VVSU'
    'NvbmZpZ0gAUghkZXZpY2VVaRqWCAoMRGV2aWNlQ29uZmlnEjgKBHJvbGUYASABKA4yJC5tZXNo'
    'dGFzdGljLkNvbmZpZy5EZXZpY2VDb25maWcuUm9sZVIEcm9sZRIpCg5zZXJpYWxfZW5hYmxlZB'
    'gCIAEoCEICGAFSDXNlcmlhbEVuYWJsZWQSHwoLYnV0dG9uX2dwaW8YBCABKA1SCmJ1dHRvbkdw'
    'aW8SHwoLYnV6emVyX2dwaW8YBSABKA1SCmJ1enplckdwaW8SWgoQcmVicm9hZGNhc3RfbW9kZR'
    'gGIAEoDjIvLm1lc2h0YXN0aWMuQ29uZmlnLkRldmljZUNvbmZpZy5SZWJyb2FkY2FzdE1vZGVS'
    'D3JlYnJvYWRjYXN0TW9kZRI3Chhub2RlX2luZm9fYnJvYWRjYXN0X3NlY3MYByABKA1SFW5vZG'
    'VJbmZvQnJvYWRjYXN0U2VjcxI6Chpkb3VibGVfdGFwX2FzX2J1dHRvbl9wcmVzcxgIIAEoCFIW'
    'ZG91YmxlVGFwQXNCdXR0b25QcmVzcxIhCgppc19tYW5hZ2VkGAkgASgIQgIYAVIJaXNNYW5hZ2'
    'VkEjAKFGRpc2FibGVfdHJpcGxlX2NsaWNrGAogASgIUhJkaXNhYmxlVHJpcGxlQ2xpY2sSFAoF'
    'dHpkZWYYCyABKAlSBXR6ZGVmEjQKFmxlZF9oZWFydGJlYXRfZGlzYWJsZWQYDCABKAhSFGxlZE'
    'hlYXJ0YmVhdERpc2FibGVkEksKC2J1enplcl9tb2RlGA0gASgOMioubWVzaHRhc3RpYy5Db25m'
    'aWcuRGV2aWNlQ29uZmlnLkJ1enplck1vZGVSCmJ1enplck1vZGUivwEKBFJvbGUSCgoGQ0xJRU'
    '5UEAASDwoLQ0xJRU5UX01VVEUQARIKCgZST1VURVIQAhIVCg1ST1VURVJfQ0xJRU5UEAMaAggB'
    'EgwKCFJFUEVBVEVSEAQSCwoHVFJBQ0tFUhAFEgoKBlNFTlNPUhAGEgcKA1RBSxAHEhEKDUNMSU'
    'VOVF9ISURERU4QCBISCg5MT1NUX0FORF9GT1VORBAJEg8KC1RBS19UUkFDS0VSEAoSDwoLUk9V'
    'VEVSX0xBVEUQCyJzCg9SZWJyb2FkY2FzdE1vZGUSBwoDQUxMEAASFQoRQUxMX1NLSVBfREVDT0'
    'RJTkcQARIOCgpMT0NBTF9PTkxZEAISDgoKS05PV05fT05MWRADEggKBE5PTkUQBBIWChJDT1JF'
    'X1BPUlROVU1TX09OTFkQBSJpCgpCdXp6ZXJNb2RlEg8KC0FMTF9FTkFCTEVEEAASDAoIRElTQU'
    'JMRUQQARIWChJOT1RJRklDQVRJT05TX09OTFkQAhIPCgtTWVNURU1fT05MWRADEhMKD0RJUkVD'
    'VF9NU0dfT05MWRAEGvoGCg5Qb3NpdGlvbkNvbmZpZxI2Chdwb3NpdGlvbl9icm9hZGNhc3Rfc2'
    'VjcxgBIAEoDVIVcG9zaXRpb25Ccm9hZGNhc3RTZWNzEkcKIHBvc2l0aW9uX2Jyb2FkY2FzdF9z'
    'bWFydF9lbmFibGVkGAIgASgIUh1wb3NpdGlvbkJyb2FkY2FzdFNtYXJ0RW5hYmxlZBIlCg5maX'
    'hlZF9wb3NpdGlvbhgDIAEoCFINZml4ZWRQb3NpdGlvbhIjCgtncHNfZW5hYmxlZBgEIAEoCEIC'
    'GAFSCmdwc0VuYWJsZWQSLgoTZ3BzX3VwZGF0ZV9pbnRlcnZhbBgFIAEoDVIRZ3BzVXBkYXRlSW'
    '50ZXJ2YWwSLAoQZ3BzX2F0dGVtcHRfdGltZRgGIAEoDUICGAFSDmdwc0F0dGVtcHRUaW1lEiUK'
    'DnBvc2l0aW9uX2ZsYWdzGAcgASgNUg1wb3NpdGlvbkZsYWdzEhcKB3J4X2dwaW8YCCABKA1SBn'
    'J4R3BpbxIXCgd0eF9ncGlvGAkgASgNUgZ0eEdwaW8SRwogYnJvYWRjYXN0X3NtYXJ0X21pbmlt'
    'dW1fZGlzdGFuY2UYCiABKA1SHWJyb2FkY2FzdFNtYXJ0TWluaW11bURpc3RhbmNlElAKJWJyb2'
    'FkY2FzdF9zbWFydF9taW5pbXVtX2ludGVydmFsX3NlY3MYCyABKA1SIWJyb2FkY2FzdFNtYXJ0'
    'TWluaW11bUludGVydmFsU2VjcxIeCgtncHNfZW5fZ3BpbxgMIAEoDVIJZ3BzRW5HcGlvEkQKCG'
    'dwc19tb2RlGA0gASgOMikubWVzaHRhc3RpYy5Db25maWcuUG9zaXRpb25Db25maWcuR3BzTW9k'
    'ZVIHZ3BzTW9kZSKrAQoNUG9zaXRpb25GbGFncxIJCgVVTlNFVBAAEgwKCEFMVElUVURFEAESEA'
    'oMQUxUSVRVREVfTVNMEAISFgoSR0VPSURBTF9TRVBBUkFUSU9OEAQSBwoDRE9QEAgSCQoFSFZE'
    'T1AQEBINCglTQVRJTlZJRVcQIBIKCgZTRVFfTk8QQBIOCglUSU1FU1RBTVAQgAESDAoHSEVBRE'
    'lORxCAAhIKCgVTUEVFRBCABCI1CgdHcHNNb2RlEgwKCERJU0FCTEVEEAASCwoHRU5BQkxFRBAB'
    'Eg8KC05PVF9QUkVTRU5UEAIaoQMKC1Bvd2VyQ29uZmlnEiYKD2lzX3Bvd2VyX3NhdmluZxgBIA'
    'EoCFINaXNQb3dlclNhdmluZxJCCh5vbl9iYXR0ZXJ5X3NodXRkb3duX2FmdGVyX3NlY3MYAiAB'
    'KA1SGm9uQmF0dGVyeVNodXRkb3duQWZ0ZXJTZWNzEjYKF2FkY19tdWx0aXBsaWVyX292ZXJyaW'
    'RlGAMgASgCUhVhZGNNdWx0aXBsaWVyT3ZlcnJpZGUSLgoTd2FpdF9ibHVldG9vdGhfc2VjcxgE'
    'IAEoDVIRd2FpdEJsdWV0b290aFNlY3MSGQoIc2RzX3NlY3MYBiABKA1SB3Nkc1NlY3MSFwoHbH'
    'Nfc2VjcxgHIAEoDVIGbHNTZWNzEiIKDW1pbl93YWtlX3NlY3MYCCABKA1SC21pbldha2VTZWNz'
    'EjsKGmRldmljZV9iYXR0ZXJ5X2luYV9hZGRyZXNzGAkgASgNUhdkZXZpY2VCYXR0ZXJ5SW5hQW'
    'RkcmVzcxIpChBwb3dlcm1vbl9lbmFibGVzGCAgASgEUg9wb3dlcm1vbkVuYWJsZXMa/QQKDU5l'
    'dHdvcmtDb25maWcSIQoMd2lmaV9lbmFibGVkGAEgASgIUgt3aWZpRW5hYmxlZBIbCgl3aWZpX3'
    'NzaWQYAyABKAlSCHdpZmlTc2lkEhkKCHdpZmlfcHNrGAQgASgJUgd3aWZpUHNrEh0KCm50cF9z'
    'ZXJ2ZXIYBSABKAlSCW50cFNlcnZlchIfCgtldGhfZW5hYmxlZBgGIAEoCFIKZXRoRW5hYmxlZB'
    'JPCgxhZGRyZXNzX21vZGUYByABKA4yLC5tZXNodGFzdGljLkNvbmZpZy5OZXR3b3JrQ29uZmln'
    'LkFkZHJlc3NNb2RlUgthZGRyZXNzTW9kZRJMCgtpcHY0X2NvbmZpZxgIIAEoCzIrLm1lc2h0YX'
    'N0aWMuQ29uZmlnLk5ldHdvcmtDb25maWcuSXBWNENvbmZpZ1IKaXB2NENvbmZpZxIlCg5yc3lz'
    'bG9nX3NlcnZlchgJIAEoCVINcnN5c2xvZ1NlcnZlchIrChFlbmFibGVkX3Byb3RvY29scxgKIA'
    'EoDVIQZW5hYmxlZFByb3RvY29scxIhCgxpcHY2X2VuYWJsZWQYCyABKAhSC2lwdjZFbmFibGVk'
    'GmAKCklwVjRDb25maWcSDgoCaXAYASABKAdSAmlwEhgKB2dhdGV3YXkYAiABKAdSB2dhdGV3YX'
    'kSFgoGc3VibmV0GAMgASgHUgZzdWJuZXQSEAoDZG5zGAQgASgHUgNkbnMiIwoLQWRkcmVzc01v'
    'ZGUSCAoEREhDUBAAEgoKBlNUQVRJQxABIjQKDVByb3RvY29sRmxhZ3MSEAoMTk9fQlJPQURDQV'
    'NUEAASEQoNVURQX0JST0FEQ0FTVBABGq0JCg1EaXNwbGF5Q29uZmlnEiQKDnNjcmVlbl9vbl9z'
    'ZWNzGAEgASgNUgxzY3JlZW5PblNlY3MSVwoKZ3BzX2Zvcm1hdBgCIAEoDjI0Lm1lc2h0YXN0aW'
    'MuQ29uZmlnLkRpc3BsYXlDb25maWcuR3BzQ29vcmRpbmF0ZUZvcm1hdEICGAFSCWdwc0Zvcm1h'
    'dBI5ChlhdXRvX3NjcmVlbl9jYXJvdXNlbF9zZWNzGAMgASgNUhZhdXRvU2NyZWVuQ2Fyb3VzZW'
    'xTZWNzEi4KEWNvbXBhc3Nfbm9ydGhfdG9wGAQgASgIQgIYAVIPY29tcGFzc05vcnRoVG9wEh8K'
    'C2ZsaXBfc2NyZWVuGAUgASgIUgpmbGlwU2NyZWVuEkMKBXVuaXRzGAYgASgOMi0ubWVzaHRhc3'
    'RpYy5Db25maWcuRGlzcGxheUNvbmZpZy5EaXNwbGF5VW5pdHNSBXVuaXRzEj0KBG9sZWQYByAB'
    'KA4yKS5tZXNodGFzdGljLkNvbmZpZy5EaXNwbGF5Q29uZmlnLk9sZWRUeXBlUgRvbGVkEk4KC2'
    'Rpc3BsYXltb2RlGAggASgOMiwubWVzaHRhc3RpYy5Db25maWcuRGlzcGxheUNvbmZpZy5EaXNw'
    'bGF5TW9kZVILZGlzcGxheW1vZGUSIQoMaGVhZGluZ19ib2xkGAkgASgIUgtoZWFkaW5nQm9sZB'
    'IwChV3YWtlX29uX3RhcF9vcl9tb3Rpb24YCiABKAhSEXdha2VPblRhcE9yTW90aW9uEmQKE2Nv'
    'bXBhc3Nfb3JpZW50YXRpb24YCyABKA4yMy5tZXNodGFzdGljLkNvbmZpZy5EaXNwbGF5Q29uZm'
    'lnLkNvbXBhc3NPcmllbnRhdGlvblISY29tcGFzc09yaWVudGF0aW9uEiIKDXVzZV8xMmhfY2xv'
    'Y2sYDCABKAhSC3VzZTEyaENsb2NrIk0KE0dwc0Nvb3JkaW5hdGVGb3JtYXQSBwoDREVDEAASBw'
    'oDRE1TEAESBwoDVVRNEAISCAoETUdSUxADEgcKA09MQxAEEggKBE9TR1IQBSIoCgxEaXNwbGF5'
    'VW5pdHMSCgoGTUVUUklDEAASDAoISU1QRVJJQUwQASJlCghPbGVkVHlwZRINCglPTEVEX0FVVE'
    '8QABIQCgxPTEVEX1NTRDEzMDYQARIPCgtPTEVEX1NIMTEwNhACEg8KC09MRURfU0gxMTA3EAMS'
    'FgoST0xFRF9TSDExMDdfMTI4XzY0EAQiQQoLRGlzcGxheU1vZGUSCwoHREVGQVVMVBAAEgwKCF'
    'RXT0NPTE9SEAESDAoISU5WRVJURUQQAhIJCgVDT0xPUhADIroBChJDb21wYXNzT3JpZW50YXRp'
    'b24SDQoJREVHUkVFU18wEAASDgoKREVHUkVFU185MBABEg8KC0RFR1JFRVNfMTgwEAISDwoLRE'
    'VHUkVFU18yNzAQAxIWChJERUdSRUVTXzBfSU5WRVJURUQQBBIXChNERUdSRUVTXzkwX0lOVkVS'
    'VEVEEAUSGAoUREVHUkVFU18xODBfSU5WRVJURUQQBhIYChRERUdSRUVTXzI3MF9JTlZFUlRFRB'
    'AHGtAJCgpMb1JhQ29uZmlnEh0KCnVzZV9wcmVzZXQYASABKAhSCXVzZVByZXNldBJMCgxtb2Rl'
    'bV9wcmVzZXQYAiABKA4yKS5tZXNodGFzdGljLkNvbmZpZy5Mb1JhQ29uZmlnLk1vZGVtUHJlc2'
    'V0Ugttb2RlbVByZXNldBIcCgliYW5kd2lkdGgYAyABKA1SCWJhbmR3aWR0aBIjCg1zcHJlYWRf'
    'ZmFjdG9yGAQgASgNUgxzcHJlYWRGYWN0b3ISHwoLY29kaW5nX3JhdGUYBSABKA1SCmNvZGluZ1'
    'JhdGUSKQoQZnJlcXVlbmN5X29mZnNldBgGIAEoAlIPZnJlcXVlbmN5T2Zmc2V0EkAKBnJlZ2lv'
    'bhgHIAEoDjIoLm1lc2h0YXN0aWMuQ29uZmlnLkxvUmFDb25maWcuUmVnaW9uQ29kZVIGcmVnaW'
    '9uEhsKCWhvcF9saW1pdBgIIAEoDVIIaG9wTGltaXQSHQoKdHhfZW5hYmxlZBgJIAEoCFIJdHhF'
    'bmFibGVkEhkKCHR4X3Bvd2VyGAogASgFUgd0eFBvd2VyEh8KC2NoYW5uZWxfbnVtGAsgASgNUg'
    'pjaGFubmVsTnVtEi4KE292ZXJyaWRlX2R1dHlfY3ljbGUYDCABKAhSEW92ZXJyaWRlRHV0eUN5'
    'Y2xlEjMKFnN4MTI2eF9yeF9ib29zdGVkX2dhaW4YDSABKAhSE3N4MTI2eFJ4Qm9vc3RlZEdhaW'
    '4SLQoSb3ZlcnJpZGVfZnJlcXVlbmN5GA4gASgCUhFvdmVycmlkZUZyZXF1ZW5jeRImCg9wYV9m'
    'YW5fZGlzYWJsZWQYDyABKAhSDXBhRmFuRGlzYWJsZWQSJwoPaWdub3JlX2luY29taW5nGGcgAy'
    'gNUg5pZ25vcmVJbmNvbWluZxIfCgtpZ25vcmVfbXF0dBhoIAEoCFIKaWdub3JlTXF0dBIpChFj'
    'b25maWdfb2tfdG9fbXF0dBhpIAEoCFIOY29uZmlnT2tUb01xdHQirgIKClJlZ2lvbkNvZGUSCQ'
    'oFVU5TRVQQABIGCgJVUxABEgoKBkVVXzQzMxACEgoKBkVVXzg2OBADEgYKAkNOEAQSBgoCSlAQ'
    'BRIHCgNBTloQBhIGCgJLUhAHEgYKAlRXEAgSBgoCUlUQCRIGCgJJThAKEgoKBk5aXzg2NRALEg'
    'YKAlRIEAwSCwoHTE9SQV8yNBANEgoKBlVBXzQzMxAOEgoKBlVBXzg2OBAPEgoKBk1ZXzQzMxAQ'
    'EgoKBk1ZXzkxORAREgoKBlNHXzkyMxASEgoKBlBIXzQzMxATEgoKBlBIXzg2OBAUEgoKBlBIXz'
    'kxNRAVEgsKB0FOWl80MzMQFhIKCgZLWl80MzMQFxIKCgZLWl84NjMQGBIKCgZOUF84NjUQGRIK'
    'CgZCUl85MDIQGiKpAQoLTW9kZW1QcmVzZXQSDQoJTE9OR19GQVNUEAASDQoJTE9OR19TTE9XEA'
    'ESFgoOVkVSWV9MT05HX1NMT1cQAhoCCAESDwoLTUVESVVNX1NMT1cQAxIPCgtNRURJVU1fRkFT'
    'VBAEEg4KClNIT1JUX1NMT1cQBRIOCgpTSE9SVF9GQVNUEAYSEQoNTE9OR19NT0RFUkFURRAHEg'
    '8KC1NIT1JUX1RVUkJPEAgaxgEKD0JsdWV0b290aENvbmZpZxIYCgdlbmFibGVkGAEgASgIUgdl'
    'bmFibGVkEkIKBG1vZGUYAiABKA4yLi5tZXNodGFzdGljLkNvbmZpZy5CbHVldG9vdGhDb25maW'
    'cuUGFpcmluZ01vZGVSBG1vZGUSGwoJZml4ZWRfcGluGAMgASgNUghmaXhlZFBpbiI4CgtQYWly'
    'aW5nTW9kZRIOCgpSQU5ET01fUElOEAASDQoJRklYRURfUElOEAESCgoGTk9fUElOEAIamgIKDl'
    'NlY3VyaXR5Q29uZmlnEh0KCnB1YmxpY19rZXkYASABKAxSCXB1YmxpY0tleRIfCgtwcml2YXRl'
    'X2tleRgCIAEoDFIKcHJpdmF0ZUtleRIbCglhZG1pbl9rZXkYAyADKAxSCGFkbWluS2V5Eh0KCm'
    'lzX21hbmFnZWQYBCABKAhSCWlzTWFuYWdlZBIlCg5zZXJpYWxfZW5hYmxlZBgFIAEoCFINc2Vy'
    'aWFsRW5hYmxlZBIxChVkZWJ1Z19sb2dfYXBpX2VuYWJsZWQYBiABKAhSEmRlYnVnTG9nQXBpRW'
    '5hYmxlZBIyChVhZG1pbl9jaGFubmVsX2VuYWJsZWQYCCABKAhSE2FkbWluQ2hhbm5lbEVuYWJs'
    'ZWQaEgoQU2Vzc2lvbmtleUNvbmZpZ0IRCg9wYXlsb2FkX3ZhcmlhbnQ=');
