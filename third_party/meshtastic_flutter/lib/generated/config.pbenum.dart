// This is a generated file - do not edit.
//
// Generated from meshtastic/config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  Defines the device's role on the Mesh network
class Config_DeviceConfig_Role extends $pb.ProtobufEnum {
  ///
  ///  Description: App connected or stand alone messaging device.
  ///  Technical Details: Default Role
  static const Config_DeviceConfig_Role CLIENT =
      Config_DeviceConfig_Role._(0, _omitEnumNames ? '' : 'CLIENT');

  ///
  ///   Description: Device that does not forward packets from other devices.
  static const Config_DeviceConfig_Role CLIENT_MUTE =
      Config_DeviceConfig_Role._(1, _omitEnumNames ? '' : 'CLIENT_MUTE');

  ///
  ///  Description: Infrastructure node for extending network coverage by relaying messages. Visible in Nodes list.
  ///  Technical Details: Mesh packets will prefer to be routed over this node. This node will not be used by client apps.
  ///    The wifi radio and the oled screen will be put to sleep.
  ///    This mode may still potentially have higher power usage due to it's preference in message rebroadcasting on the mesh.
  static const Config_DeviceConfig_Role ROUTER =
      Config_DeviceConfig_Role._(2, _omitEnumNames ? '' : 'ROUTER');
  @$core.Deprecated('This enum value is deprecated')
  static const Config_DeviceConfig_Role ROUTER_CLIENT =
      Config_DeviceConfig_Role._(3, _omitEnumNames ? '' : 'ROUTER_CLIENT');

  ///
  ///  Description: Infrastructure node for extending network coverage by relaying messages with minimal overhead. Not visible in Nodes list.
  ///  Technical Details: Mesh packets will simply be rebroadcasted over this node. Nodes configured with this role will not originate NodeInfo, Position, Telemetry
  ///    or any other packet type. They will simply rebroadcast any mesh packets on the same frequency, channel num, spread factor, and coding rate.
  static const Config_DeviceConfig_Role REPEATER =
      Config_DeviceConfig_Role._(4, _omitEnumNames ? '' : 'REPEATER');

  ///
  ///  Description: Broadcasts GPS position packets as priority.
  ///  Technical Details: Position Mesh packets will be prioritized higher and sent more frequently by default.
  ///    When used in conjunction with power.is_power_saving = true, nodes will wake up,
  ///    send position, and then sleep for position.position_broadcast_secs seconds.
  static const Config_DeviceConfig_Role TRACKER =
      Config_DeviceConfig_Role._(5, _omitEnumNames ? '' : 'TRACKER');

  ///
  ///  Description: Broadcasts telemetry packets as priority.
  ///  Technical Details: Telemetry Mesh packets will be prioritized higher and sent more frequently by default.
  ///    When used in conjunction with power.is_power_saving = true, nodes will wake up,
  ///    send environment telemetry, and then sleep for telemetry.environment_update_interval seconds.
  static const Config_DeviceConfig_Role SENSOR =
      Config_DeviceConfig_Role._(6, _omitEnumNames ? '' : 'SENSOR');

  ///
  ///  Description: Optimized for ATAK system communication and reduces routine broadcasts.
  ///  Technical Details: Used for nodes dedicated for connection to an ATAK EUD.
  ///     Turns off many of the routine broadcasts to favor CoT packet stream
  ///     from the Meshtastic ATAK plugin -> IMeshService -> Node
  static const Config_DeviceConfig_Role TAK =
      Config_DeviceConfig_Role._(7, _omitEnumNames ? '' : 'TAK');

  ///
  ///  Description: Device that only broadcasts as needed for stealth or power savings.
  ///  Technical Details: Used for nodes that "only speak when spoken to"
  ///     Turns all of the routine broadcasts but allows for ad-hoc communication
  ///     Still rebroadcasts, but with local only rebroadcast mode (known meshes only)
  ///     Can be used for clandestine operation or to dramatically reduce airtime / power consumption
  static const Config_DeviceConfig_Role CLIENT_HIDDEN =
      Config_DeviceConfig_Role._(8, _omitEnumNames ? '' : 'CLIENT_HIDDEN');

  ///
  ///  Description: Broadcasts location as message to default channel regularly for to assist with device recovery.
  ///  Technical Details: Used to automatically send a text message to the mesh
  ///     with the current position of the device on a frequent interval:
  ///     "I'm lost! Position: lat / long"
  static const Config_DeviceConfig_Role LOST_AND_FOUND =
      Config_DeviceConfig_Role._(9, _omitEnumNames ? '' : 'LOST_AND_FOUND');

  ///
  ///  Description: Enables automatic TAK PLI broadcasts and reduces routine broadcasts.
  ///  Technical Details: Turns off many of the routine broadcasts to favor ATAK CoT packet stream
  ///     and automatic TAK PLI (position location information) broadcasts.
  ///     Uses position module configuration to determine TAK PLI broadcast interval.
  static const Config_DeviceConfig_Role TAK_TRACKER =
      Config_DeviceConfig_Role._(10, _omitEnumNames ? '' : 'TAK_TRACKER');

  ///
  ///  Description: Will always rebroadcast packets, but will do so after all other modes.
  ///  Technical Details: Used for router nodes that are intended to provide additional coverage
  ///     in areas not already covered by other routers, or to bridge around problematic terrain,
  ///     but should not be given priority over other routers in order to avoid unnecessaraily
  ///     consuming hops.
  static const Config_DeviceConfig_Role ROUTER_LATE =
      Config_DeviceConfig_Role._(11, _omitEnumNames ? '' : 'ROUTER_LATE');

  static const $core.List<Config_DeviceConfig_Role> values =
      <Config_DeviceConfig_Role>[
    CLIENT,
    CLIENT_MUTE,
    ROUTER,
    ROUTER_CLIENT,
    REPEATER,
    TRACKER,
    SENSOR,
    TAK,
    CLIENT_HIDDEN,
    LOST_AND_FOUND,
    TAK_TRACKER,
    ROUTER_LATE,
  ];

  static final $core.List<Config_DeviceConfig_Role?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static Config_DeviceConfig_Role? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DeviceConfig_Role._(super.value, super.name);
}

///
///  Defines the device's behavior for how messages are rebroadcast
class Config_DeviceConfig_RebroadcastMode extends $pb.ProtobufEnum {
  ///
  ///  Default behavior.
  ///  Rebroadcast any observed message, if it was on our private channel or from another mesh with the same lora params.
  static const Config_DeviceConfig_RebroadcastMode ALL =
      Config_DeviceConfig_RebroadcastMode._(0, _omitEnumNames ? '' : 'ALL');

  ///
  ///  Same as behavior as ALL but skips packet decoding and simply rebroadcasts them.
  ///  Only available in Repeater role. Setting this on any other roles will result in ALL behavior.
  static const Config_DeviceConfig_RebroadcastMode ALL_SKIP_DECODING =
      Config_DeviceConfig_RebroadcastMode._(
          1, _omitEnumNames ? '' : 'ALL_SKIP_DECODING');

  ///
  ///  Ignores observed messages from foreign meshes that are open or those which it cannot decrypt.
  ///  Only rebroadcasts message on the nodes local primary / secondary channels.
  static const Config_DeviceConfig_RebroadcastMode LOCAL_ONLY =
      Config_DeviceConfig_RebroadcastMode._(
          2, _omitEnumNames ? '' : 'LOCAL_ONLY');

  ///
  ///  Ignores observed messages from foreign meshes like LOCAL_ONLY,
  ///  but takes it step further by also ignoring messages from nodenums not in the node's known list (NodeDB)
  static const Config_DeviceConfig_RebroadcastMode KNOWN_ONLY =
      Config_DeviceConfig_RebroadcastMode._(
          3, _omitEnumNames ? '' : 'KNOWN_ONLY');

  ///
  ///  Only permitted for SENSOR, TRACKER and TAK_TRACKER roles, this will inhibit all rebroadcasts, not unlike CLIENT_MUTE role.
  static const Config_DeviceConfig_RebroadcastMode NONE =
      Config_DeviceConfig_RebroadcastMode._(4, _omitEnumNames ? '' : 'NONE');

  ///
  ///  Ignores packets from non-standard portnums such as: TAK, RangeTest, PaxCounter, etc.
  ///  Only rebroadcasts packets with standard portnums: NodeInfo, Text, Position, Telemetry, and Routing.
  static const Config_DeviceConfig_RebroadcastMode CORE_PORTNUMS_ONLY =
      Config_DeviceConfig_RebroadcastMode._(
          5, _omitEnumNames ? '' : 'CORE_PORTNUMS_ONLY');

  static const $core.List<Config_DeviceConfig_RebroadcastMode> values =
      <Config_DeviceConfig_RebroadcastMode>[
    ALL,
    ALL_SKIP_DECODING,
    LOCAL_ONLY,
    KNOWN_ONLY,
    NONE,
    CORE_PORTNUMS_ONLY,
  ];

  static final $core.List<Config_DeviceConfig_RebroadcastMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Config_DeviceConfig_RebroadcastMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DeviceConfig_RebroadcastMode._(super.value, super.name);
}

///
///  Defines buzzer behavior for audio feedback
class Config_DeviceConfig_BuzzerMode extends $pb.ProtobufEnum {
  ///
  ///  Default behavior.
  ///  Buzzer is enabled for all audio feedback including button presses and alerts.
  static const Config_DeviceConfig_BuzzerMode ALL_ENABLED =
      Config_DeviceConfig_BuzzerMode._(0, _omitEnumNames ? '' : 'ALL_ENABLED');

  ///
  ///  Disabled.
  ///  All buzzer audio feedback is disabled.
  static const Config_DeviceConfig_BuzzerMode DISABLED =
      Config_DeviceConfig_BuzzerMode._(1, _omitEnumNames ? '' : 'DISABLED');

  ///
  ///  Notifications Only.
  ///  Buzzer is enabled only for notifications and alerts, but not for button presses.
  ///  External notification config determines the specifics of the notification behavior.
  static const Config_DeviceConfig_BuzzerMode NOTIFICATIONS_ONLY =
      Config_DeviceConfig_BuzzerMode._(
          2, _omitEnumNames ? '' : 'NOTIFICATIONS_ONLY');

  ///
  ///  Non-notification system buzzer tones only.
  ///  Buzzer is enabled only for non-notification tones such as button presses, startup, shutdown, but not for alerts.
  static const Config_DeviceConfig_BuzzerMode SYSTEM_ONLY =
      Config_DeviceConfig_BuzzerMode._(3, _omitEnumNames ? '' : 'SYSTEM_ONLY');

  ///
  ///  Direct Message notifications only.
  ///  Buzzer is enabled only for direct messages and alerts, but not for button presses.
  ///  External notification config determines the specifics of the notification behavior.
  static const Config_DeviceConfig_BuzzerMode DIRECT_MSG_ONLY =
      Config_DeviceConfig_BuzzerMode._(
          4, _omitEnumNames ? '' : 'DIRECT_MSG_ONLY');

  static const $core.List<Config_DeviceConfig_BuzzerMode> values =
      <Config_DeviceConfig_BuzzerMode>[
    ALL_ENABLED,
    DISABLED,
    NOTIFICATIONS_ONLY,
    SYSTEM_ONLY,
    DIRECT_MSG_ONLY,
  ];

  static final $core.List<Config_DeviceConfig_BuzzerMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Config_DeviceConfig_BuzzerMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DeviceConfig_BuzzerMode._(super.value, super.name);
}

///
///  Bit field of boolean configuration options, indicating which optional
///  fields to include when assembling POSITION messages.
///  Longitude, latitude, altitude, speed, heading, and DOP
///  are always included (also time if GPS-synced)
///  NOTE: the more fields are included, the larger the message will be -
///    leading to longer airtime and a higher risk of packet loss
class Config_PositionConfig_PositionFlags extends $pb.ProtobufEnum {
  ///
  ///  Required for compilation
  static const Config_PositionConfig_PositionFlags UNSET =
      Config_PositionConfig_PositionFlags._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  Include an altitude value (if available)
  static const Config_PositionConfig_PositionFlags ALTITUDE =
      Config_PositionConfig_PositionFlags._(
          1, _omitEnumNames ? '' : 'ALTITUDE');

  ///
  ///  Altitude value is MSL
  static const Config_PositionConfig_PositionFlags ALTITUDE_MSL =
      Config_PositionConfig_PositionFlags._(
          2, _omitEnumNames ? '' : 'ALTITUDE_MSL');

  ///
  ///  Include geoidal separation
  static const Config_PositionConfig_PositionFlags GEOIDAL_SEPARATION =
      Config_PositionConfig_PositionFlags._(
          4, _omitEnumNames ? '' : 'GEOIDAL_SEPARATION');

  ///
  ///  Include the DOP value ; PDOP used by default, see below
  static const Config_PositionConfig_PositionFlags DOP =
      Config_PositionConfig_PositionFlags._(8, _omitEnumNames ? '' : 'DOP');

  ///
  ///  If POS_DOP set, send separate HDOP / VDOP values instead of PDOP
  static const Config_PositionConfig_PositionFlags HVDOP =
      Config_PositionConfig_PositionFlags._(16, _omitEnumNames ? '' : 'HVDOP');

  ///
  ///  Include number of "satellites in view"
  static const Config_PositionConfig_PositionFlags SATINVIEW =
      Config_PositionConfig_PositionFlags._(
          32, _omitEnumNames ? '' : 'SATINVIEW');

  ///
  ///  Include a sequence number incremented per packet
  static const Config_PositionConfig_PositionFlags SEQ_NO =
      Config_PositionConfig_PositionFlags._(64, _omitEnumNames ? '' : 'SEQ_NO');

  ///
  ///  Include positional timestamp (from GPS solution)
  static const Config_PositionConfig_PositionFlags TIMESTAMP =
      Config_PositionConfig_PositionFlags._(
          128, _omitEnumNames ? '' : 'TIMESTAMP');

  ///
  ///  Include positional heading
  ///  Intended for use with vehicle not walking speeds
  ///  walking speeds are likely to be error prone like the compass
  static const Config_PositionConfig_PositionFlags HEADING =
      Config_PositionConfig_PositionFlags._(
          256, _omitEnumNames ? '' : 'HEADING');

  ///
  ///  Include positional speed
  ///  Intended for use with vehicle not walking speeds
  ///  walking speeds are likely to be error prone like the compass
  static const Config_PositionConfig_PositionFlags SPEED =
      Config_PositionConfig_PositionFlags._(512, _omitEnumNames ? '' : 'SPEED');

  static const $core.List<Config_PositionConfig_PositionFlags> values =
      <Config_PositionConfig_PositionFlags>[
    UNSET,
    ALTITUDE,
    ALTITUDE_MSL,
    GEOIDAL_SEPARATION,
    DOP,
    HVDOP,
    SATINVIEW,
    SEQ_NO,
    TIMESTAMP,
    HEADING,
    SPEED,
  ];

  static final $core.Map<$core.int, Config_PositionConfig_PositionFlags>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static Config_PositionConfig_PositionFlags? valueOf($core.int value) =>
      _byValue[value];

  const Config_PositionConfig_PositionFlags._(super.value, super.name);
}

class Config_PositionConfig_GpsMode extends $pb.ProtobufEnum {
  ///
  ///  GPS is present but disabled
  static const Config_PositionConfig_GpsMode DISABLED =
      Config_PositionConfig_GpsMode._(0, _omitEnumNames ? '' : 'DISABLED');

  ///
  ///  GPS is present and enabled
  static const Config_PositionConfig_GpsMode ENABLED =
      Config_PositionConfig_GpsMode._(1, _omitEnumNames ? '' : 'ENABLED');

  ///
  ///  GPS is not present on the device
  static const Config_PositionConfig_GpsMode NOT_PRESENT =
      Config_PositionConfig_GpsMode._(2, _omitEnumNames ? '' : 'NOT_PRESENT');

  static const $core.List<Config_PositionConfig_GpsMode> values =
      <Config_PositionConfig_GpsMode>[
    DISABLED,
    ENABLED,
    NOT_PRESENT,
  ];

  static final $core.List<Config_PositionConfig_GpsMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Config_PositionConfig_GpsMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_PositionConfig_GpsMode._(super.value, super.name);
}

class Config_NetworkConfig_AddressMode extends $pb.ProtobufEnum {
  ///
  ///  obtain ip address via DHCP
  static const Config_NetworkConfig_AddressMode DHCP =
      Config_NetworkConfig_AddressMode._(0, _omitEnumNames ? '' : 'DHCP');

  ///
  ///  use static ip address
  static const Config_NetworkConfig_AddressMode STATIC =
      Config_NetworkConfig_AddressMode._(1, _omitEnumNames ? '' : 'STATIC');

  static const $core.List<Config_NetworkConfig_AddressMode> values =
      <Config_NetworkConfig_AddressMode>[
    DHCP,
    STATIC,
  ];

  static final $core.List<Config_NetworkConfig_AddressMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Config_NetworkConfig_AddressMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_NetworkConfig_AddressMode._(super.value, super.name);
}

///
///  Available flags auxiliary network protocols
class Config_NetworkConfig_ProtocolFlags extends $pb.ProtobufEnum {
  ///
  ///  Do not broadcast packets over any network protocol
  static const Config_NetworkConfig_ProtocolFlags NO_BROADCAST =
      Config_NetworkConfig_ProtocolFlags._(
          0, _omitEnumNames ? '' : 'NO_BROADCAST');

  ///
  ///  Enable broadcasting packets via UDP over the local network
  static const Config_NetworkConfig_ProtocolFlags UDP_BROADCAST =
      Config_NetworkConfig_ProtocolFlags._(
          1, _omitEnumNames ? '' : 'UDP_BROADCAST');

  static const $core.List<Config_NetworkConfig_ProtocolFlags> values =
      <Config_NetworkConfig_ProtocolFlags>[
    NO_BROADCAST,
    UDP_BROADCAST,
  ];

  static final $core.List<Config_NetworkConfig_ProtocolFlags?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Config_NetworkConfig_ProtocolFlags? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_NetworkConfig_ProtocolFlags._(super.value, super.name);
}

///
///  How the GPS coordinates are displayed on the OLED screen.
class Config_DisplayConfig_GpsCoordinateFormat extends $pb.ProtobufEnum {
  ///
  ///  GPS coordinates are displayed in the normal decimal degrees format:
  ///  DD.DDDDDD DDD.DDDDDD
  static const Config_DisplayConfig_GpsCoordinateFormat DEC =
      Config_DisplayConfig_GpsCoordinateFormat._(
          0, _omitEnumNames ? '' : 'DEC');

  ///
  ///  GPS coordinates are displayed in the degrees minutes seconds format:
  ///  DD°MM'SS"C DDD°MM'SS"C, where C is the compass point representing the locations quadrant
  static const Config_DisplayConfig_GpsCoordinateFormat DMS =
      Config_DisplayConfig_GpsCoordinateFormat._(
          1, _omitEnumNames ? '' : 'DMS');

  ///
  ///  Universal Transverse Mercator format:
  ///  ZZB EEEEEE NNNNNNN, where Z is zone, B is band, E is easting, N is northing
  static const Config_DisplayConfig_GpsCoordinateFormat UTM =
      Config_DisplayConfig_GpsCoordinateFormat._(
          2, _omitEnumNames ? '' : 'UTM');

  ///
  ///  Military Grid Reference System format:
  ///  ZZB CD EEEEE NNNNN, where Z is zone, B is band, C is the east 100k square, D is the north 100k square,
  ///  E is easting, N is northing
  static const Config_DisplayConfig_GpsCoordinateFormat MGRS =
      Config_DisplayConfig_GpsCoordinateFormat._(
          3, _omitEnumNames ? '' : 'MGRS');

  ///
  ///  Open Location Code (aka Plus Codes).
  static const Config_DisplayConfig_GpsCoordinateFormat OLC =
      Config_DisplayConfig_GpsCoordinateFormat._(
          4, _omitEnumNames ? '' : 'OLC');

  ///
  ///  Ordnance Survey Grid Reference (the National Grid System of the UK).
  ///  Format: AB EEEEE NNNNN, where A is the east 100k square, B is the north 100k square,
  ///  E is the easting, N is the northing
  static const Config_DisplayConfig_GpsCoordinateFormat OSGR =
      Config_DisplayConfig_GpsCoordinateFormat._(
          5, _omitEnumNames ? '' : 'OSGR');

  static const $core.List<Config_DisplayConfig_GpsCoordinateFormat> values =
      <Config_DisplayConfig_GpsCoordinateFormat>[
    DEC,
    DMS,
    UTM,
    MGRS,
    OLC,
    OSGR,
  ];

  static final $core.List<Config_DisplayConfig_GpsCoordinateFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Config_DisplayConfig_GpsCoordinateFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DisplayConfig_GpsCoordinateFormat._(super.value, super.name);
}

///
///  Unit display preference
class Config_DisplayConfig_DisplayUnits extends $pb.ProtobufEnum {
  ///
  ///  Metric (Default)
  static const Config_DisplayConfig_DisplayUnits METRIC =
      Config_DisplayConfig_DisplayUnits._(0, _omitEnumNames ? '' : 'METRIC');

  ///
  ///  Imperial
  static const Config_DisplayConfig_DisplayUnits IMPERIAL =
      Config_DisplayConfig_DisplayUnits._(1, _omitEnumNames ? '' : 'IMPERIAL');

  static const $core.List<Config_DisplayConfig_DisplayUnits> values =
      <Config_DisplayConfig_DisplayUnits>[
    METRIC,
    IMPERIAL,
  ];

  static final $core.List<Config_DisplayConfig_DisplayUnits?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Config_DisplayConfig_DisplayUnits? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DisplayConfig_DisplayUnits._(super.value, super.name);
}

///
///  Override OLED outo detect with this if it fails.
class Config_DisplayConfig_OledType extends $pb.ProtobufEnum {
  ///
  ///  Default / Autodetect
  static const Config_DisplayConfig_OledType OLED_AUTO =
      Config_DisplayConfig_OledType._(0, _omitEnumNames ? '' : 'OLED_AUTO');

  ///
  ///  Default / Autodetect
  static const Config_DisplayConfig_OledType OLED_SSD1306 =
      Config_DisplayConfig_OledType._(1, _omitEnumNames ? '' : 'OLED_SSD1306');

  ///
  ///  Default / Autodetect
  static const Config_DisplayConfig_OledType OLED_SH1106 =
      Config_DisplayConfig_OledType._(2, _omitEnumNames ? '' : 'OLED_SH1106');

  ///
  ///  Can not be auto detected but set by proto. Used for 128x128 screens
  static const Config_DisplayConfig_OledType OLED_SH1107 =
      Config_DisplayConfig_OledType._(3, _omitEnumNames ? '' : 'OLED_SH1107');

  ///
  ///  Can not be auto detected but set by proto. Used for 128x64 screens
  static const Config_DisplayConfig_OledType OLED_SH1107_128_64 =
      Config_DisplayConfig_OledType._(
          4, _omitEnumNames ? '' : 'OLED_SH1107_128_64');

  static const $core.List<Config_DisplayConfig_OledType> values =
      <Config_DisplayConfig_OledType>[
    OLED_AUTO,
    OLED_SSD1306,
    OLED_SH1106,
    OLED_SH1107,
    OLED_SH1107_128_64,
  ];

  static final $core.List<Config_DisplayConfig_OledType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Config_DisplayConfig_OledType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DisplayConfig_OledType._(super.value, super.name);
}

class Config_DisplayConfig_DisplayMode extends $pb.ProtobufEnum {
  ///
  ///  Default. The old style for the 128x64 OLED screen
  static const Config_DisplayConfig_DisplayMode DEFAULT =
      Config_DisplayConfig_DisplayMode._(0, _omitEnumNames ? '' : 'DEFAULT');

  ///
  ///  Rearrange display elements to cater for bicolor OLED displays
  static const Config_DisplayConfig_DisplayMode TWOCOLOR =
      Config_DisplayConfig_DisplayMode._(1, _omitEnumNames ? '' : 'TWOCOLOR');

  ///
  ///  Same as TwoColor, but with inverted top bar. Not so good for Epaper displays
  static const Config_DisplayConfig_DisplayMode INVERTED =
      Config_DisplayConfig_DisplayMode._(2, _omitEnumNames ? '' : 'INVERTED');

  ///
  ///  TFT Full Color Displays (not implemented yet)
  static const Config_DisplayConfig_DisplayMode COLOR =
      Config_DisplayConfig_DisplayMode._(3, _omitEnumNames ? '' : 'COLOR');

  static const $core.List<Config_DisplayConfig_DisplayMode> values =
      <Config_DisplayConfig_DisplayMode>[
    DEFAULT,
    TWOCOLOR,
    INVERTED,
    COLOR,
  ];

  static final $core.List<Config_DisplayConfig_DisplayMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Config_DisplayConfig_DisplayMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DisplayConfig_DisplayMode._(super.value, super.name);
}

class Config_DisplayConfig_CompassOrientation extends $pb.ProtobufEnum {
  ///
  ///  The compass and the display are in the same orientation.
  static const Config_DisplayConfig_CompassOrientation DEGREES_0 =
      Config_DisplayConfig_CompassOrientation._(
          0, _omitEnumNames ? '' : 'DEGREES_0');

  ///
  ///  Rotate the compass by 90 degrees.
  static const Config_DisplayConfig_CompassOrientation DEGREES_90 =
      Config_DisplayConfig_CompassOrientation._(
          1, _omitEnumNames ? '' : 'DEGREES_90');

  ///
  ///  Rotate the compass by 180 degrees.
  static const Config_DisplayConfig_CompassOrientation DEGREES_180 =
      Config_DisplayConfig_CompassOrientation._(
          2, _omitEnumNames ? '' : 'DEGREES_180');

  ///
  ///  Rotate the compass by 270 degrees.
  static const Config_DisplayConfig_CompassOrientation DEGREES_270 =
      Config_DisplayConfig_CompassOrientation._(
          3, _omitEnumNames ? '' : 'DEGREES_270');

  ///
  ///  Don't rotate the compass, but invert the result.
  static const Config_DisplayConfig_CompassOrientation DEGREES_0_INVERTED =
      Config_DisplayConfig_CompassOrientation._(
          4, _omitEnumNames ? '' : 'DEGREES_0_INVERTED');

  ///
  ///  Rotate the compass by 90 degrees and invert.
  static const Config_DisplayConfig_CompassOrientation DEGREES_90_INVERTED =
      Config_DisplayConfig_CompassOrientation._(
          5, _omitEnumNames ? '' : 'DEGREES_90_INVERTED');

  ///
  ///  Rotate the compass by 180 degrees and invert.
  static const Config_DisplayConfig_CompassOrientation DEGREES_180_INVERTED =
      Config_DisplayConfig_CompassOrientation._(
          6, _omitEnumNames ? '' : 'DEGREES_180_INVERTED');

  ///
  ///  Rotate the compass by 270 degrees and invert.
  static const Config_DisplayConfig_CompassOrientation DEGREES_270_INVERTED =
      Config_DisplayConfig_CompassOrientation._(
          7, _omitEnumNames ? '' : 'DEGREES_270_INVERTED');

  static const $core.List<Config_DisplayConfig_CompassOrientation> values =
      <Config_DisplayConfig_CompassOrientation>[
    DEGREES_0,
    DEGREES_90,
    DEGREES_180,
    DEGREES_270,
    DEGREES_0_INVERTED,
    DEGREES_90_INVERTED,
    DEGREES_180_INVERTED,
    DEGREES_270_INVERTED,
  ];

  static final $core.List<Config_DisplayConfig_CompassOrientation?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static Config_DisplayConfig_CompassOrientation? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_DisplayConfig_CompassOrientation._(super.value, super.name);
}

class Config_LoRaConfig_RegionCode extends $pb.ProtobufEnum {
  ///
  ///  Region is not set
  static const Config_LoRaConfig_RegionCode UNSET =
      Config_LoRaConfig_RegionCode._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  United States
  static const Config_LoRaConfig_RegionCode US =
      Config_LoRaConfig_RegionCode._(1, _omitEnumNames ? '' : 'US');

  ///
  ///  European Union 433mhz
  static const Config_LoRaConfig_RegionCode EU_433 =
      Config_LoRaConfig_RegionCode._(2, _omitEnumNames ? '' : 'EU_433');

  ///
  ///  European Union 868mhz
  static const Config_LoRaConfig_RegionCode EU_868 =
      Config_LoRaConfig_RegionCode._(3, _omitEnumNames ? '' : 'EU_868');

  ///
  ///  China
  static const Config_LoRaConfig_RegionCode CN =
      Config_LoRaConfig_RegionCode._(4, _omitEnumNames ? '' : 'CN');

  ///
  ///  Japan
  static const Config_LoRaConfig_RegionCode JP =
      Config_LoRaConfig_RegionCode._(5, _omitEnumNames ? '' : 'JP');

  ///
  ///  Australia / New Zealand
  static const Config_LoRaConfig_RegionCode ANZ =
      Config_LoRaConfig_RegionCode._(6, _omitEnumNames ? '' : 'ANZ');

  ///
  ///  Korea
  static const Config_LoRaConfig_RegionCode KR =
      Config_LoRaConfig_RegionCode._(7, _omitEnumNames ? '' : 'KR');

  ///
  ///  Taiwan
  static const Config_LoRaConfig_RegionCode TW =
      Config_LoRaConfig_RegionCode._(8, _omitEnumNames ? '' : 'TW');

  ///
  ///  Russia
  static const Config_LoRaConfig_RegionCode RU =
      Config_LoRaConfig_RegionCode._(9, _omitEnumNames ? '' : 'RU');

  ///
  ///  India
  static const Config_LoRaConfig_RegionCode IN =
      Config_LoRaConfig_RegionCode._(10, _omitEnumNames ? '' : 'IN');

  ///
  ///  New Zealand 865mhz
  static const Config_LoRaConfig_RegionCode NZ_865 =
      Config_LoRaConfig_RegionCode._(11, _omitEnumNames ? '' : 'NZ_865');

  ///
  ///  Thailand
  static const Config_LoRaConfig_RegionCode TH =
      Config_LoRaConfig_RegionCode._(12, _omitEnumNames ? '' : 'TH');

  ///
  ///  WLAN Band
  static const Config_LoRaConfig_RegionCode LORA_24 =
      Config_LoRaConfig_RegionCode._(13, _omitEnumNames ? '' : 'LORA_24');

  ///
  ///  Ukraine 433mhz
  static const Config_LoRaConfig_RegionCode UA_433 =
      Config_LoRaConfig_RegionCode._(14, _omitEnumNames ? '' : 'UA_433');

  ///
  ///  Ukraine 868mhz
  static const Config_LoRaConfig_RegionCode UA_868 =
      Config_LoRaConfig_RegionCode._(15, _omitEnumNames ? '' : 'UA_868');

  ///
  ///  Malaysia 433mhz
  static const Config_LoRaConfig_RegionCode MY_433 =
      Config_LoRaConfig_RegionCode._(16, _omitEnumNames ? '' : 'MY_433');

  ///
  ///  Malaysia 919mhz
  static const Config_LoRaConfig_RegionCode MY_919 =
      Config_LoRaConfig_RegionCode._(17, _omitEnumNames ? '' : 'MY_919');

  ///
  ///  Singapore 923mhz
  static const Config_LoRaConfig_RegionCode SG_923 =
      Config_LoRaConfig_RegionCode._(18, _omitEnumNames ? '' : 'SG_923');

  ///
  ///  Philippines 433mhz
  static const Config_LoRaConfig_RegionCode PH_433 =
      Config_LoRaConfig_RegionCode._(19, _omitEnumNames ? '' : 'PH_433');

  ///
  ///  Philippines 868mhz
  static const Config_LoRaConfig_RegionCode PH_868 =
      Config_LoRaConfig_RegionCode._(20, _omitEnumNames ? '' : 'PH_868');

  ///
  ///  Philippines 915mhz
  static const Config_LoRaConfig_RegionCode PH_915 =
      Config_LoRaConfig_RegionCode._(21, _omitEnumNames ? '' : 'PH_915');

  ///
  ///  Australia / New Zealand 433MHz
  static const Config_LoRaConfig_RegionCode ANZ_433 =
      Config_LoRaConfig_RegionCode._(22, _omitEnumNames ? '' : 'ANZ_433');

  ///
  ///  Kazakhstan 433MHz
  static const Config_LoRaConfig_RegionCode KZ_433 =
      Config_LoRaConfig_RegionCode._(23, _omitEnumNames ? '' : 'KZ_433');

  ///
  ///  Kazakhstan 863MHz
  static const Config_LoRaConfig_RegionCode KZ_863 =
      Config_LoRaConfig_RegionCode._(24, _omitEnumNames ? '' : 'KZ_863');

  ///
  ///  Nepal 865MHz
  static const Config_LoRaConfig_RegionCode NP_865 =
      Config_LoRaConfig_RegionCode._(25, _omitEnumNames ? '' : 'NP_865');

  ///
  ///  Brazil 902MHz
  static const Config_LoRaConfig_RegionCode BR_902 =
      Config_LoRaConfig_RegionCode._(26, _omitEnumNames ? '' : 'BR_902');

  static const $core.List<Config_LoRaConfig_RegionCode> values =
      <Config_LoRaConfig_RegionCode>[
    UNSET,
    US,
    EU_433,
    EU_868,
    CN,
    JP,
    ANZ,
    KR,
    TW,
    RU,
    IN,
    NZ_865,
    TH,
    LORA_24,
    UA_433,
    UA_868,
    MY_433,
    MY_919,
    SG_923,
    PH_433,
    PH_868,
    PH_915,
    ANZ_433,
    KZ_433,
    KZ_863,
    NP_865,
    BR_902,
  ];

  static final $core.List<Config_LoRaConfig_RegionCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 26);
  static Config_LoRaConfig_RegionCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_LoRaConfig_RegionCode._(super.value, super.name);
}

///
///  Standard predefined channel settings
///  Note: these mappings must match ModemPreset Choice in the device code.
class Config_LoRaConfig_ModemPreset extends $pb.ProtobufEnum {
  ///
  ///  Long Range - Fast
  static const Config_LoRaConfig_ModemPreset LONG_FAST =
      Config_LoRaConfig_ModemPreset._(0, _omitEnumNames ? '' : 'LONG_FAST');

  ///
  ///  Long Range - Slow
  static const Config_LoRaConfig_ModemPreset LONG_SLOW =
      Config_LoRaConfig_ModemPreset._(1, _omitEnumNames ? '' : 'LONG_SLOW');

  ///
  ///  Very Long Range - Slow
  ///  Deprecated in 2.5: Works only with txco and is unusably slow
  @$core.Deprecated('This enum value is deprecated')
  static const Config_LoRaConfig_ModemPreset VERY_LONG_SLOW =
      Config_LoRaConfig_ModemPreset._(
          2, _omitEnumNames ? '' : 'VERY_LONG_SLOW');

  ///
  ///  Medium Range - Slow
  static const Config_LoRaConfig_ModemPreset MEDIUM_SLOW =
      Config_LoRaConfig_ModemPreset._(3, _omitEnumNames ? '' : 'MEDIUM_SLOW');

  ///
  ///  Medium Range - Fast
  static const Config_LoRaConfig_ModemPreset MEDIUM_FAST =
      Config_LoRaConfig_ModemPreset._(4, _omitEnumNames ? '' : 'MEDIUM_FAST');

  ///
  ///  Short Range - Slow
  static const Config_LoRaConfig_ModemPreset SHORT_SLOW =
      Config_LoRaConfig_ModemPreset._(5, _omitEnumNames ? '' : 'SHORT_SLOW');

  ///
  ///  Short Range - Fast
  static const Config_LoRaConfig_ModemPreset SHORT_FAST =
      Config_LoRaConfig_ModemPreset._(6, _omitEnumNames ? '' : 'SHORT_FAST');

  ///
  ///  Long Range - Moderately Fast
  static const Config_LoRaConfig_ModemPreset LONG_MODERATE =
      Config_LoRaConfig_ModemPreset._(7, _omitEnumNames ? '' : 'LONG_MODERATE');

  ///
  ///  Short Range - Turbo
  ///  This is the fastest preset and the only one with 500kHz bandwidth.
  ///  It is not legal to use in all regions due to this wider bandwidth.
  static const Config_LoRaConfig_ModemPreset SHORT_TURBO =
      Config_LoRaConfig_ModemPreset._(8, _omitEnumNames ? '' : 'SHORT_TURBO');

  static const $core.List<Config_LoRaConfig_ModemPreset> values =
      <Config_LoRaConfig_ModemPreset>[
    LONG_FAST,
    LONG_SLOW,
    VERY_LONG_SLOW,
    MEDIUM_SLOW,
    MEDIUM_FAST,
    SHORT_SLOW,
    SHORT_FAST,
    LONG_MODERATE,
    SHORT_TURBO,
  ];

  static final $core.List<Config_LoRaConfig_ModemPreset?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static Config_LoRaConfig_ModemPreset? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_LoRaConfig_ModemPreset._(super.value, super.name);
}

class Config_BluetoothConfig_PairingMode extends $pb.ProtobufEnum {
  ///
  ///  Device generates a random PIN that will be shown on the screen of the device for pairing
  static const Config_BluetoothConfig_PairingMode RANDOM_PIN =
      Config_BluetoothConfig_PairingMode._(
          0, _omitEnumNames ? '' : 'RANDOM_PIN');

  ///
  ///  Device requires a specified fixed PIN for pairing
  static const Config_BluetoothConfig_PairingMode FIXED_PIN =
      Config_BluetoothConfig_PairingMode._(
          1, _omitEnumNames ? '' : 'FIXED_PIN');

  ///
  ///  Device requires no PIN for pairing
  static const Config_BluetoothConfig_PairingMode NO_PIN =
      Config_BluetoothConfig_PairingMode._(2, _omitEnumNames ? '' : 'NO_PIN');

  static const $core.List<Config_BluetoothConfig_PairingMode> values =
      <Config_BluetoothConfig_PairingMode>[
    RANDOM_PIN,
    FIXED_PIN,
    NO_PIN,
  ];

  static final $core.List<Config_BluetoothConfig_PairingMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Config_BluetoothConfig_PairingMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Config_BluetoothConfig_PairingMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
