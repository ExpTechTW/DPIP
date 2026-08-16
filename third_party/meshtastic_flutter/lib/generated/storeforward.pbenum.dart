// This is a generated file - do not edit.
//
// Generated from meshtastic/storeforward.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  001 - 063 = From Router
///  064 - 127 = From Client
class StoreAndForward_RequestResponse extends $pb.ProtobufEnum {
  ///
  ///  Unset/unused
  static const StoreAndForward_RequestResponse UNSET =
      StoreAndForward_RequestResponse._(0, _omitEnumNames ? '' : 'UNSET');

  ///
  ///  Router is an in error state.
  static const StoreAndForward_RequestResponse ROUTER_ERROR =
      StoreAndForward_RequestResponse._(
          1, _omitEnumNames ? '' : 'ROUTER_ERROR');

  ///
  ///  Router heartbeat
  static const StoreAndForward_RequestResponse ROUTER_HEARTBEAT =
      StoreAndForward_RequestResponse._(
          2, _omitEnumNames ? '' : 'ROUTER_HEARTBEAT');

  ///
  ///  Router has requested the client respond. This can work as a
  ///  "are you there" message.
  static const StoreAndForward_RequestResponse ROUTER_PING =
      StoreAndForward_RequestResponse._(3, _omitEnumNames ? '' : 'ROUTER_PING');

  ///
  ///  The response to a "Ping"
  static const StoreAndForward_RequestResponse ROUTER_PONG =
      StoreAndForward_RequestResponse._(4, _omitEnumNames ? '' : 'ROUTER_PONG');

  ///
  ///  Router is currently busy. Please try again later.
  static const StoreAndForward_RequestResponse ROUTER_BUSY =
      StoreAndForward_RequestResponse._(5, _omitEnumNames ? '' : 'ROUTER_BUSY');

  ///
  ///  Router is responding to a request for history.
  static const StoreAndForward_RequestResponse ROUTER_HISTORY =
      StoreAndForward_RequestResponse._(
          6, _omitEnumNames ? '' : 'ROUTER_HISTORY');

  ///
  ///  Router is responding to a request for stats.
  static const StoreAndForward_RequestResponse ROUTER_STATS =
      StoreAndForward_RequestResponse._(
          7, _omitEnumNames ? '' : 'ROUTER_STATS');

  ///
  ///  Router sends a text message from its history that was a direct message.
  static const StoreAndForward_RequestResponse ROUTER_TEXT_DIRECT =
      StoreAndForward_RequestResponse._(
          8, _omitEnumNames ? '' : 'ROUTER_TEXT_DIRECT');

  ///
  ///  Router sends a text message from its history that was a broadcast.
  static const StoreAndForward_RequestResponse ROUTER_TEXT_BROADCAST =
      StoreAndForward_RequestResponse._(
          9, _omitEnumNames ? '' : 'ROUTER_TEXT_BROADCAST');

  ///
  ///  Client is an in error state.
  static const StoreAndForward_RequestResponse CLIENT_ERROR =
      StoreAndForward_RequestResponse._(
          64, _omitEnumNames ? '' : 'CLIENT_ERROR');

  ///
  ///  Client has requested a replay from the router.
  static const StoreAndForward_RequestResponse CLIENT_HISTORY =
      StoreAndForward_RequestResponse._(
          65, _omitEnumNames ? '' : 'CLIENT_HISTORY');

  ///
  ///  Client has requested stats from the router.
  static const StoreAndForward_RequestResponse CLIENT_STATS =
      StoreAndForward_RequestResponse._(
          66, _omitEnumNames ? '' : 'CLIENT_STATS');

  ///
  ///  Client has requested the router respond. This can work as a
  ///  "are you there" message.
  static const StoreAndForward_RequestResponse CLIENT_PING =
      StoreAndForward_RequestResponse._(
          67, _omitEnumNames ? '' : 'CLIENT_PING');

  ///
  ///  The response to a "Ping"
  static const StoreAndForward_RequestResponse CLIENT_PONG =
      StoreAndForward_RequestResponse._(
          68, _omitEnumNames ? '' : 'CLIENT_PONG');

  ///
  ///  Client has requested that the router abort processing the client's request
  static const StoreAndForward_RequestResponse CLIENT_ABORT =
      StoreAndForward_RequestResponse._(
          106, _omitEnumNames ? '' : 'CLIENT_ABORT');

  static const $core.List<StoreAndForward_RequestResponse> values =
      <StoreAndForward_RequestResponse>[
    UNSET,
    ROUTER_ERROR,
    ROUTER_HEARTBEAT,
    ROUTER_PING,
    ROUTER_PONG,
    ROUTER_BUSY,
    ROUTER_HISTORY,
    ROUTER_STATS,
    ROUTER_TEXT_DIRECT,
    ROUTER_TEXT_BROADCAST,
    CLIENT_ERROR,
    CLIENT_HISTORY,
    CLIENT_STATS,
    CLIENT_PING,
    CLIENT_PONG,
    CLIENT_ABORT,
  ];

  static final $core.Map<$core.int, StoreAndForward_RequestResponse> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static StoreAndForward_RequestResponse? valueOf($core.int value) =>
      _byValue[value];

  const StoreAndForward_RequestResponse._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
