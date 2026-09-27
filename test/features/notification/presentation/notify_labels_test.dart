/// The notification catalogue's labels and icons.
///
/// A mapping table, so what is worth pinning is not each row but the two ways
/// it can go wrong quietly: a channel that was added to the enum and never got
/// its own string (two rows then read identically, and the user cannot tell
/// which alert they are turning off), and a severity tier that stops being
/// visible — the icon is the only part of the row read before the subtitle.
library;

import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_labels.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('every channel has a title of its own', () {
    final titles = {
      for (final channel in NotifyChannel.values)
        notifyChannelTitle(channel, l10n),
    };

    expect(titles, everyElement(isNotEmpty));
    expect(
      titles,
      hasLength(NotifyChannel.values.length),
      reason: 'two channels share a string, so the list cannot be read',
    );
  });

  test('every channel has an icon of its own', () {
    final icons = NotifyChannel.values.map(notifyChannelIcon).toSet();

    expect(icons, hasLength(NotifyChannel.values.length));
  });

  test('every option has a label of its own', () {
    final labels = {
      for (final kind in NotifyOptionKind.values) notifyOptionLabel(kind, l10n),
    };

    expect(labels, everyElement(isNotEmpty));
    expect(labels, hasLength(NotifyOptionKind.values.length));
  });

  test('the three severity tiers stay visually apart', () {
    // Off, an intensity-gated alert, and everything. The subtitle says which
    // is which; the icon is what gets read at a glance down the list, so the
    // tiers must not collapse into one glyph.
    final off = notifyOptionIcon(NotifyOptionKind.off);
    final gated = {
      notifyOptionIcon(NotifyOptionKind.localIntensity4),
      notifyOptionIcon(NotifyOptionKind.tsunamiWarning),
    };
    final everything = {
      notifyOptionIcon(NotifyOptionKind.all),
      notifyOptionIcon(NotifyOptionKind.tsunamiAll),
    };

    expect(gated, hasLength(1), reason: 'both are the "important" tier');
    expect(everything, hasLength(1), reason: 'both are the "all" tier');
    expect({off, ...gated, ...everything}, hasLength(3));
  });
}
