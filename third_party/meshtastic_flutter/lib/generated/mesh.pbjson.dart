// This is a generated file - do not edit.
//
// Generated from meshtastic/mesh.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use hardwareModelDescriptor instead')
const HardwareModel$json = {
  '1': 'HardwareModel',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'TLORA_V2', '2': 1},
    {'1': 'TLORA_V1', '2': 2},
    {'1': 'TLORA_V2_1_1P6', '2': 3},
    {'1': 'TBEAM', '2': 4},
    {'1': 'HELTEC_V2_0', '2': 5},
    {'1': 'TBEAM_V0P7', '2': 6},
    {'1': 'T_ECHO', '2': 7},
    {'1': 'TLORA_V1_1P3', '2': 8},
    {'1': 'RAK4631', '2': 9},
    {'1': 'HELTEC_V2_1', '2': 10},
    {'1': 'HELTEC_V1', '2': 11},
    {'1': 'LILYGO_TBEAM_S3_CORE', '2': 12},
    {'1': 'RAK11200', '2': 13},
    {'1': 'NANO_G1', '2': 14},
    {'1': 'TLORA_V2_1_1P8', '2': 15},
    {'1': 'TLORA_T3_S3', '2': 16},
    {'1': 'NANO_G1_EXPLORER', '2': 17},
    {'1': 'NANO_G2_ULTRA', '2': 18},
    {'1': 'LORA_TYPE', '2': 19},
    {'1': 'WIPHONE', '2': 20},
    {'1': 'WIO_WM1110', '2': 21},
    {'1': 'RAK2560', '2': 22},
    {'1': 'HELTEC_HRU_3601', '2': 23},
    {'1': 'HELTEC_WIRELESS_BRIDGE', '2': 24},
    {'1': 'STATION_G1', '2': 25},
    {'1': 'RAK11310', '2': 26},
    {'1': 'SENSELORA_RP2040', '2': 27},
    {'1': 'SENSELORA_S3', '2': 28},
    {'1': 'CANARYONE', '2': 29},
    {'1': 'RP2040_LORA', '2': 30},
    {'1': 'STATION_G2', '2': 31},
    {'1': 'LORA_RELAY_V1', '2': 32},
    {'1': 'NRF52840DK', '2': 33},
    {'1': 'PPR', '2': 34},
    {'1': 'GENIEBLOCKS', '2': 35},
    {'1': 'NRF52_UNKNOWN', '2': 36},
    {'1': 'PORTDUINO', '2': 37},
    {'1': 'ANDROID_SIM', '2': 38},
    {'1': 'DIY_V1', '2': 39},
    {'1': 'NRF52840_PCA10059', '2': 40},
    {'1': 'DR_DEV', '2': 41},
    {'1': 'M5STACK', '2': 42},
    {'1': 'HELTEC_V3', '2': 43},
    {'1': 'HELTEC_WSL_V3', '2': 44},
    {'1': 'BETAFPV_2400_TX', '2': 45},
    {'1': 'BETAFPV_900_NANO_TX', '2': 46},
    {'1': 'RPI_PICO', '2': 47},
    {'1': 'HELTEC_WIRELESS_TRACKER', '2': 48},
    {'1': 'HELTEC_WIRELESS_PAPER', '2': 49},
    {'1': 'T_DECK', '2': 50},
    {'1': 'T_WATCH_S3', '2': 51},
    {'1': 'PICOMPUTER_S3', '2': 52},
    {'1': 'HELTEC_HT62', '2': 53},
    {'1': 'EBYTE_ESP32_S3', '2': 54},
    {'1': 'ESP32_S3_PICO', '2': 55},
    {'1': 'CHATTER_2', '2': 56},
    {'1': 'HELTEC_WIRELESS_PAPER_V1_0', '2': 57},
    {'1': 'HELTEC_WIRELESS_TRACKER_V1_0', '2': 58},
    {'1': 'UNPHONE', '2': 59},
    {'1': 'TD_LORAC', '2': 60},
    {'1': 'CDEBYTE_EORA_S3', '2': 61},
    {'1': 'TWC_MESH_V4', '2': 62},
    {'1': 'NRF52_PROMICRO_DIY', '2': 63},
    {'1': 'RADIOMASTER_900_BANDIT_NANO', '2': 64},
    {'1': 'HELTEC_CAPSULE_SENSOR_V3', '2': 65},
    {'1': 'HELTEC_VISION_MASTER_T190', '2': 66},
    {'1': 'HELTEC_VISION_MASTER_E213', '2': 67},
    {'1': 'HELTEC_VISION_MASTER_E290', '2': 68},
    {'1': 'HELTEC_MESH_NODE_T114', '2': 69},
    {'1': 'SENSECAP_INDICATOR', '2': 70},
    {'1': 'TRACKER_T1000_E', '2': 71},
    {'1': 'RAK3172', '2': 72},
    {'1': 'WIO_E5', '2': 73},
    {'1': 'RADIOMASTER_900_BANDIT', '2': 74},
    {'1': 'ME25LS01_4Y10TD', '2': 75},
    {'1': 'RP2040_FEATHER_RFM95', '2': 76},
    {'1': 'M5STACK_COREBASIC', '2': 77},
    {'1': 'M5STACK_CORE2', '2': 78},
    {'1': 'RPI_PICO2', '2': 79},
    {'1': 'M5STACK_CORES3', '2': 80},
    {'1': 'SEEED_XIAO_S3', '2': 81},
    {'1': 'MS24SF1', '2': 82},
    {'1': 'TLORA_C6', '2': 83},
    {'1': 'WISMESH_TAP', '2': 84},
    {'1': 'ROUTASTIC', '2': 85},
    {'1': 'MESH_TAB', '2': 86},
    {'1': 'MESHLINK', '2': 87},
    {'1': 'XIAO_NRF52_KIT', '2': 88},
    {'1': 'THINKNODE_M1', '2': 89},
    {'1': 'THINKNODE_M2', '2': 90},
    {'1': 'T_ETH_ELITE', '2': 91},
    {'1': 'HELTEC_SENSOR_HUB', '2': 92},
    {'1': 'RESERVED_FRIED_CHICKEN', '2': 93},
    {'1': 'HELTEC_MESH_POCKET', '2': 94},
    {'1': 'SEEED_SOLAR_NODE', '2': 95},
    {'1': 'NOMADSTAR_METEOR_PRO', '2': 96},
    {'1': 'CROWPANEL', '2': 97},
    {'1': 'LINK_32', '2': 98},
    {'1': 'SEEED_WIO_TRACKER_L1', '2': 99},
    {'1': 'SEEED_WIO_TRACKER_L1_EINK', '2': 100},
    {'1': 'QWANTZ_TINY_ARMS', '2': 101},
    {'1': 'T_DECK_PRO', '2': 102},
    {'1': 'T_LORA_PAGER', '2': 103},
    {'1': 'GAT562_MESH_TRIAL_TRACKER', '2': 104},
    {'1': 'WISMESH_TAG', '2': 105},
    {'1': 'RAK3312', '2': 106},
    {'1': 'THINKNODE_M5', '2': 107},
    {'1': 'HELTEC_MESH_SOLAR', '2': 108},
    {'1': 'T_ECHO_LITE', '2': 109},
    {'1': 'PRIVATE_HW', '2': 255},
  ],
};

/// Descriptor for `HardwareModel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List hardwareModelDescriptor = $convert.base64Decode(
    'Cg1IYXJkd2FyZU1vZGVsEgkKBVVOU0VUEAASDAoIVExPUkFfVjIQARIMCghUTE9SQV9WMRACEh'
    'IKDlRMT1JBX1YyXzFfMVA2EAMSCQoFVEJFQU0QBBIPCgtIRUxURUNfVjJfMBAFEg4KClRCRUFN'
    'X1YwUDcQBhIKCgZUX0VDSE8QBxIQCgxUTE9SQV9WMV8xUDMQCBILCgdSQUs0NjMxEAkSDwoLSE'
    'VMVEVDX1YyXzEQChINCglIRUxURUNfVjEQCxIYChRMSUxZR09fVEJFQU1fUzNfQ09SRRAMEgwK'
    'CFJBSzExMjAwEA0SCwoHTkFOT19HMRAOEhIKDlRMT1JBX1YyXzFfMVA4EA8SDwoLVExPUkFfVD'
    'NfUzMQEBIUChBOQU5PX0cxX0VYUExPUkVSEBESEQoNTkFOT19HMl9VTFRSQRASEg0KCUxPUkFf'
    'VFlQRRATEgsKB1dJUEhPTkUQFBIOCgpXSU9fV00xMTEwEBUSCwoHUkFLMjU2MBAWEhMKD0hFTF'
    'RFQ19IUlVfMzYwMRAXEhoKFkhFTFRFQ19XSVJFTEVTU19CUklER0UQGBIOCgpTVEFUSU9OX0cx'
    'EBkSDAoIUkFLMTEzMTAQGhIUChBTRU5TRUxPUkFfUlAyMDQwEBsSEAoMU0VOU0VMT1JBX1MzEB'
    'wSDQoJQ0FOQVJZT05FEB0SDwoLUlAyMDQwX0xPUkEQHhIOCgpTVEFUSU9OX0cyEB8SEQoNTE9S'
    'QV9SRUxBWV9WMRAgEg4KCk5SRjUyODQwREsQIRIHCgNQUFIQIhIPCgtHRU5JRUJMT0NLUxAjEh'
    'EKDU5SRjUyX1VOS05PV04QJBINCglQT1JURFVJTk8QJRIPCgtBTkRST0lEX1NJTRAmEgoKBkRJ'
    'WV9WMRAnEhUKEU5SRjUyODQwX1BDQTEwMDU5ECgSCgoGRFJfREVWECkSCwoHTTVTVEFDSxAqEg'
    '0KCUhFTFRFQ19WMxArEhEKDUhFTFRFQ19XU0xfVjMQLBITCg9CRVRBRlBWXzI0MDBfVFgQLRIX'
    'ChNCRVRBRlBWXzkwMF9OQU5PX1RYEC4SDAoIUlBJX1BJQ08QLxIbChdIRUxURUNfV0lSRUxFU1'
    'NfVFJBQ0tFUhAwEhkKFUhFTFRFQ19XSVJFTEVTU19QQVBFUhAxEgoKBlRfREVDSxAyEg4KClRf'
    'V0FUQ0hfUzMQMxIRCg1QSUNPTVBVVEVSX1MzEDQSDwoLSEVMVEVDX0hUNjIQNRISCg5FQllURV'
    '9FU1AzMl9TMxA2EhEKDUVTUDMyX1MzX1BJQ08QNxINCglDSEFUVEVSXzIQOBIeChpIRUxURUNf'
    'V0lSRUxFU1NfUEFQRVJfVjFfMBA5EiAKHEhFTFRFQ19XSVJFTEVTU19UUkFDS0VSX1YxXzAQOh'
    'ILCgdVTlBIT05FEDsSDAoIVERfTE9SQUMQPBITCg9DREVCWVRFX0VPUkFfUzMQPRIPCgtUV0Nf'
    'TUVTSF9WNBA+EhYKEk5SRjUyX1BST01JQ1JPX0RJWRA/Eh8KG1JBRElPTUFTVEVSXzkwMF9CQU'
    '5ESVRfTkFOTxBAEhwKGEhFTFRFQ19DQVBTVUxFX1NFTlNPUl9WMxBBEh0KGUhFTFRFQ19WSVNJ'
    'T05fTUFTVEVSX1QxOTAQQhIdChlIRUxURUNfVklTSU9OX01BU1RFUl9FMjEzEEMSHQoZSEVMVE'
    'VDX1ZJU0lPTl9NQVNURVJfRTI5MBBEEhkKFUhFTFRFQ19NRVNIX05PREVfVDExNBBFEhYKElNF'
    'TlNFQ0FQX0lORElDQVRPUhBGEhMKD1RSQUNLRVJfVDEwMDBfRRBHEgsKB1JBSzMxNzIQSBIKCg'
    'ZXSU9fRTUQSRIaChZSQURJT01BU1RFUl85MDBfQkFORElUEEoSEwoPTUUyNUxTMDFfNFkxMFRE'
    'EEsSGAoUUlAyMDQwX0ZFQVRIRVJfUkZNOTUQTBIVChFNNVNUQUNLX0NPUkVCQVNJQxBNEhEKDU'
    '01U1RBQ0tfQ09SRTIQThINCglSUElfUElDTzIQTxISCg5NNVNUQUNLX0NPUkVTMxBQEhEKDVNF'
    'RUVEX1hJQU9fUzMQURILCgdNUzI0U0YxEFISDAoIVExPUkFfQzYQUxIPCgtXSVNNRVNIX1RBUB'
    'BUEg0KCVJPVVRBU1RJQxBVEgwKCE1FU0hfVEFCEFYSDAoITUVTSExJTksQVxISCg5YSUFPX05S'
    'RjUyX0tJVBBYEhAKDFRISU5LTk9ERV9NMRBZEhAKDFRISU5LTk9ERV9NMhBaEg8KC1RfRVRIX0'
    'VMSVRFEFsSFQoRSEVMVEVDX1NFTlNPUl9IVUIQXBIaChZSRVNFUlZFRF9GUklFRF9DSElDS0VO'
    'EF0SFgoSSEVMVEVDX01FU0hfUE9DS0VUEF4SFAoQU0VFRURfU09MQVJfTk9ERRBfEhgKFE5PTU'
    'FEU1RBUl9NRVRFT1JfUFJPEGASDQoJQ1JPV1BBTkVMEGESCwoHTElOS18zMhBiEhgKFFNFRUVE'
    'X1dJT19UUkFDS0VSX0wxEGMSHQoZU0VFRURfV0lPX1RSQUNLRVJfTDFfRUlOSxBkEhQKEFFXQU'
    '5UWl9USU5ZX0FSTVMQZRIOCgpUX0RFQ0tfUFJPEGYSEAoMVF9MT1JBX1BBR0VSEGcSHQoZR0FU'
    'NTYyX01FU0hfVFJJQUxfVFJBQ0tFUhBoEg8KC1dJU01FU0hfVEFHEGkSCwoHUkFLMzMxMhBqEh'
    'AKDFRISU5LTk9ERV9NNRBrEhUKEUhFTFRFQ19NRVNIX1NPTEFSEGwSDwoLVF9FQ0hPX0xJVEUQ'
    'bRIPCgpQUklWQVRFX0hXEP8B');

@$core.Deprecated('Use constantsDescriptor instead')
const Constants$json = {
  '1': 'Constants',
  '2': [
    {'1': 'ZERO', '2': 0},
    {'1': 'DATA_PAYLOAD_LEN', '2': 233},
  ],
};

/// Descriptor for `Constants`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List constantsDescriptor = $convert.base64Decode(
    'CglDb25zdGFudHMSCAoEWkVSTxAAEhUKEERBVEFfUEFZTE9BRF9MRU4Q6QE=');

@$core.Deprecated('Use criticalErrorCodeDescriptor instead')
const CriticalErrorCode$json = {
  '1': 'CriticalErrorCode',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'TX_WATCHDOG', '2': 1},
    {'1': 'SLEEP_ENTER_WAIT', '2': 2},
    {'1': 'NO_RADIO', '2': 3},
    {'1': 'UNSPECIFIED', '2': 4},
    {'1': 'UBLOX_UNIT_FAILED', '2': 5},
    {'1': 'NO_AXP192', '2': 6},
    {'1': 'INVALID_RADIO_SETTING', '2': 7},
    {'1': 'TRANSMIT_FAILED', '2': 8},
    {'1': 'BROWNOUT', '2': 9},
    {'1': 'SX1262_FAILURE', '2': 10},
    {'1': 'RADIO_SPI_BUG', '2': 11},
    {'1': 'FLASH_CORRUPTION_RECOVERABLE', '2': 12},
    {'1': 'FLASH_CORRUPTION_UNRECOVERABLE', '2': 13},
  ],
};

/// Descriptor for `CriticalErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List criticalErrorCodeDescriptor = $convert.base64Decode(
    'ChFDcml0aWNhbEVycm9yQ29kZRIICgROT05FEAASDwoLVFhfV0FUQ0hET0cQARIUChBTTEVFUF'
    '9FTlRFUl9XQUlUEAISDAoITk9fUkFESU8QAxIPCgtVTlNQRUNJRklFRBAEEhUKEVVCTE9YX1VO'
    'SVRfRkFJTEVEEAUSDQoJTk9fQVhQMTkyEAYSGQoVSU5WQUxJRF9SQURJT19TRVRUSU5HEAcSEw'
    'oPVFJBTlNNSVRfRkFJTEVEEAgSDAoIQlJPV05PVVQQCRISCg5TWDEyNjJfRkFJTFVSRRAKEhEK'
    'DVJBRElPX1NQSV9CVUcQCxIgChxGTEFTSF9DT1JSVVBUSU9OX1JFQ09WRVJBQkxFEAwSIgoeRk'
    'xBU0hfQ09SUlVQVElPTl9VTlJFQ09WRVJBQkxFEA0=');

@$core.Deprecated('Use firmwareEditionDescriptor instead')
const FirmwareEdition$json = {
  '1': 'FirmwareEdition',
  '2': [
    {'1': 'VANILLA', '2': 0},
    {'1': 'SMART_CITIZEN', '2': 1},
    {'1': 'OPEN_SAUCE', '2': 16},
    {'1': 'DEFCON', '2': 17},
    {'1': 'BURNING_MAN', '2': 18},
    {'1': 'HAMVENTION', '2': 19},
    {'1': 'DIY_EDITION', '2': 127},
  ],
};

/// Descriptor for `FirmwareEdition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List firmwareEditionDescriptor = $convert.base64Decode(
    'Cg9GaXJtd2FyZUVkaXRpb24SCwoHVkFOSUxMQRAAEhEKDVNNQVJUX0NJVElaRU4QARIOCgpPUE'
    'VOX1NBVUNFEBASCgoGREVGQ09OEBESDwoLQlVSTklOR19NQU4QEhIOCgpIQU1WRU5USU9OEBMS'
    'DwoLRElZX0VESVRJT04Qfw==');

@$core.Deprecated('Use excludedModulesDescriptor instead')
const ExcludedModules$json = {
  '1': 'ExcludedModules',
  '2': [
    {'1': 'EXCLUDED_NONE', '2': 0},
    {'1': 'MQTT_CONFIG', '2': 1},
    {'1': 'SERIAL_CONFIG', '2': 2},
    {'1': 'EXTNOTIF_CONFIG', '2': 4},
    {'1': 'STOREFORWARD_CONFIG', '2': 8},
    {'1': 'RANGETEST_CONFIG', '2': 16},
    {'1': 'TELEMETRY_CONFIG', '2': 32},
    {'1': 'CANNEDMSG_CONFIG', '2': 64},
    {'1': 'AUDIO_CONFIG', '2': 128},
    {'1': 'REMOTEHARDWARE_CONFIG', '2': 256},
    {'1': 'NEIGHBORINFO_CONFIG', '2': 512},
    {'1': 'AMBIENTLIGHTING_CONFIG', '2': 1024},
    {'1': 'DETECTIONSENSOR_CONFIG', '2': 2048},
    {'1': 'PAXCOUNTER_CONFIG', '2': 4096},
    {'1': 'BLUETOOTH_CONFIG', '2': 8192},
    {'1': 'NETWORK_CONFIG', '2': 16384},
  ],
};

/// Descriptor for `ExcludedModules`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List excludedModulesDescriptor = $convert.base64Decode(
    'Cg9FeGNsdWRlZE1vZHVsZXMSEQoNRVhDTFVERURfTk9ORRAAEg8KC01RVFRfQ09ORklHEAESEQ'
    'oNU0VSSUFMX0NPTkZJRxACEhMKD0VYVE5PVElGX0NPTkZJRxAEEhcKE1NUT1JFRk9SV0FSRF9D'
    'T05GSUcQCBIUChBSQU5HRVRFU1RfQ09ORklHEBASFAoQVEVMRU1FVFJZX0NPTkZJRxAgEhQKEE'
    'NBTk5FRE1TR19DT05GSUcQQBIRCgxBVURJT19DT05GSUcQgAESGgoVUkVNT1RFSEFSRFdBUkVf'
    'Q09ORklHEIACEhgKE05FSUdIQk9SSU5GT19DT05GSUcQgAQSGwoWQU1CSUVOVExJR0hUSU5HX0'
    'NPTkZJRxCACBIbChZERVRFQ1RJT05TRU5TT1JfQ09ORklHEIAQEhYKEVBBWENPVU5URVJfQ09O'
    'RklHEIAgEhUKEEJMVUVUT09USF9DT05GSUcQgEASFAoOTkVUV09SS19DT05GSUcQgIAB');

@$core.Deprecated('Use positionDescriptor instead')
const Position$json = {
  '1': 'Position',
  '2': [
    {
      '1': 'latitude_i',
      '3': 1,
      '4': 1,
      '5': 15,
      '9': 0,
      '10': 'latitudeI',
      '17': true
    },
    {
      '1': 'longitude_i',
      '3': 2,
      '4': 1,
      '5': 15,
      '9': 1,
      '10': 'longitudeI',
      '17': true
    },
    {
      '1': 'altitude',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'altitude',
      '17': true
    },
    {'1': 'time', '3': 4, '4': 1, '5': 7, '10': 'time'},
    {
      '1': 'location_source',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Position.LocSource',
      '10': 'locationSource'
    },
    {
      '1': 'altitude_source',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Position.AltSource',
      '10': 'altitudeSource'
    },
    {'1': 'timestamp', '3': 7, '4': 1, '5': 7, '10': 'timestamp'},
    {
      '1': 'timestamp_millis_adjust',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'timestampMillisAdjust'
    },
    {
      '1': 'altitude_hae',
      '3': 9,
      '4': 1,
      '5': 17,
      '9': 3,
      '10': 'altitudeHae',
      '17': true
    },
    {
      '1': 'altitude_geoidal_separation',
      '3': 10,
      '4': 1,
      '5': 17,
      '9': 4,
      '10': 'altitudeGeoidalSeparation',
      '17': true
    },
    {'1': 'PDOP', '3': 11, '4': 1, '5': 13, '10': 'PDOP'},
    {'1': 'HDOP', '3': 12, '4': 1, '5': 13, '10': 'HDOP'},
    {'1': 'VDOP', '3': 13, '4': 1, '5': 13, '10': 'VDOP'},
    {'1': 'gps_accuracy', '3': 14, '4': 1, '5': 13, '10': 'gpsAccuracy'},
    {
      '1': 'ground_speed',
      '3': 15,
      '4': 1,
      '5': 13,
      '9': 5,
      '10': 'groundSpeed',
      '17': true
    },
    {
      '1': 'ground_track',
      '3': 16,
      '4': 1,
      '5': 13,
      '9': 6,
      '10': 'groundTrack',
      '17': true
    },
    {'1': 'fix_quality', '3': 17, '4': 1, '5': 13, '10': 'fixQuality'},
    {'1': 'fix_type', '3': 18, '4': 1, '5': 13, '10': 'fixType'},
    {'1': 'sats_in_view', '3': 19, '4': 1, '5': 13, '10': 'satsInView'},
    {'1': 'sensor_id', '3': 20, '4': 1, '5': 13, '10': 'sensorId'},
    {'1': 'next_update', '3': 21, '4': 1, '5': 13, '10': 'nextUpdate'},
    {'1': 'seq_number', '3': 22, '4': 1, '5': 13, '10': 'seqNumber'},
    {'1': 'precision_bits', '3': 23, '4': 1, '5': 13, '10': 'precisionBits'},
  ],
  '4': [Position_LocSource$json, Position_AltSource$json],
  '8': [
    {'1': '_latitude_i'},
    {'1': '_longitude_i'},
    {'1': '_altitude'},
    {'1': '_altitude_hae'},
    {'1': '_altitude_geoidal_separation'},
    {'1': '_ground_speed'},
    {'1': '_ground_track'},
  ],
};

@$core.Deprecated('Use positionDescriptor instead')
const Position_LocSource$json = {
  '1': 'LocSource',
  '2': [
    {'1': 'LOC_UNSET', '2': 0},
    {'1': 'LOC_MANUAL', '2': 1},
    {'1': 'LOC_INTERNAL', '2': 2},
    {'1': 'LOC_EXTERNAL', '2': 3},
  ],
};

@$core.Deprecated('Use positionDescriptor instead')
const Position_AltSource$json = {
  '1': 'AltSource',
  '2': [
    {'1': 'ALT_UNSET', '2': 0},
    {'1': 'ALT_MANUAL', '2': 1},
    {'1': 'ALT_INTERNAL', '2': 2},
    {'1': 'ALT_EXTERNAL', '2': 3},
    {'1': 'ALT_BAROMETRIC', '2': 4},
  ],
};

/// Descriptor for `Position`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List positionDescriptor = $convert.base64Decode(
    'CghQb3NpdGlvbhIiCgpsYXRpdHVkZV9pGAEgASgPSABSCWxhdGl0dWRlSYgBARIkCgtsb25naX'
    'R1ZGVfaRgCIAEoD0gBUgpsb25naXR1ZGVJiAEBEh8KCGFsdGl0dWRlGAMgASgFSAJSCGFsdGl0'
    'dWRliAEBEhIKBHRpbWUYBCABKAdSBHRpbWUSRwoPbG9jYXRpb25fc291cmNlGAUgASgOMh4ubW'
    'VzaHRhc3RpYy5Qb3NpdGlvbi5Mb2NTb3VyY2VSDmxvY2F0aW9uU291cmNlEkcKD2FsdGl0dWRl'
    'X3NvdXJjZRgGIAEoDjIeLm1lc2h0YXN0aWMuUG9zaXRpb24uQWx0U291cmNlUg5hbHRpdHVkZV'
    'NvdXJjZRIcCgl0aW1lc3RhbXAYByABKAdSCXRpbWVzdGFtcBI2Chd0aW1lc3RhbXBfbWlsbGlz'
    'X2FkanVzdBgIIAEoBVIVdGltZXN0YW1wTWlsbGlzQWRqdXN0EiYKDGFsdGl0dWRlX2hhZRgJIA'
    'EoEUgDUgthbHRpdHVkZUhhZYgBARJDChthbHRpdHVkZV9nZW9pZGFsX3NlcGFyYXRpb24YCiAB'
    'KBFIBFIZYWx0aXR1ZGVHZW9pZGFsU2VwYXJhdGlvbogBARISCgRQRE9QGAsgASgNUgRQRE9QEh'
    'IKBEhET1AYDCABKA1SBEhET1ASEgoEVkRPUBgNIAEoDVIEVkRPUBIhCgxncHNfYWNjdXJhY3kY'
    'DiABKA1SC2dwc0FjY3VyYWN5EiYKDGdyb3VuZF9zcGVlZBgPIAEoDUgFUgtncm91bmRTcGVlZI'
    'gBARImCgxncm91bmRfdHJhY2sYECABKA1IBlILZ3JvdW5kVHJhY2uIAQESHwoLZml4X3F1YWxp'
    'dHkYESABKA1SCmZpeFF1YWxpdHkSGQoIZml4X3R5cGUYEiABKA1SB2ZpeFR5cGUSIAoMc2F0c1'
    '9pbl92aWV3GBMgASgNUgpzYXRzSW5WaWV3EhsKCXNlbnNvcl9pZBgUIAEoDVIIc2Vuc29ySWQS'
    'HwoLbmV4dF91cGRhdGUYFSABKA1SCm5leHRVcGRhdGUSHQoKc2VxX251bWJlchgWIAEoDVIJc2'
    'VxTnVtYmVyEiUKDnByZWNpc2lvbl9iaXRzGBcgASgNUg1wcmVjaXNpb25CaXRzIk4KCUxvY1Nv'
    'dXJjZRINCglMT0NfVU5TRVQQABIOCgpMT0NfTUFOVUFMEAESEAoMTE9DX0lOVEVSTkFMEAISEA'
    'oMTE9DX0VYVEVSTkFMEAMiYgoJQWx0U291cmNlEg0KCUFMVF9VTlNFVBAAEg4KCkFMVF9NQU5V'
    'QUwQARIQCgxBTFRfSU5URVJOQUwQAhIQCgxBTFRfRVhURVJOQUwQAxISCg5BTFRfQkFST01FVF'
    'JJQxAEQg0KC19sYXRpdHVkZV9pQg4KDF9sb25naXR1ZGVfaUILCglfYWx0aXR1ZGVCDwoNX2Fs'
    'dGl0dWRlX2hhZUIeChxfYWx0aXR1ZGVfZ2VvaWRhbF9zZXBhcmF0aW9uQg8KDV9ncm91bmRfc3'
    'BlZWRCDwoNX2dyb3VuZF90cmFjaw==');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'long_name', '3': 2, '4': 1, '5': 9, '10': 'longName'},
    {'1': 'short_name', '3': 3, '4': 1, '5': 9, '10': 'shortName'},
    {
      '1': 'macaddr',
      '3': 4,
      '4': 1,
      '5': 12,
      '8': {'3': true},
      '10': 'macaddr',
    },
    {
      '1': 'hw_model',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.HardwareModel',
      '10': 'hwModel'
    },
    {'1': 'is_licensed', '3': 6, '4': 1, '5': 8, '10': 'isLicensed'},
    {
      '1': 'role',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.Role',
      '10': 'role'
    },
    {'1': 'public_key', '3': 8, '4': 1, '5': 12, '10': 'publicKey'},
    {
      '1': 'is_unmessagable',
      '3': 9,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'isUnmessagable',
      '17': true
    },
  ],
  '8': [
    {'1': '_is_unmessagable'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIbCglsb25nX25hbWUYAiABKAlSCGxvbmdOYW1lEh0KCn'
    'Nob3J0X25hbWUYAyABKAlSCXNob3J0TmFtZRIcCgdtYWNhZGRyGAQgASgMQgIYAVIHbWFjYWRk'
    'chI0Cghod19tb2RlbBgFIAEoDjIZLm1lc2h0YXN0aWMuSGFyZHdhcmVNb2RlbFIHaHdNb2RlbB'
    'IfCgtpc19saWNlbnNlZBgGIAEoCFIKaXNMaWNlbnNlZBI4CgRyb2xlGAcgASgOMiQubWVzaHRh'
    'c3RpYy5Db25maWcuRGV2aWNlQ29uZmlnLlJvbGVSBHJvbGUSHQoKcHVibGljX2tleRgIIAEoDF'
    'IJcHVibGljS2V5EiwKD2lzX3VubWVzc2FnYWJsZRgJIAEoCEgAUg5pc1VubWVzc2FnYWJsZYgB'
    'AUISChBfaXNfdW5tZXNzYWdhYmxl');

@$core.Deprecated('Use routeDiscoveryDescriptor instead')
const RouteDiscovery$json = {
  '1': 'RouteDiscovery',
  '2': [
    {'1': 'route', '3': 1, '4': 3, '5': 7, '10': 'route'},
    {'1': 'snr_towards', '3': 2, '4': 3, '5': 5, '10': 'snrTowards'},
    {'1': 'route_back', '3': 3, '4': 3, '5': 7, '10': 'routeBack'},
    {'1': 'snr_back', '3': 4, '4': 3, '5': 5, '10': 'snrBack'},
  ],
};

/// Descriptor for `RouteDiscovery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeDiscoveryDescriptor = $convert.base64Decode(
    'Cg5Sb3V0ZURpc2NvdmVyeRIUCgVyb3V0ZRgBIAMoB1IFcm91dGUSHwoLc25yX3Rvd2FyZHMYAi'
    'ADKAVSCnNuclRvd2FyZHMSHQoKcm91dGVfYmFjaxgDIAMoB1IJcm91dGVCYWNrEhkKCHNucl9i'
    'YWNrGAQgAygFUgdzbnJCYWNr');

@$core.Deprecated('Use routingDescriptor instead')
const Routing$json = {
  '1': 'Routing',
  '2': [
    {
      '1': 'route_request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.RouteDiscovery',
      '9': 0,
      '10': 'routeRequest'
    },
    {
      '1': 'route_reply',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.RouteDiscovery',
      '9': 0,
      '10': 'routeReply'
    },
    {
      '1': 'error_reason',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Routing.Error',
      '9': 0,
      '10': 'errorReason'
    },
  ],
  '4': [Routing_Error$json],
  '8': [
    {'1': 'variant'},
  ],
};

@$core.Deprecated('Use routingDescriptor instead')
const Routing_Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'NO_ROUTE', '2': 1},
    {'1': 'GOT_NAK', '2': 2},
    {'1': 'TIMEOUT', '2': 3},
    {'1': 'NO_INTERFACE', '2': 4},
    {'1': 'MAX_RETRANSMIT', '2': 5},
    {'1': 'NO_CHANNEL', '2': 6},
    {'1': 'TOO_LARGE', '2': 7},
    {'1': 'NO_RESPONSE', '2': 8},
    {'1': 'DUTY_CYCLE_LIMIT', '2': 9},
    {'1': 'BAD_REQUEST', '2': 32},
    {'1': 'NOT_AUTHORIZED', '2': 33},
    {'1': 'PKI_FAILED', '2': 34},
    {'1': 'PKI_UNKNOWN_PUBKEY', '2': 35},
    {'1': 'ADMIN_BAD_SESSION_KEY', '2': 36},
    {'1': 'ADMIN_PUBLIC_KEY_UNAUTHORIZED', '2': 37},
    {'1': 'RATE_LIMIT_EXCEEDED', '2': 38},
  ],
};

/// Descriptor for `Routing`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routingDescriptor = $convert.base64Decode(
    'CgdSb3V0aW5nEkEKDXJvdXRlX3JlcXVlc3QYASABKAsyGi5tZXNodGFzdGljLlJvdXRlRGlzY2'
    '92ZXJ5SABSDHJvdXRlUmVxdWVzdBI9Cgtyb3V0ZV9yZXBseRgCIAEoCzIaLm1lc2h0YXN0aWMu'
    'Um91dGVEaXNjb3ZlcnlIAFIKcm91dGVSZXBseRI+CgxlcnJvcl9yZWFzb24YAyABKA4yGS5tZX'
    'NodGFzdGljLlJvdXRpbmcuRXJyb3JIAFILZXJyb3JSZWFzb24iyQIKBUVycm9yEggKBE5PTkUQ'
    'ABIMCghOT19ST1VURRABEgsKB0dPVF9OQUsQAhILCgdUSU1FT1VUEAMSEAoMTk9fSU5URVJGQU'
    'NFEAQSEgoOTUFYX1JFVFJBTlNNSVQQBRIOCgpOT19DSEFOTkVMEAYSDQoJVE9PX0xBUkdFEAcS'
    'DwoLTk9fUkVTUE9OU0UQCBIUChBEVVRZX0NZQ0xFX0xJTUlUEAkSDwoLQkFEX1JFUVVFU1QQIB'
    'ISCg5OT1RfQVVUSE9SSVpFRBAhEg4KClBLSV9GQUlMRUQQIhIWChJQS0lfVU5LTk9XTl9QVUJL'
    'RVkQIxIZChVBRE1JTl9CQURfU0VTU0lPTl9LRVkQJBIhCh1BRE1JTl9QVUJMSUNfS0VZX1VOQV'
    'VUSE9SSVpFRBAlEhcKE1JBVEVfTElNSVRfRVhDRUVERUQQJkIJCgd2YXJpYW50');

@$core.Deprecated('Use dataDescriptor instead')
const Data$json = {
  '1': 'Data',
  '2': [
    {
      '1': 'portnum',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.PortNum',
      '10': 'portnum'
    },
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'want_response', '3': 3, '4': 1, '5': 8, '10': 'wantResponse'},
    {'1': 'dest', '3': 4, '4': 1, '5': 7, '10': 'dest'},
    {'1': 'source', '3': 5, '4': 1, '5': 7, '10': 'source'},
    {'1': 'request_id', '3': 6, '4': 1, '5': 7, '10': 'requestId'},
    {'1': 'reply_id', '3': 7, '4': 1, '5': 7, '10': 'replyId'},
    {'1': 'emoji', '3': 8, '4': 1, '5': 7, '10': 'emoji'},
    {
      '1': 'bitfield',
      '3': 9,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'bitfield',
      '17': true
    },
  ],
  '8': [
    {'1': '_bitfield'},
  ],
};

/// Descriptor for `Data`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataDescriptor = $convert.base64Decode(
    'CgREYXRhEi0KB3BvcnRudW0YASABKA4yEy5tZXNodGFzdGljLlBvcnROdW1SB3BvcnRudW0SGA'
    'oHcGF5bG9hZBgCIAEoDFIHcGF5bG9hZBIjCg13YW50X3Jlc3BvbnNlGAMgASgIUgx3YW50UmVz'
    'cG9uc2USEgoEZGVzdBgEIAEoB1IEZGVzdBIWCgZzb3VyY2UYBSABKAdSBnNvdXJjZRIdCgpyZX'
    'F1ZXN0X2lkGAYgASgHUglyZXF1ZXN0SWQSGQoIcmVwbHlfaWQYByABKAdSB3JlcGx5SWQSFAoF'
    'ZW1vamkYCCABKAdSBWVtb2ppEh8KCGJpdGZpZWxkGAkgASgNSABSCGJpdGZpZWxkiAEBQgsKCV'
    '9iaXRmaWVsZA==');

@$core.Deprecated('Use keyVerificationDescriptor instead')
const KeyVerification$json = {
  '1': 'KeyVerification',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 4, '10': 'nonce'},
    {'1': 'hash1', '3': 2, '4': 1, '5': 12, '10': 'hash1'},
    {'1': 'hash2', '3': 3, '4': 1, '5': 12, '10': 'hash2'},
  ],
};

/// Descriptor for `KeyVerification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyVerificationDescriptor = $convert.base64Decode(
    'Cg9LZXlWZXJpZmljYXRpb24SFAoFbm9uY2UYASABKARSBW5vbmNlEhQKBWhhc2gxGAIgASgMUg'
    'VoYXNoMRIUCgVoYXNoMhgDIAEoDFIFaGFzaDI=');

@$core.Deprecated('Use waypointDescriptor instead')
const Waypoint$json = {
  '1': 'Waypoint',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {
      '1': 'latitude_i',
      '3': 2,
      '4': 1,
      '5': 15,
      '9': 0,
      '10': 'latitudeI',
      '17': true
    },
    {
      '1': 'longitude_i',
      '3': 3,
      '4': 1,
      '5': 15,
      '9': 1,
      '10': 'longitudeI',
      '17': true
    },
    {'1': 'expire', '3': 4, '4': 1, '5': 13, '10': 'expire'},
    {'1': 'locked_to', '3': 5, '4': 1, '5': 13, '10': 'lockedTo'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 7, '4': 1, '5': 9, '10': 'description'},
    {'1': 'icon', '3': 8, '4': 1, '5': 7, '10': 'icon'},
  ],
  '8': [
    {'1': '_latitude_i'},
    {'1': '_longitude_i'},
  ],
};

/// Descriptor for `Waypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waypointDescriptor = $convert.base64Decode(
    'CghXYXlwb2ludBIOCgJpZBgBIAEoDVICaWQSIgoKbGF0aXR1ZGVfaRgCIAEoD0gAUglsYXRpdH'
    'VkZUmIAQESJAoLbG9uZ2l0dWRlX2kYAyABKA9IAVIKbG9uZ2l0dWRlSYgBARIWCgZleHBpcmUY'
    'BCABKA1SBmV4cGlyZRIbCglsb2NrZWRfdG8YBSABKA1SCGxvY2tlZFRvEhIKBG5hbWUYBiABKA'
    'lSBG5hbWUSIAoLZGVzY3JpcHRpb24YByABKAlSC2Rlc2NyaXB0aW9uEhIKBGljb24YCCABKAdS'
    'BGljb25CDQoLX2xhdGl0dWRlX2lCDgoMX2xvbmdpdHVkZV9p');

@$core.Deprecated('Use mqttClientProxyMessageDescriptor instead')
const MqttClientProxyMessage$json = {
  '1': 'MqttClientProxyMessage',
  '2': [
    {'1': 'topic', '3': 1, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'data', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'data'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'text'},
    {'1': 'retained', '3': 4, '4': 1, '5': 8, '10': 'retained'},
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

/// Descriptor for `MqttClientProxyMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mqttClientProxyMessageDescriptor = $convert.base64Decode(
    'ChZNcXR0Q2xpZW50UHJveHlNZXNzYWdlEhQKBXRvcGljGAEgASgJUgV0b3BpYxIUCgRkYXRhGA'
    'IgASgMSABSBGRhdGESFAoEdGV4dBgDIAEoCUgAUgR0ZXh0EhoKCHJldGFpbmVkGAQgASgIUghy'
    'ZXRhaW5lZEIRCg9wYXlsb2FkX3ZhcmlhbnQ=');

@$core.Deprecated('Use meshPacketDescriptor instead')
const MeshPacket$json = {
  '1': 'MeshPacket',
  '2': [
    {'1': 'from', '3': 1, '4': 1, '5': 7, '10': 'from'},
    {'1': 'to', '3': 2, '4': 1, '5': 7, '10': 'to'},
    {'1': 'channel', '3': 3, '4': 1, '5': 13, '10': 'channel'},
    {
      '1': 'decoded',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Data',
      '9': 0,
      '10': 'decoded'
    },
    {'1': 'encrypted', '3': 5, '4': 1, '5': 12, '9': 0, '10': 'encrypted'},
    {'1': 'id', '3': 6, '4': 1, '5': 7, '10': 'id'},
    {'1': 'rx_time', '3': 7, '4': 1, '5': 7, '10': 'rxTime'},
    {'1': 'rx_snr', '3': 8, '4': 1, '5': 2, '10': 'rxSnr'},
    {'1': 'hop_limit', '3': 9, '4': 1, '5': 13, '10': 'hopLimit'},
    {'1': 'want_ack', '3': 10, '4': 1, '5': 8, '10': 'wantAck'},
    {
      '1': 'priority',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.MeshPacket.Priority',
      '10': 'priority'
    },
    {'1': 'rx_rssi', '3': 12, '4': 1, '5': 5, '10': 'rxRssi'},
    {
      '1': 'delayed',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.MeshPacket.Delayed',
      '8': {'3': true},
      '10': 'delayed',
    },
    {'1': 'via_mqtt', '3': 14, '4': 1, '5': 8, '10': 'viaMqtt'},
    {'1': 'hop_start', '3': 15, '4': 1, '5': 13, '10': 'hopStart'},
    {'1': 'public_key', '3': 16, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'pki_encrypted', '3': 17, '4': 1, '5': 8, '10': 'pkiEncrypted'},
    {'1': 'next_hop', '3': 18, '4': 1, '5': 13, '10': 'nextHop'},
    {'1': 'relay_node', '3': 19, '4': 1, '5': 13, '10': 'relayNode'},
    {'1': 'tx_after', '3': 20, '4': 1, '5': 13, '10': 'txAfter'},
    {
      '1': 'transport_mechanism',
      '3': 21,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.MeshPacket.TransportMechanism',
      '10': 'transportMechanism'
    },
  ],
  '4': [
    MeshPacket_Priority$json,
    MeshPacket_Delayed$json,
    MeshPacket_TransportMechanism$json
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

@$core.Deprecated('Use meshPacketDescriptor instead')
const MeshPacket_Priority$json = {
  '1': 'Priority',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'MIN', '2': 1},
    {'1': 'BACKGROUND', '2': 10},
    {'1': 'DEFAULT', '2': 64},
    {'1': 'RELIABLE', '2': 70},
    {'1': 'RESPONSE', '2': 80},
    {'1': 'HIGH', '2': 100},
    {'1': 'ALERT', '2': 110},
    {'1': 'ACK', '2': 120},
    {'1': 'MAX', '2': 127},
  ],
};

@$core.Deprecated('Use meshPacketDescriptor instead')
const MeshPacket_Delayed$json = {
  '1': 'Delayed',
  '2': [
    {'1': 'NO_DELAY', '2': 0},
    {'1': 'DELAYED_BROADCAST', '2': 1},
    {'1': 'DELAYED_DIRECT', '2': 2},
  ],
};

@$core.Deprecated('Use meshPacketDescriptor instead')
const MeshPacket_TransportMechanism$json = {
  '1': 'TransportMechanism',
  '2': [
    {'1': 'TRANSPORT_INTERNAL', '2': 0},
    {'1': 'TRANSPORT_LORA', '2': 1},
    {'1': 'TRANSPORT_LORA_ALT1', '2': 2},
    {'1': 'TRANSPORT_LORA_ALT2', '2': 3},
    {'1': 'TRANSPORT_LORA_ALT3', '2': 4},
    {'1': 'TRANSPORT_MQTT', '2': 5},
    {'1': 'TRANSPORT_MULTICAST_UDP', '2': 6},
    {'1': 'TRANSPORT_API', '2': 7},
  ],
};

/// Descriptor for `MeshPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List meshPacketDescriptor = $convert.base64Decode(
    'CgpNZXNoUGFja2V0EhIKBGZyb20YASABKAdSBGZyb20SDgoCdG8YAiABKAdSAnRvEhgKB2NoYW'
    '5uZWwYAyABKA1SB2NoYW5uZWwSLAoHZGVjb2RlZBgEIAEoCzIQLm1lc2h0YXN0aWMuRGF0YUgA'
    'UgdkZWNvZGVkEh4KCWVuY3J5cHRlZBgFIAEoDEgAUgllbmNyeXB0ZWQSDgoCaWQYBiABKAdSAm'
    'lkEhcKB3J4X3RpbWUYByABKAdSBnJ4VGltZRIVCgZyeF9zbnIYCCABKAJSBXJ4U25yEhsKCWhv'
    'cF9saW1pdBgJIAEoDVIIaG9wTGltaXQSGQoId2FudF9hY2sYCiABKAhSB3dhbnRBY2sSOwoIcH'
    'Jpb3JpdHkYCyABKA4yHy5tZXNodGFzdGljLk1lc2hQYWNrZXQuUHJpb3JpdHlSCHByaW9yaXR5'
    'EhcKB3J4X3Jzc2kYDCABKAVSBnJ4UnNzaRI8CgdkZWxheWVkGA0gASgOMh4ubWVzaHRhc3RpYy'
    '5NZXNoUGFja2V0LkRlbGF5ZWRCAhgBUgdkZWxheWVkEhkKCHZpYV9tcXR0GA4gASgIUgd2aWFN'
    'cXR0EhsKCWhvcF9zdGFydBgPIAEoDVIIaG9wU3RhcnQSHQoKcHVibGljX2tleRgQIAEoDFIJcH'
    'VibGljS2V5EiMKDXBraV9lbmNyeXB0ZWQYESABKAhSDHBraUVuY3J5cHRlZBIZCghuZXh0X2hv'
    'cBgSIAEoDVIHbmV4dEhvcBIdCgpyZWxheV9ub2RlGBMgASgNUglyZWxheU5vZGUSGQoIdHhfYW'
    'Z0ZXIYFCABKA1SB3R4QWZ0ZXISWgoTdHJhbnNwb3J0X21lY2hhbmlzbRgVIAEoDjIpLm1lc2h0'
    'YXN0aWMuTWVzaFBhY2tldC5UcmFuc3BvcnRNZWNoYW5pc21SEnRyYW5zcG9ydE1lY2hhbmlzbS'
    'J+CghQcmlvcml0eRIJCgVVTlNFVBAAEgcKA01JThABEg4KCkJBQ0tHUk9VTkQQChILCgdERUZB'
    'VUxUEEASDAoIUkVMSUFCTEUQRhIMCghSRVNQT05TRRBQEggKBEhJR0gQZBIJCgVBTEVSVBBuEg'
    'cKA0FDSxB4EgcKA01BWBB/IkIKB0RlbGF5ZWQSDAoITk9fREVMQVkQABIVChFERUxBWUVEX0JS'
    'T0FEQ0FTVBABEhIKDkRFTEFZRURfRElSRUNUEAIizwEKElRyYW5zcG9ydE1lY2hhbmlzbRIWCh'
    'JUUkFOU1BPUlRfSU5URVJOQUwQABISCg5UUkFOU1BPUlRfTE9SQRABEhcKE1RSQU5TUE9SVF9M'
    'T1JBX0FMVDEQAhIXChNUUkFOU1BPUlRfTE9SQV9BTFQyEAMSFwoTVFJBTlNQT1JUX0xPUkFfQU'
    'xUMxAEEhIKDlRSQU5TUE9SVF9NUVRUEAUSGwoXVFJBTlNQT1JUX01VTFRJQ0FTVF9VRFAQBhIR'
    'Cg1UUkFOU1BPUlRfQVBJEAdCEQoPcGF5bG9hZF92YXJpYW50');

@$core.Deprecated('Use nodeInfoDescriptor instead')
const NodeInfo$json = {
  '1': 'NodeInfo',
  '2': [
    {'1': 'num', '3': 1, '4': 1, '5': 13, '10': 'num'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.User',
      '10': 'user'
    },
    {
      '1': 'position',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Position',
      '10': 'position'
    },
    {'1': 'snr', '3': 4, '4': 1, '5': 2, '10': 'snr'},
    {'1': 'last_heard', '3': 5, '4': 1, '5': 7, '10': 'lastHeard'},
    {
      '1': 'device_metrics',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceMetrics',
      '10': 'deviceMetrics'
    },
    {'1': 'channel', '3': 7, '4': 1, '5': 13, '10': 'channel'},
    {'1': 'via_mqtt', '3': 8, '4': 1, '5': 8, '10': 'viaMqtt'},
    {
      '1': 'hops_away',
      '3': 9,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'hopsAway',
      '17': true
    },
    {'1': 'is_favorite', '3': 10, '4': 1, '5': 8, '10': 'isFavorite'},
    {'1': 'is_ignored', '3': 11, '4': 1, '5': 8, '10': 'isIgnored'},
    {
      '1': 'is_key_manually_verified',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'isKeyManuallyVerified'
    },
  ],
  '8': [
    {'1': '_hops_away'},
  ],
};

/// Descriptor for `NodeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeInfoDescriptor = $convert.base64Decode(
    'CghOb2RlSW5mbxIQCgNudW0YASABKA1SA251bRIkCgR1c2VyGAIgASgLMhAubWVzaHRhc3RpYy'
    '5Vc2VyUgR1c2VyEjAKCHBvc2l0aW9uGAMgASgLMhQubWVzaHRhc3RpYy5Qb3NpdGlvblIIcG9z'
    'aXRpb24SEAoDc25yGAQgASgCUgNzbnISHQoKbGFzdF9oZWFyZBgFIAEoB1IJbGFzdEhlYXJkEk'
    'AKDmRldmljZV9tZXRyaWNzGAYgASgLMhkubWVzaHRhc3RpYy5EZXZpY2VNZXRyaWNzUg1kZXZp'
    'Y2VNZXRyaWNzEhgKB2NoYW5uZWwYByABKA1SB2NoYW5uZWwSGQoIdmlhX21xdHQYCCABKAhSB3'
    'ZpYU1xdHQSIAoJaG9wc19hd2F5GAkgASgNSABSCGhvcHNBd2F5iAEBEh8KC2lzX2Zhdm9yaXRl'
    'GAogASgIUgppc0Zhdm9yaXRlEh0KCmlzX2lnbm9yZWQYCyABKAhSCWlzSWdub3JlZBI3Chhpc1'
    '9rZXlfbWFudWFsbHlfdmVyaWZpZWQYDCABKAhSFWlzS2V5TWFudWFsbHlWZXJpZmllZEIMCgpf'
    'aG9wc19hd2F5');

@$core.Deprecated('Use myNodeInfoDescriptor instead')
const MyNodeInfo$json = {
  '1': 'MyNodeInfo',
  '2': [
    {'1': 'my_node_num', '3': 1, '4': 1, '5': 13, '10': 'myNodeNum'},
    {'1': 'reboot_count', '3': 8, '4': 1, '5': 13, '10': 'rebootCount'},
    {'1': 'min_app_version', '3': 11, '4': 1, '5': 13, '10': 'minAppVersion'},
    {'1': 'device_id', '3': 12, '4': 1, '5': 12, '10': 'deviceId'},
    {'1': 'pio_env', '3': 13, '4': 1, '5': 9, '10': 'pioEnv'},
    {
      '1': 'firmware_edition',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.FirmwareEdition',
      '10': 'firmwareEdition'
    },
    {'1': 'nodedb_count', '3': 15, '4': 1, '5': 13, '10': 'nodedbCount'},
  ],
};

/// Descriptor for `MyNodeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myNodeInfoDescriptor = $convert.base64Decode(
    'CgpNeU5vZGVJbmZvEh4KC215X25vZGVfbnVtGAEgASgNUglteU5vZGVOdW0SIQoMcmVib290X2'
    'NvdW50GAggASgNUgtyZWJvb3RDb3VudBImCg9taW5fYXBwX3ZlcnNpb24YCyABKA1SDW1pbkFw'
    'cFZlcnNpb24SGwoJZGV2aWNlX2lkGAwgASgMUghkZXZpY2VJZBIXCgdwaW9fZW52GA0gASgJUg'
    'ZwaW9FbnYSRgoQZmlybXdhcmVfZWRpdGlvbhgOIAEoDjIbLm1lc2h0YXN0aWMuRmlybXdhcmVF'
    'ZGl0aW9uUg9maXJtd2FyZUVkaXRpb24SIQoMbm9kZWRiX2NvdW50GA8gASgNUgtub2RlZGJDb3'
    'VudA==');

@$core.Deprecated('Use logRecordDescriptor instead')
const LogRecord$json = {
  '1': 'LogRecord',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'time', '3': 2, '4': 1, '5': 7, '10': 'time'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'level',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.LogRecord.Level',
      '10': 'level'
    },
  ],
  '4': [LogRecord_Level$json],
};

@$core.Deprecated('Use logRecordDescriptor instead')
const LogRecord_Level$json = {
  '1': 'Level',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'CRITICAL', '2': 50},
    {'1': 'ERROR', '2': 40},
    {'1': 'WARNING', '2': 30},
    {'1': 'INFO', '2': 20},
    {'1': 'DEBUG', '2': 10},
    {'1': 'TRACE', '2': 5},
  ],
};

/// Descriptor for `LogRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logRecordDescriptor = $convert.base64Decode(
    'CglMb2dSZWNvcmQSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRISCgR0aW1lGAIgASgHUgR0aW'
    '1lEhYKBnNvdXJjZRgDIAEoCVIGc291cmNlEjEKBWxldmVsGAQgASgOMhsubWVzaHRhc3RpYy5M'
    'b2dSZWNvcmQuTGV2ZWxSBWxldmVsIlgKBUxldmVsEgkKBVVOU0VUEAASDAoIQ1JJVElDQUwQMh'
    'IJCgVFUlJPUhAoEgsKB1dBUk5JTkcQHhIICgRJTkZPEBQSCQoFREVCVUcQChIJCgVUUkFDRRAF');

@$core.Deprecated('Use queueStatusDescriptor instead')
const QueueStatus$json = {
  '1': 'QueueStatus',
  '2': [
    {'1': 'res', '3': 1, '4': 1, '5': 5, '10': 'res'},
    {'1': 'free', '3': 2, '4': 1, '5': 13, '10': 'free'},
    {'1': 'maxlen', '3': 3, '4': 1, '5': 13, '10': 'maxlen'},
    {'1': 'mesh_packet_id', '3': 4, '4': 1, '5': 13, '10': 'meshPacketId'},
  ],
};

/// Descriptor for `QueueStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queueStatusDescriptor = $convert.base64Decode(
    'CgtRdWV1ZVN0YXR1cxIQCgNyZXMYASABKAVSA3JlcxISCgRmcmVlGAIgASgNUgRmcmVlEhYKBm'
    '1heGxlbhgDIAEoDVIGbWF4bGVuEiQKDm1lc2hfcGFja2V0X2lkGAQgASgNUgxtZXNoUGFja2V0'
    'SWQ=');

@$core.Deprecated('Use fromRadioDescriptor instead')
const FromRadio$json = {
  '1': 'FromRadio',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {
      '1': 'packet',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MeshPacket',
      '9': 0,
      '10': 'packet'
    },
    {
      '1': 'my_info',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MyNodeInfo',
      '9': 0,
      '10': 'myInfo'
    },
    {
      '1': 'node_info',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NodeInfo',
      '9': 0,
      '10': 'nodeInfo'
    },
    {
      '1': 'config',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config',
      '9': 0,
      '10': 'config'
    },
    {
      '1': 'log_record',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.LogRecord',
      '9': 0,
      '10': 'logRecord'
    },
    {
      '1': 'config_complete_id',
      '3': 7,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'configCompleteId'
    },
    {'1': 'rebooted', '3': 8, '4': 1, '5': 8, '9': 0, '10': 'rebooted'},
    {
      '1': 'moduleConfig',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig',
      '9': 0,
      '10': 'moduleConfig'
    },
    {
      '1': 'channel',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Channel',
      '9': 0,
      '10': 'channel'
    },
    {
      '1': 'queueStatus',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.QueueStatus',
      '9': 0,
      '10': 'queueStatus'
    },
    {
      '1': 'xmodemPacket',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.XModem',
      '9': 0,
      '10': 'xmodemPacket'
    },
    {
      '1': 'metadata',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceMetadata',
      '9': 0,
      '10': 'metadata'
    },
    {
      '1': 'mqttClientProxyMessage',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MqttClientProxyMessage',
      '9': 0,
      '10': 'mqttClientProxyMessage'
    },
    {
      '1': 'fileInfo',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.FileInfo',
      '9': 0,
      '10': 'fileInfo'
    },
    {
      '1': 'clientNotification',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ClientNotification',
      '9': 0,
      '10': 'clientNotification'
    },
    {
      '1': 'deviceuiConfig',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceUIConfig',
      '9': 0,
      '10': 'deviceuiConfig'
    },
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

/// Descriptor for `FromRadio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fromRadioDescriptor = $convert.base64Decode(
    'CglGcm9tUmFkaW8SDgoCaWQYASABKA1SAmlkEjAKBnBhY2tldBgCIAEoCzIWLm1lc2h0YXN0aW'
    'MuTWVzaFBhY2tldEgAUgZwYWNrZXQSMQoHbXlfaW5mbxgDIAEoCzIWLm1lc2h0YXN0aWMuTXlO'
    'b2RlSW5mb0gAUgZteUluZm8SMwoJbm9kZV9pbmZvGAQgASgLMhQubWVzaHRhc3RpYy5Ob2RlSW'
    '5mb0gAUghub2RlSW5mbxIsCgZjb25maWcYBSABKAsyEi5tZXNodGFzdGljLkNvbmZpZ0gAUgZj'
    'b25maWcSNgoKbG9nX3JlY29yZBgGIAEoCzIVLm1lc2h0YXN0aWMuTG9nUmVjb3JkSABSCWxvZ1'
    'JlY29yZBIuChJjb25maWdfY29tcGxldGVfaWQYByABKA1IAFIQY29uZmlnQ29tcGxldGVJZBIc'
    'CghyZWJvb3RlZBgIIAEoCEgAUghyZWJvb3RlZBI+Cgxtb2R1bGVDb25maWcYCSABKAsyGC5tZX'
    'NodGFzdGljLk1vZHVsZUNvbmZpZ0gAUgxtb2R1bGVDb25maWcSLwoHY2hhbm5lbBgKIAEoCzIT'
    'Lm1lc2h0YXN0aWMuQ2hhbm5lbEgAUgdjaGFubmVsEjsKC3F1ZXVlU3RhdHVzGAsgASgLMhcubW'
    'VzaHRhc3RpYy5RdWV1ZVN0YXR1c0gAUgtxdWV1ZVN0YXR1cxI4Cgx4bW9kZW1QYWNrZXQYDCAB'
    'KAsyEi5tZXNodGFzdGljLlhNb2RlbUgAUgx4bW9kZW1QYWNrZXQSOAoIbWV0YWRhdGEYDSABKA'
    'syGi5tZXNodGFzdGljLkRldmljZU1ldGFkYXRhSABSCG1ldGFkYXRhElwKFm1xdHRDbGllbnRQ'
    'cm94eU1lc3NhZ2UYDiABKAsyIi5tZXNodGFzdGljLk1xdHRDbGllbnRQcm94eU1lc3NhZ2VIAF'
    'IWbXF0dENsaWVudFByb3h5TWVzc2FnZRIyCghmaWxlSW5mbxgPIAEoCzIULm1lc2h0YXN0aWMu'
    'RmlsZUluZm9IAFIIZmlsZUluZm8SUAoSY2xpZW50Tm90aWZpY2F0aW9uGBAgASgLMh4ubWVzaH'
    'Rhc3RpYy5DbGllbnROb3RpZmljYXRpb25IAFISY2xpZW50Tm90aWZpY2F0aW9uEkQKDmRldmlj'
    'ZXVpQ29uZmlnGBEgASgLMhoubWVzaHRhc3RpYy5EZXZpY2VVSUNvbmZpZ0gAUg5kZXZpY2V1aU'
    'NvbmZpZ0IRCg9wYXlsb2FkX3ZhcmlhbnQ=');

@$core.Deprecated('Use clientNotificationDescriptor instead')
const ClientNotification$json = {
  '1': 'ClientNotification',
  '2': [
    {
      '1': 'reply_id',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'replyId',
      '17': true
    },
    {'1': 'time', '3': 2, '4': 1, '5': 7, '10': 'time'},
    {
      '1': 'level',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.LogRecord.Level',
      '10': 'level'
    },
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'key_verification_number_inform',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.KeyVerificationNumberInform',
      '9': 0,
      '10': 'keyVerificationNumberInform'
    },
    {
      '1': 'key_verification_number_request',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.KeyVerificationNumberRequest',
      '9': 0,
      '10': 'keyVerificationNumberRequest'
    },
    {
      '1': 'key_verification_final',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.KeyVerificationFinal',
      '9': 0,
      '10': 'keyVerificationFinal'
    },
    {
      '1': 'duplicated_public_key',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DuplicatedPublicKey',
      '9': 0,
      '10': 'duplicatedPublicKey'
    },
    {
      '1': 'low_entropy_key',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.LowEntropyKey',
      '9': 0,
      '10': 'lowEntropyKey'
    },
  ],
  '8': [
    {'1': 'payload_variant'},
    {'1': '_reply_id'},
  ],
};

/// Descriptor for `ClientNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientNotificationDescriptor = $convert.base64Decode(
    'ChJDbGllbnROb3RpZmljYXRpb24SHgoIcmVwbHlfaWQYASABKA1IAVIHcmVwbHlJZIgBARISCg'
    'R0aW1lGAIgASgHUgR0aW1lEjEKBWxldmVsGAMgASgOMhsubWVzaHRhc3RpYy5Mb2dSZWNvcmQu'
    'TGV2ZWxSBWxldmVsEhgKB21lc3NhZ2UYBCABKAlSB21lc3NhZ2USbgoea2V5X3ZlcmlmaWNhdG'
    'lvbl9udW1iZXJfaW5mb3JtGAsgASgLMicubWVzaHRhc3RpYy5LZXlWZXJpZmljYXRpb25OdW1i'
    'ZXJJbmZvcm1IAFIba2V5VmVyaWZpY2F0aW9uTnVtYmVySW5mb3JtEnEKH2tleV92ZXJpZmljYX'
    'Rpb25fbnVtYmVyX3JlcXVlc3QYDCABKAsyKC5tZXNodGFzdGljLktleVZlcmlmaWNhdGlvbk51'
    'bWJlclJlcXVlc3RIAFIca2V5VmVyaWZpY2F0aW9uTnVtYmVyUmVxdWVzdBJYChZrZXlfdmVyaW'
    'ZpY2F0aW9uX2ZpbmFsGA0gASgLMiAubWVzaHRhc3RpYy5LZXlWZXJpZmljYXRpb25GaW5hbEgA'
    'UhRrZXlWZXJpZmljYXRpb25GaW5hbBJVChVkdXBsaWNhdGVkX3B1YmxpY19rZXkYDiABKAsyHy'
    '5tZXNodGFzdGljLkR1cGxpY2F0ZWRQdWJsaWNLZXlIAFITZHVwbGljYXRlZFB1YmxpY0tleRJD'
    'Cg9sb3dfZW50cm9weV9rZXkYDyABKAsyGS5tZXNodGFzdGljLkxvd0VudHJvcHlLZXlIAFINbG'
    '93RW50cm9weUtleUIRCg9wYXlsb2FkX3ZhcmlhbnRCCwoJX3JlcGx5X2lk');

@$core.Deprecated('Use keyVerificationNumberInformDescriptor instead')
const KeyVerificationNumberInform$json = {
  '1': 'KeyVerificationNumberInform',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 4, '10': 'nonce'},
    {'1': 'remote_longname', '3': 2, '4': 1, '5': 9, '10': 'remoteLongname'},
    {'1': 'security_number', '3': 3, '4': 1, '5': 13, '10': 'securityNumber'},
  ],
};

/// Descriptor for `KeyVerificationNumberInform`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyVerificationNumberInformDescriptor =
    $convert.base64Decode(
        'ChtLZXlWZXJpZmljYXRpb25OdW1iZXJJbmZvcm0SFAoFbm9uY2UYASABKARSBW5vbmNlEicKD3'
        'JlbW90ZV9sb25nbmFtZRgCIAEoCVIOcmVtb3RlTG9uZ25hbWUSJwoPc2VjdXJpdHlfbnVtYmVy'
        'GAMgASgNUg5zZWN1cml0eU51bWJlcg==');

@$core.Deprecated('Use keyVerificationNumberRequestDescriptor instead')
const KeyVerificationNumberRequest$json = {
  '1': 'KeyVerificationNumberRequest',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 4, '10': 'nonce'},
    {'1': 'remote_longname', '3': 2, '4': 1, '5': 9, '10': 'remoteLongname'},
  ],
};

/// Descriptor for `KeyVerificationNumberRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyVerificationNumberRequestDescriptor =
    $convert.base64Decode(
        'ChxLZXlWZXJpZmljYXRpb25OdW1iZXJSZXF1ZXN0EhQKBW5vbmNlGAEgASgEUgVub25jZRInCg'
        '9yZW1vdGVfbG9uZ25hbWUYAiABKAlSDnJlbW90ZUxvbmduYW1l');

@$core.Deprecated('Use keyVerificationFinalDescriptor instead')
const KeyVerificationFinal$json = {
  '1': 'KeyVerificationFinal',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 4, '10': 'nonce'},
    {'1': 'remote_longname', '3': 2, '4': 1, '5': 9, '10': 'remoteLongname'},
    {'1': 'isSender', '3': 3, '4': 1, '5': 8, '10': 'isSender'},
    {
      '1': 'verification_characters',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'verificationCharacters'
    },
  ],
};

/// Descriptor for `KeyVerificationFinal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyVerificationFinalDescriptor = $convert.base64Decode(
    'ChRLZXlWZXJpZmljYXRpb25GaW5hbBIUCgVub25jZRgBIAEoBFIFbm9uY2USJwoPcmVtb3RlX2'
    'xvbmduYW1lGAIgASgJUg5yZW1vdGVMb25nbmFtZRIaCghpc1NlbmRlchgDIAEoCFIIaXNTZW5k'
    'ZXISNwoXdmVyaWZpY2F0aW9uX2NoYXJhY3RlcnMYBCABKAlSFnZlcmlmaWNhdGlvbkNoYXJhY3'
    'RlcnM=');

@$core.Deprecated('Use duplicatedPublicKeyDescriptor instead')
const DuplicatedPublicKey$json = {
  '1': 'DuplicatedPublicKey',
};

/// Descriptor for `DuplicatedPublicKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List duplicatedPublicKeyDescriptor =
    $convert.base64Decode('ChNEdXBsaWNhdGVkUHVibGljS2V5');

@$core.Deprecated('Use lowEntropyKeyDescriptor instead')
const LowEntropyKey$json = {
  '1': 'LowEntropyKey',
};

/// Descriptor for `LowEntropyKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lowEntropyKeyDescriptor =
    $convert.base64Decode('Cg1Mb3dFbnRyb3B5S2V5');

@$core.Deprecated('Use fileInfoDescriptor instead')
const FileInfo$json = {
  '1': 'FileInfo',
  '2': [
    {'1': 'file_name', '3': 1, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 13, '10': 'sizeBytes'},
  ],
};

/// Descriptor for `FileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileInfoDescriptor = $convert.base64Decode(
    'CghGaWxlSW5mbxIbCglmaWxlX25hbWUYASABKAlSCGZpbGVOYW1lEh0KCnNpemVfYnl0ZXMYAi'
    'ABKA1SCXNpemVCeXRlcw==');

@$core.Deprecated('Use toRadioDescriptor instead')
const ToRadio$json = {
  '1': 'ToRadio',
  '2': [
    {
      '1': 'packet',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MeshPacket',
      '9': 0,
      '10': 'packet'
    },
    {
      '1': 'want_config_id',
      '3': 3,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'wantConfigId'
    },
    {'1': 'disconnect', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'disconnect'},
    {
      '1': 'xmodemPacket',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.XModem',
      '9': 0,
      '10': 'xmodemPacket'
    },
    {
      '1': 'mqttClientProxyMessage',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.MqttClientProxyMessage',
      '9': 0,
      '10': 'mqttClientProxyMessage'
    },
    {
      '1': 'heartbeat',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Heartbeat',
      '9': 0,
      '10': 'heartbeat'
    },
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

/// Descriptor for `ToRadio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toRadioDescriptor = $convert.base64Decode(
    'CgdUb1JhZGlvEjAKBnBhY2tldBgBIAEoCzIWLm1lc2h0YXN0aWMuTWVzaFBhY2tldEgAUgZwYW'
    'NrZXQSJgoOd2FudF9jb25maWdfaWQYAyABKA1IAFIMd2FudENvbmZpZ0lkEiAKCmRpc2Nvbm5l'
    'Y3QYBCABKAhIAFIKZGlzY29ubmVjdBI4Cgx4bW9kZW1QYWNrZXQYBSABKAsyEi5tZXNodGFzdG'
    'ljLlhNb2RlbUgAUgx4bW9kZW1QYWNrZXQSXAoWbXF0dENsaWVudFByb3h5TWVzc2FnZRgGIAEo'
    'CzIiLm1lc2h0YXN0aWMuTXF0dENsaWVudFByb3h5TWVzc2FnZUgAUhZtcXR0Q2xpZW50UHJveH'
    'lNZXNzYWdlEjUKCWhlYXJ0YmVhdBgHIAEoCzIVLm1lc2h0YXN0aWMuSGVhcnRiZWF0SABSCWhl'
    'YXJ0YmVhdEIRCg9wYXlsb2FkX3ZhcmlhbnQ=');

@$core.Deprecated('Use compressedDescriptor instead')
const Compressed$json = {
  '1': 'Compressed',
  '2': [
    {
      '1': 'portnum',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.PortNum',
      '10': 'portnum'
    },
    {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Compressed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compressedDescriptor = $convert.base64Decode(
    'CgpDb21wcmVzc2VkEi0KB3BvcnRudW0YASABKA4yEy5tZXNodGFzdGljLlBvcnROdW1SB3Bvcn'
    'RudW0SEgoEZGF0YRgCIAEoDFIEZGF0YQ==');

@$core.Deprecated('Use neighborInfoDescriptor instead')
const NeighborInfo$json = {
  '1': 'NeighborInfo',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 13, '10': 'nodeId'},
    {'1': 'last_sent_by_id', '3': 2, '4': 1, '5': 13, '10': 'lastSentById'},
    {
      '1': 'node_broadcast_interval_secs',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'nodeBroadcastIntervalSecs'
    },
    {
      '1': 'neighbors',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.meshtastic.Neighbor',
      '10': 'neighbors'
    },
  ],
};

/// Descriptor for `NeighborInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List neighborInfoDescriptor = $convert.base64Decode(
    'CgxOZWlnaGJvckluZm8SFwoHbm9kZV9pZBgBIAEoDVIGbm9kZUlkEiUKD2xhc3Rfc2VudF9ieV'
    '9pZBgCIAEoDVIMbGFzdFNlbnRCeUlkEj8KHG5vZGVfYnJvYWRjYXN0X2ludGVydmFsX3NlY3MY'
    'AyABKA1SGW5vZGVCcm9hZGNhc3RJbnRlcnZhbFNlY3MSMgoJbmVpZ2hib3JzGAQgAygLMhQubW'
    'VzaHRhc3RpYy5OZWlnaGJvclIJbmVpZ2hib3Jz');

@$core.Deprecated('Use neighborDescriptor instead')
const Neighbor$json = {
  '1': 'Neighbor',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 13, '10': 'nodeId'},
    {'1': 'snr', '3': 2, '4': 1, '5': 2, '10': 'snr'},
    {'1': 'last_rx_time', '3': 3, '4': 1, '5': 7, '10': 'lastRxTime'},
    {
      '1': 'node_broadcast_interval_secs',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'nodeBroadcastIntervalSecs'
    },
  ],
};

/// Descriptor for `Neighbor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List neighborDescriptor = $convert.base64Decode(
    'CghOZWlnaGJvchIXCgdub2RlX2lkGAEgASgNUgZub2RlSWQSEAoDc25yGAIgASgCUgNzbnISIA'
    'oMbGFzdF9yeF90aW1lGAMgASgHUgpsYXN0UnhUaW1lEj8KHG5vZGVfYnJvYWRjYXN0X2ludGVy'
    'dmFsX3NlY3MYBCABKA1SGW5vZGVCcm9hZGNhc3RJbnRlcnZhbFNlY3M=');

@$core.Deprecated('Use deviceMetadataDescriptor instead')
const DeviceMetadata$json = {
  '1': 'DeviceMetadata',
  '2': [
    {'1': 'firmware_version', '3': 1, '4': 1, '5': 9, '10': 'firmwareVersion'},
    {
      '1': 'device_state_version',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'deviceStateVersion'
    },
    {'1': 'canShutdown', '3': 3, '4': 1, '5': 8, '10': 'canShutdown'},
    {'1': 'hasWifi', '3': 4, '4': 1, '5': 8, '10': 'hasWifi'},
    {'1': 'hasBluetooth', '3': 5, '4': 1, '5': 8, '10': 'hasBluetooth'},
    {'1': 'hasEthernet', '3': 6, '4': 1, '5': 8, '10': 'hasEthernet'},
    {
      '1': 'role',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.Role',
      '10': 'role'
    },
    {'1': 'position_flags', '3': 8, '4': 1, '5': 13, '10': 'positionFlags'},
    {
      '1': 'hw_model',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.HardwareModel',
      '10': 'hwModel'
    },
    {
      '1': 'hasRemoteHardware',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'hasRemoteHardware'
    },
    {'1': 'hasPKC', '3': 11, '4': 1, '5': 8, '10': 'hasPKC'},
    {
      '1': 'excluded_modules',
      '3': 12,
      '4': 1,
      '5': 13,
      '10': 'excludedModules'
    },
  ],
};

/// Descriptor for `DeviceMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceMetadataDescriptor = $convert.base64Decode(
    'Cg5EZXZpY2VNZXRhZGF0YRIpChBmaXJtd2FyZV92ZXJzaW9uGAEgASgJUg9maXJtd2FyZVZlcn'
    'Npb24SMAoUZGV2aWNlX3N0YXRlX3ZlcnNpb24YAiABKA1SEmRldmljZVN0YXRlVmVyc2lvbhIg'
    'CgtjYW5TaHV0ZG93bhgDIAEoCFILY2FuU2h1dGRvd24SGAoHaGFzV2lmaRgEIAEoCFIHaGFzV2'
    'lmaRIiCgxoYXNCbHVldG9vdGgYBSABKAhSDGhhc0JsdWV0b290aBIgCgtoYXNFdGhlcm5ldBgG'
    'IAEoCFILaGFzRXRoZXJuZXQSOAoEcm9sZRgHIAEoDjIkLm1lc2h0YXN0aWMuQ29uZmlnLkRldm'
    'ljZUNvbmZpZy5Sb2xlUgRyb2xlEiUKDnBvc2l0aW9uX2ZsYWdzGAggASgNUg1wb3NpdGlvbkZs'
    'YWdzEjQKCGh3X21vZGVsGAkgASgOMhkubWVzaHRhc3RpYy5IYXJkd2FyZU1vZGVsUgdod01vZG'
    'VsEiwKEWhhc1JlbW90ZUhhcmR3YXJlGAogASgIUhFoYXNSZW1vdGVIYXJkd2FyZRIWCgZoYXNQ'
    'S0MYCyABKAhSBmhhc1BLQxIpChBleGNsdWRlZF9tb2R1bGVzGAwgASgNUg9leGNsdWRlZE1vZH'
    'VsZXM=');

@$core.Deprecated('Use heartbeatDescriptor instead')
const Heartbeat$json = {
  '1': 'Heartbeat',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 13, '10': 'nonce'},
  ],
};

/// Descriptor for `Heartbeat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatDescriptor =
    $convert.base64Decode('CglIZWFydGJlYXQSFAoFbm9uY2UYASABKA1SBW5vbmNl');

@$core.Deprecated('Use nodeRemoteHardwarePinDescriptor instead')
const NodeRemoteHardwarePin$json = {
  '1': 'NodeRemoteHardwarePin',
  '2': [
    {'1': 'node_num', '3': 1, '4': 1, '5': 13, '10': 'nodeNum'},
    {
      '1': 'pin',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.RemoteHardwarePin',
      '10': 'pin'
    },
  ],
};

/// Descriptor for `NodeRemoteHardwarePin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeRemoteHardwarePinDescriptor = $convert.base64Decode(
    'ChVOb2RlUmVtb3RlSGFyZHdhcmVQaW4SGQoIbm9kZV9udW0YASABKA1SB25vZGVOdW0SLwoDcG'
    'luGAIgASgLMh0ubWVzaHRhc3RpYy5SZW1vdGVIYXJkd2FyZVBpblIDcGlu');

@$core.Deprecated('Use chunkedPayloadDescriptor instead')
const ChunkedPayload$json = {
  '1': 'ChunkedPayload',
  '2': [
    {'1': 'payload_id', '3': 1, '4': 1, '5': 13, '10': 'payloadId'},
    {'1': 'chunk_count', '3': 2, '4': 1, '5': 13, '10': 'chunkCount'},
    {'1': 'chunk_index', '3': 3, '4': 1, '5': 13, '10': 'chunkIndex'},
    {'1': 'payload_chunk', '3': 4, '4': 1, '5': 12, '10': 'payloadChunk'},
  ],
};

/// Descriptor for `ChunkedPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chunkedPayloadDescriptor = $convert.base64Decode(
    'Cg5DaHVua2VkUGF5bG9hZBIdCgpwYXlsb2FkX2lkGAEgASgNUglwYXlsb2FkSWQSHwoLY2h1bm'
    'tfY291bnQYAiABKA1SCmNodW5rQ291bnQSHwoLY2h1bmtfaW5kZXgYAyABKA1SCmNodW5rSW5k'
    'ZXgSIwoNcGF5bG9hZF9jaHVuaxgEIAEoDFIMcGF5bG9hZENodW5r');

@$core.Deprecated('Use resend_chunksDescriptor instead')
const resend_chunks$json = {
  '1': 'resend_chunks',
  '2': [
    {'1': 'chunks', '3': 1, '4': 3, '5': 13, '10': 'chunks'},
  ],
};

/// Descriptor for `resend_chunks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resend_chunksDescriptor = $convert
    .base64Decode('Cg1yZXNlbmRfY2h1bmtzEhYKBmNodW5rcxgBIAMoDVIGY2h1bmtz');

@$core.Deprecated('Use chunkedPayloadResponseDescriptor instead')
const ChunkedPayloadResponse$json = {
  '1': 'ChunkedPayloadResponse',
  '2': [
    {'1': 'payload_id', '3': 1, '4': 1, '5': 13, '10': 'payloadId'},
    {
      '1': 'request_transfer',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'requestTransfer'
    },
    {
      '1': 'accept_transfer',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'acceptTransfer'
    },
    {
      '1': 'resend_chunks',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.resend_chunks',
      '9': 0,
      '10': 'resendChunks'
    },
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

/// Descriptor for `ChunkedPayloadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chunkedPayloadResponseDescriptor = $convert.base64Decode(
    'ChZDaHVua2VkUGF5bG9hZFJlc3BvbnNlEh0KCnBheWxvYWRfaWQYASABKA1SCXBheWxvYWRJZB'
    'IrChByZXF1ZXN0X3RyYW5zZmVyGAIgASgISABSD3JlcXVlc3RUcmFuc2ZlchIpCg9hY2NlcHRf'
    'dHJhbnNmZXIYAyABKAhIAFIOYWNjZXB0VHJhbnNmZXISQAoNcmVzZW5kX2NodW5rcxgEIAEoCz'
    'IZLm1lc2h0YXN0aWMucmVzZW5kX2NodW5rc0gAUgxyZXNlbmRDaHVua3NCEQoPcGF5bG9hZF92'
    'YXJpYW50');
