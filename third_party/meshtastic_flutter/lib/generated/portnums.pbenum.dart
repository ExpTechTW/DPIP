// This is a generated file - do not edit.
//
// Generated from meshtastic/portnums.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  For any new 'apps' that run on the device or via sister apps on phones/PCs they should pick and use a
///  unique 'portnum' for their application.
///  If you are making a new app using meshtastic, please send in a pull request to add your 'portnum' to this
///  master table.
///  PortNums should be assigned in the following range:
///  0-63   Core Meshtastic use, do not use for third party apps
///  64-127 Registered 3rd party apps, send in a pull request that adds a new entry to portnums.proto to  register your application
///  256-511 Use one of these portnums for your private applications that you don't want to register publically
///  All other values are reserved.
///  Note: This was formerly a Type enum named 'typ' with the same id #
///  We have change to this 'portnum' based scheme for specifying app handlers for particular payloads.
///  This change is backwards compatible by treating the legacy OPAQUE/CLEAR_TEXT values identically.
class PortNum extends $pb.ProtobufEnum {
  ///
  ///  Deprecated: do not use in new code (formerly called OPAQUE)
  ///  A message sent from a device outside of the mesh, in a form the mesh does not understand
  ///  NOTE: This must be 0, because it is documented in IMeshService.aidl to be so
  ///  ENCODING: binary undefined
  static const PortNum UNKNOWN_APP =
      PortNum._(0, _omitEnumNames ? '' : 'UNKNOWN_APP');

  ///
  ///  A simple UTF-8 text message, which even the little micros in the mesh
  ///  can understand and show on their screen eventually in some circumstances
  ///  even signal might send messages in this form (see below)
  ///  ENCODING: UTF-8 Plaintext (?)
  static const PortNum TEXT_MESSAGE_APP =
      PortNum._(1, _omitEnumNames ? '' : 'TEXT_MESSAGE_APP');

  ///
  ///  Reserved for built-in GPIO/example app.
  ///  See remote_hardware.proto/HardwareMessage for details on the message sent/received to this port number
  ///  ENCODING: Protobuf
  static const PortNum REMOTE_HARDWARE_APP =
      PortNum._(2, _omitEnumNames ? '' : 'REMOTE_HARDWARE_APP');

  ///
  ///  The built-in position messaging app.
  ///  Payload is a Position message.
  ///  ENCODING: Protobuf
  static const PortNum POSITION_APP =
      PortNum._(3, _omitEnumNames ? '' : 'POSITION_APP');

  ///
  ///  The built-in user info app.
  ///  Payload is a User message.
  ///  ENCODING: Protobuf
  static const PortNum NODEINFO_APP =
      PortNum._(4, _omitEnumNames ? '' : 'NODEINFO_APP');

  ///
  ///  Protocol control packets for mesh protocol use.
  ///  Payload is a Routing message.
  ///  ENCODING: Protobuf
  static const PortNum ROUTING_APP =
      PortNum._(5, _omitEnumNames ? '' : 'ROUTING_APP');

  ///
  ///  Admin control packets.
  ///  Payload is a AdminMessage message.
  ///  ENCODING: Protobuf
  static const PortNum ADMIN_APP =
      PortNum._(6, _omitEnumNames ? '' : 'ADMIN_APP');

  ///
  ///  Compressed TEXT_MESSAGE payloads.
  ///  ENCODING: UTF-8 Plaintext (?) with Unishox2 Compression
  ///  NOTE: The Device Firmware converts a TEXT_MESSAGE_APP to TEXT_MESSAGE_COMPRESSED_APP if the compressed
  ///  payload is shorter. There's no need for app developers to do this themselves. Also the firmware will decompress
  ///  any incoming TEXT_MESSAGE_COMPRESSED_APP payload and convert to TEXT_MESSAGE_APP.
  static const PortNum TEXT_MESSAGE_COMPRESSED_APP =
      PortNum._(7, _omitEnumNames ? '' : 'TEXT_MESSAGE_COMPRESSED_APP');

  ///
  ///  Waypoint payloads.
  ///  Payload is a Waypoint message.
  ///  ENCODING: Protobuf
  static const PortNum WAYPOINT_APP =
      PortNum._(8, _omitEnumNames ? '' : 'WAYPOINT_APP');

  ///
  ///  Audio Payloads.
  ///  Encapsulated codec2 packets. On 2.4 GHZ Bandwidths only for now
  ///  ENCODING: codec2 audio frames
  ///  NOTE: audio frames contain a 3 byte header (0xc0 0xde 0xc2) and a one byte marker for the decompressed bitrate.
  ///  This marker comes from the 'moduleConfig.audio.bitrate' enum minus one.
  static const PortNum AUDIO_APP =
      PortNum._(9, _omitEnumNames ? '' : 'AUDIO_APP');

  ///
  ///  Same as Text Message but originating from Detection Sensor Module.
  ///  NOTE: This portnum traffic is not sent to the public MQTT starting at firmware version 2.2.9
  static const PortNum DETECTION_SENSOR_APP =
      PortNum._(10, _omitEnumNames ? '' : 'DETECTION_SENSOR_APP');

  ///
  ///  Same as Text Message but used for critical alerts.
  static const PortNum ALERT_APP =
      PortNum._(11, _omitEnumNames ? '' : 'ALERT_APP');

  ///
  ///  Module/port for handling key verification requests.
  static const PortNum KEY_VERIFICATION_APP =
      PortNum._(12, _omitEnumNames ? '' : 'KEY_VERIFICATION_APP');

  ///
  ///  Provides a 'ping' service that replies to any packet it receives.
  ///  Also serves as a small example module.
  ///  ENCODING: ASCII Plaintext
  static const PortNum REPLY_APP =
      PortNum._(32, _omitEnumNames ? '' : 'REPLY_APP');

  ///
  ///  Used for the python IP tunnel feature
  ///  ENCODING: IP Packet. Handled by the python API, firmware ignores this one and pases on.
  static const PortNum IP_TUNNEL_APP =
      PortNum._(33, _omitEnumNames ? '' : 'IP_TUNNEL_APP');

  ///
  ///  Paxcounter lib included in the firmware
  ///  ENCODING: protobuf
  static const PortNum PAXCOUNTER_APP =
      PortNum._(34, _omitEnumNames ? '' : 'PAXCOUNTER_APP');

  ///
  ///  Provides a hardware serial interface to send and receive from the Meshtastic network.
  ///  Connect to the RX/TX pins of a device with 38400 8N1. Packets received from the Meshtastic
  ///  network is forwarded to the RX pin while sending a packet to TX will go out to the Mesh network.
  ///  Maximum packet size of 240 bytes.
  ///  Module is disabled by default can be turned on by setting SERIAL_MODULE_ENABLED = 1 in SerialPlugh.cpp.
  ///  ENCODING: binary undefined
  static const PortNum SERIAL_APP =
      PortNum._(64, _omitEnumNames ? '' : 'SERIAL_APP');

  ///
  ///  STORE_FORWARD_APP (Work in Progress)
  ///  Maintained by Jm Casler (MC Hamster) : jm@casler.org
  ///  ENCODING: Protobuf
  static const PortNum STORE_FORWARD_APP =
      PortNum._(65, _omitEnumNames ? '' : 'STORE_FORWARD_APP');

  ///
  ///  Optional port for messages for the range test module.
  ///  ENCODING: ASCII Plaintext
  ///  NOTE: This portnum traffic is not sent to the public MQTT starting at firmware version 2.2.9
  static const PortNum RANGE_TEST_APP =
      PortNum._(66, _omitEnumNames ? '' : 'RANGE_TEST_APP');

  ///
  ///  Provides a format to send and receive telemetry data from the Meshtastic network.
  ///  Maintained by Charles Crossan (crossan007) : crossan007@gmail.com
  ///  ENCODING: Protobuf
  static const PortNum TELEMETRY_APP =
      PortNum._(67, _omitEnumNames ? '' : 'TELEMETRY_APP');

  ///
  ///  Experimental tools for estimating node position without a GPS
  ///  Maintained by Github user a-f-G-U-C (a Meshtastic contributor)
  ///  Project files at https://github.com/a-f-G-U-C/Meshtastic-ZPS
  ///  ENCODING: arrays of int64 fields
  static const PortNum ZPS_APP = PortNum._(68, _omitEnumNames ? '' : 'ZPS_APP');

  ///
  ///  Used to let multiple instances of Linux native applications communicate
  ///  as if they did using their LoRa chip.
  ///  Maintained by GitHub user GUVWAF.
  ///  Project files at https://github.com/GUVWAF/Meshtasticator
  ///  ENCODING: Protobuf (?)
  static const PortNum SIMULATOR_APP =
      PortNum._(69, _omitEnumNames ? '' : 'SIMULATOR_APP');

  ///
  ///  Provides a traceroute functionality to show the route a packet towards
  ///  a certain destination would take on the mesh. Contains a RouteDiscovery message as payload.
  ///  ENCODING: Protobuf
  static const PortNum TRACEROUTE_APP =
      PortNum._(70, _omitEnumNames ? '' : 'TRACEROUTE_APP');

  ///
  ///  Aggregates edge info for the network by sending out a list of each node's neighbors
  ///  ENCODING: Protobuf
  static const PortNum NEIGHBORINFO_APP =
      PortNum._(71, _omitEnumNames ? '' : 'NEIGHBORINFO_APP');

  ///
  ///  ATAK Plugin
  ///  Portnum for payloads from the official Meshtastic ATAK plugin
  static const PortNum ATAK_PLUGIN =
      PortNum._(72, _omitEnumNames ? '' : 'ATAK_PLUGIN');

  ///
  ///  Provides unencrypted information about a node for consumption by a map via MQTT
  static const PortNum MAP_REPORT_APP =
      PortNum._(73, _omitEnumNames ? '' : 'MAP_REPORT_APP');

  ///
  ///  PowerStress based monitoring support (for automated power consumption testing)
  static const PortNum POWERSTRESS_APP =
      PortNum._(74, _omitEnumNames ? '' : 'POWERSTRESS_APP');

  ///
  ///  Reticulum Network Stack Tunnel App
  ///  ENCODING: Fragmented RNS Packet. Handled by Meshtastic RNS interface
  static const PortNum RETICULUM_TUNNEL_APP =
      PortNum._(76, _omitEnumNames ? '' : 'RETICULUM_TUNNEL_APP');

  ///
  ///  App for transporting Cayenne Low Power Payload, popular for LoRaWAN sensor nodes. Offers ability to send
  ///  arbitrary telemetry over meshtastic that is not covered by telemetry.proto
  ///  ENCODING: CayenneLLP
  static const PortNum CAYENNE_APP =
      PortNum._(77, _omitEnumNames ? '' : 'CAYENNE_APP');

  ///
  ///  Private applications should use portnums >= 256.
  ///  To simplify initial development and testing you can use "PRIVATE_APP"
  ///  in your code without needing to rebuild protobuf files (via [regen-protos.sh](https://github.com/meshtastic/firmware/blob/master/bin/regen-protos.sh))
  static const PortNum PRIVATE_APP =
      PortNum._(256, _omitEnumNames ? '' : 'PRIVATE_APP');

  ///
  ///  ATAK Forwarder Module https://github.com/paulmandal/atak-forwarder
  ///  ENCODING: libcotshrink
  static const PortNum ATAK_FORWARDER =
      PortNum._(257, _omitEnumNames ? '' : 'ATAK_FORWARDER');

  ///
  ///  Currently we limit port nums to no higher than this value
  static const PortNum MAX = PortNum._(511, _omitEnumNames ? '' : 'MAX');

  static const $core.List<PortNum> values = <PortNum>[
    UNKNOWN_APP,
    TEXT_MESSAGE_APP,
    REMOTE_HARDWARE_APP,
    POSITION_APP,
    NODEINFO_APP,
    ROUTING_APP,
    ADMIN_APP,
    TEXT_MESSAGE_COMPRESSED_APP,
    WAYPOINT_APP,
    AUDIO_APP,
    DETECTION_SENSOR_APP,
    ALERT_APP,
    KEY_VERIFICATION_APP,
    REPLY_APP,
    IP_TUNNEL_APP,
    PAXCOUNTER_APP,
    SERIAL_APP,
    STORE_FORWARD_APP,
    RANGE_TEST_APP,
    TELEMETRY_APP,
    ZPS_APP,
    SIMULATOR_APP,
    TRACEROUTE_APP,
    NEIGHBORINFO_APP,
    ATAK_PLUGIN,
    MAP_REPORT_APP,
    POWERSTRESS_APP,
    RETICULUM_TUNNEL_APP,
    CAYENNE_APP,
    PRIVATE_APP,
    ATAK_FORWARDER,
    MAX,
  ];

  static final $core.Map<$core.int, PortNum> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static PortNum? valueOf($core.int value) => _byValue[value];

  const PortNum._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
