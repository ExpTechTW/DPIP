// This is a generated file - do not edit.
//
// Generated from meshtastic/atak.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Team extends $pb.ProtobufEnum {
  ///
  ///  Unspecifed
  static const Team Unspecifed_Color =
      Team._(0, _omitEnumNames ? '' : 'Unspecifed_Color');

  ///
  ///  White
  static const Team White = Team._(1, _omitEnumNames ? '' : 'White');

  ///
  ///  Yellow
  static const Team Yellow = Team._(2, _omitEnumNames ? '' : 'Yellow');

  ///
  ///  Orange
  static const Team Orange = Team._(3, _omitEnumNames ? '' : 'Orange');

  ///
  ///  Magenta
  static const Team Magenta = Team._(4, _omitEnumNames ? '' : 'Magenta');

  ///
  ///  Red
  static const Team Red = Team._(5, _omitEnumNames ? '' : 'Red');

  ///
  ///  Maroon
  static const Team Maroon = Team._(6, _omitEnumNames ? '' : 'Maroon');

  ///
  ///  Purple
  static const Team Purple = Team._(7, _omitEnumNames ? '' : 'Purple');

  ///
  ///  Dark Blue
  static const Team Dark_Blue = Team._(8, _omitEnumNames ? '' : 'Dark_Blue');

  ///
  ///  Blue
  static const Team Blue = Team._(9, _omitEnumNames ? '' : 'Blue');

  ///
  ///  Cyan
  static const Team Cyan = Team._(10, _omitEnumNames ? '' : 'Cyan');

  ///
  ///  Teal
  static const Team Teal = Team._(11, _omitEnumNames ? '' : 'Teal');

  ///
  ///  Green
  static const Team Green = Team._(12, _omitEnumNames ? '' : 'Green');

  ///
  ///  Dark Green
  static const Team Dark_Green = Team._(13, _omitEnumNames ? '' : 'Dark_Green');

  ///
  ///  Brown
  static const Team Brown = Team._(14, _omitEnumNames ? '' : 'Brown');

  static const $core.List<Team> values = <Team>[
    Unspecifed_Color,
    White,
    Yellow,
    Orange,
    Magenta,
    Red,
    Maroon,
    Purple,
    Dark_Blue,
    Blue,
    Cyan,
    Teal,
    Green,
    Dark_Green,
    Brown,
  ];

  static final $core.List<Team?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 14);
  static Team? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Team._(super.value, super.name);
}

///
///  Role of the group member
class MemberRole extends $pb.ProtobufEnum {
  ///
  ///  Unspecifed
  static const MemberRole Unspecifed =
      MemberRole._(0, _omitEnumNames ? '' : 'Unspecifed');

  ///
  ///  Team Member
  static const MemberRole TeamMember =
      MemberRole._(1, _omitEnumNames ? '' : 'TeamMember');

  ///
  ///  Team Lead
  static const MemberRole TeamLead =
      MemberRole._(2, _omitEnumNames ? '' : 'TeamLead');

  ///
  ///  Headquarters
  static const MemberRole HQ = MemberRole._(3, _omitEnumNames ? '' : 'HQ');

  ///
  ///  Airsoft enthusiast
  static const MemberRole Sniper =
      MemberRole._(4, _omitEnumNames ? '' : 'Sniper');

  ///
  ///  Medic
  static const MemberRole Medic =
      MemberRole._(5, _omitEnumNames ? '' : 'Medic');

  ///
  ///  ForwardObserver
  static const MemberRole ForwardObserver =
      MemberRole._(6, _omitEnumNames ? '' : 'ForwardObserver');

  ///
  ///  Radio Telephone Operator
  static const MemberRole RTO = MemberRole._(7, _omitEnumNames ? '' : 'RTO');

  ///
  ///  Doggo
  static const MemberRole K9 = MemberRole._(8, _omitEnumNames ? '' : 'K9');

  static const $core.List<MemberRole> values = <MemberRole>[
    Unspecifed,
    TeamMember,
    TeamLead,
    HQ,
    Sniper,
    Medic,
    ForwardObserver,
    RTO,
    K9,
  ];

  static final $core.List<MemberRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static MemberRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MemberRole._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
