/// Native Intent localization gate: reject the shipped wrong-table regression
/// and incomplete metadata before an iOS archive is built on another platform.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _definition =
    'ios/DPIPWidgets/WeatherWidgetConfiguration.intentdefinition';
const _catalog = 'ios/DPIPWidgets/WeatherWidgetConfiguration.xcstrings';
const _project = 'ios/Runner.xcodeproj/project.pbxproj';

void main() {
  late Directory fixture;
  late Map<String, dynamic> catalog;

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('intent-l10n-');
    for (final path in [_definition, _catalog, _project]) {
      final copy = File('${fixture.path}/$path');
      copy.parent.createSync(recursive: true);
      File(path).copySync(copy.path);
    }
    catalog =
        jsonDecode(File(_catalog).readAsStringSync()) as Map<String, dynamic>;
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  Map<String, dynamic> entry(String key) =>
      (catalog['strings'] as Map<String, dynamic>)[key] as Map<String, dynamic>;

  Map<String, dynamic> unit(String key, String locale) =>
      ((entry(key)['localizations'] as Map<String, dynamic>)[locale]
              as Map<String, dynamic>)['stringUnit']
          as Map<String, dynamic>;

  void check({String? rejection}) {
    File('${fixture.path}/$_catalog').writeAsStringSync(jsonEncode(catalog));
    final result = Process.runSync('python3', [
      'tool/check/intent_localization.py',
      fixture.path,
    ]);
    final output = '${result.stdout}${result.stderr}';
    expect(result.exitCode, rejection == null ? 0 : 1, reason: output);
    if (rejection != null) expect(output, contains(rejection));
  }

  test('accepts all referenced IDs and project locales', () => check());

  test('preserves the saved widget configuration schema identity', () {
    final result = Process.runSync('python3', [
      '-c',
      '''
import json, plistlib, sys
with open(sys.argv[1], 'rb') as f:
    model = plistlib.load(f)
intent = model['INIntents'][0]
parameter = intent['INIntentParameters'][0]
object_type = model['INTypes'][0]
print(json.dumps([
    model['INIntentDefinitionNamespace'], intent['INIntentName'],
    intent['INIntentTitleID'], intent['INIntentDescriptionID'],
    intent['INIntentEligibleForWidgets'],
    parameter['INIntentParameterName'], parameter['INIntentParameterTag'],
    parameter['INIntentParameterType'], parameter['INIntentParameterObjectType'],
    parameter['INIntentParameterObjectTypeNamespace'],
    parameter['INIntentParameterSupportsDynamicEnumeration'],
    object_type['INTypeName'],
    [[p['INTypePropertyName'], p['INTypePropertyTag'], p['INTypePropertyType']]
     for p in object_type['INTypeProperties']]
]))
''',
      '${fixture.path}/$_definition',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(jsonDecode(result.stdout as String), [
      'OFhAEM',
      'WeatherWidgetConfiguration',
      'aDbkHe',
      'ZjfOUb',
      true,
      'location',
      2,
      'Object',
      'WidgetLocation',
      'OFhAEM',
      true,
      'WidgetLocation',
      [
        ['identifier', 1, 'String'],
        ['displayString', 2, 'String'],
        ['pronunciationHint', 3, 'String'],
        ['alternativeSpeakableMatches', 4, 'SpeakableString'],
      ],
    ]);
  });

  test('rejects a missing description localization ID', () {
    (catalog['strings'] as Map<String, dynamic>).remove('ZjfOUb');
    check(rejection: 'missing referenced localization ID ZjfOUb');
  });

  test('rejects each missing supported title locale', () {
    final translations =
        entry('aDbkHe')['localizations'] as Map<String, dynamic>;
    for (final locale in ['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko']) {
      final saved = translations.remove(locale);
      check(rejection: 'aDbkHe/$locale: missing/empty translation');
      translations[locale] = saved;
    }
  });

  test('rejects an empty title or description', () {
    for (final key in ['aDbkHe', 'ZjfOUb']) {
      final saved = unit(key, 'zh-Hant')['value'];
      unit(key, 'zh-Hant')['value'] = '  ';
      check(rejection: '$key/zh-Hant: missing/empty translation');
      unit(key, 'zh-Hant')['value'] = saved;
    }
  });

  test('rejects a description ID without base description text', () {
    final definition = File('${fixture.path}/$_definition');
    definition.writeAsStringSync(
      definition.readAsStringSync().replaceFirst(
        RegExp(r'\s*<key>INIntentDescription</key>\s*<string>[^<]*</string>'),
        '',
      ),
    );
    check(rejection: 'missing/empty INIntentDescription');
  });

  test('rejects incomplete translation state', () {
    unit('aDbkHe', 'ko')['state'] = 'needs_review';
    check(rejection: 'state must be translated');
  });

  test('rejects stale extraction metadata', () {
    entry('aDbkHe')['extractionState'] = 'stale';
    check(rejection: 'invalid localization metadata');
  });

  test('rejects source text that differs from the Intent definition', () {
    unit('aDbkHe', 'en')['value'] = 'Another Intent';
    check(rejection: 'source differs from Intent base');
  });

  test('rejects a mismatched source language', () {
    catalog['sourceLanguage'] = 'ja';
    check(rejection: 'invalid catalog sourceLanguage/version');
  });

  test('rejects altered placeholder syntax and multiplicity', () {
    unit('2S3UQT', 'ja')['value'] = r'${location}: {count}';
    check(rejection: 'mismatched placeholders');
    unit('2S3UQT', 'ja')['value'] = r'${location}: ${count} ${count}';
    check(rejection: 'mismatched placeholders');
  });

  test('requires newly declared project locales', () {
    final project = File('${fixture.path}/$_project');
    project.writeAsStringSync(
      project.readAsStringSync().replaceFirst(
        'knownRegions = (',
        'knownRegions = (fr,',
      ),
    );
    check(rejection: '/fr: missing/empty translation');
  });

  test('rejects the shipped .intentdefinition.strings table name', () {
    File('${fixture.path}/$_catalog')
        .renameSync('${fixture.path}/$_definition.xcstrings');
    final result = Process.runSync('python3', [
      'tool/check/intent_localization.py',
      fixture.path,
    ]);
    expect(result.exitCode, 1);
    expect(result.stdout, contains('cannot load matching Intent/catalog'));
  });
}
