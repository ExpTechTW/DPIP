import '../../generated/config.pb.dart';
import '../../generated/module_config.pb.dart';
import '../../generated/channel.pb.dart';

/// Wrapper for Meshtastic device configuration
class MeshtasticConfigWrapper {
  final Config config;
  final ModuleConfig moduleConfig;
  final List<Channel> channels;

  const MeshtasticConfigWrapper({
    required this.config,
    required this.moduleConfig,
    required this.channels,
  });

  /// Device configuration
  Config_DeviceConfig? get deviceConfig =>
      config.hasDevice() ? config.device : null;

  /// Position configuration
  Config_PositionConfig? get positionConfig =>
      config.hasPosition() ? config.position : null;

  /// Power configuration
  Config_PowerConfig? get powerConfig =>
      config.hasPower() ? config.power : null;

  /// Network configuration
  Config_NetworkConfig? get networkConfig =>
      config.hasNetwork() ? config.network : null;

  /// Display configuration
  Config_DisplayConfig? get displayConfig =>
      config.hasDisplay() ? config.display : null;

  /// LoRa configuration
  Config_LoRaConfig? get loraConfig => config.hasLora() ? config.lora : null;

  /// Bluetooth configuration
  Config_BluetoothConfig? get bluetoothConfig =>
      config.hasBluetooth() ? config.bluetooth : null;

  /// MQTT module configuration
  ModuleConfig_MQTTConfig? get mqttConfig =>
      moduleConfig.hasMqtt() ? moduleConfig.mqtt : null;

  /// Serial module configuration
  ModuleConfig_SerialConfig? get serialConfig =>
      moduleConfig.hasSerial() ? moduleConfig.serial : null;

  /// External notification configuration
  ModuleConfig_ExternalNotificationConfig? get externalNotificationConfig =>
      moduleConfig.hasExternalNotification()
      ? moduleConfig.externalNotification
      : null;

  /// Store and forward configuration
  ModuleConfig_StoreForwardConfig? get storeForwardConfig =>
      moduleConfig.hasStoreForward() ? moduleConfig.storeForward : null;

  /// Range test configuration
  ModuleConfig_RangeTestConfig? get rangeTestConfig =>
      moduleConfig.hasRangeTest() ? moduleConfig.rangeTest : null;

  /// Telemetry configuration
  ModuleConfig_TelemetryConfig? get telemetryConfig =>
      moduleConfig.hasTelemetry() ? moduleConfig.telemetry : null;

  /// Canned message configuration
  ModuleConfig_CannedMessageConfig? get cannedMessageConfig =>
      moduleConfig.hasCannedMessage() ? moduleConfig.cannedMessage : null;

  /// Audio configuration
  ModuleConfig_AudioConfig? get audioConfig =>
      moduleConfig.hasAudio() ? moduleConfig.audio : null;

  /// Remote hardware configuration
  ModuleConfig_RemoteHardwareConfig? get remoteHardwareConfig =>
      moduleConfig.hasRemoteHardware() ? moduleConfig.remoteHardware : null;

  /// Neighbor info configuration
  ModuleConfig_NeighborInfoConfig? get neighborInfoConfig =>
      moduleConfig.hasNeighborInfo() ? moduleConfig.neighborInfo : null;

  /// Ambient lighting configuration
  ModuleConfig_AmbientLightingConfig? get ambientLightingConfig =>
      moduleConfig.hasAmbientLighting() ? moduleConfig.ambientLighting : null;

  /// Detection sensor configuration
  ModuleConfig_DetectionSensorConfig? get detectionSensorConfig =>
      moduleConfig.hasDetectionSensor() ? moduleConfig.detectionSensor : null;

  /// Paxcounter configuration
  ModuleConfig_PaxcounterConfig? get paxcounterConfig =>
      moduleConfig.hasPaxcounter() ? moduleConfig.paxcounter : null;

  /// Primary channel (index 0)
  Channel? get primaryChannel => channels.isNotEmpty ? channels[0] : null;

  /// Secondary channels (index 1+)
  List<Channel> get secondaryChannels =>
      channels.length > 1 ? channels.sublist(1) : [];

  /// All channels that are enabled
  List<Channel> get enabledChannels => channels
      .where((ch) => ch.hasSettings() && ch.settings.name.isNotEmpty)
      .toList();

  /// Device role
  Config_DeviceConfig_Role? get deviceRole => deviceConfig?.role;

  /// Node info broadcast interval (seconds)
  int? get nodeInfoBroadcastSecs => deviceConfig?.nodeInfoBroadcastSecs;

  /// Double tap as button press
  bool get doubleTapAsButtonPress =>
      deviceConfig?.doubleTapAsButtonPress ?? false;

  /// GPS operation mode
  Config_PositionConfig_GpsMode? get gpsMode => positionConfig?.gpsMode;

  /// GPS update interval (seconds)
  int? get gpsUpdateInterval => positionConfig?.gpsUpdateInterval;

  /// Position broadcast interval (seconds)
  int? get positionBroadcastSecs => positionConfig?.positionBroadcastSecs;

  /// Whether GPS is enabled
  bool get gpsEnabled => gpsMode == Config_PositionConfig_GpsMode.ENABLED;

  /// LoRa region
  Config_LoRaConfig_RegionCode? get region => loraConfig?.region;

  /// Hop limit
  int? get hopLimit => loraConfig?.hopLimit;

  /// Transmit enabled
  bool get txEnabled => loraConfig?.txEnabled ?? true;

  /// Transmit power level
  int? get txPower => loraConfig?.txPower;

  /// Channel number
  int? get channelNum => loraConfig?.channelNum;

  /// Override duty cycle limit
  bool get overrideDutyCycle => loraConfig?.overrideDutyCycle ?? false;

  /// Whether Bluetooth is enabled
  bool get bluetoothEnabled => bluetoothConfig?.enabled ?? true;

  /// Bluetooth mode
  Config_BluetoothConfig_PairingMode? get bluetoothMode =>
      bluetoothConfig?.mode;

  /// Fixed PIN for Bluetooth pairing
  int? get fixedPin => bluetoothConfig?.fixedPin;

  @override
  String toString() {
    return 'MeshtasticConfigWrapper(deviceRole: $deviceRole, region: $region, '
        'channels: ${channels.length}, bluetoothEnabled: $bluetoothEnabled)';
  }
}
