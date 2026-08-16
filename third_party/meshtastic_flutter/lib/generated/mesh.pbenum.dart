// This is a generated file - do not edit.
//
// Generated from meshtastic/mesh.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  Note: these enum names must EXACTLY match the string used in the device
///  bin/build-all.sh script.
///  Because they will be used to find firmware filenames in the android app for OTA updates.
///  To match the old style filenames, _ is converted to -, p is converted to .
class HardwareModel extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const HardwareModel UNSET =
      HardwareModel._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_V2 =
      HardwareModel._(1, _omitEnumNames ? '' : 'TLORA_V2');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_V1 =
      HardwareModel._(2, _omitEnumNames ? '' : 'TLORA_V1');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_V2_1_1P6 =
      HardwareModel._(3, _omitEnumNames ? '' : 'TLORA_V2_1_1P6');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TBEAM =
      HardwareModel._(4, _omitEnumNames ? '' : 'TBEAM');

  ///
  ///  The original heltec WiFi_Lora_32_V2, which had battery voltage sensing hooked to GPIO 13
  ///  (see HELTEC_V2 for the new version).
  static const HardwareModel HELTEC_V2_0 =
      HardwareModel._(5, _omitEnumNames ? '' : 'HELTEC_V2_0');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TBEAM_V0P7 =
      HardwareModel._(6, _omitEnumNames ? '' : 'TBEAM_V0P7');

  ///
  ///  TODO: REPLACE
  static const HardwareModel T_ECHO =
      HardwareModel._(7, _omitEnumNames ? '' : 'T_ECHO');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_V1_1P3 =
      HardwareModel._(8, _omitEnumNames ? '' : 'TLORA_V1_1P3');

  ///
  ///  TODO: REPLACE
  static const HardwareModel RAK4631 =
      HardwareModel._(9, _omitEnumNames ? '' : 'RAK4631');

  ///
  ///  The new version of the heltec WiFi_Lora_32_V2 board that has battery sensing hooked to GPIO 37.
  ///  Sadly they did not update anything on the silkscreen to identify this board
  static const HardwareModel HELTEC_V2_1 =
      HardwareModel._(10, _omitEnumNames ? '' : 'HELTEC_V2_1');

  ///
  ///  Ancient heltec WiFi_Lora_32 board
  static const HardwareModel HELTEC_V1 =
      HardwareModel._(11, _omitEnumNames ? '' : 'HELTEC_V1');

  ///
  ///  New T-BEAM with ESP32-S3 CPU
  static const HardwareModel LILYGO_TBEAM_S3_CORE =
      HardwareModel._(12, _omitEnumNames ? '' : 'LILYGO_TBEAM_S3_CORE');

  ///
  ///  RAK WisBlock ESP32 core: https://docs.rakwireless.com/Product-Categories/WisBlock/RAK11200/Overview/
  static const HardwareModel RAK11200 =
      HardwareModel._(13, _omitEnumNames ? '' : 'RAK11200');

  ///
  ///  B&Q Consulting Nano Edition G1: https://uniteng.com/wiki/doku.php?id=meshtastic:nano
  static const HardwareModel NANO_G1 =
      HardwareModel._(14, _omitEnumNames ? '' : 'NANO_G1');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_V2_1_1P8 =
      HardwareModel._(15, _omitEnumNames ? '' : 'TLORA_V2_1_1P8');

  ///
  ///  TODO: REPLACE
  static const HardwareModel TLORA_T3_S3 =
      HardwareModel._(16, _omitEnumNames ? '' : 'TLORA_T3_S3');

  ///
  ///  B&Q Consulting Nano G1 Explorer: https://wiki.uniteng.com/en/meshtastic/nano-g1-explorer
  static const HardwareModel NANO_G1_EXPLORER =
      HardwareModel._(17, _omitEnumNames ? '' : 'NANO_G1_EXPLORER');

  ///
  ///  B&Q Consulting Nano G2 Ultra: https://wiki.uniteng.com/en/meshtastic/nano-g2-ultra
  static const HardwareModel NANO_G2_ULTRA =
      HardwareModel._(18, _omitEnumNames ? '' : 'NANO_G2_ULTRA');

  ///
  ///  LoRAType device: https://loratype.org/
  static const HardwareModel LORA_TYPE =
      HardwareModel._(19, _omitEnumNames ? '' : 'LORA_TYPE');

  ///
  ///  wiphone https://www.wiphone.io/
  static const HardwareModel WIPHONE =
      HardwareModel._(20, _omitEnumNames ? '' : 'WIPHONE');

  ///
  ///  WIO Tracker WM1110 family from Seeed Studio. Includes wio-1110-tracker and wio-1110-sdk
  static const HardwareModel WIO_WM1110 =
      HardwareModel._(21, _omitEnumNames ? '' : 'WIO_WM1110');

  ///
  ///  RAK2560 Solar base station based on RAK4630
  static const HardwareModel RAK2560 =
      HardwareModel._(22, _omitEnumNames ? '' : 'RAK2560');

  ///
  ///  Heltec HRU-3601: https://heltec.org/project/hru-3601/
  static const HardwareModel HELTEC_HRU_3601 =
      HardwareModel._(23, _omitEnumNames ? '' : 'HELTEC_HRU_3601');

  ///
  ///  Heltec Wireless Bridge
  static const HardwareModel HELTEC_WIRELESS_BRIDGE =
      HardwareModel._(24, _omitEnumNames ? '' : 'HELTEC_WIRELESS_BRIDGE');

  ///
  ///  B&Q Consulting Station Edition G1: https://uniteng.com/wiki/doku.php?id=meshtastic:station
  static const HardwareModel STATION_G1 =
      HardwareModel._(25, _omitEnumNames ? '' : 'STATION_G1');

  ///
  ///  RAK11310 (RP2040 + SX1262)
  static const HardwareModel RAK11310 =
      HardwareModel._(26, _omitEnumNames ? '' : 'RAK11310');

  ///
  ///  Makerfabs SenseLoRA Receiver (RP2040 + RFM96)
  static const HardwareModel SENSELORA_RP2040 =
      HardwareModel._(27, _omitEnumNames ? '' : 'SENSELORA_RP2040');

  ///
  ///  Makerfabs SenseLoRA Industrial Monitor (ESP32-S3 + RFM96)
  static const HardwareModel SENSELORA_S3 =
      HardwareModel._(28, _omitEnumNames ? '' : 'SENSELORA_S3');

  ///
  ///  Canary Radio Company - CanaryOne: https://canaryradio.io/products/canaryone
  static const HardwareModel CANARYONE =
      HardwareModel._(29, _omitEnumNames ? '' : 'CANARYONE');

  ///
  ///  Waveshare RP2040 LoRa - https://www.waveshare.com/rp2040-lora.htm
  static const HardwareModel RP2040_LORA =
      HardwareModel._(30, _omitEnumNames ? '' : 'RP2040_LORA');

  ///
  ///  B&Q Consulting Station G2: https://wiki.uniteng.com/en/meshtastic/station-g2
  static const HardwareModel STATION_G2 =
      HardwareModel._(31, _omitEnumNames ? '' : 'STATION_G2');

  ///
  ///  ---------------------------------------------------------------------------
  ///  Less common/prototype boards listed here (needs one more byte over the air)
  ///  ---------------------------------------------------------------------------
  static const HardwareModel LORA_RELAY_V1 =
      HardwareModel._(32, _omitEnumNames ? '' : 'LORA_RELAY_V1');

  ///
  ///  TODO: REPLACE
  static const HardwareModel NRF52840DK =
      HardwareModel._(33, _omitEnumNames ? '' : 'NRF52840DK');

  ///
  ///  TODO: REPLACE
  static const HardwareModel PPR =
      HardwareModel._(34, _omitEnumNames ? '' : 'PPR');

  ///
  ///  TODO: REPLACE
  static const HardwareModel GENIEBLOCKS =
      HardwareModel._(35, _omitEnumNames ? '' : 'GENIEBLOCKS');

  ///
  ///  TODO: REPLACE
  static const HardwareModel NRF52_UNKNOWN =
      HardwareModel._(36, _omitEnumNames ? '' : 'NRF52_UNKNOWN');

  ///
  ///  TODO: REPLACE
  static const HardwareModel PORTDUINO =
      HardwareModel._(37, _omitEnumNames ? '' : 'PORTDUINO');

  ///
  ///  The simulator built into the android app
  static const HardwareModel ANDROID_SIM =
      HardwareModel._(38, _omitEnumNames ? '' : 'ANDROID_SIM');

  ///
  ///  Custom DIY device based on @NanoVHF schematics: https://github.com/NanoVHF/Meshtastic-DIY/tree/main/Schematics
  static const HardwareModel DIY_V1 =
      HardwareModel._(39, _omitEnumNames ? '' : 'DIY_V1');

  ///
  ///  nRF52840 Dongle : https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle/
  static const HardwareModel NRF52840_PCA10059 =
      HardwareModel._(40, _omitEnumNames ? '' : 'NRF52840_PCA10059');

  ///
  ///  Custom Disaster Radio esp32 v3 device https://github.com/sudomesh/disaster-radio/tree/master/hardware/board_esp32_v3
  static const HardwareModel DR_DEV =
      HardwareModel._(41, _omitEnumNames ? '' : 'DR_DEV');

  ///
  ///  M5 esp32 based MCU modules with enclosure, TFT and LORA Shields. All Variants (Basic, Core, Fire, Core2, CoreS3, Paper) https://m5stack.com/
  static const HardwareModel M5STACK =
      HardwareModel._(42, _omitEnumNames ? '' : 'M5STACK');

  ///
  ///  New Heltec LoRA32 with ESP32-S3 CPU
  static const HardwareModel HELTEC_V3 =
      HardwareModel._(43, _omitEnumNames ? '' : 'HELTEC_V3');

  ///
  ///  New Heltec Wireless Stick Lite with ESP32-S3 CPU
  static const HardwareModel HELTEC_WSL_V3 =
      HardwareModel._(44, _omitEnumNames ? '' : 'HELTEC_WSL_V3');

  ///
  ///  New BETAFPV ELRS Micro TX Module 2.4G with ESP32 CPU
  static const HardwareModel BETAFPV_2400_TX =
      HardwareModel._(45, _omitEnumNames ? '' : 'BETAFPV_2400_TX');

  ///
  ///  BetaFPV ExpressLRS "Nano" TX Module 900MHz with ESP32 CPU
  static const HardwareModel BETAFPV_900_NANO_TX =
      HardwareModel._(46, _omitEnumNames ? '' : 'BETAFPV_900_NANO_TX');

  ///
  ///  Raspberry Pi Pico (W) with Waveshare SX1262 LoRa Node Module
  static const HardwareModel RPI_PICO =
      HardwareModel._(47, _omitEnumNames ? '' : 'RPI_PICO');

  ///
  ///  Heltec Wireless Tracker with ESP32-S3 CPU, built-in GPS, and TFT
  ///  Newer V1.1, version is written on the PCB near the display.
  static const HardwareModel HELTEC_WIRELESS_TRACKER =
      HardwareModel._(48, _omitEnumNames ? '' : 'HELTEC_WIRELESS_TRACKER');

  ///
  ///  Heltec Wireless Paper with ESP32-S3 CPU and E-Ink display
  static const HardwareModel HELTEC_WIRELESS_PAPER =
      HardwareModel._(49, _omitEnumNames ? '' : 'HELTEC_WIRELESS_PAPER');

  ///
  ///  LilyGo T-Deck with ESP32-S3 CPU, Keyboard and IPS display
  static const HardwareModel T_DECK =
      HardwareModel._(50, _omitEnumNames ? '' : 'T_DECK');

  ///
  ///  LilyGo T-Watch S3 with ESP32-S3 CPU and IPS display
  static const HardwareModel T_WATCH_S3 =
      HardwareModel._(51, _omitEnumNames ? '' : 'T_WATCH_S3');

  ///
  ///  Bobricius Picomputer with ESP32-S3 CPU, Keyboard and IPS display
  static const HardwareModel PICOMPUTER_S3 =
      HardwareModel._(52, _omitEnumNames ? '' : 'PICOMPUTER_S3');

  ///
  ///  Heltec HT-CT62 with ESP32-C3 CPU and SX1262 LoRa
  static const HardwareModel HELTEC_HT62 =
      HardwareModel._(53, _omitEnumNames ? '' : 'HELTEC_HT62');

  ///
  ///  EBYTE SPI LoRa module and ESP32-S3
  static const HardwareModel EBYTE_ESP32_S3 =
      HardwareModel._(54, _omitEnumNames ? '' : 'EBYTE_ESP32_S3');

  ///
  ///  Waveshare ESP32-S3-PICO with PICO LoRa HAT and 2.9inch e-Ink
  static const HardwareModel ESP32_S3_PICO =
      HardwareModel._(55, _omitEnumNames ? '' : 'ESP32_S3_PICO');

  ///
  ///  CircuitMess Chatter 2 LLCC68 Lora Module and ESP32 Wroom
  ///  Lora module can be swapped out for a Heltec RA-62 which is "almost" pin compatible
  ///  with one cut and one jumper Meshtastic works
  static const HardwareModel CHATTER_2 =
      HardwareModel._(56, _omitEnumNames ? '' : 'CHATTER_2');

  ///
  ///  Heltec Wireless Paper, With ESP32-S3 CPU and E-Ink display
  ///  Older "V1.0" Variant, has no "version sticker"
  ///  E-Ink model is DEPG0213BNS800
  ///  Tab on the screen protector is RED
  ///  Flex connector marking is FPC-7528B
  static const HardwareModel HELTEC_WIRELESS_PAPER_V1_0 =
      HardwareModel._(57, _omitEnumNames ? '' : 'HELTEC_WIRELESS_PAPER_V1_0');

  ///
  ///  Heltec Wireless Tracker with ESP32-S3 CPU, built-in GPS, and TFT
  ///  Older "V1.0" Variant
  static const HardwareModel HELTEC_WIRELESS_TRACKER_V1_0 =
      HardwareModel._(58, _omitEnumNames ? '' : 'HELTEC_WIRELESS_TRACKER_V1_0');

  ///
  ///  unPhone with ESP32-S3, TFT touchscreen,  LSM6DS3TR-C accelerometer and gyroscope
  static const HardwareModel UNPHONE =
      HardwareModel._(59, _omitEnumNames ? '' : 'UNPHONE');

  ///
  ///  Teledatics TD-LORAC NRF52840 based M.2 LoRA module
  ///  Compatible with the TD-WRLS development board
  static const HardwareModel TD_LORAC =
      HardwareModel._(60, _omitEnumNames ? '' : 'TD_LORAC');

  ///
  ///  CDEBYTE EoRa-S3 board using their own MM modules, clone of LILYGO T3S3
  static const HardwareModel CDEBYTE_EORA_S3 =
      HardwareModel._(61, _omitEnumNames ? '' : 'CDEBYTE_EORA_S3');

  ///
  ///  TWC_MESH_V4
  ///  Adafruit NRF52840 feather express with SX1262, SSD1306 OLED and NEO6M GPS
  static const HardwareModel TWC_MESH_V4 =
      HardwareModel._(62, _omitEnumNames ? '' : 'TWC_MESH_V4');

  ///
  ///  NRF52_PROMICRO_DIY
  ///  Promicro NRF52840 with SX1262/LLCC68, SSD1306 OLED and NEO6M GPS
  static const HardwareModel NRF52_PROMICRO_DIY =
      HardwareModel._(63, _omitEnumNames ? '' : 'NRF52_PROMICRO_DIY');

  ///
  ///  RadioMaster 900 Bandit Nano, https://www.radiomasterrc.com/products/bandit-nano-expresslrs-rf-module
  ///  ESP32-D0WDQ6 With SX1276/SKY66122, SSD1306 OLED and No GPS
  static const HardwareModel RADIOMASTER_900_BANDIT_NANO =
      HardwareModel._(64, _omitEnumNames ? '' : 'RADIOMASTER_900_BANDIT_NANO');

  ///
  ///  Heltec Capsule Sensor V3 with ESP32-S3 CPU, Portable LoRa device that can replace GNSS modules or sensors
  static const HardwareModel HELTEC_CAPSULE_SENSOR_V3 =
      HardwareModel._(65, _omitEnumNames ? '' : 'HELTEC_CAPSULE_SENSOR_V3');

  ///
  ///  Heltec Vision Master T190 with ESP32-S3 CPU, and a 1.90 inch TFT display
  static const HardwareModel HELTEC_VISION_MASTER_T190 =
      HardwareModel._(66, _omitEnumNames ? '' : 'HELTEC_VISION_MASTER_T190');

  ///
  ///  Heltec Vision Master E213 with ESP32-S3 CPU, and a 2.13 inch E-Ink display
  static const HardwareModel HELTEC_VISION_MASTER_E213 =
      HardwareModel._(67, _omitEnumNames ? '' : 'HELTEC_VISION_MASTER_E213');

  ///
  ///  Heltec Vision Master E290 with ESP32-S3 CPU, and a 2.9 inch E-Ink display
  static const HardwareModel HELTEC_VISION_MASTER_E290 =
      HardwareModel._(68, _omitEnumNames ? '' : 'HELTEC_VISION_MASTER_E290');

  ///
  ///  Heltec Mesh Node T114 board with nRF52840 CPU, and a 1.14 inch TFT display, Ultimate low-power design,
  ///  specifically adapted for the Meshtatic project
  static const HardwareModel HELTEC_MESH_NODE_T114 =
      HardwareModel._(69, _omitEnumNames ? '' : 'HELTEC_MESH_NODE_T114');

  ///
  ///  Sensecap Indicator from Seeed Studio. ESP32-S3 device with TFT and RP2040 coprocessor
  static const HardwareModel SENSECAP_INDICATOR =
      HardwareModel._(70, _omitEnumNames ? '' : 'SENSECAP_INDICATOR');

  ///
  ///  Seeed studio T1000-E tracker card. NRF52840 w/ LR1110 radio, GPS, button, buzzer, and sensors.
  static const HardwareModel TRACKER_T1000_E =
      HardwareModel._(71, _omitEnumNames ? '' : 'TRACKER_T1000_E');

  ///
  ///  RAK3172 STM32WLE5 Module (https://store.rakwireless.com/products/wisduo-lpwan-module-rak3172)
  static const HardwareModel RAK3172 =
      HardwareModel._(72, _omitEnumNames ? '' : 'RAK3172');

  ///
  ///  Seeed Studio Wio-E5 (either mini or Dev kit) using STM32WL chip.
  static const HardwareModel WIO_E5 =
      HardwareModel._(73, _omitEnumNames ? '' : 'WIO_E5');

  ///
  ///  RadioMaster 900 Bandit, https://www.radiomasterrc.com/products/bandit-expresslrs-rf-module
  ///  SSD1306 OLED and No GPS
  static const HardwareModel RADIOMASTER_900_BANDIT =
      HardwareModel._(74, _omitEnumNames ? '' : 'RADIOMASTER_900_BANDIT');

  ///
  ///  Minewsemi ME25LS01 (ME25LE01_V1.0). NRF52840 w/ LR1110 radio, buttons and leds and pins.
  static const HardwareModel ME25LS01_4Y10TD =
      HardwareModel._(75, _omitEnumNames ? '' : 'ME25LS01_4Y10TD');

  ///
  ///  RP2040_FEATHER_RFM95
  ///  Adafruit Feather RP2040 with RFM95 LoRa Radio RFM95 with SX1272, SSD1306 OLED
  ///  https://www.adafruit.com/product/5714
  ///  https://www.adafruit.com/product/326
  ///  https://www.adafruit.com/product/938
  ///   ^^^ short A0 to switch to I2C address 0x3C
  static const HardwareModel RP2040_FEATHER_RFM95 =
      HardwareModel._(76, _omitEnumNames ? '' : 'RP2040_FEATHER_RFM95');

  /// M5 esp32 based MCU modules with enclosure, TFT and LORA Shields. All Variants (Basic, Core, Fire, Core2, CoreS3, Paper) https://m5stack.com/
  static const HardwareModel M5STACK_COREBASIC =
      HardwareModel._(77, _omitEnumNames ? '' : 'M5STACK_COREBASIC');
  static const HardwareModel M5STACK_CORE2 =
      HardwareModel._(78, _omitEnumNames ? '' : 'M5STACK_CORE2');

  /// Pico2 with Waveshare Hat, same as Pico
  static const HardwareModel RPI_PICO2 =
      HardwareModel._(79, _omitEnumNames ? '' : 'RPI_PICO2');

  /// M5 esp32 based MCU modules with enclosure, TFT and LORA Shields. All Variants (Basic, Core, Fire, Core2, CoreS3, Paper) https://m5stack.com/
  static const HardwareModel M5STACK_CORES3 =
      HardwareModel._(80, _omitEnumNames ? '' : 'M5STACK_CORES3');

  /// Seeed XIAO S3 DK
  static const HardwareModel SEEED_XIAO_S3 =
      HardwareModel._(81, _omitEnumNames ? '' : 'SEEED_XIAO_S3');

  ///
  ///  Nordic nRF52840+Semtech SX1262 LoRa BLE Combo Module. nRF52840+SX1262 MS24SF1
  static const HardwareModel MS24SF1 =
      HardwareModel._(82, _omitEnumNames ? '' : 'MS24SF1');

  ///
  ///  Lilygo TLora-C6 with the new ESP32-C6 MCU
  static const HardwareModel TLORA_C6 =
      HardwareModel._(83, _omitEnumNames ? '' : 'TLORA_C6');

  ///
  ///  WisMesh Tap
  ///  RAK-4631 w/ TFT in injection modled case
  static const HardwareModel WISMESH_TAP =
      HardwareModel._(84, _omitEnumNames ? '' : 'WISMESH_TAP');

  ///
  ///  Similar to PORTDUINO but used by Routastic devices, this is not any
  ///  particular device and does not run Meshtastic's code but supports
  ///  the same frame format.
  ///  Runs on linux, see https://github.com/Jorropo/routastic
  static const HardwareModel ROUTASTIC =
      HardwareModel._(85, _omitEnumNames ? '' : 'ROUTASTIC');

  ///
  ///  Mesh-Tab, esp32 based
  ///  https://github.com/valzzu/Mesh-Tab
  static const HardwareModel MESH_TAB =
      HardwareModel._(86, _omitEnumNames ? '' : 'MESH_TAB');

  ///
  ///  MeshLink board developed by LoraItalia. NRF52840, eByte E22900M22S (Will also come with other frequencies), 25w MPPT solar charger (5v,12v,18v selectable), support for gps, buzzer, oled or e-ink display, 10 gpios, hardware watchdog
  ///  https://www.loraitalia.it
  static const HardwareModel MESHLINK =
      HardwareModel._(87, _omitEnumNames ? '' : 'MESHLINK');

  ///
  ///  Seeed XIAO nRF52840 + Wio SX1262 kit
  static const HardwareModel XIAO_NRF52_KIT =
      HardwareModel._(88, _omitEnumNames ? '' : 'XIAO_NRF52_KIT');

  ///
  ///  Elecrow ThinkNode M1 & M2
  ///  https://www.elecrow.com/wiki/ThinkNode-M1_Transceiver_Device(Meshtastic)_Power_By_nRF52840.html
  ///  https://www.elecrow.com/wiki/ThinkNode-M2_Transceiver_Device(Meshtastic)_Power_By_NRF52840.html (this actually uses ESP32-S3)
  static const HardwareModel THINKNODE_M1 =
      HardwareModel._(89, _omitEnumNames ? '' : 'THINKNODE_M1');
  static const HardwareModel THINKNODE_M2 =
      HardwareModel._(90, _omitEnumNames ? '' : 'THINKNODE_M2');

  ///
  ///  Lilygo T-ETH-Elite
  static const HardwareModel T_ETH_ELITE =
      HardwareModel._(91, _omitEnumNames ? '' : 'T_ETH_ELITE');

  ///
  ///  Heltec HRI-3621 industrial probe
  static const HardwareModel HELTEC_SENSOR_HUB =
      HardwareModel._(92, _omitEnumNames ? '' : 'HELTEC_SENSOR_HUB');

  ///
  ///  Reserved Fried Chicken ID for future use
  static const HardwareModel RESERVED_FRIED_CHICKEN =
      HardwareModel._(93, _omitEnumNames ? '' : 'RESERVED_FRIED_CHICKEN');

  ///
  ///  Heltec Magnetic Power Bank with Meshtastic compatible
  static const HardwareModel HELTEC_MESH_POCKET =
      HardwareModel._(94, _omitEnumNames ? '' : 'HELTEC_MESH_POCKET');

  ///
  ///  Seeed Solar Node
  static const HardwareModel SEEED_SOLAR_NODE =
      HardwareModel._(95, _omitEnumNames ? '' : 'SEEED_SOLAR_NODE');

  ///
  ///  NomadStar Meteor Pro https://nomadstar.ch/
  static const HardwareModel NOMADSTAR_METEOR_PRO =
      HardwareModel._(96, _omitEnumNames ? '' : 'NOMADSTAR_METEOR_PRO');

  ///
  ///  Elecrow CrowPanel Advance models, ESP32-S3 and TFT with SX1262 radio plugin
  static const HardwareModel CROWPANEL =
      HardwareModel._(97, _omitEnumNames ? '' : 'CROWPANEL');

  ///
  ///  Lilygo LINK32 board with sensors
  static const HardwareModel LINK_32 =
      HardwareModel._(98, _omitEnumNames ? '' : 'LINK_32');

  ///
  ///  Seeed Tracker L1
  static const HardwareModel SEEED_WIO_TRACKER_L1 =
      HardwareModel._(99, _omitEnumNames ? '' : 'SEEED_WIO_TRACKER_L1');

  ///
  ///  Seeed Tracker L1 EINK driver
  static const HardwareModel SEEED_WIO_TRACKER_L1_EINK =
      HardwareModel._(100, _omitEnumNames ? '' : 'SEEED_WIO_TRACKER_L1_EINK');

  ///
  ///  Reserved ID for future and past use
  static const HardwareModel QWANTZ_TINY_ARMS =
      HardwareModel._(101, _omitEnumNames ? '' : 'QWANTZ_TINY_ARMS');

  ///
  ///  Lilygo T-Deck Pro
  static const HardwareModel T_DECK_PRO =
      HardwareModel._(102, _omitEnumNames ? '' : 'T_DECK_PRO');

  ///
  ///  Lilygo TLora Pager
  static const HardwareModel T_LORA_PAGER =
      HardwareModel._(103, _omitEnumNames ? '' : 'T_LORA_PAGER');

  ///
  ///  GAT562 Mesh Trial Tracker
  static const HardwareModel GAT562_MESH_TRIAL_TRACKER =
      HardwareModel._(104, _omitEnumNames ? '' : 'GAT562_MESH_TRIAL_TRACKER');

  ///
  ///  RAKwireless WisMesh Tag
  static const HardwareModel WISMESH_TAG =
      HardwareModel._(105, _omitEnumNames ? '' : 'WISMESH_TAG');

  ///
  ///  RAKwireless WisBlock Core RAK3312 https://docs.rakwireless.com/product-categories/wisduo/rak3112-module/overview/
  static const HardwareModel RAK3312 =
      HardwareModel._(106, _omitEnumNames ? '' : 'RAK3312');

  ///
  ///  Elecrow ThinkNode M5 https://www.elecrow.com/wiki/ThinkNode_M5_Meshtastic_LoRa_Signal_Transceiver_ESP32-S3.html
  static const HardwareModel THINKNODE_M5 =
      HardwareModel._(107, _omitEnumNames ? '' : 'THINKNODE_M5');

  ///
  ///  MeshSolar is an integrated power management and communication solution designed for outdoor low-power devices.
  ///  https://heltec.org/project/meshsolar/
  static const HardwareModel HELTEC_MESH_SOLAR =
      HardwareModel._(108, _omitEnumNames ? '' : 'HELTEC_MESH_SOLAR');

  ///
  ///  Lilygo T-Echo Lite
  static const HardwareModel T_ECHO_LITE =
      HardwareModel._(109, _omitEnumNames ? '' : 'T_ECHO_LITE');

  ///
  ///  ------------------------------------------------------------------------------------------------------------------------------------------
  ///  Reserved ID For developing private Ports. These will show up in live traffic sparsely, so we can use a high number. Keep it within 8 bits.
  ///  ------------------------------------------------------------------------------------------------------------------------------------------
  static const HardwareModel PRIVATE_HW =
      HardwareModel._(255, _omitEnumNames ? '' : 'PRIVATE_HW');

  static const $core.List<HardwareModel> values = <HardwareModel>[
    UNSET,
    TLORA_V2,
    TLORA_V1,
    TLORA_V2_1_1P6,
    TBEAM,
    HELTEC_V2_0,
    TBEAM_V0P7,
    T_ECHO,
    TLORA_V1_1P3,
    RAK4631,
    HELTEC_V2_1,
    HELTEC_V1,
    LILYGO_TBEAM_S3_CORE,
    RAK11200,
    NANO_G1,
    TLORA_V2_1_1P8,
    TLORA_T3_S3,
    NANO_G1_EXPLORER,
    NANO_G2_ULTRA,
    LORA_TYPE,
    WIPHONE,
    WIO_WM1110,
    RAK2560,
    HELTEC_HRU_3601,
    HELTEC_WIRELESS_BRIDGE,
    STATION_G1,
    RAK11310,
    SENSELORA_RP2040,
    SENSELORA_S3,
    CANARYONE,
    RP2040_LORA,
    STATION_G2,
    LORA_RELAY_V1,
    NRF52840DK,
    PPR,
    GENIEBLOCKS,
    NRF52_UNKNOWN,
    PORTDUINO,
    ANDROID_SIM,
    DIY_V1,
    NRF52840_PCA10059,
    DR_DEV,
    M5STACK,
    HELTEC_V3,
    HELTEC_WSL_V3,
    BETAFPV_2400_TX,
    BETAFPV_900_NANO_TX,
    RPI_PICO,
    HELTEC_WIRELESS_TRACKER,
    HELTEC_WIRELESS_PAPER,
    T_DECK,
    T_WATCH_S3,
    PICOMPUTER_S3,
    HELTEC_HT62,
    EBYTE_ESP32_S3,
    ESP32_S3_PICO,
    CHATTER_2,
    HELTEC_WIRELESS_PAPER_V1_0,
    HELTEC_WIRELESS_TRACKER_V1_0,
    UNPHONE,
    TD_LORAC,
    CDEBYTE_EORA_S3,
    TWC_MESH_V4,
    NRF52_PROMICRO_DIY,
    RADIOMASTER_900_BANDIT_NANO,
    HELTEC_CAPSULE_SENSOR_V3,
    HELTEC_VISION_MASTER_T190,
    HELTEC_VISION_MASTER_E213,
    HELTEC_VISION_MASTER_E290,
    HELTEC_MESH_NODE_T114,
    SENSECAP_INDICATOR,
    TRACKER_T1000_E,
    RAK3172,
    WIO_E5,
    RADIOMASTER_900_BANDIT,
    ME25LS01_4Y10TD,
    RP2040_FEATHER_RFM95,
    M5STACK_COREBASIC,
    M5STACK_CORE2,
    RPI_PICO2,
    M5STACK_CORES3,
    SEEED_XIAO_S3,
    MS24SF1,
    TLORA_C6,
    WISMESH_TAP,
    ROUTASTIC,
    MESH_TAB,
    MESHLINK,
    XIAO_NRF52_KIT,
    THINKNODE_M1,
    THINKNODE_M2,
    T_ETH_ELITE,
    HELTEC_SENSOR_HUB,
    RESERVED_FRIED_CHICKEN,
    HELTEC_MESH_POCKET,
    SEEED_SOLAR_NODE,
    NOMADSTAR_METEOR_PRO,
    CROWPANEL,
    LINK_32,
    SEEED_WIO_TRACKER_L1,
    SEEED_WIO_TRACKER_L1_EINK,
    QWANTZ_TINY_ARMS,
    T_DECK_PRO,
    T_LORA_PAGER,
    GAT562_MESH_TRIAL_TRACKER,
    WISMESH_TAG,
    RAK3312,
    THINKNODE_M5,
    HELTEC_MESH_SOLAR,
    T_ECHO_LITE,
    PRIVATE_HW,
  ];

  static final $core.Map<$core.int, HardwareModel> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static HardwareModel? valueOf($core.int value) => _byValue[value];

  const HardwareModel._(super.value, super.name);
}

///
///  Shared constants between device and phone
class Constants extends $pb.ProtobufEnum {
  ///
  ///  First enum must be zero, and we are just using this enum to
  ///  pass int constants between two very different environments
  static const Constants ZERO = Constants._(0, _omitEnumNames ? '' : 'ZERO');

  ///
  ///  From mesh.options
  ///  note: this payload length is ONLY the bytes that are sent inside of the Data protobuf (excluding protobuf overhead). The 16 byte header is
  ///  outside of this envelope
  static const Constants DATA_PAYLOAD_LEN =
      Constants._(233, _omitEnumNames ? '' : 'DATA_PAYLOAD_LEN');

  static const $core.List<Constants> values = <Constants>[
    ZERO,
    DATA_PAYLOAD_LEN,
  ];

  static final $core.Map<$core.int, Constants> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Constants? valueOf($core.int value) => _byValue[value];

  const Constants._(super.value, super.name);
}

///
///  Error codes for critical errors
///  The device might report these fault codes on the screen.
///  If you encounter a fault code, please post on the meshtastic.discourse.group
///  and we'll try to help.
class CriticalErrorCode extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const CriticalErrorCode NONE =
      CriticalErrorCode._(0, _omitEnumNames ? '' : 'NONE');

  ///
  ///  A software bug was detected while trying to send lora
  static const CriticalErrorCode TX_WATCHDOG =
      CriticalErrorCode._(1, _omitEnumNames ? '' : 'TX_WATCHDOG');

  ///
  ///  A software bug was detected on entry to sleep
  static const CriticalErrorCode SLEEP_ENTER_WAIT =
      CriticalErrorCode._(2, _omitEnumNames ? '' : 'SLEEP_ENTER_WAIT');

  ///
  ///  No Lora radio hardware could be found
  static const CriticalErrorCode NO_RADIO =
      CriticalErrorCode._(3, _omitEnumNames ? '' : 'NO_RADIO');

  ///
  ///  Not normally used
  static const CriticalErrorCode UNSPECIFIED =
      CriticalErrorCode._(4, _omitEnumNames ? '' : 'UNSPECIFIED');

  ///
  ///  We failed while configuring a UBlox GPS
  static const CriticalErrorCode UBLOX_UNIT_FAILED =
      CriticalErrorCode._(5, _omitEnumNames ? '' : 'UBLOX_UNIT_FAILED');

  ///
  ///  This board was expected to have a power management chip and it is missing or broken
  static const CriticalErrorCode NO_AXP192 =
      CriticalErrorCode._(6, _omitEnumNames ? '' : 'NO_AXP192');

  ///
  ///  The channel tried to set a radio setting which is not supported by this chipset,
  ///  radio comms settings are now undefined.
  static const CriticalErrorCode INVALID_RADIO_SETTING =
      CriticalErrorCode._(7, _omitEnumNames ? '' : 'INVALID_RADIO_SETTING');

  ///
  ///  Radio transmit hardware failure. We sent data to the radio chip, but it didn't
  ///  reply with an interrupt.
  static const CriticalErrorCode TRANSMIT_FAILED =
      CriticalErrorCode._(8, _omitEnumNames ? '' : 'TRANSMIT_FAILED');

  ///
  ///  We detected that the main CPU voltage dropped below the minimum acceptable value
  static const CriticalErrorCode BROWNOUT =
      CriticalErrorCode._(9, _omitEnumNames ? '' : 'BROWNOUT');

  /// Selftest of SX1262 radio chip failed
  static const CriticalErrorCode SX1262_FAILURE =
      CriticalErrorCode._(10, _omitEnumNames ? '' : 'SX1262_FAILURE');

  ///
  ///  A (likely software but possibly hardware) failure was detected while trying to send packets.
  ///  If this occurs on your board, please post in the forum so that we can ask you to collect some information to allow fixing this bug
  static const CriticalErrorCode RADIO_SPI_BUG =
      CriticalErrorCode._(11, _omitEnumNames ? '' : 'RADIO_SPI_BUG');

  ///
  ///  Corruption was detected on the flash filesystem but we were able to repair things.
  ///  If you see this failure in the field please post in the forum because we are interested in seeing if this is occurring in the field.
  static const CriticalErrorCode FLASH_CORRUPTION_RECOVERABLE =
      CriticalErrorCode._(
          12, _omitEnumNames ? '' : 'FLASH_CORRUPTION_RECOVERABLE');

  ///
  ///  Corruption was detected on the flash filesystem but we were unable to repair things.
  ///  NOTE: Your node will probably need to be reconfigured the next time it reboots (it will lose the region code etc...)
  ///  If you see this failure in the field please post in the forum because we are interested in seeing if this is occurring in the field.
  static const CriticalErrorCode FLASH_CORRUPTION_UNRECOVERABLE =
      CriticalErrorCode._(
          13, _omitEnumNames ? '' : 'FLASH_CORRUPTION_UNRECOVERABLE');

  static const $core.List<CriticalErrorCode> values = <CriticalErrorCode>[
    NONE,
    TX_WATCHDOG,
    SLEEP_ENTER_WAIT,
    NO_RADIO,
    UNSPECIFIED,
    UBLOX_UNIT_FAILED,
    NO_AXP192,
    INVALID_RADIO_SETTING,
    TRANSMIT_FAILED,
    BROWNOUT,
    SX1262_FAILURE,
    RADIO_SPI_BUG,
    FLASH_CORRUPTION_RECOVERABLE,
    FLASH_CORRUPTION_UNRECOVERABLE,
  ];

  static final $core.List<CriticalErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 13);
  static CriticalErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CriticalErrorCode._(super.value, super.name);
}

///
///  Enum to indicate to clients whether this firmware is a special firmware build, like an event.
///  The first 16 values are reserved for non-event special firmwares, like the Smart Citizen use case.
class FirmwareEdition extends $pb.ProtobufEnum {
  ///
  ///  Vanilla firmware
  static const FirmwareEdition VANILLA =
      FirmwareEdition._(0, _omitEnumNames ? '' : 'VANILLA');

  ///
  ///  Firmware for use in the Smart Citizen environmental monitoring network
  static const FirmwareEdition SMART_CITIZEN =
      FirmwareEdition._(1, _omitEnumNames ? '' : 'SMART_CITIZEN');

  ///
  ///  Open Sauce, the maker conference held yearly in CA
  static const FirmwareEdition OPEN_SAUCE =
      FirmwareEdition._(16, _omitEnumNames ? '' : 'OPEN_SAUCE');

  ///
  ///  DEFCON, the yearly hacker conference
  static const FirmwareEdition DEFCON =
      FirmwareEdition._(17, _omitEnumNames ? '' : 'DEFCON');

  ///
  ///  Burning Man, the yearly hippie gathering in the desert
  static const FirmwareEdition BURNING_MAN =
      FirmwareEdition._(18, _omitEnumNames ? '' : 'BURNING_MAN');

  ///
  ///  Hamvention, the Dayton amateur radio convention
  static const FirmwareEdition HAMVENTION =
      FirmwareEdition._(19, _omitEnumNames ? '' : 'HAMVENTION');

  ///
  ///  Placeholder for DIY and unofficial events
  static const FirmwareEdition DIY_EDITION =
      FirmwareEdition._(127, _omitEnumNames ? '' : 'DIY_EDITION');

  static const $core.List<FirmwareEdition> values = <FirmwareEdition>[
    VANILLA,
    SMART_CITIZEN,
    OPEN_SAUCE,
    DEFCON,
    BURNING_MAN,
    HAMVENTION,
    DIY_EDITION,
  ];

  static final $core.Map<$core.int, FirmwareEdition> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FirmwareEdition? valueOf($core.int value) => _byValue[value];

  const FirmwareEdition._(super.value, super.name);
}

///
///  Enum for modules excluded from a device's configuration.
///  Each value represents a ModuleConfigType that can be toggled as excluded
///  by setting its corresponding bit in the `excluded_modules` bitmask field.
class ExcludedModules extends $pb.ProtobufEnum {
  ///
  ///  Default value of 0 indicates no modules are excluded.
  static const ExcludedModules EXCLUDED_NONE =
      ExcludedModules._(0, _omitEnumNames ? '' : 'EXCLUDED_NONE');

  ///
  ///  MQTT module
  static const ExcludedModules MQTT_CONFIG =
      ExcludedModules._(1, _omitEnumNames ? '' : 'MQTT_CONFIG');

  ///
  ///  Serial module
  static const ExcludedModules SERIAL_CONFIG =
      ExcludedModules._(2, _omitEnumNames ? '' : 'SERIAL_CONFIG');

  ///
  ///  External Notification module
  static const ExcludedModules EXTNOTIF_CONFIG =
      ExcludedModules._(4, _omitEnumNames ? '' : 'EXTNOTIF_CONFIG');

  ///
  ///  Store and Forward module
  static const ExcludedModules STOREFORWARD_CONFIG =
      ExcludedModules._(8, _omitEnumNames ? '' : 'STOREFORWARD_CONFIG');

  ///
  ///  Range Test module
  static const ExcludedModules RANGETEST_CONFIG =
      ExcludedModules._(16, _omitEnumNames ? '' : 'RANGETEST_CONFIG');

  ///
  ///  Telemetry module
  static const ExcludedModules TELEMETRY_CONFIG =
      ExcludedModules._(32, _omitEnumNames ? '' : 'TELEMETRY_CONFIG');

  ///
  ///  Canned Message module
  static const ExcludedModules CANNEDMSG_CONFIG =
      ExcludedModules._(64, _omitEnumNames ? '' : 'CANNEDMSG_CONFIG');

  ///
  ///  Audio module
  static const ExcludedModules AUDIO_CONFIG =
      ExcludedModules._(128, _omitEnumNames ? '' : 'AUDIO_CONFIG');

  ///
  ///  Remote Hardware module
  static const ExcludedModules REMOTEHARDWARE_CONFIG =
      ExcludedModules._(256, _omitEnumNames ? '' : 'REMOTEHARDWARE_CONFIG');

  ///
  ///  Neighbor Info module
  static const ExcludedModules NEIGHBORINFO_CONFIG =
      ExcludedModules._(512, _omitEnumNames ? '' : 'NEIGHBORINFO_CONFIG');

  ///
  ///  Ambient Lighting module
  static const ExcludedModules AMBIENTLIGHTING_CONFIG =
      ExcludedModules._(1024, _omitEnumNames ? '' : 'AMBIENTLIGHTING_CONFIG');

  ///
  ///  Detection Sensor module
  static const ExcludedModules DETECTIONSENSOR_CONFIG =
      ExcludedModules._(2048, _omitEnumNames ? '' : 'DETECTIONSENSOR_CONFIG');

  ///
  ///  Paxcounter module
  static const ExcludedModules PAXCOUNTER_CONFIG =
      ExcludedModules._(4096, _omitEnumNames ? '' : 'PAXCOUNTER_CONFIG');

  ///
  ///  Bluetooth config (not technically a module, but used to indicate bluetooth capabilities)
  static const ExcludedModules BLUETOOTH_CONFIG =
      ExcludedModules._(8192, _omitEnumNames ? '' : 'BLUETOOTH_CONFIG');

  ///
  ///  Network config (not technically a module, but used to indicate network capabilities)
  static const ExcludedModules NETWORK_CONFIG =
      ExcludedModules._(16384, _omitEnumNames ? '' : 'NETWORK_CONFIG');

  static const $core.List<ExcludedModules> values = <ExcludedModules>[
    EXCLUDED_NONE,
    MQTT_CONFIG,
    SERIAL_CONFIG,
    EXTNOTIF_CONFIG,
    STOREFORWARD_CONFIG,
    RANGETEST_CONFIG,
    TELEMETRY_CONFIG,
    CANNEDMSG_CONFIG,
    AUDIO_CONFIG,
    REMOTEHARDWARE_CONFIG,
    NEIGHBORINFO_CONFIG,
    AMBIENTLIGHTING_CONFIG,
    DETECTIONSENSOR_CONFIG,
    PAXCOUNTER_CONFIG,
    BLUETOOTH_CONFIG,
    NETWORK_CONFIG,
  ];

  static final $core.Map<$core.int, ExcludedModules> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ExcludedModules? valueOf($core.int value) => _byValue[value];

  const ExcludedModules._(super.value, super.name);
}

///
///  How the location was acquired: manual, onboard GPS, external (EUD) GPS
class Position_LocSource extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const Position_LocSource LOC_UNSET =
      Position_LocSource._(0, _omitEnumNames ? '' : 'LOC_UNSET');

  ///
  ///  TODO: REPLACE
  static const Position_LocSource LOC_MANUAL =
      Position_LocSource._(1, _omitEnumNames ? '' : 'LOC_MANUAL');

  ///
  ///  TODO: REPLACE
  static const Position_LocSource LOC_INTERNAL =
      Position_LocSource._(2, _omitEnumNames ? '' : 'LOC_INTERNAL');

  ///
  ///  TODO: REPLACE
  static const Position_LocSource LOC_EXTERNAL =
      Position_LocSource._(3, _omitEnumNames ? '' : 'LOC_EXTERNAL');

  static const $core.List<Position_LocSource> values = <Position_LocSource>[
    LOC_UNSET,
    LOC_MANUAL,
    LOC_INTERNAL,
    LOC_EXTERNAL,
  ];

  static final $core.List<Position_LocSource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Position_LocSource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Position_LocSource._(super.value, super.name);
}

///
///  How the altitude was acquired: manual, GPS int/ext, etc
///  Default: same as location_source if present
class Position_AltSource extends $pb.ProtobufEnum {
  ///
  ///  TODO: REPLACE
  static const Position_AltSource ALT_UNSET =
      Position_AltSource._(0, _omitEnumNames ? '' : 'ALT_UNSET');

  ///
  ///  TODO: REPLACE
  static const Position_AltSource ALT_MANUAL =
      Position_AltSource._(1, _omitEnumNames ? '' : 'ALT_MANUAL');

  ///
  ///  TODO: REPLACE
  static const Position_AltSource ALT_INTERNAL =
      Position_AltSource._(2, _omitEnumNames ? '' : 'ALT_INTERNAL');

  ///
  ///  TODO: REPLACE
  static const Position_AltSource ALT_EXTERNAL =
      Position_AltSource._(3, _omitEnumNames ? '' : 'ALT_EXTERNAL');

  ///
  ///  TODO: REPLACE
  static const Position_AltSource ALT_BAROMETRIC =
      Position_AltSource._(4, _omitEnumNames ? '' : 'ALT_BAROMETRIC');

  static const $core.List<Position_AltSource> values = <Position_AltSource>[
    ALT_UNSET,
    ALT_MANUAL,
    ALT_INTERNAL,
    ALT_EXTERNAL,
    ALT_BAROMETRIC,
  ];

  static final $core.List<Position_AltSource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Position_AltSource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Position_AltSource._(super.value, super.name);
}

///
///  A failure in delivering a message (usually used for routing control messages, but might be provided in addition to ack.fail_id to provide
///  details on the type of failure).
class Routing_Error extends $pb.ProtobufEnum {
  ///
  ///  This message is not a failure
  static const Routing_Error NONE =
      Routing_Error._(0, _omitEnumNames ? '' : 'NONE');

  ///
  ///  Our node doesn't have a route to the requested destination anymore.
  static const Routing_Error NO_ROUTE =
      Routing_Error._(1, _omitEnumNames ? '' : 'NO_ROUTE');

  ///
  ///  We received a nak while trying to forward on your behalf
  static const Routing_Error GOT_NAK =
      Routing_Error._(2, _omitEnumNames ? '' : 'GOT_NAK');

  ///
  ///  TODO: REPLACE
  static const Routing_Error TIMEOUT =
      Routing_Error._(3, _omitEnumNames ? '' : 'TIMEOUT');

  ///
  ///  No suitable interface could be found for delivering this packet
  static const Routing_Error NO_INTERFACE =
      Routing_Error._(4, _omitEnumNames ? '' : 'NO_INTERFACE');

  ///
  ///  We reached the max retransmission count (typically for naive flood routing)
  static const Routing_Error MAX_RETRANSMIT =
      Routing_Error._(5, _omitEnumNames ? '' : 'MAX_RETRANSMIT');

  ///
  ///  No suitable channel was found for sending this packet (i.e. was requested channel index disabled?)
  static const Routing_Error NO_CHANNEL =
      Routing_Error._(6, _omitEnumNames ? '' : 'NO_CHANNEL');

  ///
  ///  The packet was too big for sending (exceeds interface MTU after encoding)
  static const Routing_Error TOO_LARGE =
      Routing_Error._(7, _omitEnumNames ? '' : 'TOO_LARGE');

  ///
  ///  The request had want_response set, the request reached the destination node, but no service on that node wants to send a response
  ///  (possibly due to bad channel permissions)
  static const Routing_Error NO_RESPONSE =
      Routing_Error._(8, _omitEnumNames ? '' : 'NO_RESPONSE');

  ///
  ///  Cannot send currently because duty cycle regulations will be violated.
  static const Routing_Error DUTY_CYCLE_LIMIT =
      Routing_Error._(9, _omitEnumNames ? '' : 'DUTY_CYCLE_LIMIT');

  ///
  ///  The application layer service on the remote node received your request, but considered your request somehow invalid
  static const Routing_Error BAD_REQUEST =
      Routing_Error._(32, _omitEnumNames ? '' : 'BAD_REQUEST');

  ///
  ///  The application layer service on the remote node received your request, but considered your request not authorized
  ///  (i.e you did not send the request on the required bound channel)
  static const Routing_Error NOT_AUTHORIZED =
      Routing_Error._(33, _omitEnumNames ? '' : 'NOT_AUTHORIZED');

  ///
  ///  The client specified a PKI transport, but the node was unable to send the packet using PKI (and did not send the message at all)
  static const Routing_Error PKI_FAILED =
      Routing_Error._(34, _omitEnumNames ? '' : 'PKI_FAILED');

  ///
  ///  The receiving node does not have a Public Key to decode with
  static const Routing_Error PKI_UNKNOWN_PUBKEY =
      Routing_Error._(35, _omitEnumNames ? '' : 'PKI_UNKNOWN_PUBKEY');

  ///
  ///  Admin packet otherwise checks out, but uses a bogus or expired session key
  static const Routing_Error ADMIN_BAD_SESSION_KEY =
      Routing_Error._(36, _omitEnumNames ? '' : 'ADMIN_BAD_SESSION_KEY');

  ///
  ///  Admin packet sent using PKC, but not from a public key on the admin key list
  static const Routing_Error ADMIN_PUBLIC_KEY_UNAUTHORIZED = Routing_Error._(
      37, _omitEnumNames ? '' : 'ADMIN_PUBLIC_KEY_UNAUTHORIZED');

  ///
  ///  Airtime fairness rate limit exceeded for a packet
  ///  This typically enforced per portnum and is used to prevent a single node from monopolizing airtime
  static const Routing_Error RATE_LIMIT_EXCEEDED =
      Routing_Error._(38, _omitEnumNames ? '' : 'RATE_LIMIT_EXCEEDED');

  static const $core.List<Routing_Error> values = <Routing_Error>[
    NONE,
    NO_ROUTE,
    GOT_NAK,
    TIMEOUT,
    NO_INTERFACE,
    MAX_RETRANSMIT,
    NO_CHANNEL,
    TOO_LARGE,
    NO_RESPONSE,
    DUTY_CYCLE_LIMIT,
    BAD_REQUEST,
    NOT_AUTHORIZED,
    PKI_FAILED,
    PKI_UNKNOWN_PUBKEY,
    ADMIN_BAD_SESSION_KEY,
    ADMIN_PUBLIC_KEY_UNAUTHORIZED,
    RATE_LIMIT_EXCEEDED,
  ];

  static final $core.Map<$core.int, Routing_Error> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Routing_Error? valueOf($core.int value) => _byValue[value];

  const Routing_Error._(super.value, super.name);
}

///
///  The priority of this message for sending.
///  Higher priorities are sent first (when managing the transmit queue).
///  This field is never sent over the air, it is only used internally inside of a local device node.
///  API clients (either on the local node or connected directly to the node)
///  can set this parameter if necessary.
///  (values must be <= 127 to keep protobuf field to one byte in size.
///  Detailed background on this field:
///  I noticed a funny side effect of lora being so slow: Usually when making
///  a protocol there isn’t much need to use message priority to change the order
///  of transmission (because interfaces are fairly fast).
///  But for lora where packets can take a few seconds each, it is very important
///  to make sure that critical packets are sent ASAP.
///  In the case of meshtastic that means we want to send protocol acks as soon as possible
///  (to prevent unneeded retransmissions), we want routing messages to be sent next,
///  then messages marked as reliable and finally 'background' packets like periodic position updates.
///  So I bit the bullet and implemented a new (internal - not sent over the air)
///  field in MeshPacket called 'priority'.
///  And the transmission queue in the router object is now a priority queue.
class MeshPacket_Priority extends $pb.ProtobufEnum {
  ///
  ///  Treated as Priority.DEFAULT
  static const MeshPacket_Priority UNSET =
      MeshPacket_Priority._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  TODO: REPLACE
  static const MeshPacket_Priority MIN =
      MeshPacket_Priority._(1, _omitEnumNames ? '' : 'MIN');

  ///
  ///  Background position updates are sent with very low priority -
  ///  if the link is super congested they might not go out at all
  static const MeshPacket_Priority BACKGROUND =
      MeshPacket_Priority._(10, _omitEnumNames ? '' : 'BACKGROUND');

  ///
  ///  This priority is used for most messages that don't have a priority set
  static const MeshPacket_Priority DEFAULT =
      MeshPacket_Priority._(64, _omitEnumNames ? '' : 'DEFAULT');

  ///
  ///  If priority is unset but the message is marked as want_ack,
  ///  assume it is important and use a slightly higher priority
  static const MeshPacket_Priority RELIABLE =
      MeshPacket_Priority._(70, _omitEnumNames ? '' : 'RELIABLE');

  ///
  ///  If priority is unset but the packet is a response to a request, we want it to get there relatively quickly.
  ///  Furthermore, responses stop relaying packets directed to a node early.
  static const MeshPacket_Priority RESPONSE =
      MeshPacket_Priority._(80, _omitEnumNames ? '' : 'RESPONSE');

  ///
  ///  Higher priority for specific message types (portnums) to distinguish between other reliable packets.
  static const MeshPacket_Priority HIGH =
      MeshPacket_Priority._(100, _omitEnumNames ? '' : 'HIGH');

  ///
  ///  Higher priority alert message used for critical alerts which take priority over other reliable packets.
  static const MeshPacket_Priority ALERT =
      MeshPacket_Priority._(110, _omitEnumNames ? '' : 'ALERT');

  ///
  ///  Ack/naks are sent with very high priority to ensure that retransmission
  ///  stops as soon as possible
  static const MeshPacket_Priority ACK =
      MeshPacket_Priority._(120, _omitEnumNames ? '' : 'ACK');

  ///
  ///  TODO: REPLACE
  static const MeshPacket_Priority MAX =
      MeshPacket_Priority._(127, _omitEnumNames ? '' : 'MAX');

  static const $core.List<MeshPacket_Priority> values = <MeshPacket_Priority>[
    UNSET,
    MIN,
    BACKGROUND,
    DEFAULT,
    RELIABLE,
    RESPONSE,
    HIGH,
    ALERT,
    ACK,
    MAX,
  ];

  static final $core.Map<$core.int, MeshPacket_Priority> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MeshPacket_Priority? valueOf($core.int value) => _byValue[value];

  const MeshPacket_Priority._(super.value, super.name);
}

///
///  Identify if this is a delayed packet
class MeshPacket_Delayed extends $pb.ProtobufEnum {
  ///
  ///  If unset, the message is being sent in real time.
  static const MeshPacket_Delayed NO_DELAY =
      MeshPacket_Delayed._(0, _omitEnumNames ? '' : 'NO_DELAY');

  ///
  ///  The message is delayed and was originally a broadcast
  static const MeshPacket_Delayed DELAYED_BROADCAST =
      MeshPacket_Delayed._(1, _omitEnumNames ? '' : 'DELAYED_BROADCAST');

  ///
  ///  The message is delayed and was originally a direct message
  static const MeshPacket_Delayed DELAYED_DIRECT =
      MeshPacket_Delayed._(2, _omitEnumNames ? '' : 'DELAYED_DIRECT');

  static const $core.List<MeshPacket_Delayed> values = <MeshPacket_Delayed>[
    NO_DELAY,
    DELAYED_BROADCAST,
    DELAYED_DIRECT,
  ];

  static final $core.List<MeshPacket_Delayed?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MeshPacket_Delayed? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MeshPacket_Delayed._(super.value, super.name);
}

///
///  Enum to identify which transport mechanism this packet arrived over
class MeshPacket_TransportMechanism extends $pb.ProtobufEnum {
  ///
  ///  The default case is that the node generated a packet itself
  static const MeshPacket_TransportMechanism TRANSPORT_INTERNAL =
      MeshPacket_TransportMechanism._(
          0, _omitEnumNames ? '' : 'TRANSPORT_INTERNAL');

  ///
  ///  Arrived via the primary LoRa radio
  static const MeshPacket_TransportMechanism TRANSPORT_LORA =
      MeshPacket_TransportMechanism._(
          1, _omitEnumNames ? '' : 'TRANSPORT_LORA');

  ///
  ///  Arrived via a secondary LoRa radio
  static const MeshPacket_TransportMechanism TRANSPORT_LORA_ALT1 =
      MeshPacket_TransportMechanism._(
          2, _omitEnumNames ? '' : 'TRANSPORT_LORA_ALT1');

  ///
  ///  Arrived via a tertiary LoRa radio
  static const MeshPacket_TransportMechanism TRANSPORT_LORA_ALT2 =
      MeshPacket_TransportMechanism._(
          3, _omitEnumNames ? '' : 'TRANSPORT_LORA_ALT2');

  ///
  ///  Arrived via a quaternary LoRa radio
  static const MeshPacket_TransportMechanism TRANSPORT_LORA_ALT3 =
      MeshPacket_TransportMechanism._(
          4, _omitEnumNames ? '' : 'TRANSPORT_LORA_ALT3');

  ///
  ///  Arrived via an MQTT connection
  static const MeshPacket_TransportMechanism TRANSPORT_MQTT =
      MeshPacket_TransportMechanism._(
          5, _omitEnumNames ? '' : 'TRANSPORT_MQTT');

  ///
  ///  Arrived via Multicast UDP
  static const MeshPacket_TransportMechanism TRANSPORT_MULTICAST_UDP =
      MeshPacket_TransportMechanism._(
          6, _omitEnumNames ? '' : 'TRANSPORT_MULTICAST_UDP');

  ///
  ///  Arrived via API connection
  static const MeshPacket_TransportMechanism TRANSPORT_API =
      MeshPacket_TransportMechanism._(7, _omitEnumNames ? '' : 'TRANSPORT_API');

  static const $core.List<MeshPacket_TransportMechanism> values =
      <MeshPacket_TransportMechanism>[
    TRANSPORT_INTERNAL,
    TRANSPORT_LORA,
    TRANSPORT_LORA_ALT1,
    TRANSPORT_LORA_ALT2,
    TRANSPORT_LORA_ALT3,
    TRANSPORT_MQTT,
    TRANSPORT_MULTICAST_UDP,
    TRANSPORT_API,
  ];

  static final $core.List<MeshPacket_TransportMechanism?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static MeshPacket_TransportMechanism? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MeshPacket_TransportMechanism._(super.value, super.name);
}

///
///  Log levels, chosen to match python logging conventions.
class LogRecord_Level extends $pb.ProtobufEnum {
  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level UNSET =
      LogRecord_Level._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level CRITICAL =
      LogRecord_Level._(50, _omitEnumNames ? '' : 'CRITICAL');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level ERROR =
      LogRecord_Level._(40, _omitEnumNames ? '' : 'ERROR');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level WARNING =
      LogRecord_Level._(30, _omitEnumNames ? '' : 'WARNING');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level INFO =
      LogRecord_Level._(20, _omitEnumNames ? '' : 'INFO');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level DEBUG =
      LogRecord_Level._(10, _omitEnumNames ? '' : 'DEBUG');

  ///
  ///  Log levels, chosen to match python logging conventions.
  static const LogRecord_Level TRACE =
      LogRecord_Level._(5, _omitEnumNames ? '' : 'TRACE');

  static const $core.List<LogRecord_Level> values = <LogRecord_Level>[
    UNSET,
    CRITICAL,
    ERROR,
    WARNING,
    INFO,
    DEBUG,
    TRACE,
  ];

  static final $core.Map<$core.int, LogRecord_Level> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static LogRecord_Level? valueOf($core.int value) => _byValue[value];

  const LogRecord_Level._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
