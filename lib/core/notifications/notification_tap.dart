import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A tapped notification, normalised from either ingress (FCM `message.data` or
/// an awesome action `payload`) to a channel key plus its data.
///
/// Carries enough to route to a screen and — once per-item detail routes exist —
/// to the specific item by [id]; the backend already sends it. Keeping the id on
/// the tap now (rather than discarding it at the String-channel boundary) means
/// deep-linking a report/event later is a localised change, not a spine rewrite.
@immutable
class NotificationTap {
  const NotificationTap({this.channelKey, this.data = const {}});

  /// Builds a tap from a raw data/payload map (FCM's dynamic values or awesome's
  /// nullable strings), dropping nulls.
  ///
  /// [channelKey] is the channel the notification was actually posted to, and
  /// it wins over the payload's `channel` key. That order is the whole reason
  /// taps used to land on Home: only notifications **this app** displayed carry
  /// `channel` in their payload — the service puts it there. A server push is
  /// rendered from awesome's own wire format, where the channel is a model
  /// field and the payload holds one key, `content`, with the producer's JSON.
  ///
  /// Three layers are merged into [data], each overwriting the last:
  ///
  /// 1. the fields of `content`,
  /// 2. the flat payload keys,
  /// 3. the producer's own map — **which wins**, and that is the point of it.
  ///    `content` is awesome's model object, so a field dropped in beside `id`
  ///    or `body` competes for a name the library already owns.
  ///
  /// That map is read from `payload` first and `extra` second. `payload` is the
  /// slot awesome's model actually reserves for application data, and on iOS it
  /// is the **only** one that survives: the native side parses `content` into
  /// its model and drops every key it does not recognise, so a custom `extra`
  /// arrives as an empty payload. Android took a different route into the same
  /// place — its FCM data map is copied wholesale — and happened to carry
  /// `extra` through, which is exactly why this looked fine on one platform and
  /// silently lost the deep-link target on the other. `extra` is still read, for
  /// any producer that has not moved yet.
  ///
  /// `content`, `payload` and `extra` are containers, not values, so none of
  /// them appears in [data] under its own name.
  factory NotificationTap.fromData(
    Map<String, dynamic>? raw, {
    String? channelKey,
  }) {
    const containers = {'content', 'payload', 'extra'};
    final data = <String, String>{};
    void put(Map<String, dynamic> source) {
      source.forEach((key, value) {
        if (value != null && !containers.contains(key)) {
          data[key] = value.toString();
        }
      });
    }

    final content = _decode(raw?['content']);
    put(content);
    if (raw != null) put(raw);
    put(_decode(content['extra'] ?? raw?['extra']));
    put(_decode(content['payload'] ?? raw?['payload']));

    return NotificationTap(
      channelKey: channelKey ?? data['channel'] ?? data['channelKey'],
      data: data,
    );
  }

  /// Reads a nested object that may arrive already decoded or as a JSON string.
  ///
  /// Both shapes are real: the producer nests `extra` as an object, while
  /// `content` reaches the app as the raw string awesome passed through. Parsed
  /// leniently — malformed or non-object input is treated as absent, never
  /// thrown on, because a tap must still route.
  static Map<String, dynamic> _decode(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    } on FormatException {
      return const {};
    }
  }

  /// The alert channel that fired (drives which screen the tap opens).
  final String? channelKey;

  /// The message's data payload.
  final Map<String, String> data;

  /// The target item id the backend sends (e.g. a report id), if any.
  String? get id => data['id'];
}
