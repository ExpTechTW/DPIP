// This is a generated file - do not edit.
//
// Generated from meshtastic/channel.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  How this channel is being used (or not).
///  Note: this field is an enum to give us options for the future.
///  In particular, someday we might make a 'SCANNING' option.
///  SCANNING channels could have different frequencies and the radio would
///  occasionally check that freq to see if anything is being transmitted.
///  For devices that have multiple physical radios attached, we could keep multiple PRIMARY/SCANNING channels active at once to allow
///  cross band routing as needed.
///  If a device has only a single radio (the common case) only one channel can be PRIMARY at a time
///  (but any number of SECONDARY channels can't be sent received on that common frequency)
class Channel_Role extends $pb.ProtobufEnum {
  ///
  ///  This channel is not in use right now
  static const Channel_Role DISABLED =
      Channel_Role._(0, _omitEnumNames ? '' : 'DISABLED');

  ///
  ///  This channel is used to set the frequency for the radio - all other enabled channels must be SECONDARY
  static const Channel_Role PRIMARY =
      Channel_Role._(1, _omitEnumNames ? '' : 'PRIMARY');

  ///
  ///  Secondary channels are only used for encryption/decryption/authentication purposes.
  ///  Their radio settings (freq etc) are ignored, only psk is used.
  static const Channel_Role SECONDARY =
      Channel_Role._(2, _omitEnumNames ? '' : 'SECONDARY');

  static const $core.List<Channel_Role> values = <Channel_Role>[
    DISABLED,
    PRIMARY,
    SECONDARY,
  ];

  static final $core.List<Channel_Role?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Channel_Role? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Channel_Role._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
