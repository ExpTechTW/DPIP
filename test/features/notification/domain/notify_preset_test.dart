/// The preset table is a safety decision written as data: which channel each
/// preset silences. A wrong row is a valid list of integers — the server
/// accepts it and the phone simply stops ringing for something — so the rows
/// that keep a life-safety alert on are pinned one by one, not only "it
/// round-trips".
library;

import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// A preset's options as a settings value — what the server holds after the
/// preset is applied in full.
NotifySettings _settingsOf(NotifyPreset preset) => NotifySettings.fromWire([
  for (final channel in NotifyChannel.values) preset.optionFor(channel)!,
]);

const _named = [
  NotifyPreset.recommended,
  NotifyPreset.all,
  NotifyPreset.emergencyOnly,
];

const _weather = [
  NotifyChannel.thunderstorm,
  NotifyChannel.weatherAdvisory,
  NotifyChannel.evacuation,
];

void main() {
  test('every named preset picks an option each channel really offers', () {
    for (final preset in _named) {
      for (final channel in NotifyChannel.values) {
        final option = preset.optionFor(channel);
        expect(option, isNotNull, reason: '$preset leaves $channel unset');
        expect(
          optionsFor(channel)[option!],
          preset.kindFor(channel),
          reason: '$preset/$channel resolves to the wrong wire index',
        );
      }
    }
  });

  test('custom names no option for any channel', () {
    for (final channel in NotifyChannel.values) {
      expect(NotifyPreset.custom.kindFor(channel), isNull);
      expect(NotifyPreset.custom.optionFor(channel), isNull);
    }
  });

  test('the named presets are three different combinations', () {
    final combos = {
      for (final preset in _named)
        NotifyChannel.values.map(preset.optionFor).join(','),
    };
    expect(combos, hasLength(_named.length));
  });

  group('life-safety channels', () {
    test('no preset turns the weather or hazard channels off', () {
      // Each carries an urgent sub-channel (mountain torrents, red-level
      // advisories, debris-flow warnings) the server switches together with
      // the routine messages.
      for (final preset in _named) {
        for (final channel in _weather) {
          expect(
            preset.kindFor(channel),
            NotifyOptionKind.weatherLocal,
            reason: '$preset silences $channel',
          );
        }
      }
    });

    test('emergency only keeps EEW at intensity 4+ and tsunami warnings', () {
      expect(
        NotifyPreset.emergencyOnly.kindFor(NotifyChannel.eew),
        NotifyOptionKind.localIntensity4,
      );
      expect(
        NotifyPreset.emergencyOnly.kindFor(NotifyChannel.tsunami),
        NotifyOptionKind.tsunamiWarning,
      );
    });

    test(
      'emergency only turns off exactly the channels with no urgent tier',
      () {
        final off = [
          for (final channel in NotifyChannel.values)
            if (NotifyPreset.emergencyOnly.kindFor(channel) ==
                NotifyOptionKind.off)
              channel,
        ];
        expect(off, [
          NotifyChannel.monitor,
          NotifyChannel.report,
          NotifyChannel.intensity,
          NotifyChannel.announcement,
        ]);
      },
    );
  });

  test('recommended drops only the earthquake report', () {
    final kinds = {
      for (final channel in NotifyChannel.values)
        channel: NotifyPreset.recommended.kindFor(channel),
    };
    expect(kinds, {
      NotifyChannel.eew: NotifyOptionKind.localIntensity1,
      NotifyChannel.monitor: NotifyOptionKind.localIntensity1,
      NotifyChannel.report: NotifyOptionKind.off,
      NotifyChannel.intensity: NotifyOptionKind.localIntensity1,
      NotifyChannel.thunderstorm: NotifyOptionKind.weatherLocal,
      NotifyChannel.weatherAdvisory: NotifyOptionKind.weatherLocal,
      NotifyChannel.evacuation: NotifyOptionKind.weatherLocal,
      NotifyChannel.tsunami: NotifyOptionKind.tsunamiAll,
      NotifyChannel.announcement: NotifyOptionKind.all,
    });
  });

  test('all is the broadest option on every channel', () {
    for (final channel in NotifyChannel.values) {
      expect(
        NotifyPreset.all.optionFor(channel),
        optionsFor(channel).length - 1,
        reason: 'wire order runs narrowest to broadest',
      );
    }
  });

  group('matching', () {
    test('recognises each named preset', () {
      for (final preset in _named) {
        expect(NotifyPreset.matching(_settingsOf(preset)), preset);
      }
    });

    test('one channel off any preset is custom', () {
      final nearlyRecommended = _settingsOf(NotifyPreset.recommended)
          .withChannel(NotifyChannel.report, 1);
      expect(NotifyPreset.matching(nearlyRecommended), NotifyPreset.custom);
    });

    test('the defaults a fresh device starts from are custom', () {
      // Every channel at its local threshold, report included — what an
      // upgraded user's server already holds. Calling it a preset would claim
      // a choice they never made.
      final fresh = NotifySettings.fromWire(const [1, 1, 1, 1, 1, 1, 1, 1, 1]);
      expect(NotifyPreset.matching(fresh), NotifyPreset.custom);
    });
  });

  group('changesFrom', () {
    test('writes nothing when the settings already match', () {
      for (final preset in _named) {
        expect(preset.changesFrom(_settingsOf(preset)), isEmpty);
      }
      expect(
        NotifyPreset.custom.changesFrom(_settingsOf(NotifyPreset.all)),
        isEmpty,
      );
    });

    test('writes only the channels that differ', () {
      final changes = NotifyPreset.emergencyOnly.changesFrom(
        _settingsOf(NotifyPreset.recommended),
      );
      expect(changes.map((c) => c.channel).toSet(), {
        NotifyChannel.eew,
        NotifyChannel.monitor,
        NotifyChannel.intensity,
        NotifyChannel.tsunami,
        NotifyChannel.announcement,
      });
    });

    test('widening writes go before narrowing ones', () {
      // Emergency-only with the earthquake report turned all the way up:
      // going to recommended widens five channels and narrows that one. A
      // sequence that stops part-way must have added alerts, never removed
      // them first.
      final mixed = _settingsOf(NotifyPreset.emergencyOnly)
          .withChannel(NotifyChannel.report, 2);
      final changes = NotifyPreset.recommended.changesFrom(mixed);

      final firstNarrowing = changes.indexWhere(
        (c) => c.option < mixed.optionOf(c.channel),
      );
      expect(firstNarrowing, greaterThanOrEqualTo(0));
      for (final change in changes.take(firstNarrowing)) {
        expect(change.option, greaterThan(mixed.optionOf(change.channel)));
      }
      for (final change in changes.skip(firstNarrowing)) {
        expect(change.option, lessThan(mixed.optionOf(change.channel)));
      }
      expect(changes.first.channel, NotifyChannel.eew);
      expect(changes.last.channel, NotifyChannel.report);
    });

    test('an applied change list reaches the preset', () {
      for (final from in _named) {
        for (final to in _named) {
          var settings = _settingsOf(from);
          for (final change in to.changesFrom(settings)) {
            settings = settings.withChannel(change.channel, change.option);
          }
          expect(NotifyPreset.matching(settings), to, reason: '$from → $to');
        }
      }
    });
  });
}
