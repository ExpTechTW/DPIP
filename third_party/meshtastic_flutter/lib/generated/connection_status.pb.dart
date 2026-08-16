// This is a generated file - do not edit.
//
// Generated from meshtastic/connection_status.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class DeviceConnectionStatus extends $pb.GeneratedMessage {
  factory DeviceConnectionStatus({
    WifiConnectionStatus? wifi,
    EthernetConnectionStatus? ethernet,
    BluetoothConnectionStatus? bluetooth,
    SerialConnectionStatus? serial,
  }) {
    final result = create();
    if (wifi != null) result.wifi = wifi;
    if (ethernet != null) result.ethernet = ethernet;
    if (bluetooth != null) result.bluetooth = bluetooth;
    if (serial != null) result.serial = serial;
    return result;
  }

  DeviceConnectionStatus._();

  factory DeviceConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<WifiConnectionStatus>(1, _omitFieldNames ? '' : 'wifi',
        subBuilder: WifiConnectionStatus.create)
    ..aOM<EthernetConnectionStatus>(2, _omitFieldNames ? '' : 'ethernet',
        subBuilder: EthernetConnectionStatus.create)
    ..aOM<BluetoothConnectionStatus>(3, _omitFieldNames ? '' : 'bluetooth',
        subBuilder: BluetoothConnectionStatus.create)
    ..aOM<SerialConnectionStatus>(4, _omitFieldNames ? '' : 'serial',
        subBuilder: SerialConnectionStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceConnectionStatus clone() =>
      DeviceConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceConnectionStatus copyWith(
          void Function(DeviceConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as DeviceConnectionStatus))
          as DeviceConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceConnectionStatus create() => DeviceConnectionStatus._();
  @$core.override
  DeviceConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<DeviceConnectionStatus> createRepeated() =>
      $pb.PbList<DeviceConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static DeviceConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceConnectionStatus>(create);
  static DeviceConnectionStatus? _defaultInstance;

  ///
  ///  WiFi Status
  @$pb.TagNumber(1)
  WifiConnectionStatus get wifi => $_getN(0);
  @$pb.TagNumber(1)
  set wifi(WifiConnectionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWifi() => $_has(0);
  @$pb.TagNumber(1)
  void clearWifi() => $_clearField(1);
  @$pb.TagNumber(1)
  WifiConnectionStatus ensureWifi() => $_ensure(0);

  ///
  ///  WiFi Status
  @$pb.TagNumber(2)
  EthernetConnectionStatus get ethernet => $_getN(1);
  @$pb.TagNumber(2)
  set ethernet(EthernetConnectionStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEthernet() => $_has(1);
  @$pb.TagNumber(2)
  void clearEthernet() => $_clearField(2);
  @$pb.TagNumber(2)
  EthernetConnectionStatus ensureEthernet() => $_ensure(1);

  ///
  ///  Bluetooth Status
  @$pb.TagNumber(3)
  BluetoothConnectionStatus get bluetooth => $_getN(2);
  @$pb.TagNumber(3)
  set bluetooth(BluetoothConnectionStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBluetooth() => $_has(2);
  @$pb.TagNumber(3)
  void clearBluetooth() => $_clearField(3);
  @$pb.TagNumber(3)
  BluetoothConnectionStatus ensureBluetooth() => $_ensure(2);

  ///
  ///  Serial Status
  @$pb.TagNumber(4)
  SerialConnectionStatus get serial => $_getN(3);
  @$pb.TagNumber(4)
  set serial(SerialConnectionStatus value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSerial() => $_has(3);
  @$pb.TagNumber(4)
  void clearSerial() => $_clearField(4);
  @$pb.TagNumber(4)
  SerialConnectionStatus ensureSerial() => $_ensure(3);
}

///
///  WiFi connection status
class WifiConnectionStatus extends $pb.GeneratedMessage {
  factory WifiConnectionStatus({
    NetworkConnectionStatus? status,
    $core.String? ssid,
    $core.int? rssi,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (ssid != null) result.ssid = ssid;
    if (rssi != null) result.rssi = rssi;
    return result;
  }

  WifiConnectionStatus._();

  factory WifiConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WifiConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WifiConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<NetworkConnectionStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: NetworkConnectionStatus.create)
    ..aOS(2, _omitFieldNames ? '' : 'ssid')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'rssi', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WifiConnectionStatus clone() =>
      WifiConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WifiConnectionStatus copyWith(void Function(WifiConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as WifiConnectionStatus))
          as WifiConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WifiConnectionStatus create() => WifiConnectionStatus._();
  @$core.override
  WifiConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<WifiConnectionStatus> createRepeated() =>
      $pb.PbList<WifiConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static WifiConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WifiConnectionStatus>(create);
  static WifiConnectionStatus? _defaultInstance;

  ///
  ///  Connection status
  @$pb.TagNumber(1)
  NetworkConnectionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(NetworkConnectionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  NetworkConnectionStatus ensureStatus() => $_ensure(0);

  ///
  ///  WiFi access point SSID
  @$pb.TagNumber(2)
  $core.String get ssid => $_getSZ(1);
  @$pb.TagNumber(2)
  set ssid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSsid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSsid() => $_clearField(2);

  ///
  ///  RSSI of wireless connection
  @$pb.TagNumber(3)
  $core.int get rssi => $_getIZ(2);
  @$pb.TagNumber(3)
  set rssi($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRssi() => $_has(2);
  @$pb.TagNumber(3)
  void clearRssi() => $_clearField(3);
}

///
///  Ethernet connection status
class EthernetConnectionStatus extends $pb.GeneratedMessage {
  factory EthernetConnectionStatus({
    NetworkConnectionStatus? status,
  }) {
    final result = create();
    if (status != null) result.status = status;
    return result;
  }

  EthernetConnectionStatus._();

  factory EthernetConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EthernetConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EthernetConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..aOM<NetworkConnectionStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: NetworkConnectionStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EthernetConnectionStatus clone() =>
      EthernetConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EthernetConnectionStatus copyWith(
          void Function(EthernetConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as EthernetConnectionStatus))
          as EthernetConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EthernetConnectionStatus create() => EthernetConnectionStatus._();
  @$core.override
  EthernetConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<EthernetConnectionStatus> createRepeated() =>
      $pb.PbList<EthernetConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static EthernetConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EthernetConnectionStatus>(create);
  static EthernetConnectionStatus? _defaultInstance;

  ///
  ///  Connection status
  @$pb.TagNumber(1)
  NetworkConnectionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(NetworkConnectionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  NetworkConnectionStatus ensureStatus() => $_ensure(0);
}

///
///  Ethernet or WiFi connection status
class NetworkConnectionStatus extends $pb.GeneratedMessage {
  factory NetworkConnectionStatus({
    $core.int? ipAddress,
    $core.bool? isConnected,
    $core.bool? isMqttConnected,
    $core.bool? isSyslogConnected,
  }) {
    final result = create();
    if (ipAddress != null) result.ipAddress = ipAddress;
    if (isConnected != null) result.isConnected = isConnected;
    if (isMqttConnected != null) result.isMqttConnected = isMqttConnected;
    if (isSyslogConnected != null) result.isSyslogConnected = isSyslogConnected;
    return result;
  }

  NetworkConnectionStatus._();

  factory NetworkConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NetworkConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NetworkConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'ipAddress', $pb.PbFieldType.OF3)
    ..aOB(2, _omitFieldNames ? '' : 'isConnected')
    ..aOB(3, _omitFieldNames ? '' : 'isMqttConnected')
    ..aOB(4, _omitFieldNames ? '' : 'isSyslogConnected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkConnectionStatus clone() =>
      NetworkConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkConnectionStatus copyWith(
          void Function(NetworkConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as NetworkConnectionStatus))
          as NetworkConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NetworkConnectionStatus create() => NetworkConnectionStatus._();
  @$core.override
  NetworkConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<NetworkConnectionStatus> createRepeated() =>
      $pb.PbList<NetworkConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static NetworkConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NetworkConnectionStatus>(create);
  static NetworkConnectionStatus? _defaultInstance;

  ///
  ///  IP address of device
  @$pb.TagNumber(1)
  $core.int get ipAddress => $_getIZ(0);
  @$pb.TagNumber(1)
  set ipAddress($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIpAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearIpAddress() => $_clearField(1);

  ///
  ///  Whether the device has an active connection or not
  @$pb.TagNumber(2)
  $core.bool get isConnected => $_getBF(1);
  @$pb.TagNumber(2)
  set isConnected($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsConnected() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsConnected() => $_clearField(2);

  ///
  ///  Whether the device has an active connection to an MQTT broker or not
  @$pb.TagNumber(3)
  $core.bool get isMqttConnected => $_getBF(2);
  @$pb.TagNumber(3)
  set isMqttConnected($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsMqttConnected() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsMqttConnected() => $_clearField(3);

  ///
  ///  Whether the device is actively remote syslogging or not
  @$pb.TagNumber(4)
  $core.bool get isSyslogConnected => $_getBF(3);
  @$pb.TagNumber(4)
  set isSyslogConnected($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsSyslogConnected() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsSyslogConnected() => $_clearField(4);
}

///
///  Bluetooth connection status
class BluetoothConnectionStatus extends $pb.GeneratedMessage {
  factory BluetoothConnectionStatus({
    $core.int? pin,
    $core.int? rssi,
    $core.bool? isConnected,
  }) {
    final result = create();
    if (pin != null) result.pin = pin;
    if (rssi != null) result.rssi = rssi;
    if (isConnected != null) result.isConnected = isConnected;
    return result;
  }

  BluetoothConnectionStatus._();

  factory BluetoothConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BluetoothConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BluetoothConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'pin', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'rssi', $pb.PbFieldType.O3)
    ..aOB(3, _omitFieldNames ? '' : 'isConnected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BluetoothConnectionStatus clone() =>
      BluetoothConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BluetoothConnectionStatus copyWith(
          void Function(BluetoothConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as BluetoothConnectionStatus))
          as BluetoothConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BluetoothConnectionStatus create() => BluetoothConnectionStatus._();
  @$core.override
  BluetoothConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<BluetoothConnectionStatus> createRepeated() =>
      $pb.PbList<BluetoothConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static BluetoothConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BluetoothConnectionStatus>(create);
  static BluetoothConnectionStatus? _defaultInstance;

  ///
  ///  The pairing PIN for bluetooth
  @$pb.TagNumber(1)
  $core.int get pin => $_getIZ(0);
  @$pb.TagNumber(1)
  set pin($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPin() => $_has(0);
  @$pb.TagNumber(1)
  void clearPin() => $_clearField(1);

  ///
  ///  RSSI of bluetooth connection
  @$pb.TagNumber(2)
  $core.int get rssi => $_getIZ(1);
  @$pb.TagNumber(2)
  set rssi($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRssi() => $_has(1);
  @$pb.TagNumber(2)
  void clearRssi() => $_clearField(2);

  ///
  ///  Whether the device has an active connection or not
  @$pb.TagNumber(3)
  $core.bool get isConnected => $_getBF(2);
  @$pb.TagNumber(3)
  set isConnected($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsConnected() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsConnected() => $_clearField(3);
}

///
///  Serial connection status
class SerialConnectionStatus extends $pb.GeneratedMessage {
  factory SerialConnectionStatus({
    $core.int? baud,
    $core.bool? isConnected,
  }) {
    final result = create();
    if (baud != null) result.baud = baud;
    if (isConnected != null) result.isConnected = isConnected;
    return result;
  }

  SerialConnectionStatus._();

  factory SerialConnectionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SerialConnectionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SerialConnectionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'baud', $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'isConnected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SerialConnectionStatus clone() =>
      SerialConnectionStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SerialConnectionStatus copyWith(
          void Function(SerialConnectionStatus) updates) =>
      super.copyWith((message) => updates(message as SerialConnectionStatus))
          as SerialConnectionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SerialConnectionStatus create() => SerialConnectionStatus._();
  @$core.override
  SerialConnectionStatus createEmptyInstance() => create();
  static $pb.PbList<SerialConnectionStatus> createRepeated() =>
      $pb.PbList<SerialConnectionStatus>();
  @$core.pragma('dart2js:noInline')
  static SerialConnectionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SerialConnectionStatus>(create);
  static SerialConnectionStatus? _defaultInstance;

  ///
  ///  Serial baud rate
  @$pb.TagNumber(1)
  $core.int get baud => $_getIZ(0);
  @$pb.TagNumber(1)
  set baud($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBaud() => $_has(0);
  @$pb.TagNumber(1)
  void clearBaud() => $_clearField(1);

  ///
  ///  Whether the device has an active connection or not
  @$pb.TagNumber(2)
  $core.bool get isConnected => $_getBF(1);
  @$pb.TagNumber(2)
  set isConnected($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsConnected() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsConnected() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
