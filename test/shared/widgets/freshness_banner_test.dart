import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/freshness_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations zh;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    zh = await AppLocalizations.delegate.load(const Locale('zh', 'TW'));
  });

  String age(AppLocalizations l10n, Duration d) =>
      FreshnessBanner.ageLabel(l10n, d);

  test('minutes under an hour, never zero', () {
    expect(age(en, Duration.zero), '1 minute');
    expect(age(en, const Duration(seconds: 59)), '1 minute');
    expect(age(en, const Duration(minutes: 59)), '59 minutes');
    expect(age(zh, const Duration(minutes: 5)), '5 分鐘');
  });

  test('hours under two days, then days', () {
    expect(age(en, const Duration(hours: 1)), '1 hour');
    expect(age(en, const Duration(hours: 47, minutes: 59)), '47 hours');
    expect(age(en, const Duration(days: 2)), '2 days');
    expect(age(zh, const Duration(days: 9)), '9 天');
  });

  test('a clock that moved backwards reads as the minimum', () {
    expect(age(en, const Duration(minutes: -3)), '1 minute');
  });
}
