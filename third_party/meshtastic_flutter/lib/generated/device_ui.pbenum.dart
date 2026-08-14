// This is a generated file - do not edit.
//
// Generated from meshtastic/device_ui.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CompassMode extends $pb.ProtobufEnum {
  ///
  ///  Compass with dynamic ring and heading
  static const CompassMode DYNAMIC =
      CompassMode._(0, _omitEnumNames ? '' : 'DYNAMIC');

  ///
  ///  Compass with fixed ring and heading
  static const CompassMode FIXED_RING =
      CompassMode._(1, _omitEnumNames ? '' : 'FIXED_RING');

  ///
  ///  Compass with heading and freeze option
  static const CompassMode FREEZE_HEADING =
      CompassMode._(2, _omitEnumNames ? '' : 'FREEZE_HEADING');

  static const $core.List<CompassMode> values = <CompassMode>[
    DYNAMIC,
    FIXED_RING,
    FREEZE_HEADING,
  ];

  static final $core.List<CompassMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CompassMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CompassMode._(super.value, super.name);
}

class Theme extends $pb.ProtobufEnum {
  ///
  ///  Dark
  static const Theme DARK = Theme._(0, _omitEnumNames ? '' : 'DARK');

  ///
  ///  Light
  static const Theme LIGHT = Theme._(1, _omitEnumNames ? '' : 'LIGHT');

  ///
  ///  Red
  static const Theme RED = Theme._(2, _omitEnumNames ? '' : 'RED');

  static const $core.List<Theme> values = <Theme>[
    DARK,
    LIGHT,
    RED,
  ];

  static final $core.List<Theme?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Theme? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Theme._(super.value, super.name);
}

///
///  Localization
class Language extends $pb.ProtobufEnum {
  ///
  ///  English
  static const Language ENGLISH =
      Language._(0, _omitEnumNames ? '' : 'ENGLISH');

  ///
  ///  French
  static const Language FRENCH = Language._(1, _omitEnumNames ? '' : 'FRENCH');

  ///
  ///  German
  static const Language GERMAN = Language._(2, _omitEnumNames ? '' : 'GERMAN');

  ///
  ///  Italian
  static const Language ITALIAN =
      Language._(3, _omitEnumNames ? '' : 'ITALIAN');

  ///
  ///  Portuguese
  static const Language PORTUGUESE =
      Language._(4, _omitEnumNames ? '' : 'PORTUGUESE');

  ///
  ///  Spanish
  static const Language SPANISH =
      Language._(5, _omitEnumNames ? '' : 'SPANISH');

  ///
  ///  Swedish
  static const Language SWEDISH =
      Language._(6, _omitEnumNames ? '' : 'SWEDISH');

  ///
  ///  Finnish
  static const Language FINNISH =
      Language._(7, _omitEnumNames ? '' : 'FINNISH');

  ///
  ///  Polish
  static const Language POLISH = Language._(8, _omitEnumNames ? '' : 'POLISH');

  ///
  ///  Turkish
  static const Language TURKISH =
      Language._(9, _omitEnumNames ? '' : 'TURKISH');

  ///
  ///  Serbian
  static const Language SERBIAN =
      Language._(10, _omitEnumNames ? '' : 'SERBIAN');

  ///
  ///  Russian
  static const Language RUSSIAN =
      Language._(11, _omitEnumNames ? '' : 'RUSSIAN');

  ///
  ///  Dutch
  static const Language DUTCH = Language._(12, _omitEnumNames ? '' : 'DUTCH');

  ///
  ///  Greek
  static const Language GREEK = Language._(13, _omitEnumNames ? '' : 'GREEK');

  ///
  ///  Norwegian
  static const Language NORWEGIAN =
      Language._(14, _omitEnumNames ? '' : 'NORWEGIAN');

  ///
  ///  Slovenian
  static const Language SLOVENIAN =
      Language._(15, _omitEnumNames ? '' : 'SLOVENIAN');

  ///
  ///  Ukrainian
  static const Language UKRAINIAN =
      Language._(16, _omitEnumNames ? '' : 'UKRAINIAN');

  ///
  ///  Bulgarian
  static const Language BULGARIAN =
      Language._(17, _omitEnumNames ? '' : 'BULGARIAN');

  ///
  ///  Simplified Chinese (experimental)
  static const Language SIMPLIFIED_CHINESE =
      Language._(30, _omitEnumNames ? '' : 'SIMPLIFIED_CHINESE');

  ///
  ///  Traditional Chinese (experimental)
  static const Language TRADITIONAL_CHINESE =
      Language._(31, _omitEnumNames ? '' : 'TRADITIONAL_CHINESE');

  static const $core.List<Language> values = <Language>[
    ENGLISH,
    FRENCH,
    GERMAN,
    ITALIAN,
    PORTUGUESE,
    SPANISH,
    SWEDISH,
    FINNISH,
    POLISH,
    TURKISH,
    SERBIAN,
    RUSSIAN,
    DUTCH,
    GREEK,
    NORWEGIAN,
    SLOVENIAN,
    UKRAINIAN,
    BULGARIAN,
    SIMPLIFIED_CHINESE,
    TRADITIONAL_CHINESE,
  ];

  static final $core.Map<$core.int, Language> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Language? valueOf($core.int value) => _byValue[value];

  const Language._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
