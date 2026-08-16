import 'package:flutter/material.dart';

import 'package:dpip/app/theme/app_spacing.dart';

/// Draws the platform tags in a release note without fetching anything.
///
/// A note marks which platforms an entry applies to with 14 px SVGs hosted in
/// this repository, because that is what GitHub renders. In the app the same
/// Markdown would become an `Image.network` — and this app is read when the
/// network is the thing that failed, so every tag would be a broken box
/// exactly when the note matters most.
///
/// The two known names map to a Material icon instead. Anything else still
/// works: the builder cannot decline, so an unknown image degrades to its own
/// alt text rather than to a failed request.
///
/// Pass this to **every** `MarkdownBody` that renders a release note. It lives
/// here rather than beside one of them because the second page to render a
/// note did not have it, and the symptom — a network fetch, offline, for a
/// decoration — is invisible until the network is gone.
Widget platformTagIcon(Uri uri, String? title, String? alt) {
  final name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  final icon = switch (name) {
    'android.svg' => Icons.android,
    'ios.svg' => Icons.apple,
    _ => null,
  };
  return Builder(
    builder: (context) {
      final style = DefaultTextStyle.of(context).style;
      if (icon == null) return Text(alt ?? '', style: style);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Icon(
          icon,
          size: 16,
          // The colour the surrounding text already carries: the SVG picks a
          // fixed tint because an `<img>` inherits no theme, but here the icon
          // sits inside the theme and should follow it.
          color: style.color,
        ),
      );
    },
  );
}
