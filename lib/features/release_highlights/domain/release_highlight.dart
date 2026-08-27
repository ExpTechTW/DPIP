/// Version-highlight card models.
///
/// The in-app cards are rendered from structured multi-locale content that
/// ships as Dart source in the `dpip_release_highlights` content package —
/// each version's cards live at `release_highlights/<version>/` in the repo and
/// are compiled into the app only when that version is current. UI chrome
/// (titles, section names, buttons) lives in ARB; the article body lives in the
/// content package, keyed by locale so every language reads its own copy.
///
/// A new version is authored as JSON under `release_highlights/<version>/…`,
/// converted to Dart by `tool/gen/release_highlights.py`, and the app's
/// repository imports the new version's files. Older versions stay in the
/// package as the archive; unimported, they are never compiled into a build.
library;

import 'package:json_annotation/json_annotation.dart';

part 'release_highlight.g.dart';

/// Kind of highlight deck — which tab of the version-highlights page it fills.
enum HighlightKind { normal, advanced }

/// Where a deck comes from — abstracted so the page depends on the domain, not
/// on the content-package loading.
abstract interface class ReleaseHighlightRepository {
  /// The current version's deck for [kind].
  ///
  /// Content is compiled into the app (imported from the content package), so
  /// loading never touches the disk or the network and cannot fail.
  HighlightDeck load(HighlightKind kind);
}

/// One deck of cards for one kind, already decoded.
class HighlightDeck {
  const HighlightDeck({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.cards,
  });

  final HighlightKind kind;

  /// Deck title, every locale.
  final LocalizedText title;

  /// Deck subtitle, every locale.
  final LocalizedText subtitle;

  final List<ReleaseHighlightCard> cards;
}

/// A multi-locale string: locale → text. Keys are BCP-47 tags with
/// underscores (`zh_Hant`, `en`, `ja`, …).
typedef LocalizedText = Map<String, String>;

/// A single highlight card — one theme, one headline, one icon, optional big
/// number and detail rows.
@JsonSerializable()
class ReleaseHighlightCard {
  const ReleaseHighlightCard({
    required this.id,
    required this.icon,
    required this.title,
    this.headline,
    this.body,
    this.stat,
    this.statLabel,
    this.highlights = const [],
    this.details = const [],
    this.stats = const [],
  });

  factory ReleaseHighlightCard.fromJson(Map<String, dynamic> json) =>
      _$ReleaseHighlightCardFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseHighlightCardToJson(this);

  /// Stable identifier (also used as the icon's semantic label key).
  final String id;

  /// Material icon name, e.g. `bolt`, `data_saver`. Resolved by the UI layer —
  /// never hand-write a codepoint (DESIGN.md → Icons).
  final String icon;

  /// Card title, in every shipped locale.
  final LocalizedText title;

  /// One-line hook, in every shipped locale.
  final LocalizedText? headline;

  /// Longer body, in every shipped locale.
  final LocalizedText? body;

  /// Big stat number, in every shipped locale.
  final LocalizedText? stat;

  /// Caption under the big number, in every shipped locale.
  final LocalizedText? statLabel;

  /// Short bullet highlights, each localized across the shipped locales.
  final List<LocalizedText> highlights;

  /// Key/value technical rows, in every shipped locale.
  final List<HighlightDetail> details;

  /// Pure-number stat rows (the "verifiable numbers" card), in every locale.
  final List<HighlightStat> stats;

  /// True when [details] is non-empty — a technical card, not a marketing one.
  bool get isTechnical => details.isNotEmpty;
}

/// One key/value row in a technical card, both sides localized.
@JsonSerializable()
class HighlightDetail {
  const HighlightDetail({required this.key, required this.value});

  factory HighlightDetail.fromJson(Map<String, dynamic> json) =>
      _$HighlightDetailFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightDetailToJson(this);

  final LocalizedText key;
  final LocalizedText value;
}

/// One labelled number in the "verifiable numbers" card.
@JsonSerializable()
class HighlightStat {
  const HighlightStat({required this.value, required this.label});

  factory HighlightStat.fromJson(Map<String, dynamic> json) =>
      _$HighlightStatFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightStatToJson(this);

  final LocalizedText value;
  final LocalizedText label;
}

/// Picks the active locale's copy of a [field], falling back to zh_Hant (the
/// authoring locale) and then to whatever key exists.
///
/// [tag] is the BCP-47 tag with underscores (`zh_Hant`, `en`, `ja`, …). The
/// UI layer derives it from `Localizations.localeOf`, keeping domain pure.
String localized(LocalizedText field, String tag) {
  final exact = field[tag];
  if (exact != null) return exact;
  final base = field[tag.split('_').first];
  if (base != null) return base;
  return field['zh_Hant'] ?? field.values.firstOrNull ?? '';
}
